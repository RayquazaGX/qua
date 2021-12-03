## 概念 ##
---

### 使用情景 ###

#### <u>按工程写出配置 | Project -> Manifest</u> ####

按照包管理器的思路，各个子工程都可以看作一个个包来管理。为了能让正在开发的工程利用已存在的各个包，需要一个工程配置文件，要素包括：

- 入口：期望此包能在什么情况下被运行
- 直接依赖项：记录要想正确导入此包需要先导入哪些其他包

在Qua包管理器里，这对应工程目录下的`project.quaspec`文件。如果工程下包含`project.quaspec`文件，请将其加入到版本管理程序中。`project.quaspec`可以手动修改，也可以用CLI的指令按需自动修改。

为了兼容现有的非Qua包工程（例如已经公开的现有Lua库），不放置`project.quaspec`文件的工程目录也可以当作Qua包使用，但这种包无法依赖其他Qua包。

#### <u>从配置锁定依赖版本 | Manifest -> Lock</u> ####

工程配置文件记录了各个依赖项后，每个依赖项又可能再依赖其他的项。另外，也需要根据各包内对依赖项的版本要求，计算出适合各要求的具体版本；确定下来也便于他人使用同样的各包版本复现工程。因此，需要一个版本锁定文件，记录以下这些内容：

- 直接和间接的依赖项：各包间的依赖形成树状层级，这里需要摊平所有依赖项形成一个列表，来检查整个依赖树确定各依赖都有效；例如避免出现两包间循环依赖的情况
- 各包的具体版本：借此找到目标文件唯一指定的内容；如果没有具体版本的话，包对应的文件内容在不同主机上可能不一致，会影响工程按预期正确运行

在Qua包管理器里，这对应`lock.quaspec`文件。如果工程下包含`lock.quaspec`文件，请将其加入到版本管理程序中。不建议手动修改`lock.quaspec`。

#### <u>按依赖版本下载依赖包 | Lock -> Dependency Files</u> ####

有了版本锁定文件，就可以按其中的内容从源仓库下载各个包到本地了。而为了顺利从源仓库中寻找到所需的包，需要有一个注册项文件来记录：

- 包描述：名称、概述和维护人等，用文字方式简要记录包的信息以区分于其他的包
- 版本：用版本号记录包的发展
- 下载方式：具体源码从哪里提供

在Qua包管理器的框架下，这对应远端中的`registry.quaspec`文件。想要公开项目成Qua包供他人下载的话，就需要从本地向远端上传这个文件。如果`registry.quaspec`位于工程目录下，请将其从版本管理程序中排除。

Qua包管理器下载指定包时，先将源仓库整体更新到本地以获得各包的`registry.quaspec`，再根据锁定的版本找到指定`registry.quaspec`，根据其内容将包源码下载到本地。

下载时目的位置有两种类型：

- 下载到本机全局位置：如果本机上有正在开发中的多个工程，可以在这些工程间通用
- 下载到工程下或其他指定文件夹下：随主程序一同打包发布

这两种类型Qua都支持，但CLI默认下载到本机全局位置。通过CLI指令的参数也可以选择下载到工程下或者其他指定的文件夹下。

### 文件组织结构 ###

#### <u>包的工作目录</u> ####

开发Qua包或基于Qua包的工程时，工作目录的情况。

具体结构如下：

```
<work-dir>/
|- (.quapackages/)   # 使用CLI下载各依赖包时，若指定下载到工作目录下，则此文件夹将作为默认存放位置；建议在版本控制中排除此文件夹
|- (project.quaspec) # 工程配置文件；建议添加到版本控制中；如果不需要其他Qua包作为依赖项，则可以省略
|- (lock.quaspec)    # 版本锁定文件；如果`project.quaspec`存在，则需要通过CLI生成此文件，并添加到版本控制中
|- ...               # 包内其他各种文件
```

#### <u>源仓库</u> ####

源仓库记录有哪些包可供安装。通常是远端的git仓库，但在本机查询包或将要安装包时，也会被拉取到本机。

