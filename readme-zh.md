## 概念 ##
---

### 使用情景 ###

#### <u>按工程写出配置 | Project -> Manifest</u> ####

按照包管理器的思路，各个脚本工程都可以看作一个个包来管理。包的要素主要包括：
- 描述：名称、描述和维护人等，用文字方式简要记录包的信息以区分于其他的包
- 版本：用版本号记录包的发展
- 入口：期望此包能在什么情况下被运行
- 直接依赖的包：记录要想正确导入此包需要先导入哪些其他包

这些信息被记录在工程配置文件中。

在Qua包管理器里，这对应`project.quaspec`文件。如果工程下包含`project.quaspec`文件，请将其加入到版本管理程序中。`project.quaspec`可以手动修改，也可以用CLI的指令按需自动修改。

#### <u>从配置锁定依赖版本 | Manifest -> Lock</u> ####

工程配置文件记录了各个依赖项后，每个依赖项又可能再依赖其他的项。另外，也需要根据各包内对依赖项的版本要求，计算出适合各要求的具体版本；确定下来也便于他人使用同样的各包版本复现工程。

也就是说，要有一个文件来记录：
- 直接和间接的依赖项：各包间的依赖形成树状层级，这里需要摊平所有依赖项形成一个列表，来检查整个依赖树确定各依赖都有效；例如避免出现两包间循环依赖的情况
- 各包的具体版本：借此找到目标文件唯一指定的内容；如果没有具体版本的话，包对应的文件内容在不同主机上可能不一致，会影响工程按预期正确运行

这些信息被记录在版本锁定文件中。

在Qua包管理器里，这对应`lock.quaspec`文件。如果工程下包含`lock.quaspec`文件，请将其加入到版本管理程序中。不建议手动修改`lock.quaspec`。

#### <u>按依赖版本下载依赖包 | Lock -> Dependency Files</u> ####

根据版本锁定文件，就可以按其中的内容从源仓库下载各个包到本地了。

对大部分包管理器来说，下载按结果可以分成两种类型：
- 下载到本机全局位置：可以在本机上正在开发中的各个工程间通用
- 下载到工程下或其他指定文件夹下：便于打包发布时随主程序一同发布

这两种类型Qua都支持，但默认下载到本机全局位置。通过CLI指令的参数也可以选择下载到工程下或者其他指定的文件夹下。

### 文件组织结构 ###

#### <u>已下载的包的位置</u> ####

如果下载包时没有显式指定位置，已下载的包根据CLI指令的参数会存放在两个默认位置：
- 全局位置：
    - Windows上是`%LocalAppData%\qua\packages\`
    - Unix上是`~/.local/share/qua/packages/`
- 包的工作目录下：
    - `./.quapackages/`

具体结构如下：

```
<packges-root>/
|- <package-name>/
  |- <fork-name>/         # 包含"/"时按各段拆为层级目录
    |- <version>/
      |- package.quaspec  # 包描述文件，即使包中已存在此文件仍会从源仓库覆盖
      |- ...              # 包内其他各种文件
```

#### <u>包的工作目录</u> ####

可能和大多数语言包管理器不同的一点是，不存在`package.quaspec`的包也能被视为是有效的包，这样能够兼容没有专门为Qua包管理器做调整的源码。对应的，这样一来包内脚本也无法利用Qua运行时所提供的设施。

```
<work-dir>/
|- (.quapackages/)    # 使用CLI下载各依赖包时，若指定下载到工作目录下，则默认下载到此文件夹；建议在版本控制中排除
|- (package.quaspec)  # 包描述文件；建议添加到版本控制中；如果不需要其他Qua包作为依赖项，且不利用Qua运行时设施，则可以省略
|- (lock.quaspec)     # 版本锁定文件；如果`package.quaspec`存在，则建议通过CLI生成此文件，并添加到版本控制中；否则将按各依赖项最高可用版本锁定（不推荐）
|- ...                # 包内其他各种文件
```

#### <u>源仓库</u> ####

源仓库记录有哪些包可供安装。通常是远端的git仓库，但在本机查询包或将要安装包时，也会被拉取到本机。

```
<repo-root>/
|- <package-name>/
  |- <fork-name>/          # 包含"/"时按各段拆为层级目录
    |- <version>/
      |- package.quaspec   # 包描述文件；如果工作目录下也存在，两份应保持一致
      |- registry.quaspec  # 注册项文件，包含如何下载等信息
      |- (source.zip)      # 如果`registry.quaspec`里的下载方式用了"regdir"，可以直接把包放在这里（不推荐）
