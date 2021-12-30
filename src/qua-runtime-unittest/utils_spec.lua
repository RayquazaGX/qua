describe("Utils", function()
    local Utils = require "qua-runtime.utils"
    describe("path", function()
        it("concats", function()
            local toSepEnded = Utils.path.toSepEnded
            assert.has_error(function() return toSepEnded(nil) end)
            assert.has_error(function() return toSepEnded("") end)
            assert.are.equal("a/", toSepEnded("a"))
            assert.are.equal("/a/", toSepEnded("/a"))
            assert.are.equal("a/", toSepEnded("a/"))

            local concat2 = Utils.path.concat2
            assert.are.equal("", concat2(nil,nil))
            assert.are.equal("", concat2(nil,""))
            assert.are.equal("", concat2("",nil))
            assert.are.equal("", concat2("",""))
            assert.are.equal("b", concat2("","b"))
            assert.are.equal("a/", concat2("a",nil))
            assert.are.equal("a/", concat2("a",""))
            assert.are.equal("a/b", concat2("a","b"))
            assert.are.equal("a/", concat2("a/",""))
            assert.are.equal("a/b", concat2("a/","b"))

            local concat = Utils.path.concat
            assert.are.equal("", concat(nil,nil))
            assert.are.equal("", concat(nil,""))
            assert.are.equal("", concat("",nil))
            assert.are.equal("", concat("",""))
            assert.are.equal("", concat("","",""))
            assert.are.equal("c", concat("","","c"))
            assert.are.equal("b/", concat("","b",""))
            assert.are.equal("b/c", concat("","b","c"))
            assert.are.equal("a/", concat("a",nil,nil))
            assert.are.equal("a/", concat("a","",""))
            assert.are.equal("a/c", concat("a",nil,"c"))
            assert.are.equal("a/c", concat("a","","c"))
            assert.are.equal("a/b/", concat("a","b",""))
            assert.are.equal("a/b/c", concat("a","b","c"))
            assert.are.equal("a/b/c", concat("a/","b","c"))
            assert.are.equal("a/b/c", concat("a","b/","c"))
            assert.are.equal("a/b/c", concat("a/","b/","c"))
            assert.are.equal("a/b/c/", concat("a/","b/","c/"))
        end)
        it("converts", function()
            local dpathToSpath = Utils.path.convertDotPathToSlashPath
            assert.has_error(function() dpathToSpath(nil) end)
            assert.are.equal("", dpathToSpath(""))
            assert.are.equal("a", dpathToSpath("a"))
            assert.are.equal("a/b", dpathToSpath("a.b"))
            assert.are.equal("a/b", dpathToSpath("a/b"))
            assert.are.equal("a/b/c", dpathToSpath("a.b.c"))
            assert.are.equal("a.b/c", dpathToSpath("a.b/c"))
            assert.are.equal("a/b.c", dpathToSpath("a/b.c"))
            assert.are.equal("a/b/c", dpathToSpath("a/b/c"))
        end)
    end)

    describe("fs", function()
        it("checksExistence", function()
            local exists = Utils.fs.exists
            assert.is.truthy(exists("qua-runtime-unittest/"))
            assert.is.truthy(exists("qua-runtime-unittest/utils_spec.lua"))
            assert.is.falsy(exists("qua-runtime-unittest-bad/"))
            assert.is.falsy(exists("qua-runtime-unittest/utils_spec_bad.lua"))
        end)
    end)

    describe("fp", function()
        it("makesDutyChain", function()
            local dutyChain = Utils.fp.dutyChain

            local counter
            local signal
            local lose = function(x)
                counter = counter + 1
                return false, counter, signal
            end
            local lose_addSignal = function(x)
                counter = counter + 1
                signal = signal + 1
                return false, counter, signal
            end
            local win = function(x)
                counter = counter + 1
                return true, counter, signal, x
            end

            local function unit(fs, x, _1B, _2B, _3B, _4B)
                counter = 0
                signal = 0
                local _1A, _2A, _3A, _4A = dutyChain(fs, x)
                assert.are.equal(_1B, _1A)
                assert.are.equal(_2B, _2A)
                assert.are.equal(_3B, _3A)
                assert.are.equal(_4B, _4A)
            end

            unit(
                {lose}, "1",
                false, 1, 0, nil
            )
            unit(
                {lose_addSignal}, "2",
                false, 1, 1, nil
            )
            unit(
                {win}, "3",
                true, 1, 0, "3"
            )
            unit(
                {lose, lose, lose, lose}, "4",
                false, 4, 0, nil
            )
            unit(
                {lose, lose_addSignal, lose, lose_addSignal}, "5",
                false, 4, 2, nil
            )
            unit(
                {lose, lose, win, lose}, "6",
                true, 3, 0, "6"
            )
            unit(
                {lose, lose_addSignal, win, lose_addSignal}, "7",
                true, 3, 1, "7"
            )
        end)
    end)

    describe("lang", function()
        it("evals", function()
            local eval = Utils.lang.eval
            assert.has_error(function() return assert(eval(nil)) end)
            assert.has_error(function() return assert(eval("("))() end)
            assert.are.equal(0, eval("return 0")())
            assert.are.equal(55, eval("local n=0;for i=1,10 do n=n+i end return n")())
            do
                local env = {}
                eval("a=1", "chunkName", env)()
                assert.are.equal(1, env.a)
            end

            local evalOpenedFileAndClose = Utils.lang.evalOpenedFileAndClose
            do
                assert.has_error(function() return evalOpenedFileAndClose(nil) end)
                local file = io.open("qua-runtime-unittest/utils_spec_eval_file.luafile")
                assert.are.equal(24, evalOpenedFileAndClose(file, "chunkName", _G)())
                assert.has_error(function() return evalOpenedFileAndClose(file) end)
            end

            local evalSpec = Utils.lang.evalSpec
            assert.has_error(function() return evalSpec(nil) end)
            assert.has_error(function() return evalSpec("(")() end)
            assert.are.equal(0, evalSpec("0")())
            assert.are.equal(1+3.14, evalSpec("1+3.14")())

            local evalSpecFile = Utils.lang.evalSpecFile
            assert.has_error(function() return evalSpecFile(nil) end)
            assert.has_error(function() return evalSpecFile("bad.luatable") end)
            assert.are.same(
                {"One", {["Yin"] = "Yang"}},
                evalSpecFile("qua-runtime-unittest/utils_spec_eval_spec.luatable")()
            )
        end)
    end)

    describe("string", function()
        it("splits", function()
            local split = Utils.string.split
            assert.has_error(function() split(nil) end)
            assert.are.same({}, split(""))
            assert.are.same({"a"}, split("a"))
            assert.are.same({"a", "b"}, split("a b"))
            assert.are.same({"a", "b", "c"}, split("a b c"))
            assert.are.same({"a", "b", "c"}, split("  a   b   c  "))
            assert.are.same({}, split("", '%.'))
            assert.are.same({"a"}, split("a", '%.'))
            assert.are.same({"a", "b"}, split("a.b", '%.'))
            assert.are.same({"a", "b", "c"}, split("a.b.c", '%.'))
            assert.are.same({"a", "b", "c"}, split("..a...b...c..", '%.'))
        end)
        it("encodesAndDecodes", function()
            local encode = Utils.string.urlEncode
            local decode = Utils.string.urlDecode
            assert.are.equal(nil, encode(nil))
            assert.are.equal("", encode(""))
            assert.are.equal("a", encode("a"))
            assert.are.equal("a%2Fb", encode("a/b"))
            assert.are.equal(nil, decode(nil))
            assert.are.equal("", decode(""))
            assert.are.equal("a", decode("a"))
            assert.are.equal("a/b", decode("a%2Fb"))
        end)
    end)

    describe("table", function()
        it("clones", function()
            local deepClone = Utils.table.deepClone
            assert.are.same(nil, deepClone(nil))
            assert.are.same(1, deepClone(1))
            assert.are.same({}, deepClone({}))
            assert.are.same({a=1}, deepClone({a=1}))
            assert.are.same({a=1, {b=2}}, deepClone({a=1, {b=2}}))
            assert.are.same({a=1, {b=2, c={3,4,5}}}, deepClone({a=1, {b=2, c={3,4,5}}}))
        end)
    end)
end)
