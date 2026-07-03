' HomeScreen: shows one RowList row per server library, filled with posters.

sub init()
    m.rowList = m.top.FindNode("rowList")
    m.statusLabel = m.top.FindNode("statusLabel")
    m.taskObserved = false
    m.loaded = false

    m.rowList.ObserveField("rowItemSelected", "onRowItemSelected")
    m.top.ObserveField("focusedChild", "onFocusChanged")
end sub

sub onFocusChanged()
    if m.top.HasFocus() then m.rowList.SetFocus(true)
end sub

' Fired when MainScene hands us the media-server task; starts loading.
sub onServerTaskChanged()
    if m.loaded then return
    task = m.top.serverTask
    if task = invalid then return

    if not m.taskObserved
        task.ObserveField("output", "onTaskOutput")
        m.taskObserved = true
    end if

    m.loaded = true
    m.statusLabel.text = "Loading your libraries..."
    task.input = { command: "getHomeContent", params: {} }
end sub

sub onTaskOutput(event as object)
    output = event.GetData()
    if output = invalid or output.command <> "getHomeContent" then return

    if not output.success
        errorText = "Could not load libraries."
        if output.error <> invalid then errorText = output.error
        m.statusLabel.text = errorText
        return
    end if

    buildRows(output.data)
end sub

sub buildRows(rows as object)
    content = CreateObject("roSGNode", "ContentNode")

    if rows <> invalid
        for each row in rows
            if row.items <> invalid and row.items.Count() > 0
                rowNode = content.CreateChild("ContentNode")
                rowNode.title = row.title
                for each item in row.items
                    itemNode = rowNode.CreateChild("ContentNode")
                    itemNode.title = item.title
                    itemNode.HDPosterUrl = item.imageUrl
                    ' Stash the full item metadata for Detail/Player screens.
                    itemNode.AddFields({ meta: item })
                end for
            end if
        end for
    end if

    m.rowList.content = content

    if content.GetChildCount() = 0
        m.statusLabel.text = "No media found on this server."
    else
        m.statusLabel.text = ""
        if m.top.IsInFocusChain() then m.rowList.SetFocus(true)
    end if
end sub

sub onRowItemSelected()
    selected = m.rowList.rowItemSelected ' [rowIndex, itemIndex]
    content = m.rowList.content
    if content = invalid or selected = invalid or selected.Count() < 2 then return

    rowNode = content.GetChild(selected[0])
    if rowNode = invalid then return

    itemNode = rowNode.GetChild(selected[1])
    if itemNode = invalid or not itemNode.HasField("meta") then return

    m.top.selectedItem = itemNode.meta
end sub
