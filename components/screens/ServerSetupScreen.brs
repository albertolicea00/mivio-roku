' ServerSetupScreen: collects server URL / username / password and signs in.

sub init()
    m.menu = m.top.FindNode("menu")
    m.serverButton = m.top.FindNode("serverButton")
    m.userButton = m.top.FindNode("userButton")
    m.passwordButton = m.top.FindNode("passwordButton")
    m.statusLabel = m.top.FindNode("statusLabel")

    m.form = { serverUrl: "", username: "", password: "" }
    m.editingField = ""
    m.keyboard = invalid
    m.taskObserved = false
    m.busy = false

    m.menu.ObserveField("buttonSelected", "onMenuButton")
    m.top.ObserveField("focusedChild", "onFocusChanged")
end sub

sub onFocusChanged()
    if m.top.HasFocus() then m.menu.SetFocus(true)
end sub

sub onMenuButton()
    if m.busy then return

    index = m.menu.buttonSelected
    if index = 0
        openKeyboard("serverUrl", "Server URL (e.g. 192.168.1.10:8096)", m.form.serverUrl)
    else if index = 1
        openKeyboard("username", "Username", m.form.username)
    else if index = 2
        ' TODO: mask the password input (secure text edit box, Roku OS 10+).
        openKeyboard("password", "Password", m.form.password)
    else if index = 3
        connect()
    end if
end sub

' ---------------------------------------------------------------------------
' Keyboard dialog
' ---------------------------------------------------------------------------

sub openKeyboard(fieldName as string, title as string, currentValue as string)
    m.editingField = fieldName

    keyboard = CreateObject("roSGNode", "KeyboardDialog")
    keyboard.title = title
    keyboard.text = currentValue
    keyboard.buttons = ["OK", "Cancel"]
    keyboard.ObserveField("buttonSelected", "onKeyboardButton")

    m.keyboard = keyboard
    m.top.GetScene().dialog = keyboard
end sub

sub onKeyboardButton()
    if m.keyboard = invalid then return

    if m.keyboard.buttonSelected = 0
        m.form[m.editingField] = m.keyboard.text
        refreshButtons()
    end if

    m.keyboard.close = true
    m.keyboard = invalid
    m.menu.SetFocus(true)
end sub

sub refreshButtons()
    m.serverButton.text = "Server URL: " + displayValue(m.form.serverUrl, false)
    m.userButton.text = "Username: " + displayValue(m.form.username, false)
    m.passwordButton.text = "Password: " + displayValue(m.form.password, true)
end sub

function displayValue(value as string, mask as boolean) as string
    if value = "" then return "(not set)"
    if mask then return String(Len(value), "*")
    return value
end function

' ---------------------------------------------------------------------------
' Sign in
' ---------------------------------------------------------------------------

sub connect()
    if m.form.serverUrl = "" or m.form.username = ""
        m.statusLabel.text = "Please enter at least a server URL and username."
        return
    end if

    task = m.top.serverTask
    if task = invalid
        m.statusLabel.text = "Media-server task is not available."
        return
    end if

    if not m.taskObserved
        task.ObserveField("output", "onTaskOutput")
        m.taskObserved = true
    end if

    m.busy = true
    m.statusLabel.text = "Connecting..."
    task.input = {
        command: "signIn"
        params: {
            serverUrl: m.form.serverUrl
            username: m.form.username
            password: m.form.password
        }
    }
end sub

sub onTaskOutput(event as object)
    output = event.GetData()
    if output = invalid or output.command <> "signIn" then return

    m.busy = false
    if output.success
        m.statusLabel.text = "Connected!"
        m.top.credentials = output.data
    else
        errorText = "Sign in failed."
        if output.error <> invalid then errorText = output.error
        m.statusLabel.text = errorText
    end if
end sub
