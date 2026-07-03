' PlayerScreen: plays a stream with the native Video node and reports
' watch progress back to the media server (watch state lives server-side).

sub init()
    m.video = m.top.FindNode("video")
    m.statusLabel = m.top.FindNode("statusLabel")

    m.taskObserved = false
    m.startedReported = false
    m.stopReported = false
    m.closing = false
    m.playSessionId = ""
    m.mediaSourceId = ""

    m.top.ObserveField("focusedChild", "onFocusChanged")
end sub

sub onFocusChanged()
    if m.top.HasFocus() then m.video.SetFocus(true)
end sub

' Fired when MainScene sets the item to play (serverTask is set first).
sub onItemChanged()
    item = m.top.item
    task = m.top.serverTask
    if item = invalid or task = invalid then return

    if not m.taskObserved
        task.ObserveField("output", "onTaskOutput")
        m.taskObserved = true
    end if

    m.statusLabel.text = "Preparing playback..."
    task.input = { command: "getPlaybackInfo", params: { itemId: item.id } }
end sub

sub onTaskOutput(event as object)
    output = event.GetData()
    if output = invalid or output.command <> "getPlaybackInfo" then return
    if m.closing then return

    if not output.success
        errorText = "Could not start playback."
        if output.error <> invalid then errorText = output.error
        m.statusLabel.text = errorText
        return
    end if

    startPlayback(output.data)
end sub

sub startPlayback(data as object)
    m.playSessionId = data.playSessionId
    m.mediaSourceId = data.mediaSourceId

    content = CreateObject("roSGNode", "ContentNode")
    content.url = data.url
    content.streamFormat = data.streamFormat
    content.title = m.top.item.title
    if data.positionTicks <> invalid and data.positionTicks > 0
        content.playStart = data.positionTicks / 10000000
    end if

    m.statusLabel.visible = false
    m.video.content = content
    m.video.notificationInterval = 10 ' progress reports every 10 seconds
    m.video.ObserveField("state", "onVideoState")
    m.video.ObserveField("position", "onVideoPosition")
    m.video.control = "play"
    m.video.SetFocus(true)
end sub

' ---------------------------------------------------------------------------
' Playback state / progress reporting
' ---------------------------------------------------------------------------

sub onVideoState()
    state = m.video.state

    if state = "playing"
        if not m.startedReported
            m.startedReported = true
            report("reportPlaying", false)
        else
            report("reportProgress", false) ' resumed after pause
        end if
    else if state = "paused"
        report("reportProgress", true)
    else if state = "finished" or state = "stopped"
        reportStopped()
        if not m.closing then m.top.playbackFinished = true
    else if state = "error"
        m.statusLabel.visible = true
        m.statusLabel.text = "Playback error: " + m.video.errorMsg
        reportStopped()
    end if
end sub

sub onVideoPosition()
    if m.startedReported and not m.stopReported
        report("reportProgress", false)
    end if
end sub

sub reportStopped()
    if m.stopReported then return
    if not m.startedReported then return
    m.stopReported = true
    report("reportStopped", false)
end sub

sub report(command as string, isPaused as boolean)
    task = m.top.serverTask
    item = m.top.item
    if task = invalid or item = invalid then return

    task.input = {
        command: command
        params: {
            itemId: item.id
            mediaSourceId: m.mediaSourceId
            playSessionId: m.playSessionId
            positionTicks: toTicks(m.video.position)
            isPaused: isPaused
        }
    }
end sub

function toTicks(positionSeconds as double) as longinteger
    ' Jellyfin uses 100-nanosecond ticks (1 second = 10,000,000 ticks).
    return positionSeconds * 10000000&
end function

' Called by MainScene right before this screen is popped from the stack.
sub onClosed()
    if not m.top.wasClosed then return
    m.closing = true
    reportStopped()
    m.video.control = "stop"
end sub
