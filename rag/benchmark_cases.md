# ArkTS RAG 系统基准测试用例集

本文档包含一系列针对 HarmonyOS (ArkTS) 开发的典型测试问题，旨在覆盖不同的 API 类别和难度级别。你可以使用这些问题在 `query_system.py` 中进行测试，对比 RAG 开启前后的效果。

## 1. 基础 UI 与交互 (ArkUI)

这些问题测试模型对基础 ArkUI 组件的掌握程度。

*   **Case 1.1**: "如何创建一个包含确认和取消按钮的自定义弹窗 (CustomDialog)？"
    *   *关注点*: 是否使用了 `CustomDialogController`，装饰器 `@CustomDialog` 是否正确。
*   **Case 1.2**: "如何使用 List 组件实现一个懒加载的数据列表？"
    *   *关注点*: 是否使用了 `LazyForEach` 或 `DataSource` 接口。
*   **Case 1.3**: "如何在两个页面之间传递参数并跳转？"
    *   *关注点*: 是否使用了 `router.pushUrl` 或 `Navigation` 组件。

## 2. 系统能力 (System Capabilities)

这些问题测试模型对系统级功能的调用能力。

*   **Case 2.1 (网络)**: "如何发起一个 HTTP GET 请求并处理返回的 JSON 数据？"
    *   *关注点*: `http.createHttp()`, `request()`, 以及异步处理 (Promise/async/await)。
*   **Case 2.2 (数据存储)**: "如何使用用户首选项 (Preferences) 保存和读取用户的设置信息？"
    *   *关注点*: `@kit.ArkData` 中的 `preferences.getPreferences`。
*   **Case 2.3 (权限)**: "如何在应用运行时向用户申请麦克风和相机权限？"
    *   *关注点*: `abilityAccessCtrl`, `requestPermissionsFromUser`。

## 3. 专项 Kit 能力 (Specific Kits)

这部分是 **RAG 系统的强项**。这些问题针对特定的 Kit，如果 RAG 工作正常，它应该能检索到准确的 `import` 路径和 API 签名。

*   **Case 3.1 (账号服务)**: "如何实现华为账号的一键登录功能？"
    *   *关键 API*: `authentication.HuaweiIDProvider`, `createLoginWithHuaweiIDRequest`.
    *   *参考文件*: `account-api-authentication.json`
*   **Case 3.2 (自动化测试)**: "在 UiTest 脚本中，如何查找文本为 'Confirm' 的按钮并执行点击操作？"
    *   *关键 API*: `Driver.create()`, `findComponent`, `ON.text()`.
    *   *参考文件*: `js-apis-uitest.json`
*   **Case 3.3 (图片选择)**: "如何使用 Picker 选择器从图库中选择一张图片？"
    *   *关键 API*: `photoAccessHelper.PhotoViewPicker`, `select()`.
    *   *参考文件*: `ohos-file-photopickercomponent.json` 或 `js-apis-photoaccesshelper.json`
*   **Case 3.4 (健康服务)**: "如何读取用户的今日步数数据？"
    *   *关键 API*: `healthStore.getHealthRecord` 或相关 Health Kit 接口。
    *   *参考文件*: `health-api-healthstore.json`

## 4. 进阶/生僻功能

这些问题针对较新的或不常用的 API，用来测试长尾知识的覆盖。

*   **Case 4.1 (视觉服务)**: "如何使用 Core Vision 进行人脸检测？"
    *   *参考文件*: `core-vision-face-detector-api.json`
*   **Case 4.2 (实况窗)**: "如何创建一个 LiveView (实况窗) 并更新状态？"
    *   *参考文件*: `liveveiw-liveviewmanager.json`

## 5. 记录模板

建议在测试时使用如下格式记录结果：

| Case ID | 问题 | 无 RAG 表现 | RAG 表现 | 结论 |
| :--- | :--- | :--- | :--- | :--- |
| 3.1 | 华为账号登录 | 幻觉，使用了过时的 `HuaweiIdAuthParamsHelper` | 准确，使用了 `authentication.HuaweiIDProvider` | RAG 修正了 API 演进导致的错误 |
| 1.1 | 自定义弹窗 | 正确 | 正确 | 基础知识两者相当 |