```
<repo-root>/
|- <package-name>/
  |- <fork-name>/          # 包含"/"时按各段拆为层级目录
    |- <version>/
      |- registry.quaspec  # 注册项文件，包含如何下载等信息
      |- (project.quaspec) # 工程配置文件，便于下载用户确认包间依赖关系等；存在与否及具体内容都需要和包工作目录下的同名文件保持一致
      |- (source.zip)      # 如果`registry.quaspec`里的下载方式用了"regdir"，可以直接把包放在这里（不推荐）
```

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
  |- <fork-name>/          # 包含"/"时按各段拆为层级目录
    |- <version>/          # 已下载的包的源码（包的工作目录）
      |- registry.quaspec  # 注册项文件；从源仓库复制得来，已存在则将覆盖
      |- (project.quaspec) # 工程配置文件；从源仓库复制得来，已存在则将覆盖
      |- (lock.quaspec)    # 版本锁定文件；包内原本的文件
      |- ...               # 包内其他各种文件
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

# 初始化工作目录，写出配置
# 向<dir>写出工作目录配置`project.quaspec`；不指定<dir>时使用控制台当前工作目录
qua init [<dir>] [-h <host-id-range>] [-e <entry-point-file>]
    # -h | --host <host-id-range>            记录脚本包推荐用于的宿主程序范围为<host-id-range>；
    #                                          <host-id-range>形如`host-name[@fork-name][@version-range]`，
    #                                          或特殊字符串`*`表示可用于任意宿主程序；
    #                                          默认为`*`
    # -e | --entry-point <entry-point-file>  标明脚本包被其他包`require`时，入口文件是工作目录下的<entry-point-file>；
    #                                          不指定时默认是`init.lua`

### 操作工作目录

# 显示工作目录信息
qua list host [-w <workdir>]         # 显示建议宿主程序列表
qua list entry-point [-w <workdir>]  # 显示入口设置列表
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`project.quaspec`；
    #                             默认使用控制台当前工作目录

# 从源仓库按模式匹配寻找并列出包
# <pattern>使用Lua模式匹配
# 默认只匹配包名，使用`-s``-d`和`-l`可以分别指定也在概述、说明和标签中寻找
# 隐式筛选：只会列出可安装并正常使用的包
#     不符合宿主程序要求的包会自动隐藏：
#     - 优先使用`-h`标识的<host-id-range>匹配
#     - 不指明`-h`则使用当前目录中的`project.quaspec`中的信息
#     - 不存在`project.quaspec`则匹配任意宿主程序
qua search [-r <repo>] [-sdl] <pattern> [-v <version-range>] [-h <host-id-range>]
    # -r | --repo <repo>              只从源仓库<repo>查找包
    # -s | --summary                  也在概述文字中寻找是否有和<pattern>相符的结果
    # -d | --description              也在说明文字中寻找是否有和<pattern>相符的结果
    # -l | --label                    也在标签中寻找是否有和<pattern>相符的结果
    # -h | --host <host-id-range>     只匹配目标宿主程序能整个覆盖<host-id-range>范围的包；
    #                                   <host-id-range>形如`host-name[@fork-name][@version-range]`，
    #                                   或`*`表示要求可用于任意宿主程序
    # -v | --version <version-range>  只匹配包版本符合<version-range>的包

# 设置直接依赖项（编辑`project.quaspec`）
# 这些指令操作`project.quaspec`中记录的对其他Qua包的直接依赖
# 版本策略：升降级时一些特殊处理如下
#     - 同时升级或降级多个包时，会从顶级未被其他要变动的包依赖的包优先开始变动
#     - 如果要升级或降级的包被其他包依赖，则只会升级或降级到不打破依赖的最高版本
#     - 如果包的升级或降级会途经或抵达仅版本有差异但标识的其他部分都相同的已安装的包，
#         会优先合流到这个已安装版本并停止
# <package-id-range>形如`package-name[@fork-name][@version-range]`，用来指定欲操作的具体依赖
qua list dependency [-w <workdir>]                                # 列出直接依赖的其他包
qua add dependency [-w <workdir>] [-r <repo>] <package-id-range>  # 从源仓库安装包，作为工作目录的直接依赖项
qua remove dependency [-w <workdir>] <package-id-range>           # 从工作目录的直接依赖项中移除指定的包
qua upgrade dependency [-w <workdir>] [-r <repo>] <package-id-range> [-v <version>]  # 升级<package-id-range>所指定的依赖项
qua upgrade-all dependency [-w <workdir>] [-r <repo>]             # 升级所有可升级的依赖项
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`project.quaspec`；
    #                             默认使用控制台当前工作目录
    # -r | --repo <repo>        只从源仓库<repo>查找包
    # -v | --version <version>  最高只更新到<version>版本；
    #                             如果无法更新到<version>版本，更新到最接近的版本；
    #                             默认尽可能升到最新版本