```

## API列表 ##
---

### CLI指令 ###

```bash
qua get version    # 打印Qua版本号
qua help [<topic>] # 打印帮助

### 配置

# 设置源仓库
# 支持http/https上的git仓库，例如https://yourremote/repo.git
# 源仓库按添加顺序被查询，新加的源仓库优先
qua list repository           # 显示源仓库列表
qua add repository <repo>     # 添加源仓库
qua remove repository <repo>  # 移除源仓库

# 更多设置
qua globalconfig  # 打开全局设置文件

### 初始化工程

# 设置工作目录，初始化`package.quaspec`文件
qua init [<dir>] [-e <entry-point-file>] [-h <host-id-range>] [-p <package-id>] # 向<dir>写出`package.quaspec`文件作为工作目录配置；不指定<dir>时使用控制台当前工作目录
    # -e | --entry-point <entry-point-file>  标明脚本包被`require`时，入口文件是工作目录下的<entry-point-file>；不指定时默认是`init.lua`
    # -h | --host <host-id-range>            记录脚本包推荐用于的宿主程序范围为<host-id-range>；<host-id-range>形如`host-name[/fork-name][@version-range]`，或特殊字符串`*`表示可用于任意宿主程序；默认为`*`
    # -p | --publication <package-id>        记录脚本包对外公开时使用的标识为<package-id>；<package-id>形如`package-name[/fork-name][@version]`

### 操作工作目录

# 显示工作目录信息
qua list entry-point [-w <workdir>]  # 显示入口设置列表
qua list host [-w <workdir>]         # 显示建议宿主程序列表
qua get id [-w <workdir>]            # 显示包的标识，形如`package-name[/fork-name][@version]`
qua get publication [-w <workdir>]   # 显示发布时所用信息
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`package.quaspec`；默认使用控制台当前工作目录

# 从源仓库寻找并列出包
# <pattern>使用Lua模式匹配
# 默认只匹配包名，使用`-s``-d`和`-l`可以分别指定也在概述、说明和标签中寻找
# 只会列出可安装并正常使用的包，不符合宿主程序要求的包会自动隐藏：优先使用`-h`标识的<host-id-range>匹配；不指明`-h`则使用当前目录中的`package.quaspec`中的信息；不存在`package.quaspec`则匹配任意宿主程序
qua search [-r <repo>] [-sdl] <pattern> [-v <version-range>] [-h <host-id-range>]
    # -r | --repo <repo>              只从源仓库<repo>查找包
    # -s | --summary                  也在概述文字中寻找是否有和<pattern>相符的结果
    # -d | --description              也在说明文字中寻找是否有和<pattern>相符的结果
    # -l | --label                    也在标签中寻找是否有和<pattern>相符的结果
    # -h | --host <host-id-range>     只匹配目标宿主程序能整个覆盖<host-id-range>范围的包；<host-id-range>形如`host-name[/fork-name][@version-range]`，或`*`表示要求可用于任意宿主程序
    # -v | --version <version-range>  只匹配包版本符合<version-range>的包

# 设置直接依赖项（编辑`package.quaspec`）
# 这些指令操作`package.quaspec`中记录的对其他Qua包的直接依赖
# 同时升级或降级多个包时，会从顶级未被其他要变动的包依赖的包优先开始变动
# 如果要升级或降级的包被其他包依赖，则只会升级或降级到不打破依赖的最高版本
# 如果包的升级或降级会途经或抵达已安装的另一个版本的同标识(名package-name和派生名fork-name都相同)的包，会优先合流到这个已安装版本并停止
# <package-id-range>形如`package-name[/fork-name][@version-range]`，用来指定欲操作的具体依赖
qua list dependency [-w <workdir>]                                # 列出直接依赖的其他包
qua add dependency [-w <workdir>] [-r <repo>] <package-id-range>  # 从源仓库安装包，作为工作目录的直接依赖项
qua remove dependency [-w <workdir>] <package-id-range>           # 从工作目录的直接依赖项中移除指定的包
qua upgrade dependency [-w <workdir>] [-r <repo>] <package-id-range> [-v <version>]  # 升级<package-id-range>所指定的依赖项
qua upgrade-all dependency [-w <workdir>] [-r <repo>]             # 升级所有可升级的依赖项
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`package.quaspec`；默认使用控制台当前工作目录
    # -r | --repo <repo>        只从源仓库<repo>查找包
    # -v | --version <version>  最高只更新到<version>版本；如果无法更新到<version>版本，更新到最接近的版本；不指定时，尽可能升到最新版本

