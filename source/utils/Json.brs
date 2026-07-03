' JSON helpers shared between render-thread components and Task nodes.

' ParseJson that tolerates invalid / empty / non-string input.
function ParseJsonSafe(text as dynamic) as dynamic
    if text = invalid then return invalid
    if GetInterface(text, "ifString") = invalid then return invalid
    if text = "" then return invalid
    return ParseJson(text)
end function

' Read a string value from an associative array with a fallback.
function JsonGetString(data as dynamic, key as string, fallback as string) as string
    if data = invalid then return fallback
    if GetInterface(data, "ifAssociativeArray") = invalid then return fallback
    value = data[key]
    if value = invalid then return fallback
    if GetInterface(value, "ifString") = invalid then return fallback
    return value
end function

' Read an array value from an associative array; returns [] when missing.
function JsonGetArray(data as dynamic, key as string) as object
    if data <> invalid and GetInterface(data, "ifAssociativeArray") <> invalid
        value = data[key]
        if value <> invalid and GetInterface(value, "ifArray") <> invalid then return value
    end if
    return []
end function
