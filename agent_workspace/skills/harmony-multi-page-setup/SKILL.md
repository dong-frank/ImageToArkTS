---
name: harmony-multi-page-setup
description: |-
  HarmonyOS 多页面组织助手。用于在开始编码前规划多页面 app 的入口页、页面注册、
  main_pages.json、EntryAbility.loadContent、页面跳转方式和导航链路，避免跳板页设计、
  避免页面已生成但未注册、避免入口页和路由配置不一致。
  适合在 coder 开始写多页面应用时使用。
---

# Harmony Multi Page Setup

## 何时使用

- architect 输出里存在多个页面
- 需要在计算页、详情页、列表页、设置页之间跳转
- 需要决定真实首页是谁
- 需要写 `EntryAbility.ets`
- 需要更新 `main_pages.json`
- 需要决定页面之间如何导航
- 想避免“编译能过但启动白屏”或“页面没注册”的问题

## 目标

这个 skill 不是事后排障手册，而是前置组织规范。

优先帮助 coder 在开始写代码前做四件事：

1. 选定一个真实首页
2. 统一入口页加载、页面注册和路由名
3. 规划最短且稳定的多页面导航链路
4. 避免使用高风险的首屏跳转组织方式

## 多页面原型的默认组织方式

对于快速原型，多页面默认遵循下面的方式：

1. 选一个真实首页，例如 `CalculatorPage`
2. 让 `EntryAbility` 直接 `loadContent('pages/CalculatorPage')`
3. 在 `main_pages.json` 中注册所有会直接进入或跳转到的页面
4. 页面文件名、注册名、路由字符串保持完全一致
5. 不要为了“结构更规范”再额外创建一个跳板页 `Index`

## 开始编码前必须统一的三处

### 1. `EntryAbility.ets`

重点看：

- `windowStage.loadContent('pages/XXX', ...)`

这里必须直接加载真实首页。

更稳做法：

```ts
windowStage.loadContent('pages/CalculatorPage', ...)
```

不要先加载 `pages/Index` 再在 `Index.ets` 里跳转。

### 2. `main_pages.json`

重点看：

- 是否包含真实首页
- 是否包含所有会被直接跳转到的页面

例如：

```json
{
  "src": [
    "pages/CalculatorPage",
    "pages/ConverterPage"
  ]
}
```

### 3. `pages/` 目录

重点看：

- 页面文件名是否和路由名一致
- 例如文件是 `CalculatorPage.ets`，那路由就统一用 `pages/CalculatorPage`

## 多页面原型的高风险模式

### A. 跳板页模式

高风险写法：

- `EntryAbility` 先加载 `pages/Index`
- `Index.ets` 的 `aboutToAppear` 里再 `replaceUrl('pages/CalculatorPage')`

为什么危险：

- 跳板页本身也需要注册
- 多一层跳转，多一层失败点
- 入口页和真实首页容易失配
- 更容易出现“编译通过但启动白屏”或“首页没有显示预期页面”

更稳做法：

- 删除这层跳板
- 让 `EntryAbility` 直接加载真实首页

### B. 注册名、文件名、跳转名不一致

高风险写法：

- 文件名：`ConverterPage.ets`
- `main_pages.json`：`pages/ConvertPage`
- 跳转：`pages/Converter`

更稳做法：

- 三处统一成一个名字
- 推荐直接跟文件名走

### C. 过早设计复杂导航链路

高风险模式：

- 首页先跳中间页
- 中间页再跳真实页
- 返回又回到不存在或未注册页面

更稳做法：

- 只保留最短链路
- 首页直达
- 二级页面从首页进入

## 当前项目里的导航建议

对于像“计算器 + 换算器”这种双页面原型，建议这样组织：

1. `CalculatorPage` 作为真实首页
2. `EntryAbility` 直接加载 `pages/CalculatorPage`
3. `main_pages.json` 注册：
   - `pages/CalculatorPage`
   - `pages/ConverterPage`
4. 页面顶部 Tab 或按钮只负责页面切换，不要依赖 `Index` 中转

## 关于导航 API 的规则

### 1. 不要把 `replaceUrl` 当成默认首屏组织方式

在标准 HarmonyOS 单平台项目里，页面跳转 API 可以使用，但首页组织仍然应当更直接。

所以默认规则是：

- 不要把 `replaceUrl` 当成首页中转手段
- 不要在 `Index.ets` 里靠 `replaceUrl` 跳首页

### 2. `pushUrl` / `back` 先作为次优方案看待

它们可以用于真实的页面切换，但不应该拿来补救入口页设计问题。

快速原型阶段更稳的策略是：

- 先把真实首页直接挂到 `EntryAbility`
- 再最小化页面间跳转

### 3. 先保证入口稳定，再优化导航 API

优先级应该是：

1. 页面已注册
2. 首页可显示
3. 页面名一致
4. 跳转链路最短
5. 再考虑替换成更合适的导航 API

### 4. 入口配置优先于页面内部导航

在标准 HarmonyOS 项目里，首先要保证：

- `EntryAbility.loadContent(...)` 指向真实首页
- `main_pages.json` 已注册所有目标页面
- 文件名、路由名、注册名完全一致

只有这三处一致以后，再实现按钮点击、Tab 切换或页面返回。

## 给 coder 的硬规则

1. 只要是多页面应用，先确定真实首页，再写页面代码。
2. `EntryAbility` 必须直接加载真实首页，不要默认走 `Index` 跳板页。
3. `main_pages.json`、页面文件名、路由字符串必须一致。
4. 不要先写跳转，再补页面注册；注册和页面文件要同步完成。
5. 不要把 `replaceUrl` 当作默认首屏跳转方案。
6. 如果导航链路复杂，先收缩成最短可运行版本。

## 最小组织模板

### 模板 1：双页面原型

```text
首页: CalculatorPage
次级页: ConverterPage
EntryAbility.loadContent: pages/CalculatorPage
main_pages.json:
- pages/CalculatorPage
- pages/ConverterPage
页面跳转:
- CalculatorPage -> ConverterPage
- ConverterPage -> CalculatorPage
```

### 模板 2：入口配置检查

```text
先检查:
1. EntryAbility 加载的是不是注册过的真实首页
2. main_pages.json 里有没有这个页面
3. pages/ 目录里有没有对应 .ets 文件
4. 路由字符串是否和文件名一致
```

### 模板 3：发现跳板页时

```text
根因: 使用了 Index 作为中转页，再通过 replaceUrl/pushUrl 跳真实首页
建议改法: 删除这层中转，让 EntryAbility 直接加载真实首页
```

## 输出风格

回答要短、直接、偏“开始写代码前的组织建议”。

优先给：

- 真实首页是谁
- `EntryAbility` 应该加载哪个页面
- `main_pages.json` 应该注册哪些页面
- 页面名、注册名、路由名怎么统一

避免：

- 一开始就设计复杂导航体系
- 先生成跳板页再想办法补救