# 设置依赖项版本（更新`lock.quaspec`）
# 这些指令在保持`package.quaspec`中给定的依赖要求不变的基础上，操作`lock.quaspec`中的依赖项的具体版本
# 同时升级或降级多个包时，会从顶级未被其他要变动的包依赖的包优先开始变动
# 如果要升级或降级的包被其他包依赖，则只会升级或降级到不打破依赖的最高版本
# 如果包的升级或降级会途经或抵达已安装的另一个版本的同标识(名package-name和派生名fork-name都相同)的包，会优先合流到这个已安装版本并停止
# <package-id>形如`package-name[/fork-name][@version]`，可以用来指定欲变动的包的现有具体版本
qua sync lock [-w <workdir>]                                        # 重建`lock.quaspec`文件，使之符合`package.quaspec`中的要求，同时尽可能不变动已存在的`lock.quaspec`中现有锁定版本
qua list lock [-w <workdir>]                                        # 以树状列表列出`lock.quaspec`中记录的直接和间接依赖项包（不会修改`lock.quaspec`内容）
qua upgrade lock [-w <workdir>] [-r <repo>] <package-id> [-v <version>]  # 升级<package-id>所指定的包
qua upgrade-all lock [-w <workdir>] [-r <repo>]                          # 升级所有可升级的包
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`package.quaspec`；默认使用控制台当前工作目录
    # -r | --repo <repo>        只从源仓库<repo>查找包
    # -v | --version <version>  最高只更新到<version>版本；如果无法更新到<version>版本，更新到最接近的版本；不指定时，尽可能升到最新版本

# 下载包或设置已下载的包
qua sync package [-w <workdir>] [-g | -d [<dir>]]  # 根据`lock.quaspec`，按需下载锁定版本的包到本地以供使用
qua list package [-w <workdir>] [-g | -d [<dir>]]  # 列出已下载到全局或<dir>下的各包
    # -w | --working <workdir>    使用指定工作目录中的设置并对其进行操作，<workdir>下必须已经包含`package.quaspec`；默认使用控制台当前工作目录
    # -g | --global               下载包到全局默认位置（默认使用此项）
    # -d | --destination [<dir>]  下载包到指定目录<dir>下；<dir>是相对控制台工作目录的路径；不指定<dir>时使用包下默认路径（见文档「文件组织结构」）

# 一键式更新
qua sync [-w <workdir>] [-g | -d [<dir>]]  # `qua sync lock && qua sync package`的简写

