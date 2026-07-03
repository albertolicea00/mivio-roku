' DetailScreen: shows media info and requests playback.

sub init()
    m.poster = m.top.FindNode("poster")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.metaLabel = m.top.FindNode("metaLabel")
    m.overviewLabel = m.top.FindNode("overviewLabel")
    m.playButton = m.top.FindNode("playButton")

    m.playButton.ObserveField("buttonSelected", "onPlaySelected")
    m.top.ObserveField("focusedChild", "onFocusChanged")
end sub

sub onFocusChanged()
    if m.top.HasFocus() then m.playButton.SetFocus(true)
end sub

sub onItemChanged()
    item = m.top.item
    if item = invalid then return

    m.titleLabel.text = stringOr(item.title, "")
    m.overviewLabel.text = stringOr(item.overview, "")
    m.poster.uri = stringOr(item.imageUrl, "")
    m.metaLabel.text = buildMetaText(item)
end sub

sub onPlaySelected()
    ' TODO: Series items need an episode picker; for now playback is
    ' attempted directly and the server decides what to do.
    m.top.playRequested = m.top.item
end sub

function buildMetaText(item as object) as string
    parts = []

    mediaType = stringOr(item.mediaType, "")
    if mediaType <> "" then parts.Push(mediaType)

    if item.runtimeTicks <> invalid and item.runtimeTicks > 0
        minutes = Cint(item.runtimeTicks / 600000000)
        if minutes > 0 then parts.Push(minutes.ToStr() + " min")
    end if

    text = ""
    for each part in parts
        if text <> "" then text = text + "  -  "
        text = text + part
    end for
    return text
end function

function stringOr(value as dynamic, fallback as string) as string
    if value = invalid then return fallback
    if GetInterface(value, "ifString") = invalid then return fallback
    return value
end function
