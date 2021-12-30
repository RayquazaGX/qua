local Utils = {}

Utils.path = {}
Utils.path.sep = package.config:sub(1, 1)
function Utils.path.toSepEnded(path)
    local last = string.sub(path, -1)
    if last == '' then
        error("Not a valid path!")
    elseif last == '/' or last == Utils.path.sep then
        return path
    else
        return path .. Utils.path.sep
    end
end
function Utils.path.concat2(a, b)
    b = b or ""
    if not a or a == "" then
        return b
    else
        return Utils.path.toSepEnded(a) .. b
    end
end
function Utils.path.concat(a, b, c, ...)
    return Utils.path.concat2(a, c and Utils.path.concat(b, c, ...) or b)
end
function Utils.path.convertDotPathToSlashPath(path)
    return
        (string.find(path, '/') or string.find(path, Utils.path.sep))
        and path
        or table.concat(Utils.string.split(path, '%.'), '/')
end

Utils.fs = {}
-- https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
-- Check if a file or directory exists in this path
function Utils.fs.exists(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
        if code == 13 or code == 17 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok, err
end

Utils.fp = {}
-- (a.k.a. Chain-of-Responsibility Pattern)
function Utils.fp.dutyChain(fs, ...)
    local _1, _2, _3, _4, _5, _6
    for i = 1, #fs do
        _1, _2, _3, _4, _5, _6 = fs[i](...)
        if _1 then return _1, _2, _3, _4, _5, _6 end
    end
    return _1, _2, _3, _4, _5, _6
end

Utils.lang = {}
function Utils.lang.eval(str, chunkName, env)
    env = env or {}
    if setfenv and loadstring then
        -- lua 5.1/luaJIT
        local chunk, msg = loadstring(str, chunkName)
        if chunk then
            setfenv(chunk, env)
            return chunk
        else return nil, msg end
    else
        -- lua 5.2 or up
        local chunk, msg = load(str, chunkName, "t", env)
        if chunk then
            return chunk
        else return nil, msg end
    end
end
function Utils.lang.evalOpenedFileAndClose(openedFile, chunkName, env)
    local str = assert(openedFile:read("*a"))
    openedFile:close()
    local chunk, msg = Utils.lang.eval(str, chunkName, env)
    return chunk, msg
end
function Utils.lang.evalSpec(str, chunkName)
    return Utils.lang.eval("return "..str, chunkName, {})
end
function Utils.lang.evalSpecFile(filename)
    local file = assert(io.open(filename, "r"))
    local str = assert(file:read("*a"))
    file:close()
    local chunk, msg = Utils.lang.evalSpec(str, filename)
    return chunk, msg
end

Utils.string = {}
function Utils.string.split(str, sepPattern)
    sepPattern = sepPattern or "%s"
    local ret = {}
    for w in string.gmatch(str, "([^"..sepPattern.."]+)") do
        ret[#ret+1] = w
    end
    return ret
end
-- https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
-- charToHex, hexToChar, urlEncode, urlDecode
function Utils.string.charToHex(c)
    return string.format("%%%02X", string.byte(c))
end
function Utils.string.hexToChar(x)
    return string.char(tonumber(x, 16))
end
function Utils.string.urlEncode(url)
    if url == nil then return nil end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", Utils.string.charToHex)
    url = url:gsub(" ", "+")
    return url
end
function Utils.string.urlDecode(url)
    if url == nil then return nil end
    url = url:gsub("+", " ")
    url = url:gsub("%%(%x%x)", Utils.string.hexToChar)
    return url
end

Utils.table = {}
function Utils.table.deepClone(t)
    if type(t) == "table" then
        local ret = {}
        for k, v in pairs(t) do ret[k] = Utils.table.deepClone(v) end
        return ret
    else
        return t
    end
end

return Utils