# 设置依赖项版本（更新`lock.quaspec`）
# 这些指令在保持`project.quaspec`中给定的依赖要求不变的基础上，操作`lock.quaspec`中的依赖项的具体版本
# 版本策略：升降级时一些特殊处理如下
#     - 同时升级或降级多个包时，会从顶级未被其他要变动的包依赖的包优先开始变动
#     - 如果要升级或降级的包被其他包依赖，则只会升级或降级到不打破依赖的最高版本
#     - 如果包的升级或降级会途经或抵达仅版本有差异但标识的其他部分都相同的已安装的包，
#         会优先合流到这个已安装版本并停止
# <package-id>形如`package-name[@fork-name][@version]`，可以用来指定欲变动的包的现有具体版本
qua sync lock [-w <workdir>]    # 重建`lock.quaspec`文件，使之符合`project.quaspec`中的要求，同时尽可能不变动已存在的`lock.quaspec`中现有锁定版本
qua list lock [-w <workdir>]    # 列出`lock.quaspec`中记录的直接和间接依赖项包
qua upgrade lock [-w <workdir>] [-r <repo>] <package-id> [-v <version>]  # 升级<package-id>所指定的包
qua upgrade-all lock [-w <workdir>] [-r <repo>]                          # 升级所有可升级的包
    # -w | --working <workdir>  对指定工作目录进行操作，<workdir>下必须已经包含`project.quaspec`；
    #                             默认使用控制台当前工作目录
    # -r | --repo <repo>        只从源仓库<repo>查找包
    # -v | --version <version>  最高只更新到<version>版本；
    #                             如果无法更新到<version>版本，更新到最接近的版本；
    #                             默认尽可能升到最新版本

# 下载包
# 这些指令或设置已下载的包，以供工程使用
# 下载的目标位置有三种：
#   - 全局默认位置
#   - 工程下默认位置
#   - 手动指定位置
# 其中全局和工程下的默认位置见文档「文件组织结构・已下载的包的位置」
qua sync package [-w <workdir>] [-g | -d [<dir>]]  # 根据`lock.quaspec`，按需下载锁定版本的包到本地以供使用
qua list package [-w <workdir>] [-g | -d [<dir>]]  # 列出已下载到全局或<dir>下的各包
    # -w | --working <workdir>    使用指定工作目录中的设置并对其进行操作，<workdir>下必须已经包含`project.quaspec`；
    #                               默认使用控制台当前工作目录
    # -g | --global               下载包到全局默认位置（默认使用此项）
    # -d | --destination [<dir>]  下载包到指定目录<dir>下；
    #                               <dir>是相对控制台工作目录的路径；
    #                               不指定<dir>时使用包下默认路径

# 一键式更新
qua sync [-w <workdir>] [-g | -d [<dir>]]  # `qua sync lock && qua sync package`的简写

