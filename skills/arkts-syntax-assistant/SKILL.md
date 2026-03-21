---
name: arkts-syntax-assistant
description: |-
  ArkTS/HarmonyOS 编译修复助手。用于处理 .ets 文件、ArkUI 组件写法、@ohos
  包、ArkTS 类型错误、No overload matches this call、Unexpected token、
  组件参数类型不匹配、TypeScript 到 ArkTS 迁移不兼容等问题。适合在 coder
  编译失败后快速定位根因并给出可编译替代写法。
license: MIT
---

# ArkTS Syntax Assistant

## 何时使用

- 正在修改 `.ets` 文件
- 出现 ArkTS 编译错误
- 日志里出现 `No overload matches this call`
- 日志里出现 `Unexpected token`
- 日志里出现 `Type 'xxx' is not assignable to ...`
- 在 ArkUI 声明式组件链里，不确定某个 API 到底该接收什么类型
- 想把 TypeScript / React 风格写法改成更稳的 ArkTS 写法

## 核心目标

不要做泛泛解释，优先帮助 coder 完成这四件事：

1. 从编译日志里抽出真正根因
2. 判断是语法问题、类型问题、组件 API 误用，还是工程配置问题
3. 给出更保守、更容易编译通过的 ArkTS 写法
4. 优先选择简单、直接、可编译的 UI 实现

## 处理编译错误的固定流程

拿到编译日志后，按这个顺序处理：

1. 先找文件路径和行号
2. 先看是否存在 `No overload matches this call`
3. 再看是否存在 `Type 'xxx' is not assignable to ...`
4. 最后才看 `Unexpected token`

输出结论时，优先用这个格式：

```text
文件:
行号:
根因:
建议改法:
```

不要原样复述整段日志。

## 高优先级判断规则

### 1. `No overload matches this call`

这通常说明：

- 传给组件 API 的参数类型不对
- 调用了一个看起来像对、其实签名不匹配的方法
- 把链式属性对象当成了 API 参数

优先排查：

- 组件方法的参数类型
- 当前表达式最终返回的到底是什么类型
- 是否把 `TextAttribute`、`ButtonAttribute`、`RowAttribute` 之类对象误传给别的 API

### 2. `Unexpected token`

在 ArkUI 声明式 UI 里，它不一定真的是括号或逗号问题。

如果日志里同时有：

- `Unexpected token`
- `No overload matches this call`
- `Type 'xxx' is not assignable to ...`

那优先把“参数类型错误”当根因，不要先去乱改换行、标点、括号。

### 3. `Type 'xxx' is not assignable to ...`

这通常说明：

- 变量声明类型不对
- API 接受的不是当前表达式返回值
- 你在用 TypeScript 思路写 ArkTS，但 ArkTS 的约束更严格

这类错误优先用“更窄、更明确、更保守”的类型替代。

## ArkUI 最容易犯错的几类写法

### 1. 把链式 UI 结果当作别的 API 参数

错误示意：

```ts
.tabBar(
  Text('计算').fontSize(16)
)
```

上面传进去的通常是 `TextAttribute`，不是 `tabBar(...)` 允许的类型。

更安全的写法：

```ts
.tabBar('计算')
```

或者：

```ts
.tabBar({ text: '计算' })
```

结论：

- `Text('xxx')...` 常常用于构建组件本身
- 不等于它可以作为任意 API 的参数

### 2. 过度照搬 TypeScript/React 思路

高风险写法：

- `any`
- `unknown`
- 动态对象扩展
- 把对象字面量随意塞给复杂 API
- 依赖宽松的隐式类型推断

更稳的策略：

- 显式类型
- 结构更简单的对象
- 优先使用组件文档明确支持的参数形式
- 先做能编译的静态 UI，再补逻辑

### 3. 为了做复杂 UI，过早引入复杂 Builder 或复杂类型

如果一种高级写法报类型错，优先退回简单版本：

- 复杂 tabBar 自定义 -> 先用字符串 tab
- 复杂状态模型 -> 先用简单 `@State`
- 复杂泛型对象 -> 先用明确 interface
- 复杂动态渲染 -> 先写静态骨架

## 给 coder 的硬规则

1. 编译失败时，先修第一个明确文件和行号对应的错误。
2. 先修类型和 API 签名错误，再修样式细节。
3. 当一个组件有多种写法时，优先选择最简单、最保守、最常见的那种。
4. 当日志中有多个错误，但都指向同一段 UI 链式代码时，优先判断是否为同一根因引发的连锁报错。
5. 如果某段 ArkUI 写法不确定是否受支持，先退回简单文本、字符串、基础配置对象。
6. 不要为了“更像设计稿”而坚持使用会导致类型不稳定的高级写法。

## 常见修复模板

### 模板 1：组件参数不确定时

先从：

```ts
someApi(complexExpression)
```

退回到：

```ts
someApi('简单值')
```

或：

```ts
someApi({ text: '简单值' })
```

### 模板 2：Builder 不确定时

如果不确定某个 API 是否接受 `@Builder`，先不要引入 `@Builder`。

先用简单页面结构保证能编译：

```ts
Column() {
  Text('占位内容')
}
```

### 模板 3：日志分析输出模板

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 62
根因: tabBar(...) 参数类型错误，把 Text(...).fontSize(...) 产生的 TextAttribute 传进去了
建议改法: 先改成 .tabBar('计算') 或 .tabBar({ text: '计算' })
```

## 与 references 的关系

默认先使用本 skill 的规则完成判断，不要一上来就读整套参考文档。

只有在下面情况才继续读 `references/zh/`：

- 遇到明确的 ArkTS 语法细节仍无法确定
- 需要查迁移规则的更完整例子
- 需要确认某种语言特性是否受支持

优先参考：

- `references/zh/typescript-to-arkts-migration-guide.md`
- `references/zh/introduction-to-arkts.md`
- `references/zh/arkts-more-cases.md`

## 输出风格

回答要短、硬、可执行。

优先给：

- 根因
- 最小改法
- 更稳的替代写法

避免：

- 大段背景知识
- 原样复述整段编译日志
- 一次性给太多不确定方案
