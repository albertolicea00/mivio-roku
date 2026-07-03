' JellyfinTask: all Jellyfin HTTP traffic happens here, on the task thread.
' No network calls ever run on the render thread.
'
' Supported commands (request via the "input" field):
'   signIn          params: { serverUrl, username, password }
'   getViews        params: {}
'   getItems        params: { parentId }
'   getHomeContent  params: {}   (views + items per view in one response)
'   getPlaybackInfo params: { itemId }
'   reportPlaying / reportProgress / reportStopped
'                   params: { itemId, mediaSourceId, playSessionId,
'                             positionTicks, isPaused }

sub init()
    m.top.functionName = "taskLoop"
end sub

sub taskLoop()
    m.port = CreateObject("roMessagePort")
    m.top.ObserveField("input", m.port)

    ' Cache connection state locally on the task thread.
    m.serverUrl = m.top.serverUrl
    m.token = m.top.token
    m.userId = m.top.userId
    m.deviceId = m.top.deviceId
    if m.deviceId = "" then m.deviceId = CreateObject("roDeviceInfo").GetChannelClientId()

    ' Signal the render thread that requests can be sent now.
    m.top.ready = true

    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGNodeEvent" and msg.GetField() = "input"
            request = msg.GetData()
            if request <> invalid and request.command <> invalid
                handleRequest(request)
            end if
        end if
    end while
end sub

sub handleRequest(request as object)
    command = request.command
    params = request.params
    if params = invalid then params = {}

    if command = "signIn"
        result = signIn(params)
    else if command = "getViews"
        result = getViews()
    else if command = "getItems"
        result = getItems(params)
    else if command = "getHomeContent"
        result = getHomeContent()
    else if command = "getPlaybackInfo"
        result = getPlaybackInfo(params)
    else if command = "reportPlaying"
        result = reportPlayback("/Sessions/Playing", params, false)
    else if command = "reportProgress"
        result = reportPlayback("/Sessions/Playing/Progress", params, true)
    else if command = "reportStopped"
        result = reportPlayback("/Sessions/Playing/Stopped", params, false)
    else
        result = fail("Unknown command: " + command)
    end if

    m.top.output = {
        command: command
        params: params
        success: result.success
        data: result.data
        error: result.error
    }
end sub

' ---------------------------------------------------------------------------
' Commands
' ---------------------------------------------------------------------------

function signIn(params as object) as object
    m.serverUrl = normalizeServerUrl(JsonGetString(params, "serverUrl", ""))
    m.token = ""
    if m.serverUrl = "" then return fail("Server URL is required")

    body = {
        Username: JsonGetString(params, "username", "")
        Pw: JsonGetString(params, "password", "")
    }
    response = httpRequest("POST", m.serverUrl + "/Users/AuthenticateByName", body)
    if response.code = 401 then return fail("Wrong username or password")
    if response.code <> 200 then return fail("Sign in failed (HTTP " + response.code.ToStr() + ")")

    data = ParseJsonSafe(response.body)
    if data = invalid or data.AccessToken = invalid or data.User = invalid
        return fail("Unexpected response from server")
    end if

    m.token = data.AccessToken
    m.userId = JsonGetString(data.User, "Id", "")

    return succeed({
        serverUrl: m.serverUrl
        token: m.token
        userId: m.userId
        username: JsonGetString(params, "username", "")
    })
end function

function getViews() as object
    response = httpRequest("GET", m.serverUrl + "/Users/" + m.userId + "/Views", invalid)
    if response.code <> 200 then return fail("Could not load libraries (HTTP " + response.code.ToStr() + ")")

    data = ParseJsonSafe(response.body)
    if data = invalid then return fail("Unexpected response from server")

    views = []
    for each entry in JsonGetArray(data, "Items")
        views.Push({
            id: JsonGetString(entry, "Id", "")
            title: JsonGetString(entry, "Name", "Library")
            collectionType: JsonGetString(entry, "CollectionType", "")
        })
    end for
    return succeed(views)
