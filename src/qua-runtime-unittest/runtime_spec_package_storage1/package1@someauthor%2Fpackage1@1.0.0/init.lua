local Qua = require "qua-runtime"

return {
    name = Qua.currentPackage().name,
    sub = Qua.require("subfolder.sub"),
    subAgain = Qua.require("subfolder.sub"),
    inner = Qua.requireDependency("package2"),
    innerText = Qua.requireDependencyFile("package2plaintext"):read("*a")
}