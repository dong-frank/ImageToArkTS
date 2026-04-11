---
name: harmony-project-layout
description: |-
  HarmonyOS/ArkTS 项目结构助手。用于在 ace create 创建项目后快速定位应该修改的
  目录和文件，判断页面代码、资源文件、应用名称、图标、模块配置分别放在哪里。
  遇到鸿蒙项目骨架理解、页面落位、资源落位、工程入口定位时激活。
---

# Harmony Project Layout

## 何时使用

- 刚调用 `create_project(project_name)` 创建完鸿蒙项目
- 需要判断新的页面、组件、资源、配置文件应该放在哪
- 需要区分 `AppScope`、`entry`、`resources`、`ets/pages` 的职责
- 需要快速定位首屏页面、入口 Ability、应用名、图标、字符串资源

## 创建项目后的默认检查顺序

创建项目后，优先按下面顺序理解工程：

1. 看 `/projects/<project_name>/entry/src/main/ets/pages/Index.ets`
2. 看 `/projects/<project_name>/entry/src/main/ets/entryability/EntryAbility.ets`
3. 看 `/projects/<project_name>/entry/src/main/module.json5`
4. 看 `/projects/<project_name>/AppScope/app.json5`
5. 看 `/projects/<project_name>/entry/src/main/resources/`
6. 看 `/projects/<project_name>/AppScope/resources/`

先改页面，再补资源和配置。不要一开始就在测试目录、构建缓存目录或 `oh_modules` 中编辑业务代码。

## 目录职责速查

### 1. `/projects/<project_name>/entry/src/main/ets/pages/`

这是最重要的页面目录。

- 页面 UI 优先写在这里
- `Index.ets` 往往是首屏入口页面
- 多页面应用可以在这里新增 `HomePage.ets`、`DetailPage.ets` 等页面文件
- 当任务重点是 UI 还原时，绝大多数代码修改都应从这里开始

### 2. `/projects/<project_name>/entry/src/main/ets/entryability/`

这是 Ability 入口目录。

- `EntryAbility.ets` 负责应用启动入口
- 通常只在需要调整入口页面、生命周期、启动行为时修改
- 做纯 UI 还原时，改动频率通常低于 `ets/pages`

### 3. `/projects/<project_name>/entry/src/main/resources/`

这是模块级资源目录。

- 图片、颜色、字符串、页面资源优先考虑放这里
- 常见子目录包括 `base/element`、`base/media`、`base/profile`
- 如果 UI 需要图标、插图、字符串资源，可优先在这里补
- 但在快速原型阶段，不必为了规范化把所有文本和颜色都搬进资源文件；能直接硬编码时，优先直接硬编码

### 4. `/projects/<project_name>/AppScope/`

这是应用级配置目录。

- `app.json5` 管应用级信息，如应用名、图标、版本
- `AppScope/resources` 放应用级公共资源
- 当你需要改应用显示名、应用图标、全局 app 信息时，优先看这里

### 5. `/projects/<project_name>/entry/src/test` 和 `/projects/<project_name>/entry/src/ohosTest`

这是测试目录。

- 默认不是当前阶段的核心编辑区域
- UI 原型阶段通常不用优先修改这里

### 6. 不应优先手改的目录

- `/projects/<project_name>/oh_modules`
- `/projects/<project_name>/.hvigor`
- `/projects/<project_name>/entry/build`
- `/projects/<project_name>/.arkui-x`

这些通常是依赖、构建产物或平台生成内容，不应作为主要业务代码编辑位置。

## 常见任务应该改哪里

### 只改页面 UI

优先修改：

- `/projects/<project_name>/entry/src/main/ets/pages/Index.ets`
- `/projects/<project_name>/entry/src/main/ets/pages/<NewPage>.ets`

### 新增页面

优先操作：

1. 在 `ets/pages` 新建页面文件
2. 如需入口跳转，再回头检查 `Index.ets` 或 `EntryAbility.ets`

### 改应用名称或图标

优先检查：

- `/projects/<project_name>/AppScope/app.json5`
- `/projects/<project_name>/AppScope/resources/base/element/string.json`
- `/projects/<project_name>/AppScope/resources/base/media/`

### 改页面字符串、图片、局部资源

优先检查：

- `/projects/<project_name>/entry/src/main/resources/base/element/`
- `/projects/<project_name>/entry/src/main/resources/base/media/`

快速原型模式下：

- 页面文本优先直接写普通字符串
- 页面颜色优先直接写十六进制值
- 只有确实要复用、或组件/API 明确适合资源时，再引入资源文件

## 针对 coder 的工作规则

1. 创建项目后，先读 `Index.ets`，确认当前首屏结构。
2. 如果目标是快速完成 UI，先在 `ets/pages` 中搭好页面骨架，不要先改复杂配置。
3. 如果需要多个页面，优先继续在 `ets/pages` 中扩展，而不是把大量 UI 写进 `EntryAbility.ets`。
4. 改应用名称、图标、全局信息时，再进入 `AppScope`。
5. 除非编译错误明确指向配置问题，否则先改页面文件，再改配置文件。
6. 如果某个目录看起来像构建缓存或依赖目录，不要在那里写业务实现。
7. 快速原型阶段优先把 UI 写出来并通过编译，不要为了资源规范化提前创建大量 `string/color/media` 资源。

## 最小落地流程

```text
create_project
-> 找到 /projects/<project_name>/entry/src/main/ets/pages/Index.ets
-> 先完成首屏 UI
-> 如有需要，在 ets/pages 下补充更多页面
-> 再补 resources
-> 最后调整 AppScope/app.json5
-> compile_project
```
