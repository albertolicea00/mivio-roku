' PlexTask: Plex media-server client (STUB).
' Implements the generic media-server task loop but rejects every command.
'
' TODO: implement the Plex API behind the same command set as JellyfinTask:
'   signIn, getViews, getItems, getHomeContent, getPlaybackInfo,
'   reportPlaying, reportProgress, reportStopped

sub init()
    m.top.functionName = "taskLoop"
end sub

sub taskLoop()
    port = CreateObject("roMessagePort")
    m.top.ObserveField("input", port)
    m.top.ready = true

    while true
        msg = wait(0, port)
        if type(msg) = "roSGNodeEvent" and msg.GetField() = "input"
            request = msg.GetData()
            command = ""
            if request <> invalid and request.command <> invalid then command = request.command

            m.top.output = {
                command: command
                params: {}
                success: false
                data: invalid
                error: "Plex support is not implemented yet"
            }
        end if
    end while
end sub
