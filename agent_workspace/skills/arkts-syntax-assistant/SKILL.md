---
name: arkts-syntax-assistant
description: |-
  ArkTS/HarmonyOS 编译修复助手。用于处理 .ets 文件、ArkUI 组件写法、@ohos
  包、No overload matches this call、Unexpected token、Cannot find name、
  does not meet UI component syntax、类型不匹配、Unknown resource name、
  Resource 与 string 混用、对象字面量类型声明、Grid/GridCol 误用、
  枚举成员不存在等问题。适合在 coder 编译失败后快速定位根因并给出可编译替代写法。
---

# ArkTS Syntax Assistant

## 何时使用

- 正在修改 `.ets` 文件
- 出现 ArkTS 编译错误
- 日志里出现 `No overload matches this call`
- 日志里出现 `Type 'xxx' is not assignable to ...`
- 日志里出现 `Cannot find name 'xxx'`
- 日志里出现 `Unexpected token`
- 日志里出现 `does not meet UI component syntax`
- 日志里出现 `Object literals cannot be used as type declarations`
- 日志里出现 `GridCol can only be nested in GridRow`
- 日志里出现 `Unknown resource name 'xxx'`
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

先按这个速查表分类，再看下面详细说明：

| 分类 | 先看什么 |
|---|---|
| API / 参数类型 | `No overload matches this call`、`Argument of type ... is not assignable to ...` |
| 组件 / 类型名不存在 | `Cannot find name 'SearchBar'`、`Cannot find name 'TabBarMode'` |
| 组件语法次生报错 | `does not meet UI component syntax` |
| 资源问题 | `Unknown resource name 'xxx'`、`Resource` / `string` 混用 |
| 枚举误用 | 枚举成员不存在、`HorizontalAlign` / `VerticalAlign` / `ItemAlign` 混用 |
| 结构误用 | `GridCol can only be nested in GridRow`、把函数传给容器组件 |
| 作用域 / 字段误写 | `this.Xxx`、基类属性冲突、Builder 名未定义 |

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

### I. 组件属性名不存在

典型日志：

- `Property 'placeholderFontColor' does not exist on type 'TextInputAttribute'. Did you mean 'placeholderColor'?`

这说明：

- 使用了不存在的 ArkUI 链式属性名
- 很多时候只是把官方属性名写错了，编译器还会直接给出可替代名称

更稳修法：

- 优先采用编译器提示的候选属性
- 对 `TextInput` 这类组件，先使用常见、明确存在的属性名
- 不要想当然扩展出 `...FontColor`、`...TextColor` 之类写法

例如：

- `placeholderFontColor(...)` 改成 `placeholderColor(...)`

### J. 组件名 / Builder 名未定义或作用域错误

典型日志：

- `Cannot find name 'NavItem'. Did you mean the instance member 'this.NavItem'?`

这说明：

- 直接使用了未定义的自定义组件、Builder、常量或函数名
- 或者它其实是实例成员，却被当成当前作用域的自由标识符使用

优先排查：

- `NavItem` 是否真的声明过
- 如果是组件内方法或 Builder，是否应写成 `this.NavItem(...)`
- 如果只是为了快速通过编译，优先内联成普通 `Row` / `Column` / `Text` / `Image` 结构

### K. `HorizontalAlign` / `VerticalAlign` 枚举混用

典型日志：

- `Argument of type 'VerticalAlign' is not assignable to parameter of type 'HorizontalAlign'`
- `Argument of type 'HorizontalAlign' is not assignable to parameter of type 'VerticalAlign'`

这通常说明：

- 把横向对齐枚举传给了纵向 API
- 或把纵向对齐枚举传给了横向 API
- 这类错误在 `alignItems`、`justifyContent`、容器构造参数里很常见

更稳修法：

- 先确认当前 API 期待的是 `HorizontalAlign` 还是 `VerticalAlign`
- 不确定时，不要凭视觉语义猜，直接按报错中的目标类型改
- 常见保守策略是回退到最简单、最常见的对齐写法，避免同时叠加多个对齐配置

### L. 资源名不存在

典型日志：

- `Unknown resource name 'avatar_placeholder'`
- `Unknown resource name 'icon_placeholder'`

这说明：

- 代码引用了并不存在于资源表中的图片、图标或字符串资源
- 这类问题经常出现在从设计稿或 Web 代码迁移到 ArkTS 时，直接假设资源名已经存在

快速原型阶段更稳修法：

- 如果只是占位图，不要先依赖不存在的资源名
- 优先改成纯文本占位、系统图标、纯色背景，或先删掉图片引用
- 只有在确认 `resources` 中确实存在对应资源时，才继续使用 `$r(...)`

### M. 多轮修复后，优先关注最新一轮的剩余阻塞项

如果同一文件多次编译失败：

