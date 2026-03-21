---
name: arkts-syntax-assistant
description: |-
  ArkTS/HarmonyOS 编译修复助手。用于处理 .ets 文件、ArkUI 组件写法、@ohos
  包、No overload matches this call、Unexpected token、类型不匹配、
  Resource 与 string 混用、对象字面量类型声明、Grid/GridCol 误用、
  枚举成员不存在等问题。适合在 coder 编译失败后快速定位根因并给出可编译替代写法。
---

# ArkTS Syntax Assistant

## 何时使用

- 正在修改 `.ets` 文件
- 出现 ArkTS 编译错误
- 日志里出现 `No overload matches this call`
- 日志里出现 `Type 'xxx' is not assignable to ...`
- 日志里出现 `Unexpected token`
- 日志里出现 `Object literals cannot be used as type declarations`
- 日志里出现 `GridCol can only be nested in GridRow`
- 不确定某个 ArkUI 组件 API 到底接受什么参数

## 目标

这个 skill 的目标不是讲 ArkTS 基础知识，而是帮助 coder 在编译失败后快速做四件事：

1. 找到真正阻塞编译的第一根因
2. 判断问题属于哪一类 API/类型误用
3. 给出最小、最保守、最容易通过编译的修法
4. 在快速原型模式下，优先保留 UI 可见效果，而不是追求“高级写法”

## 总体原则

- 先修阻塞编译的 `ERROR`，再看 `WARN`
- 先修类型错误和 API 签名错误，再修视觉细节
- 先修第一个明确文件和行号对应的错误
- 优先退回简单、保守、常见的 ArkUI 写法
- 在快速原型阶段，优先直接写字符串和十六进制颜色，不要过早资源化

## 日志诊断顺序

拿到编译日志后，按下面顺序判断：

1. 找文件路径和行号
2. 看是否存在 `No overload matches this call`
3. 看是否存在 `Type 'xxx' is not assignable to ...`
4. 看是否存在对象类型声明、枚举成员、组件层级相关错误
5. 最后才看 `Unexpected token`
6. deprecated warning 先记下，不要抢在阻塞错误前处理

输出结论时，优先用这个格式：

```text
文件:
行号:
根因:
建议改法:
```

不要原样复述整段日志。

## 错误模式

### A. API 参数类型错误

典型日志：

- `No overload matches this call`
- `Argument of type 'xxx' is not assignable to parameter of type 'yyy'`

这通常说明：

- 给组件 API 传了不接受的参数类型
- 把链式属性对象误当成 API 参数
- 把函数、Builder、对象、字符串塞到了错误的位置

优先排查：

- 这个 API 真正接受什么类型
- 当前表达式最终返回的是什么类型
- 是否把组件 DSL 和函数调用风格混在一起了

典型误用：

```ts
.tabBar(
  Text('计算').fontSize(16)
)
```

更稳写法：

```ts
.tabBar('计算')
```

或：

```ts
.tabBar({ text: '计算' })
```

### B. `Unexpected token` 不是根因

如果日志里同时出现：

- `Unexpected token`
- `No overload matches this call`
- `Type 'xxx' is not assignable to ...`

优先把“参数类型错误 / API 误用”当根因，不要先去改括号、逗号、换行。

### C. `Resource` 和 `string` 混用

典型日志：

- `Type 'Resource' is not assignable to type 'string'`

这通常说明：

- 把 `$r(...)` 赋给了 `string`
- 把 `Resource` 传进了只接受普通字符串的字段或 API

快速原型阶段最稳的修法：

- 直接改回普通字符串
- 不要继续扩大资源系统使用范围

示例：

```text
根因: 把 $r(...) 返回的 Resource 赋给了 string 类型状态
建议改法: 直接改成普通字符串，如 'm'、'km'
```

### D. 字段名误写导致和组件基类属性冲突

典型日志：

- `Property 'backgroundColor' in type 'XxxPage' is not assignable to the same property in base type 'CustomComponent'`

这类错误经常不是 `.backgroundColor(...)` 方法本身有问题，而是：

- 你定义的是 `bgColor`
- 代码里却写成了 `this.backgroundColor`

编译器把它误解析成组件基类成员，报出很怪的类型错误。

先检查：

- 字段名是否拼错
- 是否存在 `cardBgColor` / `backgroundColor`、`bgColor` / `backgroundColor` 这类近似名

### E. 对象字面量类型声明不被接受

典型日志：

- `Object literals cannot be used as type declarations`

高风险写法：

- 在回调参数位置直接写复杂对象类型
- 把 TypeScript 的内联对象类型写法直接搬进 ArkTS

更稳修法：

- 先去掉内联类型标注，让编译器推断
- 或先提取成简单 `interface`

例如：

```ts
ForEach(items, (item) => {
```

通常比：

```ts
ForEach(items, (item: { id: string; label: string }) => {
```

更稳。

### F. 枚举成员想当然

典型日志：

- `Property 'Light' does not exist on type 'typeof FontWeight'. Did you mean 'Lighter'?`

