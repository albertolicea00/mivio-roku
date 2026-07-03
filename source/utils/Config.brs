' Registry-backed configuration persistence for Mivio.
' Stores the media-server connection (URL, token, user) in roRegistrySection.
' Watch state and profiles are NOT stored locally - they live on the server.

function MivioConfig_Read() as object
    section = CreateObject("roRegistrySection", "MivioConfig")
    keys = ["serverType", "serverUrl", "username", "userId", "token"]

    config = {}
    for each key in keys
        if section.Exists(key)
            config[key] = section.Read(key)
        else
            config[key] = ""
        end if
    end for

    if config.serverType = "" then config.serverType = "jellyfin"
    return config
end function

sub MivioConfig_Write(config as object)
    section = CreateObject("roRegistrySection", "MivioConfig")
    for each key in config
        value = config[key]
        if value <> invalid and GetInterface(value, "ifString") <> invalid
            section.Write(key, value)
        end if
    end for
    section.Flush()
end sub

sub MivioConfig_Clear()
    registry = CreateObject("roRegistry")
    registry.Delete("MivioConfig")
    registry.Flush()
end sub
