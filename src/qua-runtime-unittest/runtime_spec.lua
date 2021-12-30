describe("Runtime", function()
    randomize(false)

    package.path = package.path .. ";./?/init.lua"
    local Qua = require("qua-runtime")

    it("inits", function()
        local lockPath = "qua-runtime-unittest/runtime_spec.lock.quaspec"
        local packageStorage1 = "qua-runtime-unittest/runtime_spec_package_storage1"
        local packageStorage2 = "qua-runtime-unittest/runtime_spec_package_storage2"
        local searchers = {
            Qua.SearchFromStorage(packageStorage1),
            Qua.SearchFromStorage(packageStorage2)
        }
        Qua.init(lockPath, {searchers = searchers})
    end)

    it("dealsRequirement", function()
        local Package1 = Qua.requireDependency("package1")
        assert.are.same({
            name = "package1",
            sub = "sub",
            subAgain = "sub",
            inner = {
                name = "package2",
                outer = "package1"
            },
            innerText = "plaintext",
        },
        Package1)
    end)
end)