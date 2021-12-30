-- Unlike lua builtin searchers, a searcher here does not load a certain file,
-- but makes an opener function for opening files inside the package,
-- with no permission on opening files outside the package.

return function(options)
    local Utils = options.Utils
    local folderOfProjectStorage = options.folderOfProjectStorage
    local folderOfUserHomeStorage = options.folderOfUserHomeStorage
    local packageSearchPath = options.packageSearchPath or package.path

    -- Always allow matching original name when searching (least priority)
    packageSearchPath = packageSearchPath .. ";./?"

    local Searchers = {}

    local function getPathOfPackage(storage, name, fork, version)
        return
            Utils.path.toSepEnded(Utils.path.concat2(
                storage,
                string.format(
                    "%s@%s@%s",
                    Utils.string.urlEncode(name),
                    Utils.string.urlEncode(fork),
                    version
                )
            ))
    end

    local function StoragePackageFileOpener(packageDir)
        -- TODO: FIXME: Prevent accessing to outside of the package
        return function(dotPath, mode)
            -- Use `packageSearchPath`, search each possible location
            local searchParts = Utils.string.split(packageSearchPath, ';')
            local fullFilenames = {} -- for printing error message
            for i = 1, #searchParts do
                -- One possible location
                local slashPath = Utils.path.convertDotPathToSlashPath(dotPath)
                local filename = string.gsub(searchParts[i], '%?', slashPath)
                local fullFilename = Utils.path.concat2(packageDir, filename)
                fullFilenames[#fullFilenames+1] = fullFilename
                -- Success
                if Utils.fs.exists(fullFilename) then
                    return io.open(fullFilename, mode)
                end
            end
            -- Failure
            local msg = "Cannot find such file:"
            for i = 1, #fullFilenames do
                msg = string.format("%s\r\n\tfrom: %s", msg, fullFilenames[i])
            end
            return nil, msg
        end
    end

    function Searchers.SearchFromStorage(dir)
        return function(name, fork, version)
            local packageDir = getPathOfPackage(dir, name, fork, version)
            if Utils.fs.exists(packageDir) then
                return StoragePackageFileOpener(packageDir)
            else
                return nil, string.format(
                        "Could not find package: %s@%s@%s",
                        name, fork, version)
            end
        end
    end

    function Searchers.SearchFromProject()
        return Searchers.SearchFromStorage(folderOfProjectStorage)
    end

    function Searchers.SearchFromUserHome()
        return Searchers.SearchFromStorage(folderOfUserHomeStorage)
    end

    function Searchers.DefaultSearchers()
        return {
            Searchers.SearchFromProject(),
            Searchers.SearchFromUserHome(),
        }
    end

    return Searchers
end
