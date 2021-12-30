-- Operators on a internal stack(`internal/stack.lua`)
-- When a `requireDependency` happens, we push the required
-- dependency onto the top of the stack; and when it finishes being
-- evaled, we pop it off from the stack.

return function(options)
    local Utils = options.Utils

    local Operators = {}

    local function getInterfaceDotPath(package, demandingVersionNotion)
        return
            package
            and package.provisions
            and package.provisions[
                demandingVersionNotion[4] or "default"
            ]
            or "init"
    end

    local function makeChunkName(package, filePath)
        return string.format("%s@%s@%s:%s",
            package.name,
            package.fork,
            package.version,
            filePath
        )
    end

    function Operators.require(stack, dotPath)
        local top = stack.top()
        if not top.loaded[dotPath] then
            local filename = Utils.path.convertDotPathToSlashPath(dotPath)
            local file = assert(top.open(filename))
            local evaled = assert(Utils.lang.evalOpenedFileAndClose(
                file,
                makeChunkName(top, filename),
                _G
            ))()
            top.loaded[dotPath] = evaled
        end
        return top.loaded[dotPath]
    end

    local function pushAndLocateDependency(stack, dependencyName)
        local versionNotion = stack.top().dependencies[dependencyName]
        assert(versionNotion, "Dependency not registered!")
        stack.push(versionNotion)
        local newTop = stack.top()
        local dotPath = getInterfaceDotPath(newTop, versionNotion)
        assert(dotPath, "Entry point interface not registered!")
        return dotPath, newTop
    end

    function Operators.requireDependencyFile(stack, dependencyName)
        local dotPath, newTop = pushAndLocateDependency(stack, dependencyName)
        local filename = Utils.path.convertDotPathToSlashPath(dotPath)
        local file = assert(newTop.open(filename))
        stack.pop()
        return file
    end

    function Operators.requireDependency(stack, dependencyName)
        local dotPath, newTop = pushAndLocateDependency(stack, dependencyName)
        if not newTop.loaded[dotPath] then
            local filename = Utils.path.convertDotPathToSlashPath(dotPath)
            local file = assert(newTop.open(filename))
            local evaled = assert(Utils.lang.evalOpenedFileAndClose(
                file,
                makeChunkName(newTop, filename),
                _G
            ))()
            newTop.loaded[dotPath] = evaled
        end
        stack.pop()
        return newTop.loaded[dotPath]
    end

    return Operators
end
