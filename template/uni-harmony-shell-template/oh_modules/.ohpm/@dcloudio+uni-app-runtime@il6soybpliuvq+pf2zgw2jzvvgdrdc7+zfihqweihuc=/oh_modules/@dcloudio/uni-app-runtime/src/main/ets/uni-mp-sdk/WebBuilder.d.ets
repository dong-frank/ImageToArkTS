import webview from '@ohos.web.webview';
interface JavaScriptProxy {
    object: object;
    name: string;
    methodList: Array<string>;
    controller: WebviewController;
}
interface WebBuilderOptions extends WebOptions {
    darkmode: boolean;
    scrollIndicator: string;
    controller: webview.WebviewController;
    javaScriptProxy: JavaScriptProxy;
    safeAreaEdges: Array<SafeAreaEdge>;
    backgroundColor?: string;
    bounce?: string;
    onPageBegin: () => void;
    onPageEnd: () => void;
    onFocus: () => void;
    onBlur: () => void;
    onPageVisible: () => void;
    onInterceptRequest: () => WebResourceResponse;
    onNativeEmbedLifecycleChange: (event: NativeEmbedDataInfo) => void;
    onNativeEmbedGestureEvent: (event: NativeEmbedTouchInfo) => void;
    onAreaChange: (oldValue: Area, newValue: Area) => void;
    onControllerAttached: () => void;
}
export declare const WEB_PAGE_END = "WebPageEnd";
@Builder
export declare function WebBuilder(options: WebBuilderOptions): void;
@Builder
export declare function WebComponent(options: WebBuilderOptions): void;
export {};
