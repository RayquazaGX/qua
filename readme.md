# 廓 | Qua #

!!! 正在开发中 | Work In Progress

一款包管理器，帮助开发者在编写[Lua](www.lua.org)脚本时以**纯Lua脚本包**为单位管理依赖。

A package manager for [Lua](www.lua.org) programming language, that helps developers managing **pure Lua packages** as dependecies.

## 功能与特点 | Features ##

- <u>仅支持纯Lua脚本包</u>
    - 虽然更严格，但不用再为等待编译和跨平台适配苦恼
    - 虽然包内容是纯Lua，但可以在包描述中指定使用哪些来自底层语言的支持库，并期望宿主程序为其提供这些库
- <u>编写Lua脚本过程中，通过CLI，可以操作并下载工程依赖</u>
    - 在项目工程中编辑`package.quaspec`说明项目包信息和依赖信息，生成版本锁定文件`lock.quaspec`，并以此下载所需的依赖项到本地
    - 默认使用一个中央源仓库作为包的来源，也可以自行指定其他git仓库作为源仓库
    - 按名称、概述、说明或标签搜索想要的包
    - 安装新的依赖项、卸载或升级已记录的依赖项
- <u>工程运行时，通过纯Lua编写的运行时库，读取已准备好的依赖项各个包</u>
    - 原理是生成一个自定义搜索函数以扩展Lua自带`require`的功能
    - 可以选择在要导入的包脚本的描述不符合宿主程序时抛出错误
    - 除了从本地文件系统读取，可以自行传入自定义IO方法，指定读取依赖项的方式；便于实现从压缩文件中读取包等等
- *进阶用法*：<u>构建自定义的工具时，使用纯Lua编写的后端库，为工具增加包管理器功能</u>
    - 读写配置文件
    - 按照配置文件计算版本锁定或下载依赖
- <u>Only supports pure Lua packages</u>
    - Limited, but it clears away troubles, eg. waiting for compiling downloaded components, or caring about cross-platform issues
    - While the scripts need to be in pure Lua, you may write down in the package spec your need of lower-level libraries, demanding that the host executable should provide them
- <u>During development of your Lua script project, you can manage the dependencies with the provided CLI</u>
    - Edit `package.quaspec` to hold the project info and its dependencies, generate `lock.quaspec` which locks the actual versions of dependencies, and download the versioned packages accordingly
    - Apart from the centralized repository, you may manually set other git repos as the package source
    - Search the packages with patterns on name/summary/description/tags
    - Install new dependencies, or remove/upgrade installed dependencies
- <u>During project runtime, you can import the downloaded packages with the provided runtime library written in pure Lua</u>
    - The idea is just to generate a custom loader function, to extend the functionality of the Lua `require`
    - You decide whether to throw an error if the spec of a package being imported does not match up to the host executable
    - Apart from importing from the filesystem, you may use customized IO; this can be useful for cases like loading packages from zipped archives
- *Advanced usage*: <u>When making new tools, you can add to it the ability of managing packages, with the provided backend library written in pure Lua</u>
    - Save/load spec files
    - Calculate the version locks and download the dependency packages

## 使用范例 | Usage Examples ##

!!! TODO

## 安装 | Installation ##

!!! TODO

## 详情 | Details ##

< [中文文档](readme-zh.md) | English Documentation >

## 开源协议 | License ##

MIT