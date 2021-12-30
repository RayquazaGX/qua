local Qua = require "qua-runtime"

return {
    name = Qua.currentPackage().name,
    outer = Qua.packageStack(2).name,
}