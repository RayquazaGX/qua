-- An internal stack, that holds info about currently loaded files
-- from demanded packages. See also `internal/operators.lua`

return function(options)
    local Utils = options.Utils

    local function Stack(lock, searchers)

        local function getId_fromVersionNotion(notion)
            return string.format(
                "%s@%s@%s",
                notion[1],
                notion[2],
                notion[3]
            )
        end
        local function getId_fromPackage(package)
            return string.format(
                "%s@%s@%s",
                package.name,
                package.fork,
                package.version
            )
        end
        local function loadForStack(packageLock)
            local loaded = Utils.table.deepClone(packageLock)
            loaded.loaded = {} -- loaded file under package
            loaded.open = nil
            if loaded.name then
                -- Use searchers IO for packages
                loaded.open = assert(Utils.fp.dutyChain(
                    searchers,
                    loaded.name,
                    loaded.fork,
                    loaded.version
                ))
            else
                -- Use project scope IO for anonymous packages
                loaded.open = function(dotPath, mode)
                    return io.open(
                        Utils.path.convertDotPathToSlashPath(dotPath),
                        mode
                    )
                end
            end
            return loaded
        end

        -- Refs to raw tables provided by lock file
        -- Note that the project serves as an anonymous package
        local project = lock.project or {}
        local packages = {}
        if lock.packages then
            for i = 1, #lock.packages do
                local id = getId_fromPackage(lock.packages[i])
                packages[id] = packages[id] or lock.packages[i]
            end
        end

        -- Storing processed content using `contentGetter`
        -- stack: [1]=bottom of the stack(project), [n]=top of the stack
        -- loaded: [true]=project, [id]=package
        local stack = {}
        local loaded = {}

        -- Top project is always at the bottom of the stack
        loaded[true] = loadForStack(project)
        stack[1] = loaded[true]

        local interface = {}

        function interface.push(versionNotion)
            local id = getId_fromVersionNotion(versionNotion)
            if not loaded[id] then
                local packageLock = packages[id]
                assert(packageLock, "Package not found or invalid version!")
                loaded[id] = loadForStack(packageLock)
            end
            stack[#stack+1] = loaded[id]
        end

        function interface.pop()
            assert(#stack > 1, "Cannot pop stack: No package in stack!")
            stack[#stack] = nil
        end

        function interface.top()
            return stack[#stack]
        end

        function interface.bottom()
            return stack[1]
        end

        function interface.at(nFromTop)
            return stack[#stack + 1 - nFromTop]
        end

        return interface, stack, loaded
    end

    return Stack
end
