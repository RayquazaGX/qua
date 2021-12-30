local here = ...
local Utils = require(here .. ".utils")
local Searchers = require(here .. ".components.searchers")({
    Utils = Utils,
    -- These two folder paths are for default searchers;
    -- they are not used if you use custom searchers when initializing Qua
    folderOfUserHomeStorage =
        (Utils.path.sep == '\\')
        and "%LocalAppData%\\qua\\packages\\"
        or "~/.local/share/qua/packages/",
    folderOfProjectStorage = "./.quapackages/",
})
local Stack = require(here .. ".internal.stack")({
    Utils = Utils
})
local Operators = require(here .. ".internal.operators")({
    Utils = Utils
})

local Qua = {
    _VERSION = "0.1.0",
    lockFileDefault = "lock.quaspec",
    components = {
        Searchers
    },
}
local initedContext = nil
setmetatable(Qua, {__index = function(t, k)
    if initedContext and initedContext[k] then
        return initedContext[k]
    else
        for i = 1, #t.components do
            if t.components[i][k] then return t.components[i][k] end
        end
    end
end})

-- Init Qua, returns context for further operations.
-- After initing, `Qua.xxxx` can also be used in place of the context;
-- which means that `require "qua-runtime"` points to the same context.
-- - lockFilePath: string
-- - options: table?
--   - searchers: Searcher[]?
--     List of searcher functions. Priority goes by index.
--     Defaults to `Searchers.DefaultSearchers()` in `components/searchers.lua`.
--     - where Searcher: fun(name:string, fork:string, version:string):PackageFileOpener
--       - where PackageFileOpener: fun(dotSeperatedFilename:string):file
function Qua.init(lockFilePath, options)
    assert(not initedContext, "Qua already inited!")

    lockFilePath = lockFilePath or Qua.lockFileDefault
    options = options or {}
    options.searchers = options.searchers or Qua.DefaultSearchers()

    local lock = assert(Utils.lang.evalSpecFile(lockFilePath))()
    assert(type(lock) == "table", "Content in a quaspec file should be a table!")

    -- `stack`, `loaded` are useful for debugging
    local stackInterface, stack, loaded = Stack(lock, options.searchers)

    ---- Main API
    -- Remember that these utilities are only available during the loading process
    local context = {}

    -- Require a file under the current package as a Lua script
    function context.require(luaRequireName)
        return Operators.require(stackInterface, luaRequireName)
    end

    -- Open the file specified by a dependency
    function context.requireDependencyFile(dependencyName)
        return Operators.requireDependencyFile(stackInterface, dependencyName)
    end

    -- Require the file specified by a dependency as a Lua script
    function context.requireDependency(dependencyName)
        return Operators.requireDependency(stackInterface, dependencyName)
    end

    -- Info about the current Package
    -- - returns: table
    --   - name: string?
    --   - fork: string?
    --   - version: string?
    --   - open: fun(dotSeperatedFilename:string):file
    function context.currentPackage()
        return stackInterface.top()
    end

    -- Info about a specified package currently in stack
    -- See also `Qua.currentPackage()`
    -- 1: Current package; 2: The package calling current package; etc.
    -- 0 as a special case: Top project, note that top project does not
    -- have a name
    function context.packageStack(nFromTop)
        return
            (nFromTop == 0)
            and stackInterface.bottom()
            or stackInterface.at(nFromTop)
    end

    initedContext = context
    return context
end

return Qua