```

### package.quaspec ###

```lua
-- `*.quaspec`文件的格式是一个用`{}`围住的Lua表。表中各域仅允许字面量或仅由字面量构成的表。
-- `package.quaspec`具体允许的各项如下：（默认都是必填项，只有带有“（可选）”字样的项是选填项）
{
    -- 此文件所用`quaspec`格式的版本
    quaspec = "0.1.0",

    -- （可选）该工作目录包含的程序入口信息
    -- 其他程序（宿主程序或者其他包）使用作为Qua包的此工作目录时，通过唤起入口文件来调起此包
    -- 入口信息是一个哈希表：键是入口的名字，值是入口文件相对工作目录的路径
    -- 一个特殊的入口名`default`表示此包被Lua的`require`时所用的入口，不设置时默认为`./init.lua`
    -- 除了`default`外，其他的入口名字对应的意义由调用方自行约定
    entry_points = {

        -- （可选）"default"对应此包作为被`require`的对象时的入口脚本；省略则默认"init.lua"
        default = "init.lua",

        -- （可选）其他任意字符串键值对应自定义的入口脚本；这些入口如何被唤起取决于宿主程序内的实现
        release = "main.lua",
        debug = "main_debug.lua",
    },

    -- 该工作目录所表示的包的信息
    -- 手动更改后建议用CLI前端`qua sync`下载更新数据
    package = {

        -- 推荐宿主程序列表
        -- 宿主程序是Qua包最终的服务对象，这个列表表示期望此Qua包能在什么宿主程序下运行
        -- 每个条目的格式是{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
        -- 多个目标表示这个包可以用于多种可能的宿主程序，按条目顺序优先匹配靠前的条目
        -- 一个特殊的字符串"*"可以用来匹配任意宿主程序（例如如果期望此Qua包能在任意宿主程序中运行，可以写作hosts={"*"}）
        hosts = {
            {"some-special-host", "alice/main", ">=1.0.0, <1.3.10, ~=1.3.6", {repo = "https://somespecificsource/repo.git"}},
            {"some-fallback-host", "bob/main", "~>1.2"},
        },

        -- 此包依赖的由宿主程序提供的库列表
        -- 这个列表表示要求宿主程序提供对应的库，才能保证此Qua包正常运行（例如，由C/C++层面提供的库等等适用于此列表）
        -- 每个条目的格式是{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
        -- 名称会作为脚本包内require使用的字符串参数，或者也可用rename指定require时使用的别名
        -- `qua add dependency ...`和`qua remove dependency ...`会自动扩容此列表以满足下面`dependencies`中的要求
        host_dependencies = {
            {"some-gui-dependency", "claire/main", "~>1", {repo = "https://somespecificsource/repo.git", rename = "gui"}},
            {"some-threading-dependency", "david/main", "~>1"},
        },

        -- 直接依赖的Qua包列表
        -- 这个列表表示工作目录下的脚本可以使用什么其他Qua包所提供的现有脚本资源；工作目录被执行时会在本地寻找对应的包
        -- 每个条目的格式是{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
        -- 名称会作为脚本包内require使用的字符串参数，或者也可用rename指定require时使用的别名
        -- `qua add dependency ...`和`qua remove dependency ...`会自动修改此列表，以记录此包所用的依赖
        dependencies = {
            {"some-oop-dependency", "elissa/main", "~>3, ~=3.2", {repo = "https://somespecificsource/repo.git", rename = "oop"}},
            {"some-algorithm-dependency", "frank/main", "~>2"},
        },
    },

    -- （可选）发布信息
    -- 将包提交到源仓库时需要公开的信息，以便用户搜寻到此包
    publication = {

        -- 包的名称，[A-Za-z0-9-]+
        -- 名称会作为脚本包内require使用的字符串参数
        name = "example-package",

        -- 包的派生名，[A-Za-z0-9-/]+
        -- 这个域会用于区别同名包，也便于直观描述源码来自于哪个代码库的哪个分支
        -- 建议命名为类似`git仓库所有人/git分支名`的格式，各部分和版本控制程序保持一致
        fork = "example-author/main",

        -- 包的版本，遵守semver2.0.0规范
        -- 这个域会用于确定是否能为他人下载的此包提供更新等等，作为包管理器确定包的版本的直接依据
        -- 建议和版本控制程序中的版本标签保持一致
        version = "1.0.0",

        -- 包的概述
        summary = "Insert a brief summary of the package.",

        -- 包的说明
        description = [[
            Insert a longer description of the package here.
            You may want to write about the motivations, goals, features and restrictions of the package.
        ]],

        -- 包的标签
        -- 推荐在这里写明包所对应的领域和可用于的宿主程序
        labels = {"graphics", "shader", "toon-shading", "some-special-host", "some-fallback-host"},

        -- 包源码所使用的协议
        license = "MIT",

        -- 维护此包的维护人及联系方式
        maintainer = "John Doe <johndoe123@abc.net>",

        -- （可选）包的主页
        homepage = "https://somegitservice.net/example-author/example-package",

        -- （可选）问题反馈页面
        issue_tracker = "https://somegitservice.net/example-author/example-package/issues",

    },

}

```

### lock.quaspec ###

```lua
-- `*.quaspec`文件的格式是一个用`{}`围住的Lua表。表中各域仅允许字面量或仅由字面量构成的表。
-- `locks.quaspec`具体允许的各项如下：（默认都是必填项，只有带有“（可选）”字样的项是选填项）
{
    -- 此文件所用`quaspec`格式的版本
    quaspec = "0.1.0",

    -- 各直接或间接依赖项的各个包被锁定到的版本；按id字典顺排列
    versions = {

        -- 一个依赖项
        {
            -- 此包标识信息，{名称，派生名，版本（semver2版本号），元数据（可选）}
            -- 与源仓库中对应`package.quaspec`中的`publication`对应域一致
            -- 但元数据可以指定`rename`以重命名在`require`中使用的名字
            id = {"some-dependency", "author/main", "1.0.0", {repo = "https://somespecificsource/repo.git", rename = "renamed"}},

            -- 此包的各直接依赖项
            -- 与源仓库中对应`package.quaspec`中的`package.dependencies`对应域一致
            dependencies = {
                {"some-algorithm-dependency", "david/main", "~>2"},
            },

            -- 此包来源
            -- 与源仓库中对应`registry.quaspec`中的`source`一致
            source = {type = "curl", file = "https://someremote/some-dependency/author/main/v1.0.0.tar.gz", md5 = "0f1e2d3c4b5a69788796a5b4c3d2e1f0"},
        },
    }
}
```

### registry.quaspec ###

```lua
-- `*.quaspec`文件的格式是一个用`{}`围住的Lua表。表中各域仅允许字面量或仅由字面量构成的表。
-- `registry.quaspec`具体允许的各项如下：（默认都是必填项，只有带有“（可选）”字样的项是选填项）
{
    -- 此文件所用`quaspec`格式的版本
    quaspec = "0.1.0",

    -- 下载源码的方式
    source = {

        -- 源码会以什么途径下载到本地。可以选用的值有"regdir"（直接从注册项同级目录寻找文件），"curl"（通过curl下载网络上的文件到本地）
        type = "curl",

        -- 文件路径；`type`为"regdir"时，直接视为相对于当前文件夹的相对文件路径；`type`为"curl"时，填写远程文件的路径
        -- 下载下来的文件经过验证后解压使用
        file = "https://somegitservice.net/example-author/example-package/archive/refs/tags/v0.0.1.tar.gz",

        -- 文件压缩包的MD5，用于验证包的完整性
        md5 = "0f1e2d3c4b5a69788796a5b4c3d2e1f0",
    },
}

```

### Qua运行时库 ###

```lua
-- 在宿主程序或者宿主程序所用Lua脚本的入口中导入这个运行时库
-- 这样一来：
--     宿主程序：调用下面的初始化函数后，可以通过`require`利用已下载的Qua包
--     Qua包编写者：无需二次引入这些文件，可以直接使用`require "qua"`使用下面除了初始化函数外的其他设施（当然，如果是为了能和不使用Qua包管理器的其他宿主程序兼容，也可以选择不使用这些设施）

-- 导入此包
local qua = require "qua"
local version = qua._VERSION

-- 初始化
-- 初始化由宿主程序或者宿主程序所用Lua脚本的入口使用，并且只可以调用一次，初始化完成后不能修改传入的设置
-- 可以链式调用例如`qua("./script").useGlobal().setHost({...}).setHostPackages({}).init()`
-- 实际做的工作是向`package.loaders or package.searchers`中加入自定义的搜索函数，以供require能找到对应的Qua包
-- 详细来说，搜索函数`searcher`的签名为`local package = searcher(requirename)`，`requirename`格式与lua自带的`require`所接受的参数相同
-- 如果`requirename`只由一节构成，这个函数加载`requirename`包下由`package.quaspec`所指定的默认入口文件
-- 如果`requirename`由多节构成形如"foo.a.b.c"，这个函数加载`foo`包下的`a/b/c.lua`
-- 如果对应的包未导入则返回`nil`
local quaInitSetting = qua(entryPointPackageDir, entryPointName?)   -- 设置入口包；`entryPointPackageDir`是相对应用程序当前工作目录的路径；可用`entryPointName`指定使用包中`package.quaspec`的`entry_points`中记录的哪个入口，默认为"default"
local quaInitSetting = quaInitSetting.useGlobal()           -- 从全局默认位置搜索已下载的包（不建议在打包发布版本中使用此设置）
local quaInitSetting = quaInitSetting.useLocal(dir?)        -- 从指定目录搜索已下载的包；`dir`是相对应用程序当前工作目录的路径，省略时使用入口包下的".quapackages"目录
local quaInitSetting = quaInitSetting.useSearcher(searcher) -- 从指定函数搜索已下载的包，例如可以用来在压缩文件中搜索等等，取决于实际配置；`searcher`是一个函数，其签名是`local open = searcher(packageId)`，未找到`packageId`对应的包时返回的`open`为`nil`，否则返回的`open`与Lua自带的`io.open`一致，调用后返回对应符合Lua io库标准的文件对象，但参数传入的路径是相对于`packageId`对应包下的相对路径，使用绝对路径或超出包的路径时抛出错误
local quaInitSetting = quaInitSetting.setHostId(hostId, useStrict)              -- 能允许所用的Qua包通过`getHost`读取此处所给定的`hostId`；如果`useStrict`为真值，搜索函数找到入口包时，用`hostId`对照包`package.quaspec`中的`package.hosts`域，无法匹配时会抛出错误，以此强制要求入口包符合宿主程序的要求（非入口包不受影响）
local quaInitSetting = quaInitSetting.setHostPackages(hostPackages, useStrict)  -- 能允许所用的Qua包通过`getHostPackages`读取此处所给定的`hostPackages`；如果`useStrict`为真值，搜索函数找到各Qua包时，用`hostPackages`对照包`package.quaspec`中的`package.host_dependencies`域，无法匹配时会抛出错误，以此强制各Qua包符合宿主程序的要求
local entryPointPackage = quaInitSetting.init()  -- 将`hostId`等已设定的配置加入记录，并修改`package.loaders or package.searchers`，向其末尾加入按配置生成的搜索函数，以供`require`能找到对应的Qua包，最后返回加载好的入口；这个函数只能调用一次，之后的调用会抛出错误

-- 宿主程序信息
-- 通常由Qua包内使用，以在必要时动态区分宿主程序
local hostId = qua.getHostId()              -- 返回先前初始化时`hostId`的副本
local hostPackages = qua.getHostPackages()  -- 返回先前初始化时`hostPackages`的副本

-- 包内IO
local open = qua.packageIO(packageId)  -- 返回一个能按相对路径打开`packageId`对应包下文件的`open`函数；未找到`packageId`对应的包时返回的`open`为`nil`，否则返回的`open`与Lua自带的`io.open`一致，调用后返回对应符合Lua io库标准的文件对象，但参数传入的路径是相对于`packageId`对应包下的相对路径，使用绝对路径或超出包的路径时抛出错误

```

### Qua包管理器作为Qua包：qua-package-manager ###

```lua
-- 这个包提供在开发时对Qua包的搜索/下载等管理方式，是CLI工具的后端

-- 使用此包
local pm = require "qua-package-manager"
local version = pm._VERSION

-- 读取和写出配置文件（`*.quaspec`）
local spec = pcall(pm.readSpec, path...)       -- 读取配置文件
local ok = pcall(pm.writeSpec, spec, path...)  -- 写出配置文件

-- 下载管理
local ok = pcall(pm.pullRepo, localRepoDir, remoteGitRepo)          -- 从`remoteGitRepo`更新源仓库到本地`localRepoDir`
local ok, packages, registries = pcall(pm.readRepo, localRepoDir)   -- 从`localRepoDir`读取源仓库中各包描述和各注册项
local ok, packages = pcall(pm.readRepoPackages, localRepoDir)       -- 从`localRepoDir`读取可下载的各包描述
local ok, registries = pcall(pm.readRepoRegistries, localRepoDir)   -- 从`localRepoDir`读取可下载的各包注册项
local ok, packages = pcall(pm.readLocalPackages, localPackagesDir)  -- 从`localPackagesDir`读取已下载的各包描述

-- 工程更新
local ok, syncedLock = pcall(pm.syncLock, package, oldLock?)             -- 从`spec`和可能的`oldLock`更新依赖情况，计算新的版本锁定，得到`syncedLock`；循环依赖等情况无法建立新lock时失败
local ok, syncedPackages, syncedRegistries = pcall(pm.syncPackage, lock) -- 按照`lock`提供的版本锁定，从源仓库找到对应各包的包描述和注册项，得到`syncedPackages`和`syncedRegistries`，按照这两个结果下载包就可满足工作目录的要求；源仓库没有办法提供所要求的包等情况无法得到对应的包描述和注册项时失败

```