end function

function getItems(params as object) as object
    parentId = JsonGetString(params, "parentId", "")
    if parentId = "" then return fail("parentId is required")

    query = "?ParentId=" + parentId
    query = query + "&SortBy=SortName&SortOrder=Ascending&Limit=60"
    query = query + "&Recursive=true&IncludeItemTypes=Movie,Series,Video"
    query = query + "&Fields=Overview,RunTimeTicks,PrimaryImageAspectRatio"
    query = query + "&ImageTypeLimit=1&EnableImageTypes=Primary"

    response = httpRequest("GET", m.serverUrl + "/Users/" + m.userId + "/Items" + query, invalid)
    if response.code <> 200 then return fail("Could not load items (HTTP " + response.code.ToStr() + ")")

    data = ParseJsonSafe(response.body)
    if data = invalid then return fail("Unexpected response from server")

    items = []
    for each entry in JsonGetArray(data, "Items")
        items.Push(mapItem(entry))
    end for
    return succeed(items)
end function

' Fetches views and their items in a single request/response round trip so
' screens do not have to queue several task requests at once.
function getHomeContent() as object
    viewsResult = getViews()
    if not viewsResult.success then return viewsResult

    rows = []
    for each view in viewsResult.data
        row = { id: view.id, title: view.title, items: [] }
        itemsResult = getItems({ parentId: view.id })
        if itemsResult.success then row.items = itemsResult.data
        rows.Push(row)
    end for
    return succeed(rows)
end function

function getPlaybackInfo(params as object) as object
    itemId = JsonGetString(params, "itemId", "")
    if itemId = "" then return fail("itemId is required")

    url = m.serverUrl + "/Items/" + itemId + "/PlaybackInfo?UserId=" + m.userId
    response = httpRequest("GET", url, invalid)
    if response.code <> 200 then return fail("Could not load playback info (HTTP " + response.code.ToStr() + ")")

    data = ParseJsonSafe(response.body)
    mediaSources = JsonGetArray(data, "MediaSources")
    if mediaSources.Count() = 0 then return fail("No playable media sources")

    mediaSource = mediaSources[0]
    playSessionId = JsonGetString(data, "PlaySessionId", "")
    mediaSourceId = JsonGetString(mediaSource, "Id", "")

    container = JsonGetString(mediaSource, "Container", "mp4")
    containerParts = container.Tokenize(",")
    if containerParts.Count() > 0 then container = containerParts[0]

    transcodingUrl = JsonGetString(mediaSource, "TranscodingUrl", "")
    if transcodingUrl <> ""
        ' Server decided to transcode: use the HLS URL it prepared.
        streamUrl = m.serverUrl + transcodingUrl
        streamFormat = "hls"
    else
        streamUrl = m.serverUrl + "/Videos/" + itemId + "/stream." + container
        streamUrl = streamUrl + "?Static=true&MediaSourceId=" + mediaSourceId
        streamUrl = streamUrl + "&PlaySessionId=" + playSessionId
        streamUrl = streamUrl + "&api_key=" + m.token
        streamFormat = containerToStreamFormat(container)
    end if

    ' TODO: resume support - read UserData.PlaybackPositionTicks from the item
    ' and surface it here so PlayerScreen can set content.playStart.
    return succeed({
        itemId: itemId
        url: streamUrl
        streamFormat: streamFormat
        playSessionId: playSessionId
        mediaSourceId: mediaSourceId
        positionTicks: 0
    })
end function

