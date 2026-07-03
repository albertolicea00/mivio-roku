' MainScene: root scene.
' Responsibilities:
'   - Owns the media-server Task node (JellyfinTask today, PlexTask later).
'   - Manages the screen stack (push/pop) and global back-key handling.
'   - Persists server credentials to the registry after sign in.

sub init()
    m.screenStack = m.top.FindNode("screenStack")
    m.screens = []
    m.started = false
    m.config = MivioConfig_Read()

    startServerTask()
end sub

' Creates the media-server task. Any task exposing the same interface
' (serverUrl/token/userId/deviceId/input/output/ready) can be swapped in;
' see components/tasks/PlexTask.xml for the Plex stub.
sub startServerTask()
    taskName = "JellyfinTask"
    if m.config.serverType = "plex" then taskName = "PlexTask"

    m.serverTask = CreateObject("roSGNode", taskName)
    m.serverTask.serverUrl = m.config.serverUrl
    m.serverTask.token = m.config.token
    m.serverTask.userId = m.config.userId
    m.serverTask.deviceId = CreateObject("roDeviceInfo").GetChannelClientId()

    ' Wait for the task thread to observe its input field before any screen
    ' is allowed to send requests (avoids a missed-event race at startup).
    m.serverTask.ObserveField("ready", "onTaskReady")
    m.serverTask.control = "RUN"
end sub

sub onTaskReady()
    if m.started then return
    if not m.serverTask.ready then return
    m.started = true

    if m.config.serverUrl <> "" and m.config.token <> ""
        pushScreen("HomeScreen", {})
    else
        pushScreen("ServerSetupScreen", {})
    end if
end sub

' ---------------------------------------------------------------------------
' Screen stack
' ---------------------------------------------------------------------------

function pushScreen(screenName as string, fields as object) as object
    screen = CreateObject("roSGNode", screenName)
    if screen = invalid then return invalid

    screen.serverTask = m.serverTask
    if fields <> invalid then screen.SetFields(fields)

    if m.screens.Count() > 0
        m.screens.Peek().visible = false
    end if

    m.screens.Push(screen)
    m.screenStack.AppendChild(screen)
    wireScreen(screenName, screen)
    screen.visible = true
    screen.SetFocus(true)
    return screen
end function

sub popScreen()
    if m.screens.Count() <= 1 then return

    screen = m.screens.Pop()
    if screen.HasField("wasClosed") then screen.wasClosed = true
    m.screenStack.RemoveChild(screen)

    current = m.screens.Peek()
    current.visible = true
    current.SetFocus(true)
end sub

sub resetStackTo(screenName as string)
    while m.screens.Count() > 0
        screen = m.screens.Pop()
        if screen.HasField("wasClosed") then screen.wasClosed = true
        m.screenStack.RemoveChild(screen)
    end while
    pushScreen(screenName, {})
end sub

' Hooks up the navigation signals each screen exposes.
sub wireScreen(screenName as string, screen as object)
    if screenName = "ServerSetupScreen"
        screen.ObserveField("credentials", "onCredentials")
    else if screenName = "HomeScreen"
        screen.ObserveField("selectedItem", "onItemSelected")
    else if screenName = "DetailScreen"
        screen.ObserveField("playRequested", "onPlayRequested")
    else if screenName = "PlayerScreen"
        screen.ObserveField("playbackFinished", "onPlaybackFinished")
    end if
end sub

' ---------------------------------------------------------------------------
' Navigation signal handlers
' ---------------------------------------------------------------------------

sub onCredentials(event as object)
    creds = event.GetData()
    if creds = invalid then return

    m.config.serverUrl = creds.serverUrl
    m.config.token = creds.token
    m.config.userId = creds.userId
    m.config.username = creds.username
    m.config.serverType = "jellyfin" ' TODO: read from setup screen once Plex support lands
    MivioConfig_Write(m.config)

    ' Push the fresh credentials into the running task.
    m.serverTask.serverUrl = creds.serverUrl
    m.serverTask.token = creds.token
    m.serverTask.userId = creds.userId

    resetStackTo("HomeScreen")
end sub

sub onItemSelected(event as object)
    item = event.GetData()
    if item = invalid then return
    pushScreen("DetailScreen", { item: item })
end sub

sub onPlayRequested(event as object)
    item = event.GetData()
    if item = invalid then return
    pushScreen("PlayerScreen", { item: item })
end sub

sub onPlaybackFinished(event as object)
    popScreen()
end sub

' ---------------------------------------------------------------------------
' Key handling
' ---------------------------------------------------------------------------

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back" and m.screens.Count() > 1
        popScreen()
        return true
    end if

    return false
end function