```

### project.quaspec ###

```lua
-- `*.quaspec`文件的格式是一个用`{}`围住的Lua表。表中各域仅允许字面量或仅由字面量构成的表。
-- `project.quaspec`具体允许的各项如下：（默认都是必填项，只有带有“（可选）”字样的项是选填项）
{
    -- 此文件所用`quaspec`格式的版本
    quaspec = "0.1.0",

    -- （可选）其他包使用此包时的入口信息
    -- 入口信息是一个哈希表：键是入口的名字，值是入口文件相对工作目录的路径
    -- 一个特殊的入口名`default`表示此包被Lua的`require`时所用的入口，不设置时默认为`init.lua`
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
        -- 其中名称，派生名，版本范围一同构成限制版本的条件
        -- 元数据仅作为控制包管理器行为的额外参数，各域均为可选：
        --    repo: 宿主程序源码的来源，仅作说明用
        -- 多个目标表示这个包可以用于多种可能的宿主程序，按条目顺序优先匹配靠前的条目
        -- 一个特殊的字符串"*"可以用来匹配任意宿主程序（例如如果期望此Qua包能在任意宿主程序中运行，可以写作hosts={"*"}）
        hosts = {
            {"some-special-host", "alice/host/main", ">=1.0.0, <1.3.10, ~=1.3.6", {repo = "https://somespecificsource/repo.git"}},
            {"some-fallback-host", "bob/host/main", "~>1.2"},
        },

        -- 此包依赖的由宿主程序提供的库列表
        -- 这个列表表示要求宿主程序提供对应的库，才能保证此Qua包正常运行（例如，由C/C++层面提供的库等等适用于此列表）
        -- 每个条目的格式是{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
        -- 其中名称，派生名，版本范围一同构成限制版本的条件
        -- 元数据仅作为控制包管理器行为的额外参数，各域均为可选：
        --    repo: 库源码的来源，仅作说明用
        --    rename: 库被require时所用的名称；默认使用库名称
        -- `qua add dependency ...`和`qua remove dependency ...`会自动扩容此列表，以满足新加Qua包依赖项的要求
        host_dependencies = {
            {"some-gui-dependency", "claire/gui/main", "~>1", {repo = "https://somespecificsource/repo.git", rename = "gui"}},
            {"some-threading-dependency", "david/thread/main", "~>1"},
        },

        -- 直接依赖的Qua包列表
        -- 这个列表表示工作目录下的脚本可以使用什么其他Qua包所提供的现有脚本资源；工作目录被执行时会在本地寻找对应的包
        -- 每个条目的格式是{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
        -- 其中名称，派生名，版本范围一同构成限制版本的条件
        -- 元数据仅作为控制包管理器行为的额外参数，各域均为可选：
        --    repo: 包源码的来源，会作为包被下载时的依据
        --    rename: 包被require时所用的名称；默认使用包名称
        -- `qua add dependency ...`和`qua remove dependency ...`会自动修改此列表，以记录此包所用的依赖
        dependencies = {
            {"some-oop-dependency", "elissa/oop/main", "~>3, ~=3.2", {repo = "https://somespecificsource/repo.git", rename = "oop"}},
            {"some-algorithm-dependency", "frank/algorithm/main", "~>2"},
        },
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

        -- 一个被锁定的版本
        {
            -- 此包标识信息，{名称，派生名，版本（semver2版本号）}
            -- 与源仓库中对应`project.quaspec`中的`publication`对应域一致
            -- 但元数据可以指定`rename`以重命名在`require`中使用的名字
            id = {"some-qua-package", "author/proj/main", "1.0.0"},

            -- 此包的各直接依赖项，{名称，派生名，版本范围（== ~= < > <= >= ~> 后接semver2版本号，各个限制间用逗号隔开），元数据（可选）}
            -- 与源仓库中对应`project.quaspec`中的`package.dependencies`对应域一致
            dependencies = {
                {"some-oop-dependency", "elissa/oop/main", "~>3, ~=3.2", {repo = "https://somespecificsource/repo.git", rename = "oop"}},
            },

            -- 此包来源
            -- 与源仓库中对应`registry.quaspec`中的`source`一致
            source = {type = "curl", file = "https://someremote/some-qua-package/author/proj/main/v1.0.0.tar.gz", md5 = "0f1e2d3c4b5a69788796a5b4c3d2e1f0"},
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

    -- 发布信息
    -- 将包提交到源仓库时需要公开的信息，以便用户搜寻到此包
    publication = {

        -- 包的名称，[A-Za-z0-9-]+
        -- 名称会作为脚本包内require使用的字符串参数
        name = "example-package",

        -- 包的派生名，[A-Za-z0-9-]+(/[A-Za-z0-9-]+)*
        -- 这个域会用于区别同名包，也便于直观描述源码来自于哪个代码库的哪个分支
        -- 建议命名为类似`git仓库所有人/git仓库名/git分支名`的格式，各部分和版本控制程序保持一致
        fork = "example-author/example-project-name/main",

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
        -- 推荐在这里写明包所对应的领域，也可以写上包可用于的宿主程序
        labels = {"graphics", "shader", "toon-shading", "some-special-host", "some-fallback-host"},

        -- 包源码所使用的协议
        license = "MIT",

        -- 维护此包的维护人及联系方式
        maintainer = "John Doe <johndoe123@abc.net>",

        -- （可选）包的主页
        homepage = "https://somegitservice.net/example-author/example-project-name",

        -- （可选）问题反馈页面
        issue_tracker = "https://somegitservice.net/example-author/example-project-name/issues",

    },

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

----
-- 运行时库有两种用法：
-- 1) 对于想要使用Qua包依赖项的工程：
--     准备好对应`project.quaspec`和`lock.quaspec`文件和已下载的依赖项，并将Qua运行时库的Lua源码文件复制到项目目录中
--     通过`local qua = require "qua"`导入运行时，并调用初始化方法后，就可以通过`require`使用已下载的Qua包了
-- 2) 对于Qua包的编写者：
--     直接`local qua = require "qua"`后，就可以使用Qua运行时库所提供的设施了，例如可以取得宿主程序或所在包的信息
--     这是非强制性的：要想允许用到这包的用户使用Qua以外的包管理方式，也可以先判断`require "qua"`是否能正常返回已加载的Qua运行时，或者直接不使用这些设施
----

-- 导入此包
local qua = require "qua"
local version = qua._VERSION

-- 初始化
-- 读入`project.quaspec`和`lock.quaspec`确定要用到的依赖包的信息，并指定从什么位置搜索要用到的包，以完成初始化
-- 初始化后，工程就可以通过`require`使用已下载的依赖包了
-- 初始化只可以调用一次，之后不能修改传入的设置，再次调用也会抛出错误
-- 可以使用链式调用的格式，例如`qua.from("./script"):useGlobal():setHost({...}):setHostPackages({}):init()`
-- 技术注解：
--     实际做的工作是向`package.loaders or package.searchers`中加入自定义的搜索函数，以供require能找到对应的Qua包
--     详细来说，搜索函数`searcher`的签名为`local package = searcher(requirename)`，`requirename`格式与lua自带的`require`所接受的参数相同
--     如果`requirename`只由一节构成，这个函数加载`requirename`包下由`project.quaspec`所指定的默认入口文件
--     如果`requirename`由多节构成形如"foo.a.b.c"，这个函数加载`foo`包下的`a/b/c.lua`
--     如果对应的包未导入则返回`nil`
-- 自定义IO注解：
--     `useCustomIO`可以设置使用指定函数搜索已下载的包，例如可以用来在压缩文件中搜索等等，取决于实际配置
--     参数`customIO`是一个函数，其签名是`local open = customIO(packageId)`，
--     未找到`packageId`对应的包时返回的`open`为`nil`，否则返回的`open`表示用来打开`packageId`对应包下文件的函数，
--     `open`行为应当与Lua自带的`io.open`一致，调用后返回符合Lua io库标准的文件对象，
--     但`open`参数传入的路径只允许相对于`packageId`对应包下的相对路径，使用绝对路径或超出包的路径时抛出错误
-- `useStrict`注解：
--     使用`setHostId`和`setHostPackages`时，可以指定是否与入口工程及各包的`project.quaspec`配置对比校验，来确定入口或包是否按预期一样可用
--     如果启用了`useStrict`，那么`hostId`会和刚刚已读入的入口`package.hosts`比对，而`hostPackages`会和入口及将要加载的所有包中的`package.host_dependencies`比对
--     比对发现无法匹配时，会抛出错误，以此拒绝不符合要求的入口或包
local quaInitSetting = qua.from(projectFolder)                     -- 使用包文件夹下的`project.quaspec`和`lock.quaspec`
local quaInitSetting = qua.fromFile(projectSpecPath, lockSpecPath) -- 手动指定对应`project.quaspec`和`lock.quaspec`路径
local quaInitSetting = qua.fromMemory(projectSpecTable, lockSpecTable) -- 手动指定内容
local quaInitSetting = quaInitSetting:useGlobal()           -- 从全局默认位置搜索已下载的包（不建议在打包发布版本中使用此设置）
local quaInitSetting = quaInitSetting:useLocal(dir?)        -- 从指定目录搜索已下载的包；`dir`是相对应用程序当前工作目录的路径，省略时使用包内默认位置
local quaInitSetting = quaInitSetting:useCustomIO(customIO) -- 从指定函数搜索已下载的包；见自定义IO注解
local quaInitSetting = quaInitSetting:setHostId(hostId, useStrict)              -- 能允许稍后通过`getHost`读取此处所给定的`hostId`；另见`useStrict`注解
local quaInitSetting = quaInitSetting:setHostPackages(hostPackages, useStrict)  -- 能允许稍后通过`getHostPackages`读取此处所给定的`hostPackages`；另见`useStrict`注解
local _ = quaInitSetting:init()  -- 根据已设置的配置初始化，之后就可以通过`require`使用已下载的依赖包了；这个函数只能调用一次
local _ = qua.init(quaInitSetting) -- 与`quaInitSetting:init()`同义

-- 设施
-- 自定义IO注解：
--     `packageIO`可以返回一个能按相对路径打开`packageId`对应包下文件的`open`函数
--     未找到`packageId`对应的包时返回的`open`为`nil`，
--     否则`open`行为应当与Lua自带的`io.open`一致，调用后返回符合Lua io库标准的文件对象，
--     但`open`参数传入的路径只允许相对于`packageId`对应包下的相对路径，使用绝对路径或超出包的路径时抛出错误
local hostId = qua.getHostId()              -- 返回先前初始化时`hostId`的副本
local hostPackages = qua.getHostPackages()  -- 返回先前初始化时`hostPackages`的副本
local packageId = qua.getPackageId()        -- 返回当前代码所在包的标识；当前代码不在包内或者包不是公开包则返回`nil`
local open = qua.packageIO(packageId?)      -- 返回一个能按相对路径打开`packageId`对应包下文件的`open`函数；`packageId`默认使用当前包；见自定义IO注解

```

### Qua包管理器 ###

```lua

----
-- 这个包提供在开发时对Qua包的搜索/下载等管理方式，是CLI工具的后端
-- 所有函数没有特别说明则都是`assert`-friendly的：失败时返回形如`ok, msg`的多值，适合被`assert`包住
----

-- 使用此包
local pm = require "qua-package-manager"
local version = pm._VERSION

-- 读取和写出配置文件（`*.quaspec`）
-- `path...`可以分节，例如"a", "b", "c"表示路径`a/b/c`
local spec = pm.readSpec(path...)       -- 读取配置文件
local ok, msg = pm.writeSpec(spec, path...)  -- 写出配置文件

-- 同步
local ok, msg = pm.pullRepo(localRepoDir, remoteGitRepo)  -- 从`remoteGitRepo`更新源仓库到本地`localRepoDir`；自动丢弃所有未提交修改

-- 源仓库/已下载仓库管理
-- 源仓库（`repoDir`）和本地已下载包的目录（`packRoot`）结构近似，可以都使用`readPackXxx`函数读出
local regs = pm.readPackRegs(packRoot)            -- 从`packRoot`读取可下载的各包注册项`registry.quaspec`
local projs = pm.readPackProjs(packRoot)          -- 从`packRoot`读取可下载的各包配置`project.quaspec`（返回值`projs`中可能有`false`表示文件不存在）
local locks = pm.readPackLocks(packRoot)          -- 从`packRoot`读取可下载的各包版本锁定`lock.quaspec`（返回值`locks`中可能有`false`表示文件不存在）
local regs, projs, locks = pm.readPack(packRoot)  -- 上面`pm.readPackXxx`的综合，一次性读出；同包资源所在下标一致

-- 定位
local dir = pm.locatePack(packRoot, packageId)    -- 在`packRoot`下寻找特定标识的包级根目录，对应目录不存在时失败

-- 工程更新
local syncedLock = pm.syncLock(proj, oldLock?)  -- 从`proj`和可能的`oldLock`更新依赖情况，计算新的版本锁定；循环依赖等情况无法建立新lock时失败
local syncedDownloadAction = pm.syncPackage(lock, repoDir)  -- 按照`lock`提供的版本锁定，从源仓库`repoDir`找到对应可下载的各包配置和注册项，创建下载事务；源仓库没有办法提供所要求的包等情况时失败
local ok, msg = syncedDownloadAction:apply(targetPackRoot)  -- 按需执行下载，更新`targetPackRoot`中的内容到包含所需依赖

```
