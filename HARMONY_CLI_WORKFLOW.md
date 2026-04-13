# Uni-app 到 HarmonyOS 原生 HAP 的纯 CLI 流程

## 速查命令

创建项目：

	cd /Users/dong/2026/uni-app-test
	./create_project.sh 项目名

浏览器预览：

	cd /Users/dong/2026/uni-app-test/项目名
	npm run dev:h5

编译并在鸿蒙设备运行：

	cd /Users/dong/2026/uni-app-test/项目名
	npm run build:harmony:cli
	/Users/dong/command-line-tools/sdk/default/openharmony/toolchains/hdc install -r ./unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap

## 适用场景

- 前端项目：my-vue3-project（uni-app）
- 壳工程：template/uni-harmony-shell-template（HarmonyOS 原生工程模板）
- 目标：不使用 HBuilderX，全程通过命令行完成编译、资源同步、HAP 打包

## 目录约定

- Uni 项目目录：/Users/dong/2026/uni-app-test/my-vue3-project
- Harmony 壳工程模板目录：/Users/dong/2026/uni-app-test/template/uni-harmony-shell-template
- Uni 编译产物：my-vue3-project/dist/build/app-harmony
- 运行壳目录：project/unpackage/dist/dev/app-harmony
- 壳工程 rawfile 目标目录：template/uni-harmony-shell-template/entry/src/main/resources/rawfile/www
- HAP 输出：project/unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap

## 运行时壳来源（关键）

app-harmony 产物依赖 uni runtime，不能直接放入一个普通 ArkUI 空壳 WebView 里运行。

本机已验证可用壳来源：

- hbuilderx-test/unpackage/dist/dev/app-harmony

验证依据：在设备日志中已出现 `App Launch` / `App Show`，说明 runtime 注入正常。

建议做法：

1. 先用 HBuilderX 跑通一次 app-harmony，拿到可运行壳目录。
2. 将该壳作为长期 CLI 壳模板（替换或重建 template/uni-harmony-shell-template）。
3. 后续继续走本文 CLI 流程（uni build + 资源同步 + hvigor 打包）。

## 前置条件

确保下列命令可用：

- npm
- uni（通过 npm scripts 或 npx 调用）
- ohpm
- hvigorw
- hdc（如需安装到设备）

已在本机验证到的路径示例：

- /Users/dong/command-line-tools/bin/ohpm
- /Users/dong/command-line-tools/bin/hvigorw
- /Users/dong/command-line-tools/sdk/default/openharmony/toolchains/hdc

## 一次性配置（已完成）

已在 my-vue3-project/package.json 增加以下脚本：

- build:app-harmony
- sync:app-harmony-shell
- sync:harmony-shell-meta
- build:hap:cli
- build:harmony:cli

具体定义见 my-vue3-project/package.json。

## 推荐执行方式（一键）

在 my-vue3-project 目录执行：

```bash
npm run build:harmony:cli
```

该命令会依次执行：

1. uni 编译 app-harmony
2. 把 dist/build/app-harmony 同步到壳工程 rawfile/www
3. 自动同步壳工程 app_name（从 uni manifest.name 读取，空则回退 package.json.name）
4. 在壳工程内执行 ohpm install 和 hvigorw assembleHap

## 壳名称自动替换（仿 HBuilderX 体验）

已新增脚本：

- my-vue3-project/scripts/sync-harmony-shell-meta.mjs

功能：

1. 读取 my-vue3-project/src/manifest.json 的 name。
2. 若 name 为空，回退到 my-vue3-project/package.json 的 name。
3. 写入 template/uni-harmony-shell-template/AppScope/resources/base/element/string.json 的 app_name。

手动执行：

```bash
cd /Users/dong/2026/uni-app-test/my-vue3-project
npm run sync:harmony-shell-meta
```

注意：

- 若想应用显示为你的业务名，优先在 uni 的 manifest.json 中配置 name。

## 分步执行方式

在 my-vue3-project 目录执行：

```bash
npm run build:app-harmony
npm run sync:app-harmony-shell
npm run build:hap:cli
```

## 设备安装（可选）

```bash
/Users/dong/command-line-tools/sdk/default/openharmony/toolchains/hdc install -r \
/Users/dong/2026/uni-app-test/project-name/unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 已验证结论

1. 纯 CLI 编译链路可跑通。
2. HAP 可成功产出（当前为 unsigned）。
3. 如果需要可安装的签名包，需在壳工程 build-profile.json5 配置 signingConfigs。

## 关键坑位与排查

### 1) rawfile 目录层级错误会导致资源编译失败

错误示例：

- 放到 entry/src/main/resources/base/rawfile

会报：

- Invalid resource directory name 'rawfile'. Valid values: ["element","media","profile"]

正确路径：

- entry/src/main/resources/rawfile/www

### 2) 壳工程默认页面不是 Uni 页面

当前 template/uni-harmony-shell-template 是默认 ArkUI 示例页。

即使已同步 Uni 资源到 rawfile/www，也需要在壳工程里有对应的 WebView/启动桥接逻辑，才能真正显示 Uni 页面。

补充说明：

- 若壳工程本身不是 uni runtime 壳（仅普通 ArkUI 工程），常见现象是白屏。
- 优先使用上文“运行时壳来源”中的目录作为壳模板，再进行 CLI 打包。

## 壳工程 WebView 接入（已验证）

目标：让壳工程首页直接加载 rawfile/www 下的 Uni 入口。

已修改文件：

- template/uni-harmony-shell-template/entry/src/main/ets/pages/Index.ets

核心做法：

1. 引入 ArkWeb：`import { webview } from '@kit.ArkWeb';`
2. 创建 controller：`new webview.WebviewController()`
3. 使用 Web 组件加载本地资源：`$rawfile('www/__uniappview.html')`

示例结构（精简版）：

```ts
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
	private controller: webview.WebviewController = new webview.WebviewController();

	build() {
		Column() {
			Web({
				src: $rawfile('www/__uniappview.html'),
				controller: this.controller
			})
		}
		.width('100%')
		.height('100%')
	}
}
```

验证方式：

```bash
cd /Users/dong/2026/uni-app-test/my-vue3-project
npm run build:harmony:cli
```

预期结果：

- hvigor BUILD SUCCESSFUL
- 生成 HAP：project/unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap

### 3) 打包警告：Unexpected source code files packaged

示例文件：

- rawfile/www/uni_modules/index.generated.ets

该警告不阻断构建，可先忽略；若需严格治理，可按 hvigor 提示调整 source code check 策略。

## 给后续 Agent 的执行清单

1. 优先确认壳是否来自可运行的 uni runtime 壳（建议使用 hbuilderx-test/unpackage/dist/dev/app-harmony）。
2. 进入 my-vue3-project 执行 npm run build:harmony:cli。
3. 确认产物存在：项目目录/unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap。
4. 如需上机安装，执行 hdc install -r。
5. 如需发布，先补签名配置后重打包。
