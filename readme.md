# 廓 | Qua #

!!! 正在开发中 | Work In Progress

一款包管理器，使用[Lua](www.lua.org)语言管理即下即用的资源包，如纯Lua脚本库或游戏资源包等无需额外编译步骤的资源。

A package manager that manages out-of-the-box resource packages using [Lua](www.lua.org) programming language, eg. pure Lua script packages, game asset packages, etc. that do not require extra build steps.

## 特点 | Features ##

- __依赖树结构__
    - 每个包可以设置接口文件以允许其他包依赖
    - 每个包可以依赖其他包中的接口文件
- __中心化或自定义的包仓库__
    - 手动将网络上的资源制作成包注册项，提交到仓库中供他人搜索
    - 通过CLI从指定仓库（默认是中心仓库）搜索包，并下载到本地以供使用
- __Dependency tree__
    - Each package can specify interface files as *provisions*
    - Each package can rely on interface files from other packages as *dependencies*
- __Centralized or customized registry__
    - Manually make a package version spec from a public resource, and submit it to a registry to make it available for anyone accessing the registry
    - Using the CLI, search the desired packages from a registry (the centralized one as the default), and download it to a local storage for further use

## 构成 | Structure ##

- __命令行界面（CLI）__
    - 用于便捷管理当前Lua工程所用包
    - 设置远程仓库
    - 按名称、概述、说明或标签搜索包
    - 安装、卸载或升级包
- __运行时库__
    - 纯Lua编写
    - 供脚本包或宿主环境使用
    - 控制包间依赖而不污染全局`package.loaded`
    - 读取包下数据
- __包管理器库__
    - 为自定义工具增加包管理功能
    - ~~扫描项目，将所需依赖项列出为`manifest.quaspec`清单文件~~（尚未实现，当前需要手动编辑）
    - 将清单文件根据各包要求版本区间锁定依赖项版本为`lock.quaspec`锁定文件
    - 根据锁定文件从远程仓库下载所需的依赖项到本地
- __Command Line Interface(CLI)__
    - Can be used for managing dependency packages of the current working Lua project
    - Set from which remote registry to download packages
    - Search packages by name, summary, description or tag
    - Add, remove and upgrade dependency packages
- __Runtime Library__
    - Written in pure Lua
    - Can be used by a script package or the host environment
    - Import other packages without polluting global `package.loaded`
    - Load files inside the current package
- __Package Manager Library__
    - Can be used by tools to gain the ability of managing packages
    - ~~Scan the dependencies from the source project to a manifest file `manifest.quaspec`~~ (Not yet impemented, require manual editing by now)
    - Lock the demanded actual version of each dependency, by calculating from the ranges given by each package, and write these versions to the lock file `lock.quaspec`
    - Download according to a remote registry the locked versions of dependencies to a local storage

## 使用范例 | Usage Examples ##

!!! TODO

## 安装 | Installation ##

!!! TODO

## 详情 | Details ##

< [中文文档](readme-zh.md) | English Documentation >

## 开源协议 | License ##

MIT