- 第一轮往往暴露一组语法、API、资源问题
- 后续轮次剩下的错误更接近真正还未修掉的阻塞点

处理策略：

- 不要反复重看第一轮所有错误
- 优先基于最新一次编译日志决定下一步修复顺序
- 如果错误数量明显收敛，优先处理还残留的 1 到 2 个明确报错
- 不要因为早期日志里错误更多，就忽视最新日志已经给出的更小问题面

### N. 想当然使用并不存在的 ArkUI 组件或类型名

典型日志：

- `Cannot find name 'SearchBar'. Did you mean 'Search'?`
- `Cannot find name 'TabBar'.`
- `Cannot find name 'TabBarMode'. Did you mean 'BarMode'?`
- `Cannot find name 'TabBarStyle'. Did you mean 'BarStyle'?`
- `Cannot find name 'TabBarItem'.`
- `Cannot find name 'Spacer'.`

这通常说明：

- 把其他 UI 框架、设计稿描述、旧示例里的名字直接搬进了 ArkTS
- 或者把 ArkUI 中并不存在的高级组件名、配置类型名想当然写出来了

更稳修法：

- 优先采用编译器提示给出的现有类型名，例如 `Search`、`BarMode`、`BarStyle`
- 如果某个组件名完全不存在，不要继续补更多围绕它的配置对象
- 快速原型阶段，优先回退到 `Row` / `Column` / `Text` / `Image` / `Tabs` 这类常见基础组件组合

### O. `does not meet UI component syntax` 往往是次生错误

典型日志：

- `'SearchBar({...}) ...' does not meet UI component syntax`
- `'Spacer()' does not meet UI component syntax`
- `'TabBar({...}) ...' does not meet UI component syntax`

如果同一段日志里同时还有：

- `Cannot find name 'SearchBar'`
- `Cannot find name 'Spacer'`
- `Cannot find name 'TabBar'`

优先判断为：

- 组件名本身就不存在
- 或当前写法不符合 ArkUI 声明式组件语法

处理顺序：

- 不要先盯着链式调用、换行、括号格式
- 先确认这个名字是不是 ArkUI 真实存在的组件
- 再确认它是否应该写成声明式块结构，而不是普通函数调用风格

### P. `Alignment` 和 `ItemAlign` 不是同一类枚举

典型日志：

- `Argument of type 'Alignment' is not assignable to parameter of type 'ItemAlign'`

这说明：

- 把全局对齐枚举直接传给了只接受子项对齐枚举的 API
- 名字看起来相近，但不是同一种类型

更稳修法：

- 不要因为都叫“对齐”就互相替换
- 先看目标 API 参数签名要求的是 `Alignment` 还是 `ItemAlign`
- 如果不确定，优先删掉这条高风险对齐配置，回退到默认布局，再逐项加回

### Q. 搜索框 / 底部栏配置对象很容易照搬错 API

典型日志：

- `Argument of type '{ placeholder: string; showSearchIcon: boolean; showClearButton: boolean; }' is not assignable to parameter of type 'SearchOptions'`
- `Property 'Bottom' does not exist on type 'typeof BarPosition'`

这通常说明：

- 用了想当然的配置字段名
- 或把别的框架、旧版本示例、设计稿语义直接映射成 ArkTS API

更稳修法：

- 不要一上来就堆完整配置对象
- 先使用最小可编译调用，再逐个追加已确认存在的配置字段
- 如果枚举成员不存在，优先采用编译器提示的候选项，或暂时删掉该配置

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

### 模板 8：组件属性名不存在

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 42
根因: 使用了 ArkUI 中不存在的链式属性 placeholderFontColor
建议改法: 按编译器提示改成 placeholderColor(...)
```

### 模板 9：组件名或类型名不存在

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 21
根因: 使用了当前 ArkTS 环境中不存在的 SearchBar 组件名
建议改法: 优先改用编译器提示的 Search，或回退到基础组件组合，不要继续围绕 SearchBar 补配置
```

### 模板 10：UI component syntax 次生报错

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 141
根因: TabBar({...}) 本身不是当前可用的 ArkUI 组件写法，后续链式报错属于次生错误
建议改法: 先确认组件名是否真实存在，再改回 ArkUI 支持的声明式组件结构
```

### 模板 11：对齐枚举类型混用

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 99
根因: 把 Alignment 传给了只接受 ItemAlign 的 API
建议改法: 按目标参数类型改用正确枚举；不确定时先删除该对齐配置，回退到默认布局
```

### 模板 12：资源名不存在

```text
文件: entry/src/main/ets/pages/Index.ets
行号: 151
根因: 引用了 resources 中并不存在的图片资源，例如 icon_message
建议改法: 先移除该资源依赖，改成文本占位、系统图标或确认资源存在后再继续使用 $r(...)
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