function reportPlayback(path as string, params as object, includePause as boolean) as object
    body = {
        ItemId: JsonGetString(params, "itemId", "")
        MediaSourceId: JsonGetString(params, "mediaSourceId", "")
        PlaySessionId: JsonGetString(params, "playSessionId", "")
        PositionTicks: params.positionTicks
        PlayMethod: "DirectStream"
        CanSeek: true
    }
    if body.PositionTicks = invalid then body.PositionTicks = 0
    if includePause
        isPaused = false
        if params.isPaused <> invalid then isPaused = params.isPaused
        body.IsPaused = isPaused
    end if

    response = httpRequest("POST", m.serverUrl + path, body)
    if response.code >= 200 and response.code < 300 then return succeed({})
    return fail("Playback report failed (HTTP " + response.code.ToStr() + ")")
end function

' ---------------------------------------------------------------------------
' HTTP plumbing
' ---------------------------------------------------------------------------

' Blocking HTTP request (safe here: we are on the task thread).
' Returns { code as integer, body as string }; code 0 means transport failure.
function httpRequest(method as string, url as string, body as dynamic) as object
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.RetainBodyOnError(true)
    transfer.EnableEncodings(true)

    if LCase(Left(url, 8)) = "https://"
        transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
        transfer.InitClientCertificates()
    end if

    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("Content-Type", "application/json")
    transfer.AddHeader("X-Emby-Authorization", buildAuthHeader())

    started = false
    if method = "POST"
        payload = ""
        if body <> invalid then payload = FormatJson(body)
        started = transfer.AsyncPostFromString(payload)
    else
        started = transfer.AsyncGetToString()
    end if
    if not started then return { code: 0, body: "" }

    msg = wait(30000, port)
    if type(msg) = "roUrlEvent"
        return { code: msg.GetResponseCode(), body: msg.GetString() }
    end if

    transfer.AsyncCancel()
    return { code: 0, body: "" }
end function

function buildAuthHeader() as string
    q = Chr(34)
    header = "MediaBrowser Client=" + q + "Mivio Roku" + q
    header = header + ", Device=" + q + "Roku" + q
    header = header + ", DeviceId=" + q + m.deviceId + q
    header = header + ", Version=" + q + "0.1.0" + q
    if m.token <> invalid and m.token <> ""
        header = header + ", Token=" + q + m.token + q
    end if
    return header
end function

' ---------------------------------------------------------------------------
' Mapping helpers
' ---------------------------------------------------------------------------

function mapItem(entry as object) as object
    id = JsonGetString(entry, "Id", "")

    imageUrl = ""
    if id <> ""
        imageUrl = m.serverUrl + "/Items/" + id + "/Images/Primary"
        imageUrl = imageUrl + "?maxWidth=400&quality=90&api_key=" + m.token
    end if

    runtimeTicks = 0
    if entry.RunTimeTicks <> invalid then runtimeTicks = entry.RunTimeTicks

    return {
        id: id
        title: JsonGetString(entry, "Name", "")
        overview: JsonGetString(entry, "Overview", "")
        mediaType: JsonGetString(entry, "Type", "")
        imageUrl: imageUrl
        runtimeTicks: runtimeTicks
    }
end function

function normalizeServerUrl(url as string) as string
    trimmed = url.Trim()
    if trimmed = "" then return ""
    if LCase(Left(trimmed, 7)) <> "http://" and LCase(Left(trimmed, 8)) <> "https://"
        trimmed = "http://" + trimmed
    end if
    while Right(trimmed, 1) = "/"
        trimmed = Left(trimmed, Len(trimmed) - 1)
    end while
    return trimmed
end function

function containerToStreamFormat(container as string) as string
    lowered = LCase(container)
    if lowered = "mkv" then return "mkv"
    if lowered = "ts" or lowered = "mpegts" then return "ts"
    if lowered = "m3u8" or lowered = "hls" then return "hls"
    return "mp4"
end function

' ---------------------------------------------------------------------------
' Result helpers
' ---------------------------------------------------------------------------

function succeed(data as dynamic) as object
    return { success: true, data: data, error: invalid }
end function

function fail(message as string) as object
    return { success: false, data: invalid, error: message }
end function
