' PosterItem: item renderer used by the HomeScreen RowList.

sub init()
    m.poster = m.top.FindNode("poster")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.focusRing = m.top.FindNode("focusRing")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    m.poster.uri = content.HDPosterUrl
    m.titleLabel.text = content.title
end sub

sub onFocusChanged()
    focused = m.top.focusPercent > 0.5
    m.focusRing.visible = focused
    m.poster.opacity = 0.7 + (0.3 * m.top.focusPercent)
end sub