更稳修法：

- 优先使用最常见成员：`Normal`、`Medium`、`Bold`、`Lighter`
- 如果日志已经给了提示，优先按提示修

### G. Grid 系统混用

典型日志：

- `The 'GridCol' component can only be nested in the 'GridRow' parent component`

这说明你混用了两套栅格体系：

- `Grid` / `GridItem`
- `GridRow` / `GridCol`

更稳修法：

- 选一套用到底
- 计算器、九宫格、功能入口页这类场景，优先统一用 `Grid + GridItem`
- 不要在普通 `Grid` 里塞 `GridCol`

### H. 把函数或 Builder 当成 `Grid(...)` 参数

典型日志：

- `No overload matches this call`
- `Argument of type '() => void' is not assignable to parameter of type 'string'`

这通常说明写成了类似：

```ts
Grid(() => {
  ...
})
```

而当前组件预期的是声明式容器写法：

```ts
Grid() {
  ...
}
```

结论：

- 不要把函数式调用风格硬套到 ArkUI 容器组件上
- 如果不确定，优先退回最常见的声明式块结构

## 快速原型模式规则

这个项目默认走快速原型模式，所以：

- 页面文本优先直接写普通字符串
- 颜色优先直接写十六进制值
- mock 数据优先直接写在页面里
- 不要为了规范化把普通文本和颜色都搬进资源文件
- 不要为了做复杂视觉效果过早引入高风险 Builder / 泛型 / 复杂类型

## 给 coder 的硬规则

1. 编译失败时，先修第一个明确文件和行号对应的错误。
2. 先修 `ERROR`，后看 `WARN`。
3. 先修类型和 API 签名错误，再修样式细节。
4. 如果多个错误指向同一段代码，优先判断是否是一个根因导致的连锁报错。
5. 如果不确定某段 ArkUI 写法是否受支持，先退回简单文本、基础容器、基础配置对象。
6. 不要为了“更像设计稿”而坚持使用会导致类型不稳定的高级写法。
7. 不要为了工程规范化而过早资源化。
8. 如果报错看起来像组件属性冲突，先检查字段名是不是写错了。
9. deprecated warning 先记下，不要排在阻塞编译错误前面处理。

## 最小修复模板

### 模板 1：参数类型错误

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 62
根因: tabBar(...) 参数类型错误，把 Text(...).fontSize(...) 产生的 TextAttribute 传进去了
建议改法: 改成 .tabBar('计算') 或 .tabBar({ text: '计算' })
```

### 模板 2：资源类型错误

```text
文件: entry/src/main/ets/pages/ConvertPage.ets
行号: 7
根因: 把 $r(...) 返回的 Resource 赋给了 string 类型状态
建议改法: 直接改成普通字符串，如 'm'、'km'
```

### 模板 3：对象字面量类型声明错误

```text
文件: entry/src/main/ets/pages/ConverterPage.ets
行号: 125
根因: 在回调参数位置使用了 ArkTS 不接受的对象类型声明写法
建议改法: 先去掉内联类型标注，改成 (item) => {...}
```

### 模板 4：字段名误写导致属性冲突

```text
文件: entry/src/main/ets/pages/ConverterPage.ets
行号: 61
根因: 使用了未定义的 this.backgroundColor，编译器将其误解为组件基类属性
建议改法: 检查并改回实际定义的字段名，例如 this.bgColor
```

### 模板 5：枚举成员不存在

```text
文件: entry/src/main/ets/pages/CalculatorPage.ets
行号: 208
根因: 使用了不存在的 FontWeight.Light
建议改法: 改成 FontWeight.Lighter 或 FontWeight.Normal / FontWeight.Medium
```

### 模板 6：Grid 系统混用

```text
文件: entry/src/main/ets/pages/CalculatorPage.ets
行号: 193
根因: 在普通 Grid 结构里混入了 GridCol，组件层级不合法
建议改法: 统一改回 Grid + GridItem，不要混用 GridRow/GridCol
```

### 模板 7：把函数传给 Grid

```text
文件: entry/src/main/ets/pages/CalculatorPage.ets
行号: 183
根因: 把函数/Builder 当成 Grid(...) 参数传入了
建议改法: 改回声明式容器写法，使用 Grid() { ... }，不要写成 Grid(() => { ... })
```

## references 何时再看

默认先用本 skill 的规则完成诊断，不要一上来就读整套 references。

只有下面这些情况再继续读 `references/zh/`：

- 遇到明确的 ArkTS 语法细节仍无法确定
- 需要查 TypeScript 到 ArkTS 的迁移细则
- 需要确认某种语言特性或限制是否受支持

优先参考：

- `references/zh/typescript-to-arkts-migration-guide.md`
- `references/zh/introduction-to-arkts.md`
- `references/zh/arkts-more-cases.md`

## 输出风格

回答要短、硬、可执行。

优先给：

- 根因
- 最小改法
- 更稳替代写法

避免：

- 大段背景知识
- 原样复述整段编译日志
- 一次性给太多不确定方案
