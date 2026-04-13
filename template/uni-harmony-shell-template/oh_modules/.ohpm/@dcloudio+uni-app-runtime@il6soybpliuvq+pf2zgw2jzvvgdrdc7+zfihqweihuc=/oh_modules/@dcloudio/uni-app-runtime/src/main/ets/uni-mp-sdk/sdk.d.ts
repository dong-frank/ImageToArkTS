import * as window from '@ohos.window';
import window__default from '@ohos.window';
import { NodeRenderType, NodeController, FrameNode, BuilderNode } from '@ohos.arkui.node';
import harmonyWebView from '@ohos.web.webview';
import UIAbility from '@ohos.app.ability.UIAbility';
import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

declare const uni: Record<string, any>;
/**
 * 仅供内部api初始化使用
 * 注意：内部api中发布到ohpm的包不会使用此方式进行初始化，如：uni.startFacialRecognitionVerify = startFacialRecognitionVerify
 */
declare function initUniApi(api: any): any;

interface IManifestApp {
    darkmode?: boolean;
    useragent?: {
        value?: string;
        concatenate?: boolean;
    };
    safearea?: {
        background?: string;
        backgroundDark?: string;
        bottom?: {
            offset?: 'auto' | 'none';
        };
    };
    scrollIndicator?: string;
    distribute?: {
        bundleName?: string;
        splashScreens?: {
            startWindowIcon?: string;
            startWindowBackground?: string;
        };
    };
}
type OrientationLandscape = ['landscape-primary', 'landscape-secondary'];
type OrientationPortrait = ['portrait-primary', 'portrait-secondary'];
type OrientationAuto = ['landscape-primary', 'landscape-secondary', 'portrait-primary', 'portrait-secondary'];
interface Manifest {
    id: string;
    name: string;
    version: {
        name: string;
        code: string;
    };
    description?: string;
    'app-harmony'?: IManifestApp;
    plus: IManifestApp & {
        launchwebview: {
            id: string;
        };
        tabBar?: {
            selectedIndex?: number;
            list?: Array<{
                pagePath?: string;
                text?: string;
                iconPath?: string;
                selectedIconPath?: string;
            }>;
        };
        'uni-app': {
            compilerVersion: string;
        };
    };
    launch_path: string;
    screenOrientation?: OrientationLandscape | OrientationPortrait | OrientationAuto;
}

declare function getCurrentMP(): UniMP | null;
declare function getCurrentWindow$1(): window__default.Window | null | undefined;
interface IUserAgent {
    value: string;
    concatenate: boolean;
    fullUserAgent: string;
}
interface IAppVersionInfo {
    name: string;
    code: string;
}
declare function getAppVersionInfo(appId: string): IAppVersionInfo | null;
type UNIMP_EVENT = '_init' | 'close' | 'show' | 'hide' | 'beforeClose' | 'plusMessage' | 'menuItemClick' | 'uniMPEvent' | '_nativeEventReceive';
interface IUniMP {
    appId: string;
    hide(): void;
    show(): void;
    close(): void;
    isRunning(): boolean;
    getCurrentPageUrl(): string;
    sendUniMPEvent: (event: string, data: any) => void;
    on(event: 'uniMPEvent', callback: (event: string, data: any, notify: (...args: any[]) => void) => void): void;
    on(event: 'menuItemClick', callback: (id: string) => void): void;
    on(event: 'close' | 'show' | 'hide', callback: () => void): void;
    off(name: string, callback: Function): void;
}
interface LaunchOptions {
    redirectInfo: {
        path?: string;
        query?: string;
        extraData?: Record<string, unknown>;
        userAction?: boolean;
        fromAppid?: string;
        appScheme?: string;
        appLink?: string;
    };
    arguments?: Record<string, unknown> | string;
    channel: string;
    launcher: PlusRuntime['launcher'];
}
declare class UniMP implements IUniMP {
    appId: string;
    appName: string;
    /**
     * @internal
     */
    isMain: boolean;
    /**
     * @internal
     */
    host: string;
    /**
     * @internal
     */
    window: window__default.Window | null;
    /**
     * @internal
     */
    context: UIContext | null;
    /**
     * @internal
     */
    router: NavPathStack;
    /**
     * @internal
     */
    manifest: Manifest;
    /**
     * @internal
     */
    showCapsuleButton: boolean;
    /**
     * @internal
     */
    capsuleMenuActionSheetItems: ICapsuleMenuActionSheetItem[];
    /**
     * @internal
     */
    capsuleButtonStyle: ICapsuleStyle;
    /**
     * @internal
     */
    launchOptions: LaunchOptions;
    /**
     * @internal
     */
    runtimeVersion: string;
    /**
     * @internal
     */
    waitForRestart: boolean;
    /**
     * @internal
     */
    animationType: string;
    /**
     * @internal
     */
    animationDuration: number;
    /**
     * @internal
     */
    showSplashScreen: boolean;
    startWindowIcon?: string;
    startWindowBackground: string;
    orientation: 'auto' | 'portrait' | 'landscape';
    /**
     * @internal
     */
    private _emitter;
    /**
     * @internal
     */
    private _runtime;
    /**
     * @internal
     * 禁止自动显示窗口
     */
    private _disableAutoShow;
    /**
     * @internal
     * 最小化窗口（隐藏状态）
     */
    private _minimize;
    /**
     * @internal
     */
    private _onBackground;
    /**
     * @internal
     */
    private _onForeground;
    capsuleMenuButtonClick: () => void;
    capsuleCloseButtonClick: () => void;
    userAgent: IUserAgent;
    private _closed;
    constructor(id: string, config?: IOpenUniMPConfig);
    getCurrentPageUrl(): string;
    close(): void;
    isRunning(): boolean;
    hide(): void;
    show(): void;
    on(name: UNIMP_EVENT, callback: Function): void;
    off(name: UNIMP_EVENT, callback: Function): void;
    /**
     * @internal
     */
    emit(name: UNIMP_EVENT, ...args: unknown[]): void;
    sendUniMPEvent(event: string, data: any): void;
    /**
     * @internal
     */
    private _setMinimize;
}
interface ICapsuleStyle {
    backgroundColor?: string;
    textColor?: string;
    highlightColor?: string;
    borderColor?: string;
}
interface ICapsuleMenuActionSheetItem {
    id: string;
    title: string;
}
interface IOpenUniMPConfig {
    /**
     * @internal
     */
    isMain?: boolean;
    /**
     * @internal
     */
    host?: string;
    showCapsuleButton?: boolean;
    capsuleMenuActionSheetItems?: ICapsuleMenuActionSheetItem[];
    capsuleButtonStyle?: ICapsuleStyle;
    redirectPath?: string;
    animationType?: string;
    animationDuration?: number;
    showSplashScreen?: boolean;
    /**
     * @deprecated
     */
    arguments?: Record<string, unknown> | string;
    extraData?: Record<string, unknown>;
    /**
     * @internal
     */
    channel?: string;
    /**
     * @internal
     */
    launcher?: PlusRuntime['launcher'];
}
/**
 * 启动小程序
 */
declare function openUniMP(appId: string, config?: IOpenUniMPConfig): UniMP;
/**
 * 获取小程序
 */
declare function getUniMP(appId: string): UniMP;
/**
 * 关闭小程序
 */
declare function closeUniMP(appId: string): void;
/**
 * 启动 UniApp
 */
declare function openUniApp(appId: string, config?: IOpenUniMPConfig): UniMP;
declare function hmrOpenUniApp(appId: string, config?: IOpenUniMPConfig): Promise<void>;
declare function hmrRestartUniApp(): Promise<void>;

interface ControllerConstructor {
    new (): any;
}
interface DefineNativeEmbedOptions<T extends NativeEmbedBuilderOptions = NativeEmbedBuilderOptions> {
    builder: (options: T) => void;
    controller?: ControllerConstructor;
    nodeRenderType?: NodeRenderType;
}
declare function defineNativeEmbed<T extends NativeEmbedBuilderOptions = NativeEmbedBuilderOptions>(name: string, options: DefineNativeEmbedOptions<T>): void;
interface NativeEmbedEvent {
    detail: object;
}
interface NativeEmbedBuilderOptions {
    controller?: Object;
    width: number;
    height: number;
    x: number;
    y: number;
    visibility: Visibility;
    on?: Map<string, (event?: NativeEmbedEvent) => void>;
    [key: string]: unknown;
}
declare class NativeEmbedNodeController extends NodeController {
    surfaceId: string;
    renderType: NodeRenderType;
    embedId: string;
    /**
     * @internal
     */
    private isDestroy;
    /**
     * @internal
     */
    private isDetached;
    /**
     * @internal
     */
    private rootNode;
    private isWebviewControllerAttached;
    private WebviewInvokes;
    options: NativeEmbedBuilderOptions;
    controller?: any;
    type: string;
    id: string;
    elId: string;
    parent: WebView;
    /**
     * @internal
     */
    private _defineNativeEmbedOptions;
    constructor(parent: WebView, id: string, info: NativeEmbedInfo, surfaceId: string, embedId: string, elId?: string);
    parseOptions(info: NativeEmbedInfo): NativeEmbedBuilderOptions;
    makeNode(uiContext: UIContext): FrameNode | null;
    update(info: NativeEmbedInfo): void;
    invoke(method: string, args: unknown[]): any;
    postTouchEvent(event: TouchEvent | undefined): boolean;
    detach(): void;
    destroy(): void;
}

declare function getCurrentWebview(mp?: UniMP): WebView | undefined;
interface WindowInfo$1 {
    statusBarHeight: number;
    screenTop: number;
    windowHeight: number;
    windowWidth: number;
    screenHeight: number;
    screenWidth: number;
}
declare function createWebNode(mp: UniMP, id: string, options: WebBuilderOptions): BuilderNode<[WebBuilderOptions]>;
interface JavaScriptProxy {
    object: object;
    name: string;
    methodList: Array<string>;
    controller: WebviewController;
}
interface WebBuilderOptions extends WebOptions {
    darkmode: boolean;
    javaScriptProxy: JavaScriptProxy;
    safeAreaEdges: Array<SafeAreaEdge>;
    backgroundColor?: string;
    scrollIndicator: string;
    bounce: string;
    onFocus: () => void;
    onBlur: () => void;
    onPageBegin: () => void;
    onPageEnd: () => void;
    onPageVisible: () => void;
    onInterceptRequest: (event?: {
        request: WebResourceRequest;
    }) => WebResourceResponse | void;
    onNativeEmbedLifecycleChange: (event: NativeEmbedDataInfo) => void;
    onNativeEmbedGestureEvent: (event: NativeEmbedTouchInfo) => void;
    onAreaChange: (oldValue: Area, newValue: Area) => void;
    onControllerAttached: () => void;
}
interface IWebNodeController extends NodeController {
    update: (options: Partial<WebBuilderOptions>) => void;
}
declare class WebNodeController extends NodeController implements IWebNodeController {
    id: string;
    isDisappear: boolean;
    mp: UniMP;
    constructor(id: string);
    makeNode(uiContext: UIContext): FrameNode | null;
    aboutToDisappear(): void;
    update(options: Partial<WebBuilderOptions>): void;
}
interface UniWebviewWebviewStyles {
    uniPageUrl?: {
        path: string;
        query: string;
    };
    debugRefresh?: {
        isTab: boolean;
        arguments: string;
    };
}
declare class WebView implements PlusWebviewWebviewObject {
    id: string;
    /**
     * harmony Webview 控制器
     */
    controller?: harmonyWebView.WebviewController;
    /**
     * harmony Webview 节点
     */
    node: ReturnType<typeof createWebNode>;
    /**
     * Webview 对应的 harmony 页面（组件）
     * 先使用占位信息
     */
    page: PageState;
    /**
     * 是否开始渲染
     */
    isRendering: boolean;
    /**
     * 页面样式配置
     */
    get style(): PlusWebviewWebviewStyles & UniWebviewWebviewStyles;
    /**
     * 页面状态
     */
    pageState: SubPageState;
    /**
     * 关联的 UniMP 实例
     */
    mp: UniMP;
    onclose: (result: any) => void;
    onerror: (result: any) => void;
    onloaded: (result: any) => void;
    onloading: (result: any) => void;
    private _emitter;
    private _isFocused;
    private _softinputTemporary?;
    private _safeAreaInsetsChangeHandler?;
    private _keyboardHeightChangeHandler?;
    private _lastKeyboardHeight;
    private _children;
    private _childTasks;
    private _manifestSafeArea;
    isCloseCalled: boolean;
    constructor(src?: string, id?: string, style?: PlusWebviewWebviewStyles, extras?: any);
    /**
     * 注册子节点任务，用于处理部分情况下view层任务来了但是子节点的NodeController仍未创建导致任务被丢弃的Bug
     * 典型场景：页面onLoad内setTimeout(() => {设置webview src}, 0)
     */
    private _registerChildTask;
    private _updateNode;
    getCurrentNodeController(elId: string): NativeEmbedNodeController | undefined;
    addEventListener(event: 'controllerAttached' | 'close' | 'hide' | 'show' | 'error' | 'dragBounce' | 'loading' | 'loaded' | 'maskClick' | 'popGesture' | 'titleUpdate' | 'pullToRefresh' | 'resize', listener: (result?: any) => void, capture?: boolean | undefined): void;
    append(webview: PlusWebviewWebviewObject | PlusNativeObjView): void;
    appendJsFile(file: string): void;
    animate(options?: PlusWebviewWebviewContentAnimationOptions | undefined, callback?: (() => void) | undefined): void;
    back(): void;
    beginPullToRefresh(): void;
    canBack(queryCallback: (result: boolean) => void): void;
    canForward(queryCallback: (result: any) => void): void;
    checkRenderedContent(options?: PlusWebviewWebviewRenderedEventOptions | undefined, successCallback?: (() => void) | undefined, errorCallback?: ((result: any) => void) | undefined): void;
    children(): PlusWebviewWebviewObject[];
    clear(): void;
    close(aniClose?: 'none' | 'pop-out' | 'slide-out-right' | 'auto' | 'slide-out-left' | 'slide-out-top' | 'slide-out-bottom' | 'fade-out' | 'zoom-in' | 'zoom-fade-in' | 'flip-x' | 'flip-rx' | 'flip-y' | 'flip-ry' | 'page-backward' | undefined, duration?: number | undefined, extras?: PlusWebviewWebviewExtraOptions | undefined): void;
    drag(options: PlusWebviewWebviewDragOptions, otherView?: PlusWebviewWebviewDragOtherViewOptions | undefined, callback?: ((result: PlusWebviewWebviewDragEvent) => void) | undefined): void;
    draw(bitmap?: PlusNativeObjBitmap | undefined, successCallback?: (() => void) | undefined, errorCallback?: ((result: any) => void) | undefined, options?: PlusWebviewWebviewDrawOptions | undefined): void;
    endPullToRefresh(): void;
    evalJS(js: string): void;
    evalJSAsync(js: string): Promise<string>;
    forward(): void;
    getFavoriteOptions(): PlusWebviewWebviewFavoriteOptions;
    getSafeAreaInsets(): PlusNavigatorSafeAreaInsets & WindowInfo$1;
    getShareOptions(): PlusWebviewWebviewShareOptions;
    getStyle(): PlusWebviewWebviewStyles;
    getSubNViews(): PlusNativeObjView[];
    getTitle(): string;
    getTitleNView(): PlusNativeObjView;
    getTitleNViewSearchInputText(): string;
    getURL(): string;
    hide(aniHide?: 'none' | 'pop-out' | 'slide-out-right' | 'auto' | 'slide-out-left' | 'slide-out-top' | 'slide-out-bottom' | 'fade-out' | 'zoom-in' | 'zoom-fade-in' | 'flip-x' | 'flip-rx' | 'flip-y' | 'flip-ry' | 'page-backward' | undefined, duration?: number | undefined, extras?: PlusWebviewWebviewExtraOptions | undefined): void;
    hideTitleNViewButtonRedDot(options: PlusWebviewHideTitleNViewButtonRedDotOptions): void;
    interceptTouchEvent(intercept?: boolean | undefined): void;
    isHardwareAccelerated(): boolean;
    isPause(): boolean;
    isVisible(): boolean;
    listenResourceLoading(options?: PlusWebviewWebviewListenResourceOptions | undefined, callback?: ((result: any) => void) | undefined): void;
    loadData(data: string, options?: PlusWebviewWebviewLoadDataOptions | undefined): void;
    loadURL(url: string, additionalHttpHeaders?: any): void;
    nativeInstanceObject(): PlusAndroidInstanceObject | PlusIosInstanceObject;
    opened(): PlusWebviewWebviewObject[];
    opener(): PlusWebviewWebviewObject;
    overrideResourceRequest(options?: PlusWebviewWebviewOverrideResourceOptions[] | undefined): void;
    overrideUrlLoading(options?: PlusWebviewWebviewOverrideUrlOptions | undefined, callback?: ((result: any) => void) | undefined): void;
    parent(): PlusWebviewWebviewObject;
    pause(): void;
    reload(force: boolean): void;
    resetBounce(): void;
    restore(): void;
    remove(webview: PlusWebviewWebviewObject | PlusNativeObjView): void;
    removeEventListener(event: PlusWebviewWebviewEvent | 'controllerAttached' | 'close' | 'hide' | 'show' | 'error' | 'dragBounce' | 'loading' | 'loaded' | 'maskClick' | 'popGesture' | 'titleUpdate' | 'pullToRefresh' | 'resize', listener?: (result?: any) => void): void;
    removeFromParent(): void;
    removeTitleNViewButtonBadge(options: PlusWebviewRemoveTitleNViewButtonBadgeOptions): void;
    resume(): void;
    setBounce(style: PlusWebviewWebviewBounceStyle): void;
    setBlockNetworkImage(block: boolean): void;
    setContentVisible(visible: boolean): void;
    setCssFile(file: string): void;
    setCssText(text: string): void;
    setFavoriteOptions(options: PlusWebviewWebviewFavoriteOptions): void;
    setFixBottom(height: number): void;
    setJsFile(file: string): void;
    setPullToRefresh(style: PlusWebviewWebviewPullToRefreshStyles, refreshCB: () => void): void;
    setRenderedEventOptions(options: PlusWebviewWebviewRenderedEventOptions): void;
    setSoftinputTemporary(options: PlusWebviewSetSoftinputTemporaryOptions): void;
    setStyle(styles: PlusWebviewWebviewStyles): void;
    setShareOptions(options: PlusWebviewWebviewShareOptions): void;
    setTitleNViewButtonBadge(options: PlusWebviewSetTitleNViewButtonBadgeOptions): void;
    setTitleNViewButtonStyle(index: number, styles: PlusWebviewWebviewTitleNViewButtonStyles): void;
    setTitleNViewSearchInputFocus(focus: boolean): void;
    setTitleNViewSearchInputText(text: string): void;
    setVisible(visible: boolean): void;
    show(aniShow?: 'none' | 'pop-in' | 'slide-in-right' | 'auto' | 'flip-x' | 'flip-rx' | 'flip-y' | 'flip-ry' | 'slide-in-left' | 'slide-in-bottom' | 'fade-in' | 'zoom-out' | 'zoom-fade-out' | 'page-forward' | undefined, duration?: number | undefined, showedCB?: (() => void) | undefined, extras?: PlusWebviewWebviewExtraOptions | undefined): void;
    showBehind(webview?: PlusWebviewWebviewObject | undefined): void;
    showTitleNViewButtonRedDot(options: PlusWebviewShowTitleNViewButtonRedDotOptions): void;
    stop(): void;
    updateSubNViews(styles: PlusWebviewWebviewSubNViewStyles[]): void;
}

declare class TinyEmitter {
  on(event: string, callback: Function, ctx?: any): this;
  once(event: string, callback: Function, ctx?: any): this;
  emit(event: string, ...args: any[]): this;
  off(event: string, callback?: Function): this;
}

declare const TEMPLATE_PAGE_NAME = "UniPage";
type ServiceMethodHandler = (params: any, resolve: (arg: any) => void) => void;
declare function registerServiceMethod(name: string, fn: ServiceMethodHandler): void;
declare function getServiceMethod(): Record<string, ServiceMethodHandler>;
interface SetOSRuntimeOptions<T extends WebOptions = WebOptions> {
    WebBuilder: (options: T) => void;
    createSubPageState: (options: SubPageState) => SubPageState;
    createTabBarState: (options: TabBarState) => TabBarState;
    createTabBarItem: (options: TabBarItem) => TabBarItem;
    previewImage: (options: {
        urls: string[];
        current?: string;
        showmenu?: boolean;
    }, page: any) => void;
    closePreviewImage: () => void;
    showLoading: (options: {
        title: string;
        mask: boolean;
    }, page: any) => void;
    hideLoading: () => void;
    setThemeState: (themeState: ThemeState) => void;
}
declare function setOSRuntime<T extends WebOptions = WebOptions>(options: SetOSRuntimeOptions<T>): void;
declare function getOSRuntime(): SetOSRuntimeOptions<any>;
declare function getAbilityContext(): common.UIAbilityContext | null;
declare function getWindowStage$1(): window__default.WindowStage | null;
declare const onBackPressCallbacks: WeakMap<UniMP, ((res: PlusKeyKeyEvent) => void)[]>;
interface IRefreshState {
    refreshing?: boolean;
    onRefreshing?: () => void;
    onRefreshStateChange?: (state?: RefreshStatus) => void;
}
interface SubPageState {
    id: string;
    style: WebView['style'] & {
        marginTop?: number;
        paddingBottom?: number;
    };
    embedChildren: NodeController[];
    stackChildren: NodeController[];
    refreshState: IRefreshState;
}
interface ThemeState {
    tabBarBackground?: string;
    isDark?: boolean;
}
type PageComponent = CustomComponent & PageState;
type PageState = {
    name?: string;
    pages: SubPageState[];
    tabBar: TabBarState;
    safeArea: Manifest['plus']['safearea'];
};
interface TabBarItem {
    pagePath?: string;
    text?: string;
    iconPath?: string;
    selectedIconPath?: string;
    visible?: boolean;
    badgeType?: undefined | 'dot' | 'number';
    badgeText?: string;
}
interface TabBarStyle {
    backgroundColor?: string;
    borderStyle?: string;
    color?: string;
    selectedColor?: string;
}
interface TabBarMidButtonIconfont {
    text?: string;
    selectedText?: string;
    fontSize?: string;
    color?: string;
    selectedColor?: string;
}
interface TabBarMidButton {
    width?: string;
    height?: string;
    text?: string;
    iconPath?: string;
    iconWidth?: string;
    backgroundImage?: string;
    iconfont?: TabBarMidButtonIconfont;
}
interface TabBarState extends TabBarStyle {
    selectedIndex?: number;
    list?: TabBarItem[];
    midButton?: TabBarMidButton;
    visible?: boolean;
    onClick?: (options?: {
        index: number;
    }) => void;
    onMidButtonClick?: () => void;
}
type PageLifeCycle = 'aboutToAppear' | 'aboutToDisappear' | 'onBackPress' | 'onPageShow' | 'onPageHide';
declare const pageLifeCycle: TinyEmitter;
declare class NativePagesManager {
    pages: PageComponent[];
    ready: boolean;
    private _onReadyCallbacks;
    constructor();
    push(page: PageComponent): void;
    remove(page: PageComponent): void;
    onNativePageReady(callback: (page: PageComponent) => void): void;
}
declare const nativePagesManager: NativePagesManager;
declare function callPageLifeCycle(name: PageLifeCycle, page: PageComponent): boolean;
declare const appLifeCycle$1: TinyEmitter;
interface IInitConfig {
    debug?: boolean;
}
declare const globalConfig: IInitConfig;
/**
 * 尽量早调用，需要提供给uts插件使用
 */
declare function initAbility(ability: UIAbility): void;
/**
 * 初始化 SDK
 * 此方法在onWindowStageCreate生命周期调用，但是uni-push又需要在onCreate生命周期调用获取context。
 * 暂时暴露onWindowStageCreate生命周期给uni-push使用，uni-push暂存onCreate生命周期的参数，等到onWindowStageCreate生命周期再处理暂存的参数。
 */
declare function init(ability: UIAbility, stage: window__default.WindowStage, config?: IInitConfig): void;
declare function createDownloadDelegate(): harmonyWebView.WebDownloadDelegate;
declare const telSchemeHandler: harmonyWebView.WebSchemeHandler;

declare function getEntryMetadata(): bundleManager.Metadata[];

declare function getResourceStr<T extends boolean>(filepath: string, forceStr?: T, appId?: string): T extends true ? string : ResourceStr;
declare function getRealPath(url: string): string;
interface Env {
    USER_DATA_PATH: string;
    TEMP_PATH: string;
    CACHE_PATH: string;
}
declare function getEnv(): Env;

interface HarmonyNavigator extends PlusNavigator {
    setStatusBarStyle(style: 'dark' | 'light', statusBarBackground?: string): void;
}
declare function getSafeAreaInsets(px?: boolean): {
    top: number;
    bottom: number;
    left: number;
    right: number;
    keyboardHeight?: number;
};
declare function onSafeAreaInsetsChange(callback: (info: {
    top?: number;
    bottom?: number;
    left?: number;
    right?: number;
    keyboardHeight?: number;
}) => void, px?: boolean): void;
declare function offSafeAreaInsetsChange(callback: (...args: any[]) => unknown): void;
declare const navigator: Pick<HarmonyNavigator, 'setStatusBarStyle' | 'getSafeAreaInsets' | 'getOrientation' | 'getUIStyle'>;

/**
 * devicePX2px
 * @description 物理像素转换为页面的px像素
 * @param {number} px
 * @return {number}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function devicePX2px(px: number): number;

/**
 * getAppId
 * @internal
 */
declare function getAppId(): string;

/**
 * getAppName
 * @internal
 */
declare function getAppName(): string;

/**
 * getAppVersion
 * @internal
 */
declare function getAppVersion(): {
    name: string;
    code: string;
};

/**
 * getUniCompilerVersion
 * @internal
 */
declare function getUniCompilerVersion(): string | undefined;

/**
 * getUniRuntimeVersion
 * @internal
 */
declare function getUniRuntimeVersion(): string;

/**
 * getWindowStage
 * @internal
 */
declare function getWindowStage(): window.default.WindowStage | null;

/**
 * isUniMp
 * @internal
 */
declare function isUniMp(): boolean;

/**
 * isUniAppX
 * @internal
 */
declare function isUniAppX(): boolean;

/**
 * 用户允许了全部权限请求，会通过 success回调通知调用者，并且此时allRight参数为 true
 * 用户拒绝了全部权限请求，会通过 fail 回调通知调用者，doNotAskAgain 参数标识了用户拒绝时是否选择了不再询问
 * 用户允许了部分请求，拒绝了部分权限请求,此时既会调用success也会调用fail。由其中的 string数组参数 标识具体被拒绝/允许的权限
 */
/**
 * requestSystemPermission
 * @description 请求系统权限
 * @param {OnWindowStageCreate} callback
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function requestSystemPermission(permissions: string[], success?: (allRight: boolean, grantedList: string[]) => void, fail?: (doNotAskAgain: boolean, grantedList: string[]) => void): void;

/**
 * exit
 * @description 退出应用
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "x"
 *    }
 *   }
 * }
 */
declare function exit(): void;

/**
 * appLifeCycle
 * @internal
 */
declare const appLifeCycle: TinyEmitter;

declare const appAbilityEmitter: TinyEmitter;
type OnCreate = (want: Want, launchParam: AbilityConstant.LaunchParam) => void;
type OnNewWant = (want: Want, launchParam: AbilityConstant.LaunchParam) => void;
type OnShare = (wantParam: Record<string, any>) => void;
type OnWindowStageCreate = (windowStage: window__default.WindowStage) => void;
/**
 * onAppAbilityCreate
 * @description 监听应用EntryAbility生命周期onCreate
 * @param {OnCreate} callback
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function onAppAbilityCreate(callback: OnCreate): void;
/**
 * onAppAbilityNewWant
 * @description 监听应用EntryAbility生命周期onNewWant
 * @param {OnNewWant} callback
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function onAppAbilityNewWant(callback: OnNewWant): void;
/**
 * onAppAbilityShare
 * @description 监听应用EntryAbility生命周期onShare
 * @param {OnShare} callback
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function onAppAbilityShare(callback: OnShare): void;
/**
 * onAppAbilityWindowStageCreate
 * @description 监听应用EntryAbility生命周期onWindowStageCreate
 * @param {OnWindowStageCreate} callback
 * @return {void}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function onAppAbilityWindowStageCreate(callback: OnWindowStageCreate): void;

/**
 * 如下方法参照android规范
 * https://developer.android.com/reference/android/webkit/MimeTypeMap#getMimeTypeFromExtension
 */
/**
 * getExtensionFromMimeType
 * @internal
 */
declare function getExtensionFromMimeType(mimeType: string): string | null;
/**
 * getMimeTypeFromExtension
 * @param {string} extension A file extension without the leading '.'
 * @internal
 */
declare function getMimeTypeFromExtension(extension: string): string | null;

/**
 * getUIAbilityContext
 * @description 获取应用的UIAbilityContext
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function getUIAbilityContext(): common.UIAbilityContext;

/**
 * getCurrentWindow
 * @description 获取当前原生窗口对象
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.31",
 *      "uniVer": "4.31",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function getCurrentWindow(): window__default.Window;

/**
 * convert2AbsFullPath
 * @description 将文件的项目相对地址转换为 运行期对应的绝对地址
 * @param {string} filePath
 * @return {string}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.61",
 *      "uniVer": "4.61",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function convert2AbsFullPath(filePath: string): string;

/**
 * getResourcePath
 * @description 获取资源文件的原生路径。
 * @param {string} filePath
 * @return {string}
 * @uniPlatform
 * {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "3.0",
 *      "uniUtsPlugin": "4.61",
 *      "uniVer": "4.61",
 *      "unixVer": "4.61",
 *      "unixUtsPlugin": "4.61"
 *    }
 *   }
 * }
 */
declare function getResourcePath(filePath: string): string;

/**
 * getUserAgent
 * @internal
 */
declare function getUserAgent(): string;

type AppTheme = 'dark' | 'light' | 'auto';
type AppThemeWithoutAuto = 'dark' | 'light';
declare const appThemeChangeEmitter: TinyEmitter;
/**
 * 设置应用主题
 *
 * @param {AppTheme} appTheme 应用主题
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function setAppTheme(appTheme: AppTheme): void;
/**
 * 获取应用主题
 *
 * @return {AppTheme} 应用主题
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function getAppTheme(): AppTheme;
interface OnAppThemeChangeCallbackResult {
    /**
     * 主题名称
     */
    appTheme: AppThemeWithoutAuto;
}
type OnAppThemeChangeCallback = (res: OnAppThemeChangeCallbackResult) => void;
/**
 * 监听应用主题变化
 *
 * @param {OnAppThemeChangeCallback} callback 应用主题
 * @returns {number} 监听ID
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function onAppThemeChange(callback: OnAppThemeChangeCallback): number;
/**
 * 取消监听应用主题变化
 *
 * @param {number} id 应用主题
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function offAppThemeChange(id: number): void;

/**
 * 参考文档
 * - [webview组件设置深色模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-set-dark-mode)
 * - [应用深浅色适配](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-dark-light-color-adaptation#%E5%BA%94%E7%94%A8%E8%B7%9F%E9%9A%8F%E7%B3%BB%E7%BB%9F%E7%9A%84%E6%B7%B1%E6%B5%85%E8%89%B2%E6%A8%A1%E5%BC%8F)
 */
type OsTheme = 'dark' | 'light';
/**
 * 获取系统主题
 *
 * @return {OsTheme} 系统主题
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function getOsTheme(): OsTheme;
interface OnOsThemeChangeCallbackResult {
    /**
     * 主题名称
     */
    osTheme: OsTheme;
}
type OnOsThemeChangeCallback = (res: OnOsThemeChangeCallbackResult) => void;
/**
 * 监听系统主题变化
 *
 * @param {OnOsThemeChangeCallback} callback 系统主题变化回调
 * @returns {number} 监听ID
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function onOsThemeChange(callback: OnOsThemeChangeCallback): number;
/**
 * 取消监听系统主题变化
 *
 * @param {number} id 监听ID
 * @uniPlatform {
 *   "app": {
 *     "android": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *     "ios": {
 *       "osVer": "x",
 *       "uniVer": "x",
 *       "unixVer": "x"
 *     },
 *    "harmony": {
 *      "osVer": "5.0.0 (12)",
 *      "uniUtsPlugin": "4.71",
 *      "uniVer": "x",
 *      "unixVer": "4.71",
 *      "unixUtsPlugin": "4.71"
 *    }
 *   }
 * }
 */
declare function offOsThemeChange(id: number): void;

type HostTHeme = 'dark' | 'light';
interface OnHostThemeChangeCallbackResult {
    /**
     * 主题名称
     */
    hostTheme: HostTHeme;
}
type OnHostThemeChangeCallback = (res: OnHostThemeChangeCallbackResult) => void;
/**
 * 监听宿主题变化
 *
 * @param {OnHostThemeChangeCallback} callback 主机主题变化回调
 * @returns {number} 监听ID
 * @internal
 */
declare function onHostThemeChange(callback: OnHostThemeChangeCallback): number;
/**
 * 取消监听宿主题变化
 *
 * @param {number} id 监听ID
 * @internal
 */
declare function offHostThemeChange(id: number): void;

type index_d_AppTheme = AppTheme;
type index_d_OnAppThemeChangeCallbackResult = OnAppThemeChangeCallbackResult;
declare const index_d_appLifeCycle: typeof appLifeCycle;
declare const index_d_appThemeChangeEmitter: typeof appThemeChangeEmitter;
declare const index_d_convert2AbsFullPath: typeof convert2AbsFullPath;
declare const index_d_devicePX2px: typeof devicePX2px;
declare const index_d_exit: typeof exit;
declare const index_d_getAppId: typeof getAppId;
declare const index_d_getAppName: typeof getAppName;
declare const index_d_getAppTheme: typeof getAppTheme;
declare const index_d_getAppVersion: typeof getAppVersion;
declare const index_d_getCurrentWindow: typeof getCurrentWindow;
declare const index_d_getExtensionFromMimeType: typeof getExtensionFromMimeType;
declare const index_d_getMimeTypeFromExtension: typeof getMimeTypeFromExtension;
declare const index_d_getOsTheme: typeof getOsTheme;
declare const index_d_getResourcePath: typeof getResourcePath;
declare const index_d_getUIAbilityContext: typeof getUIAbilityContext;
declare const index_d_getUniCompilerVersion: typeof getUniCompilerVersion;
declare const index_d_getUniRuntimeVersion: typeof getUniRuntimeVersion;
declare const index_d_getUserAgent: typeof getUserAgent;
declare const index_d_getWindowStage: typeof getWindowStage;
declare const index_d_isUniAppX: typeof isUniAppX;
declare const index_d_isUniMp: typeof isUniMp;
declare const index_d_offAppThemeChange: typeof offAppThemeChange;
declare const index_d_offHostThemeChange: typeof offHostThemeChange;
declare const index_d_offOsThemeChange: typeof offOsThemeChange;
declare const index_d_onAppAbilityCreate: typeof onAppAbilityCreate;
declare const index_d_onAppAbilityNewWant: typeof onAppAbilityNewWant;
declare const index_d_onAppAbilityShare: typeof onAppAbilityShare;
declare const index_d_onAppAbilityWindowStageCreate: typeof onAppAbilityWindowStageCreate;
declare const index_d_onAppThemeChange: typeof onAppThemeChange;
declare const index_d_onHostThemeChange: typeof onHostThemeChange;
declare const index_d_onOsThemeChange: typeof onOsThemeChange;
declare const index_d_requestSystemPermission: typeof requestSystemPermission;
declare const index_d_setAppTheme: typeof setAppTheme;
declare namespace index_d {
  export { type index_d_AppTheme as AppTheme, type index_d_OnAppThemeChangeCallbackResult as OnAppThemeChangeCallbackResult, index_d_appLifeCycle as appLifeCycle, index_d_appThemeChangeEmitter as appThemeChangeEmitter, index_d_convert2AbsFullPath as convert2AbsFullPath, index_d_devicePX2px as devicePX2px, index_d_exit as exit, index_d_getAppId as getAppId, index_d_getAppName as getAppName, index_d_getAppTheme as getAppTheme, index_d_getAppVersion as getAppVersion, index_d_getCurrentWindow as getCurrentWindow, index_d_getExtensionFromMimeType as getExtensionFromMimeType, index_d_getMimeTypeFromExtension as getMimeTypeFromExtension, index_d_getOsTheme as getOsTheme, index_d_getResourcePath as getResourcePath, index_d_getUIAbilityContext as getUIAbilityContext, index_d_getUniCompilerVersion as getUniCompilerVersion, index_d_getUniRuntimeVersion as getUniRuntimeVersion, index_d_getUserAgent as getUserAgent, index_d_getWindowStage as getWindowStage, index_d_isUniAppX as isUniAppX, index_d_isUniMp as isUniMp, index_d_offAppThemeChange as offAppThemeChange, index_d_offHostThemeChange as offHostThemeChange, index_d_offOsThemeChange as offOsThemeChange, index_d_onAppAbilityCreate as onAppAbilityCreate, index_d_onAppAbilityNewWant as onAppAbilityNewWant, index_d_onAppAbilityShare as onAppAbilityShare, index_d_onAppAbilityWindowStageCreate as onAppAbilityWindowStageCreate, index_d_onAppThemeChange as onAppThemeChange, index_d_onHostThemeChange as onHostThemeChange, index_d_onOsThemeChange as onOsThemeChange, index_d_requestSystemPermission as requestSystemPermission, index_d_setAppTheme as setAppTheme };
}

interface SafeArea {
    top: number;
    bottom: number;
    left: number;
    right: number;
    width: number;
    height: number;
}
interface SafeAreaInsets {
    top: number;
    bottom: number;
    left: number;
    right: number;
}
interface WindowInfo {
    safeArea: SafeArea;
    safeAreaInsets: SafeAreaInsets;
    pixelRatio: number;
    screenHeight: number;
    screenTop: number;
    screenWidth: number;
    statusBarHeight: number;
    windowHeight: number;
    windowWidth: number;
    windowTop: number;
    windowBottom: number;
}
declare function getWindowInfo(): WindowInfo;

declare function getDeviceId(): string | number | bigint | true | object;

declare function onNativePageReady(): Promise<PageComponent>;

declare function startPullDownRefresh(): void;
declare function stopPullDownRefresh(): void;

declare function getTabBar(): {
    readonly style: Partial<TabBarState>;
    onMaskClick(): void;
    onClick(callback: ({ index }?: {
        index: number;
    }) => void): void;
    onMidButtonClick(callback: () => void): void;
    showTabBarRedDot({ index }: {
        index: number;
    }): void;
    hideTabBarRedDot({ index }: {
        index: number;
    }): void;
    setTabBarBadge({ index, text }: {
        index: number;
        text: string;
    }): void;
    removeTabBarBadge({ index }: {
        index: number;
    }): void;
    setTabBarItems(tabBarState: TabBarState): void;
    setTabBarItem(item: TabBarItem & {
        index: number;
    }): void;
    setTabBarStyle(style: TabBarStyle): void;
    hideTabBar(): void;
    showTabBar(): void;
    append({ id }: {
        id: string;
    }): void;
    setMask(): never;
    switchSelect({ index }: {
        index: number;
    }): void;
} | undefined;

type Prettify<T> = {
    [K in keyof T]: T[K];
} & {};
type UnionToIntersection<U> = (U extends any ? (k: U) => void : never) extends (k: infer I) => void ? I : never;
type LooseRequired<T> = {
    [P in keyof (T & Required<T>)]: T[P];
};
type IfAny<T, Y, N> = 0 extends 1 & T ? Y : N;
type Awaited<T> = T extends null | undefined ? T : T extends object & {
    then(onfulfilled: infer F, ...args: infer _): any;
} ? F extends (value: infer V, ...args: infer _) => any ? Awaited<V> : never : T;

declare function defineOnApi(name, fn, options) {
    return wrapperOnApi(name, fn, options);
}
declare function defineOffApi(name, fn, options) {
    return wrapperOffApi(name, fn, options);
}
declare function defineTaskApi(name, fn, protocol, options) {
    return promisify(name, wrapperTaskApi(name, fn, (process.env.NODE_ENV !== 'production') ? protocol : undefined, options));
}
declare function defineSyncApi(name, fn, protocol, options) {
    return wrapperSyncApi(name, fn, (process.env.NODE_ENV !== 'production') ? protocol : undefined, options);
}
declare function defineAsyncApi(name, fn, protocol, options) {
    return promisify(name, wrapperAsyncApi(name, fn, (process.env.NODE_ENV !== 'production') ? protocol : undefined, options));
}

declare const freeze: {
    <T extends Function>(f: T): T;
    <T extends {
        [idx: string]: U | null | undefined | object;
    }, U extends string | bigint | number | boolean | symbol>(o: T): Readonly<T>;
    <T>(o: T): Readonly<T>;
};
declare const isPlainObject: (val: object) => boolean;
declare const isRealPlainObject: (val: object) => boolean;
declare const capitalize: (str: string) => string;
declare function getType(val: any): string;
declare function disableEnumerable(obj: object, properties: string[]): void;
declare function hasOwn(obj: object, key: string): boolean;
declare function formatValueRound(px: number): number;
declare function formatValueCeil(px: number): number;

type ReleaseWgtToRunPathCallback = (code: 1 | -1, error?: Error) => void;
declare function releaseWgtToRunPath(appId: string, wgtPath: string, callback: ReleaseWgtToRunPathCallback): void;
declare function isExistsApp(appId: string): boolean;
declare function getUniMPRunPath(appId: string): string;
declare function hmrGetUniAppWWWPath(appId?: string | undefined): string;
declare function hmrGetUniAppWWWPathInResfile(appId?: string | undefined): string;
declare function releaseCurrentWgtToRunPath(wgtPath: string, callback: ReleaseWgtToRunPathCallback): void;

declare function registerModule(name: string, module: Record<string, unknown>): void;

declare enum TrackOpTypes {
    GET = "get",
    HAS = "has",
    ITERATE = "iterate"
}
declare enum TriggerOpTypes {
    SET = "set",
    ADD = "add",
    DELETE = "delete",
    CLEAR = "clear"
}
declare enum ReactiveFlags {
    SKIP = "__v_skip",
    IS_REACTIVE = "__v_isReactive",
    IS_READONLY = "__v_isReadonly",
    IS_SHALLOW = "__v_isShallow",
    RAW = "__v_raw"
}

type Dep = Map<ReactiveEffect, number> & {
    cleanup: () => void;
    computed?: ComputedRefImpl<any>;
};

declare class EffectScope {
    detached: boolean;
    constructor(detached?: boolean);
    get active(): boolean;
    run<T>(fn: () => T): T | undefined;
    stop(fromParent?: boolean): void;
}

type EffectScheduler = (...args: any[]) => any;
type DebuggerEvent = {
    effect: ReactiveEffect;
} & DebuggerEventExtraInfo;
type DebuggerEventExtraInfo = {
    target: object;
    type: TrackOpTypes | TriggerOpTypes;
    key: any;
    newValue?: any;
    oldValue?: any;
    oldTarget?: Map<any, any> | Set<any>;
};
declare class ReactiveEffect<T = any> {
    fn: () => T;
    trigger: () => void;
    scheduler?: EffectScheduler | undefined;
    active: boolean;
    deps: Dep[];
    onStop?: () => void;
    onTrack?: (event: DebuggerEvent) => void;
    onTrigger?: (event: DebuggerEvent) => void;
    constructor(fn: () => T, trigger: () => void, scheduler?: EffectScheduler | undefined, scope?: EffectScope);
    get dirty(): boolean;
    set dirty(v: boolean);
    run(): T;
    stop(): void;
}
interface DebuggerOptions {
    onTrack?: (event: DebuggerEvent) => void;
    onTrigger?: (event: DebuggerEvent) => void;
}
type ComputedGetter<T> = (oldValue?: T) => T;
type ComputedSetter<T> = (newValue: T) => void;
interface WritableComputedOptions<T> {
    get: ComputedGetter<T>;
    set: ComputedSetter<T>;
}
declare class ComputedRefImpl<T> {
    private getter;
    private readonly _setter;
    dep?: Dep;
    private _value;
    readonly effect: ReactiveEffect<T>;
    readonly __v_isRef = true;
    readonly [ReactiveFlags.IS_READONLY]: boolean;
    _cacheable: boolean;
    /**
     * Dev only
     */
    _warnRecursive?: boolean;
    constructor(getter: ComputedGetter<T>, _setter: ComputedSetter<T>, isReadonly: boolean, isSSR: boolean);
    get value(): T;
    set value(newValue: T);
    get _dirty(): boolean;
    set _dirty(v: boolean);
}

type UnwrapNestedRefs<T> = T extends Ref ? T : UnwrapRefSimple<T>;
declare const ShallowReactiveMarker: unique symbol;

declare const RefSymbol: unique symbol;
declare const RawSymbol: unique symbol;
interface Ref<T = any> {
    value: T;
    /**
     * Type differentiator only.
     * We need this to be in public d.ts but don't want it to show up in IDE
     * autocomplete, so we use a private Symbol instead.
     */
    [RefSymbol]: true;
}
declare const ShallowRefMarker: unique symbol;
type ShallowRef<T = any> = Ref<T> & {
    [ShallowRefMarker]?: true;
};
type BaseTypes = string | number | boolean;
/**
 * This is a special exported interface for other packages to declare
 * additional types that should bail out for ref unwrapping. For example
 * \@vue/runtime-dom can declare it like so in its d.ts:
 *
 * ``` ts
 * declare module '@vue/reactivity' {
 *   export interface RefUnwrapBailTypes {
 *     runtimeDOMBailTypes: Node | Window
 *   }
 * }
 * ```
 */
interface RefUnwrapBailTypes {
}
type ShallowUnwrapRef<T> = {
    [K in keyof T]: DistrubuteRef<T[K]>;
};
type DistrubuteRef<T> = T extends Ref<infer V> ? V : T;
type UnwrapRef<T> = T extends ShallowRef<infer V> ? V : T extends Ref<infer V> ? UnwrapRefSimple<V> : UnwrapRefSimple<T>;
type UnwrapRefSimple<T> = T extends Function | BaseTypes | Ref | RefUnwrapBailTypes[keyof RefUnwrapBailTypes] | {
    [RawSymbol]?: true;
} ? T : T extends Map<infer K, infer V> ? Map<K, UnwrapRefSimple<V>> & UnwrapRef<Omit<T, keyof Map<any, any>>> : T extends WeakMap<infer K, infer V> ? WeakMap<K, UnwrapRefSimple<V>> & UnwrapRef<Omit<T, keyof WeakMap<any, any>>> : T extends Set<infer V> ? Set<UnwrapRefSimple<V>> & UnwrapRef<Omit<T, keyof Set<any>>> : T extends WeakSet<infer V> ? WeakSet<UnwrapRefSimple<V>> & UnwrapRef<Omit<T, keyof WeakSet<any>>> : T extends ReadonlyArray<any> ? {
    [K in keyof T]: UnwrapRefSimple<T[K]>;
} : T extends object & {
    [ShallowReactiveMarker]?: never;
} ? {
    [P in keyof T]: P extends symbol ? T[P] : UnwrapRef<T[P]>;
} : T;

type Slot<T extends any = any> = (...args: IfAny<T, any[], [T] | (T extends undefined ? [] : never)>) => VNode[];
type InternalSlots = {
    [name: string]: Slot | undefined;
};
type Slots = Readonly<InternalSlots>;
declare const SlotSymbol: unique symbol;
type SlotsType<T extends Record<string, any> = Record<string, any>> = {
    [SlotSymbol]?: T;
};
type StrictUnwrapSlotsType<S extends SlotsType, T = NonNullable<S[typeof SlotSymbol]>> = [keyof S] extends [never] ? Slots : Readonly<T> & T;
type UnwrapSlotsType<S extends SlotsType, T = NonNullable<S[typeof SlotSymbol]>> = [keyof S] extends [never] ? Slots : Readonly<Prettify<{
    [K in keyof T]: NonNullable<T[K]> extends (...args: any[]) => any ? T[K] : Slot<T[K]>;
}>>;
type RawSlots = {
    [name: string]: unknown;
    $stable?: boolean;
};

interface SchedulerJob extends Function {
    id?: number;
    pre?: boolean;
    active?: boolean;
    computed?: boolean;
    /**
     * Indicates whether the effect is allowed to recursively trigger itself
     * when managed by the scheduler.
     *
     * By default, a job cannot trigger itself because some built-in method calls,
     * e.g. Array.prototype.push actually performs reads as well (#1740) which
     * can lead to confusing infinite loops.
     * The allowed cases are component update functions and watch callbacks.
     * Component update functions may update child component props, which in turn
     * trigger flush: "pre" watch callbacks that mutates state that the parent
     * relies on (#1801). Watch callbacks doesn't track its dependencies so if it
     * triggers itself again, it's likely intentional and it is the user's
     * responsibility to perform recursive state mutation that eventually
     * stabilizes (#1727).
     */
    allowRecurse?: boolean;
    /**
     * Attached by renderer.ts when setting up a component's render effect
     * Used to obtain component information when reporting max recursive updates.
     * dev only.
     */
    ownerInstance?: ComponentInternalInstance;
}
declare function nextTick<T = void, R = void>(this: T, fn?: (this: T) => R): Promise<Awaited<R>>;

type ObjectEmitsOptions = Record<string, ((...args: any[]) => any) | null>;
type EmitsOptions = ObjectEmitsOptions | string[];
type EmitsToProps<T extends EmitsOptions> = T extends string[] ? {
    [K in `on${Capitalize<T[number]>}`]?: (...args: any[]) => any;
} : T extends ObjectEmitsOptions ? {
    [K in `on${Capitalize<string & keyof T>}`]?: K extends `on${infer C}` ? (...args: T[Uncapitalize<C>] extends (...args: infer P) => any ? P : T[Uncapitalize<C>] extends null ? any[] : never) => any : never;
} : {};
type ShortEmitsToObject<E> = E extends Record<string, any[]> ? {
    [K in keyof E]: (...args: E[K]) => any;
} : E;
type EmitFn<Options = ObjectEmitsOptions, Event extends keyof Options = keyof Options> = Options extends Array<infer V> ? (event: V, ...args: any[]) => void : {} extends Options ? (event: string, ...args: any[]) => void : UnionToIntersection<{
    [key in Event]: Options[key] extends (...args: infer Args) => any ? (event: key, ...args: Args) => void : Options[key] extends any[] ? (event: key, ...args: Options[key]) => void : (event: key, ...args: any[]) => void;
}[Event]>;

/**
 * Custom properties added to component instances in any way and can be accessed through `this`
 *
 * @example
 * Here is an example of adding a property `$router` to every component instance:
 * ```ts
 * import { createApp } from 'vue'
 * import { Router, createRouter } from 'vue-router'
 *
 * declare module '@vue/runtime-core' {
 *   interface ComponentCustomProperties {
 *     $router: Router
 *   }
 * }
 *
 * // effectively adding the router to every component instance
 * const app = createApp({})
 * const router = createRouter()
 * app.config.globalProperties.$router = router
 *
 * const vm = app.mount('#app')
 * // we can access the router from the instance
 * vm.$router.push('/')
 * ```
 */
interface ComponentCustomProperties {
}
type IsDefaultMixinComponent<T> = T extends ComponentOptionsMixin ? ComponentOptionsMixin extends T ? true : false : false;
type MixinToOptionTypes<T> = T extends ComponentOptionsBase<infer P, infer B, infer D, infer C, infer M, infer Mixin, infer Extends, any, any, infer Defaults, any, any, any> ? OptionTypesType<P & {}, B & {}, D & {}, C & {}, M & {}, Defaults & {}> & IntersectionMixin<Mixin> & IntersectionMixin<Extends> : never;
type ExtractMixin<T> = {
    Mixin: MixinToOptionTypes<T>;
}[T extends ComponentOptionsMixin ? 'Mixin' : never];
type IntersectionMixin<T> = IsDefaultMixinComponent<T> extends true ? OptionTypesType : UnionToIntersection<ExtractMixin<T>>;
type UnwrapMixinsType<T, Type extends OptionTypesKeys> = T extends OptionTypesType ? T[Type] : never;
type EnsureNonVoid<T> = T extends void ? {} : T;
type ComponentPublicInstanceConstructor<T extends ComponentPublicInstance<Props, RawBindings, D, C, M> = ComponentPublicInstance<any>, Props = any, RawBindings = any, D = any, C extends ComputedOptions = ComputedOptions, M extends MethodOptions = MethodOptions> = {
    __isFragment?: never;
    __isTeleport?: never;
    __isSuspense?: never;
    new (...args: any[]): T;
};
type CreateComponentPublicInstance<P = {}, B = {}, D = {}, C extends ComputedOptions = {}, M extends MethodOptions = {}, Mixin extends ComponentOptionsMixin = ComponentOptionsMixin, Extends extends ComponentOptionsMixin = ComponentOptionsMixin, E extends EmitsOptions = {}, PublicProps = P, Defaults = {}, MakeDefaultsOptional extends boolean = false, I extends ComponentInjectOptions = {}, S extends SlotsType = {}, PublicMixin = IntersectionMixin<Mixin> & IntersectionMixin<Extends>, PublicP = UnwrapMixinsType<PublicMixin, 'P'> & EnsureNonVoid<P>, PublicB = UnwrapMixinsType<PublicMixin, 'B'> & EnsureNonVoid<B>, PublicD = UnwrapMixinsType<PublicMixin, 'D'> & EnsureNonVoid<D>, PublicC extends ComputedOptions = UnwrapMixinsType<PublicMixin, 'C'> & EnsureNonVoid<C>, PublicM extends MethodOptions = UnwrapMixinsType<PublicMixin, 'M'> & EnsureNonVoid<M>, PublicDefaults = UnwrapMixinsType<PublicMixin, 'Defaults'> & EnsureNonVoid<Defaults>> = ComponentPublicInstance<PublicP, PublicB, PublicD, PublicC, PublicM, E, PublicProps, PublicDefaults, MakeDefaultsOptional, ComponentOptionsBase<P, B, D, C, M, Mixin, Extends, E, string, Defaults, {}, string, S>, I, S>;
type ComponentPublicInstance<P = {}, // props type extracted from props option
B = {}, // raw bindings returned from setup()
D = {}, // return from data()
C extends ComputedOptions = {}, M extends MethodOptions = {}, E extends EmitsOptions = {}, PublicProps = P, Defaults = {}, MakeDefaultsOptional extends boolean = false, Options = ComponentOptionsBase<any, any, any, any, any, any, any, any, any>, I extends ComponentInjectOptions = {}, S extends SlotsType = {}> = {
    $: ComponentInternalInstance;
    $data: D;
    $props: MakeDefaultsOptional extends true ? Partial<Defaults> & Omit<Prettify<P> & PublicProps, keyof Defaults> : Prettify<P> & PublicProps;
    $attrs: Data;
    $refs: Data;
    $slots: UnwrapSlotsType<S>;
    $root: ComponentPublicInstance | null;
    $parent: ComponentPublicInstance | null;
    $emit: EmitFn<E>;
    $el: any;
    $options: Options & MergedComponentOptionsOverride;
    $forceUpdate: () => void;
    $nextTick: typeof nextTick;
    $watch<T extends string | ((...args: any) => any)>(source: T, cb: T extends (...args: any) => infer R ? (...args: [R, R]) => any : (...args: any) => any, options?: WatchOptions): WatchStopHandle;
} & IfAny<P, P, Omit<P, keyof ShallowUnwrapRef<B>>> & ShallowUnwrapRef<B> & UnwrapNestedRefs<D> & ExtractComputedReturns<C> & M & ComponentCustomProperties & InjectToObject<I>;

interface SuspenseProps {
    onResolve?: () => void;
    onPending?: () => void;
    onFallback?: () => void;
    timeout?: string | number;
    /**
     * Allow suspense to be captured by parent suspense
     *
     * @default false
     */
    suspensible?: boolean;
}
declare const SuspenseImpl: {
    name: string;
    __isSuspense: boolean;
    process(n1: VNode | null, n2: VNode, container: RendererElement, anchor: RendererNode | null, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean, rendererInternals: RendererInternals): void;
    hydrate: typeof hydrateSuspense;
    create: typeof createSuspenseBoundary;
    normalize: typeof normalizeSuspenseChildren;
};
declare const Suspense: {
    new (): {
        $props: VNodeProps & SuspenseProps;
        $slots: {
            default(): VNode[];
            fallback(): VNode[];
        };
    };
    __isSuspense: true;
};
interface SuspenseBoundary {
    vnode: VNode<RendererNode, RendererElement, SuspenseProps>;
    parent: SuspenseBoundary | null;
    parentComponent: ComponentInternalInstance | null;
    namespace: ElementNamespace;
    container: RendererElement;
    hiddenContainer: RendererElement;
    activeBranch: VNode | null;
    pendingBranch: VNode | null;
    deps: number;
    pendingId: number;
    timeout: number;
    isInFallback: boolean;
    isHydrating: boolean;
    isUnmounted: boolean;
    effects: Function[];
    resolve(force?: boolean, sync?: boolean): void;
    fallback(fallbackVNode: VNode): void;
    move(container: RendererElement, anchor: RendererNode | null, type: MoveType): void;
    next(): RendererNode | null;
    registerDep(instance: ComponentInternalInstance, setupRenderEffect: SetupRenderEffectFn): void;
    unmount(parentSuspense: SuspenseBoundary | null, doRemove?: boolean): void;
}
declare function createSuspenseBoundary(vnode: VNode, parentSuspense: SuspenseBoundary | null, parentComponent: ComponentInternalInstance | null, container: RendererElement, hiddenContainer: RendererElement, anchor: RendererNode | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean, rendererInternals: RendererInternals, isHydrating?: boolean): SuspenseBoundary;
declare function hydrateSuspense(node: Node, vnode: VNode, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean, rendererInternals: RendererInternals, hydrateNode: (node: Node, vnode: VNode, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, slotScopeIds: string[] | null, optimized: boolean) => Node | null): Node | null;
declare function normalizeSuspenseChildren(vnode: VNode): void;

type Hook<T = () => void> = T | T[];
interface BaseTransitionProps<HostElement = RendererElement> {
    mode?: 'in-out' | 'out-in' | 'default';
    appear?: boolean;
    persisted?: boolean;
    onBeforeEnter?: Hook<(el: HostElement) => void>;
    onEnter?: Hook<(el: HostElement, done: () => void) => void>;
    onAfterEnter?: Hook<(el: HostElement) => void>;
    onEnterCancelled?: Hook<(el: HostElement) => void>;
    onBeforeLeave?: Hook<(el: HostElement) => void>;
    onLeave?: Hook<(el: HostElement, done: () => void) => void>;
    onAfterLeave?: Hook<(el: HostElement) => void>;
    onLeaveCancelled?: Hook<(el: HostElement) => void>;
    onBeforeAppear?: Hook<(el: HostElement) => void>;
    onAppear?: Hook<(el: HostElement, done: () => void) => void>;
    onAfterAppear?: Hook<(el: HostElement) => void>;
    onAppearCancelled?: Hook<(el: HostElement) => void>;
}
interface TransitionHooks<HostElement = RendererElement> {
    mode: BaseTransitionProps['mode'];
    persisted: boolean;
    beforeEnter(el: HostElement): void;
    enter(el: HostElement): void;
    leave(el: HostElement, remove: () => void): void;
    clone(vnode: VNode): TransitionHooks<HostElement>;
    afterLeave?(): void;
    delayLeave?(el: HostElement, earlyRemove: () => void, delayedLeave: () => void): void;
    delayedLeave?(): void;
}
type ElementNamespace = 'svg' | 'mathml' | undefined;
interface RendererOptions<HostNode = RendererNode, HostElement = RendererElement> {
    patchProp(el: HostElement, key: string, prevValue: any, nextValue: any, namespace?: ElementNamespace, prevChildren?: VNode<HostNode, HostElement>[], parentComponent?: ComponentInternalInstance | null, parentSuspense?: SuspenseBoundary | null, unmountChildren?: UnmountChildrenFn): void;
    insert(el: HostNode, parent: HostElement, anchor?: HostNode | null): void;
    remove(el: HostNode): void;
    createElement(type: string, namespace?: ElementNamespace, isCustomizedBuiltIn?: string, vnodeProps?: (VNodeProps & {
        [key: string]: any;
    }) | null): HostElement;
    createText(text: string): HostNode;
    createComment(text: string): HostNode;
    setText(node: HostNode, text: string): void;
    setElementText(node: HostElement, text: string): void;
    parentNode(node: HostNode): HostElement | null;
    nextSibling(node: HostNode): HostNode | null;
    querySelector?(selector: string): HostElement | null;
    setScopeId?(el: HostElement, id: string): void;
    cloneNode?(node: HostNode): HostNode;
    insertStaticContent?(content: string, parent: HostElement, anchor: HostNode | null, namespace: ElementNamespace, start?: HostNode | null, end?: HostNode | null): [HostNode, HostNode];
}
interface RendererNode {
    [key: string]: any;
}
interface RendererElement extends RendererNode {
}
interface RendererInternals<HostNode = RendererNode, HostElement = RendererElement> {
    p: PatchFn;
    um: UnmountFn;
    r: RemoveFn;
    m: MoveFn;
    mt: MountComponentFn;
    mc: MountChildrenFn;
    pc: PatchChildrenFn;
    pbc: PatchBlockChildrenFn;
    n: NextFn;
    o: RendererOptions<HostNode, HostElement>;
}
type PatchFn = (n1: VNode | null, // null means this is a mount
n2: VNode, container: RendererElement, anchor?: RendererNode | null, parentComponent?: ComponentInternalInstance | null, parentSuspense?: SuspenseBoundary | null, namespace?: ElementNamespace, slotScopeIds?: string[] | null, optimized?: boolean) => void;
type MountChildrenFn = (children: VNodeArrayChildren, container: RendererElement, anchor: RendererNode | null, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean, start?: number) => void;
type PatchChildrenFn = (n1: VNode | null, n2: VNode, container: RendererElement, anchor: RendererNode | null, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean) => void;
type PatchBlockChildrenFn = (oldChildren: VNode[], newChildren: VNode[], fallbackContainer: RendererElement, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null) => void;
type MoveFn = (vnode: VNode, container: RendererElement, anchor: RendererNode | null, type: MoveType, parentSuspense?: SuspenseBoundary | null) => void;
type NextFn = (vnode: VNode) => RendererNode | null;
type UnmountFn = (vnode: VNode, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, doRemove?: boolean, optimized?: boolean) => void;
type RemoveFn = (vnode: VNode) => void;
type UnmountChildrenFn = (children: VNode[], parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, doRemove?: boolean, optimized?: boolean, start?: number) => void;
type MountComponentFn = (initialVNode: VNode, container: RendererElement, anchor: RendererNode | null, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, optimized: boolean) => void;
type SetupRenderEffectFn = (instance: ComponentInternalInstance, initialVNode: VNode, container: RendererElement, anchor: RendererNode | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, optimized: boolean) => void;
declare enum MoveType {
    ENTER = 0,
    LEAVE = 1,
    REORDER = 2
}
type DebuggerHook = (e: DebuggerEvent) => void;
type ErrorCapturedHook<TError = unknown> = (err: TError, instance: ComponentPublicInstance | null, info: string) => boolean | void;

type ComponentPropsOptions<P = Data> = ComponentObjectPropsOptions<P> | string[];
type ComponentObjectPropsOptions<P = Data> = {
    [K in keyof P]: Prop<P[K]> | null;
};
type Prop<T, D = T> = PropOptions<T, D> | PropType<T>;
type DefaultFactory<T> = (props: Data) => T | null | undefined;
interface PropOptions<T = any, D = T> {
    type?: PropType<T> | true | null;
    required?: boolean;
    default?: D | DefaultFactory<D> | null | undefined | object;
    validator?(value: unknown, props: Data): boolean;
}
type PropType<T> = PropConstructor<T> | PropConstructor<T>[];
type PropConstructor<T = any> = {
    new (...args: any[]): T & {};
} | {
    (): T;
} | PropMethod<T>;
type PropMethod<T, TConstructor = any> = [T] extends [
    ((...args: any) => any) | undefined
] ? {
    new (): TConstructor;
    (): T;
    readonly prototype: TConstructor;
} : never;
type RequiredKeys<T> = {
    [K in keyof T]: T[K] extends {
        required: true;
    } | {
        default: any;
    } | BooleanConstructor | {
        type: BooleanConstructor;
    } ? T[K] extends {
        default: undefined | (() => undefined);
    } ? never : K : never;
}[keyof T];
type OptionalKeys<T> = Exclude<keyof T, RequiredKeys<T>>;
type DefaultKeys<T> = {
    [K in keyof T]: T[K] extends {
        default: any;
    } | BooleanConstructor | {
        type: BooleanConstructor;
    } ? T[K] extends {
        type: BooleanConstructor;
        required: true;
    } ? never : K : never;
}[keyof T];
type InferPropType<T> = [T] extends [null] ? any : [T] extends [{
    type: null | true;
}] ? any : [T] extends [ObjectConstructor | {
    type: ObjectConstructor;
}] ? Record<string, any> : [T] extends [BooleanConstructor | {
    type: BooleanConstructor;
}] ? boolean : [T] extends [DateConstructor | {
    type: DateConstructor;
}] ? Date : [T] extends [(infer U)[] | {
    type: (infer U)[];
}] ? U extends DateConstructor ? Date | InferPropType<U> : InferPropType<U> : [T] extends [Prop<infer V, infer D>] ? unknown extends V ? IfAny<V, V, D> : V : T;
/**
 * Extract prop types from a runtime props options object.
 * The extracted types are **internal** - i.e. the resolved props received by
 * the component.
 * - Boolean props are always present
 * - Props with default values are always present
 *
 * To extract accepted props from the parent, use {@link ExtractPublicPropTypes}.
 */
type ExtractPropTypes<O> = {
    [K in keyof Pick<O, RequiredKeys<O>>]: InferPropType<O[K]>;
} & {
    [K in keyof Pick<O, OptionalKeys<O>>]?: InferPropType<O[K]>;
};
type ExtractDefaultPropTypes<O> = O extends object ? {
    [K in keyof Pick<O, DefaultKeys<O>>]: InferPropType<O[K]>;
} : {};

/**
Runtime helper for applying directives to a vnode. Example usage:

const comp = resolveComponent('comp')
const foo = resolveDirective('foo')
const bar = resolveDirective('bar')

return withDirectives(h(comp), [
  [foo, this.x],
  [bar, this.y]
])
*/

interface DirectiveBinding<V = any> {
    instance: ComponentPublicInstance | null;
    value: V;
    oldValue: V | null;
    arg?: string;
    modifiers: DirectiveModifiers;
    dir: ObjectDirective<any, V>;
}
type DirectiveHook<T = any, Prev = VNode<any, T> | null, V = any> = (el: T, binding: DirectiveBinding<V>, vnode: VNode<any, T>, prevVNode: Prev) => void;
type SSRDirectiveHook = (binding: DirectiveBinding, vnode: VNode) => Data | undefined;
interface ObjectDirective<T = any, V = any> {
    created?: DirectiveHook<T, null, V>;
    beforeMount?: DirectiveHook<T, null, V>;
    mounted?: DirectiveHook<T, null, V>;
    beforeUpdate?: DirectiveHook<T, VNode<any, T>, V>;
    updated?: DirectiveHook<T, VNode<any, T>, V>;
    beforeUnmount?: DirectiveHook<T, null, V>;
    unmounted?: DirectiveHook<T, null, V>;
    getSSRProps?: SSRDirectiveHook;
    deep?: boolean;
}
type FunctionDirective<T = any, V = any> = DirectiveHook<T, any, V>;
type Directive<T = any, V = any> = ObjectDirective<T, V> | FunctionDirective<T, V>;
type DirectiveModifiers = Record<string, boolean>;

declare enum DeprecationTypes$1 {
    GLOBAL_MOUNT = "GLOBAL_MOUNT",
    GLOBAL_MOUNT_CONTAINER = "GLOBAL_MOUNT_CONTAINER",
    GLOBAL_EXTEND = "GLOBAL_EXTEND",
    GLOBAL_PROTOTYPE = "GLOBAL_PROTOTYPE",
    GLOBAL_SET = "GLOBAL_SET",
    GLOBAL_DELETE = "GLOBAL_DELETE",
    GLOBAL_OBSERVABLE = "GLOBAL_OBSERVABLE",
    GLOBAL_PRIVATE_UTIL = "GLOBAL_PRIVATE_UTIL",
    CONFIG_SILENT = "CONFIG_SILENT",
    CONFIG_DEVTOOLS = "CONFIG_DEVTOOLS",
    CONFIG_KEY_CODES = "CONFIG_KEY_CODES",
    CONFIG_PRODUCTION_TIP = "CONFIG_PRODUCTION_TIP",
    CONFIG_IGNORED_ELEMENTS = "CONFIG_IGNORED_ELEMENTS",
    CONFIG_WHITESPACE = "CONFIG_WHITESPACE",
    CONFIG_OPTION_MERGE_STRATS = "CONFIG_OPTION_MERGE_STRATS",
    INSTANCE_SET = "INSTANCE_SET",
    INSTANCE_DELETE = "INSTANCE_DELETE",
    INSTANCE_DESTROY = "INSTANCE_DESTROY",
    INSTANCE_EVENT_EMITTER = "INSTANCE_EVENT_EMITTER",
    INSTANCE_EVENT_HOOKS = "INSTANCE_EVENT_HOOKS",
    INSTANCE_CHILDREN = "INSTANCE_CHILDREN",
    INSTANCE_LISTENERS = "INSTANCE_LISTENERS",
    INSTANCE_SCOPED_SLOTS = "INSTANCE_SCOPED_SLOTS",
    INSTANCE_ATTRS_CLASS_STYLE = "INSTANCE_ATTRS_CLASS_STYLE",
    OPTIONS_DATA_FN = "OPTIONS_DATA_FN",
    OPTIONS_DATA_MERGE = "OPTIONS_DATA_MERGE",
    OPTIONS_BEFORE_DESTROY = "OPTIONS_BEFORE_DESTROY",
    OPTIONS_DESTROYED = "OPTIONS_DESTROYED",
    WATCH_ARRAY = "WATCH_ARRAY",
    PROPS_DEFAULT_THIS = "PROPS_DEFAULT_THIS",
    V_ON_KEYCODE_MODIFIER = "V_ON_KEYCODE_MODIFIER",
    CUSTOM_DIR = "CUSTOM_DIR",
    ATTR_FALSE_VALUE = "ATTR_FALSE_VALUE",
    ATTR_ENUMERATED_COERCION = "ATTR_ENUMERATED_COERCION",
    TRANSITION_CLASSES = "TRANSITION_CLASSES",
    TRANSITION_GROUP_ROOT = "TRANSITION_GROUP_ROOT",
    COMPONENT_ASYNC = "COMPONENT_ASYNC",
    COMPONENT_FUNCTIONAL = "COMPONENT_FUNCTIONAL",
    COMPONENT_V_MODEL = "COMPONENT_V_MODEL",
    RENDER_FUNCTION = "RENDER_FUNCTION",
    FILTERS = "FILTERS",
    PRIVATE_APIS = "PRIVATE_APIS"
}
type CompatConfig = Partial<Record<DeprecationTypes$1, boolean | 'suppress-warning'>> & {
    MODE?: 2 | 3 | ((comp: Component | null) => 2 | 3);
};

/**
 * Interface for declaring custom options.
 *
 * @example
 * ```ts
 * declare module '@vue/runtime-core' {
 *   interface ComponentCustomOptions {
 *     beforeRouteUpdate?(
 *       to: Route,
 *       from: Route,
 *       next: () => void
 *     ): void
 *   }
 * }
 * ```
 */
interface ComponentCustomOptions {
}
type RenderFunction = () => VNodeChild;
interface ComponentOptionsBase<Props, RawBindings, D, C extends ComputedOptions, M extends MethodOptions, Mixin extends ComponentOptionsMixin, Extends extends ComponentOptionsMixin, E extends EmitsOptions, EE extends string = string, Defaults = {}, I extends ComponentInjectOptions = {}, II extends string = string, S extends SlotsType = {}> extends LegacyOptions<Props, D, C, M, Mixin, Extends, I, II>, ComponentInternalOptions, ComponentCustomOptions {
    setup?: (this: void, props: LooseRequired<Props & Prettify<UnwrapMixinsType<IntersectionMixin<Mixin> & IntersectionMixin<Extends>, 'P'>>>, ctx: SetupContext<E, S>) => Promise<RawBindings> | RawBindings | RenderFunction | void;
    name?: string;
    template?: string | object;
    render?: Function;
    components?: Record<string, Component>;
    directives?: Record<string, Directive>;
    inheritAttrs?: boolean;
    emits?: (E | EE[]) & ThisType<void>;
    slots?: S;
    expose?: string[];
    serverPrefetch?(): void | Promise<any>;
    compilerOptions?: RuntimeCompilerOptions;
    call?: (this: unknown, ...args: unknown[]) => never;
    __isFragment?: never;
    __isTeleport?: never;
    __isSuspense?: never;
    __defaults?: Defaults;
}
/**
 * Subset of compiler options that makes sense for the runtime.
 */
interface RuntimeCompilerOptions {
    isCustomElement?: (tag: string) => boolean;
    whitespace?: 'preserve' | 'condense';
    comments?: boolean;
    delimiters?: [string, string];
}
type ComponentOptionsWithoutProps<Props = {}, RawBindings = {}, D = {}, C extends ComputedOptions = {}, M extends MethodOptions = {}, Mixin extends ComponentOptionsMixin = ComponentOptionsMixin, Extends extends ComponentOptionsMixin = ComponentOptionsMixin, E extends EmitsOptions = EmitsOptions, EE extends string = string, I extends ComponentInjectOptions = {}, II extends string = string, S extends SlotsType = {}, PE = Props & EmitsToProps<E>> = ComponentOptionsBase<PE, RawBindings, D, C, M, Mixin, Extends, E, EE, {}, I, II, S> & {
    props?: undefined;
} & ThisType<CreateComponentPublicInstance<PE, RawBindings, D, C, M, Mixin, Extends, E, PE, {}, false, I, S>>;
type ComponentOptions<Props = {}, RawBindings = any, D = any, C extends ComputedOptions = any, M extends MethodOptions = any, Mixin extends ComponentOptionsMixin = any, Extends extends ComponentOptionsMixin = any, E extends EmitsOptions = any, S extends SlotsType = any> = ComponentOptionsBase<Props, RawBindings, D, C, M, Mixin, Extends, E, string, S> & ThisType<CreateComponentPublicInstance<{}, RawBindings, D, C, M, Mixin, Extends, E, Readonly<Props>>>;
type ComponentOptionsMixin = ComponentOptionsBase<any, any, any, any, any, any, any, any, any, any, any>;
type ComputedOptions = Record<string, ComputedGetter<any> | WritableComputedOptions<any>>;
interface MethodOptions {
    [key: string]: Function;
}
type ExtractComputedReturns<T extends any> = {
    [key in keyof T]: T[key] extends {
        get: (...args: any[]) => infer TReturn;
    } ? TReturn : T[key] extends (...args: any[]) => infer TReturn ? TReturn : never;
};
type ObjectWatchOptionItem = {
    handler: WatchCallback | string;
} & WatchOptions;
type WatchOptionItem = string | WatchCallback | ObjectWatchOptionItem;
type ComponentWatchOptionItem = WatchOptionItem | WatchOptionItem[];
type ComponentWatchOptions = Record<string, ComponentWatchOptionItem>;
type ComponentProvideOptions = ObjectProvideOptions | Function;
type ObjectProvideOptions = Record<string | symbol, unknown>;
type ComponentInjectOptions = string[] | ObjectInjectOptions;
type ObjectInjectOptions = Record<string | symbol, string | symbol | {
    from?: string | symbol;
    default?: unknown;
}>;
type InjectToObject<T extends ComponentInjectOptions> = T extends string[] ? {
    [K in T[number]]?: unknown;
} : T extends ObjectInjectOptions ? {
    [K in keyof T]?: unknown;
} : never;
interface LegacyOptions<Props, D, C extends ComputedOptions, M extends MethodOptions, Mixin extends ComponentOptionsMixin, Extends extends ComponentOptionsMixin, I extends ComponentInjectOptions, II extends string> {
    compatConfig?: CompatConfig;
    [key: string]: any;
    data?: (this: CreateComponentPublicInstance<Props, {}, {}, {}, MethodOptions, Mixin, Extends>, vm: CreateComponentPublicInstance<Props, {}, {}, {}, MethodOptions, Mixin, Extends>) => D;
    computed?: C;
    methods?: M;
    watch?: ComponentWatchOptions;
    provide?: ComponentProvideOptions;
    inject?: I | II[];
    filters?: Record<string, Function>;
    mixins?: Mixin[];
    extends?: Extends;
    beforeCreate?(): void;
    created?(): void;
    beforeMount?(): void;
    mounted?(): void;
    beforeUpdate?(): void;
    updated?(): void;
    activated?(): void;
    deactivated?(): void;
    /** @deprecated use `beforeUnmount` instead */
    beforeDestroy?(): void;
    beforeUnmount?(): void;
    /** @deprecated use `unmounted` instead */
    destroyed?(): void;
    unmounted?(): void;
    renderTracked?: DebuggerHook;
    renderTriggered?: DebuggerHook;
    errorCaptured?: ErrorCapturedHook;
    /**
     * runtime compile only
     * @deprecated use `compilerOptions.delimiters` instead.
     */
    delimiters?: [string, string];
    /**
     * #3468
     *
     * type-only, used to assist Mixin's type inference,
     * typescript will try to simplify the inferred `Mixin` type,
     * with the `__differentiator`, typescript won't be able to combine different mixins,
     * because the `__differentiator` will be different
     */
    __differentiator?: keyof D | keyof C | keyof M;
}
type MergedHook<T = () => void> = T | T[];
type MergedComponentOptionsOverride = {
    beforeCreate?: MergedHook;
    created?: MergedHook;
    beforeMount?: MergedHook;
    mounted?: MergedHook;
    beforeUpdate?: MergedHook;
    updated?: MergedHook;
    activated?: MergedHook;
    deactivated?: MergedHook;
    /** @deprecated use `beforeUnmount` instead */
    beforeDestroy?: MergedHook;
    beforeUnmount?: MergedHook;
    /** @deprecated use `unmounted` instead */
    destroyed?: MergedHook;
    unmounted?: MergedHook;
    renderTracked?: MergedHook<DebuggerHook>;
    renderTriggered?: MergedHook<DebuggerHook>;
    errorCaptured?: MergedHook<ErrorCapturedHook>;
};
type OptionTypesKeys = 'P' | 'B' | 'D' | 'C' | 'M' | 'Defaults';
type OptionTypesType<P = {}, B = {}, D = {}, C extends ComputedOptions = {}, M extends MethodOptions = {}, Defaults = {}> = {
    P: P;
    B: B;
    D: D;
    C: C;
    M: M;
    Defaults: Defaults;
};

interface InjectionKey<T> extends Symbol {
}

type PublicProps = VNodeProps & AllowedComponentProps & ComponentCustomProps;
type ResolveProps<PropsOrPropOptions, E extends EmitsOptions> = Readonly<PropsOrPropOptions extends ComponentPropsOptions ? ExtractPropTypes<PropsOrPropOptions> : PropsOrPropOptions> & ({} extends E ? {} : EmitsToProps<E>);
type DefineComponent<PropsOrPropOptions = {}, RawBindings = {}, D = {}, C extends ComputedOptions = ComputedOptions, M extends MethodOptions = MethodOptions, Mixin extends ComponentOptionsMixin = ComponentOptionsMixin, Extends extends ComponentOptionsMixin = ComponentOptionsMixin, E extends EmitsOptions = {}, EE extends string = string, PP = PublicProps, Props = ResolveProps<PropsOrPropOptions, E>, Defaults = ExtractDefaultPropTypes<PropsOrPropOptions>, S extends SlotsType = {}> = ComponentPublicInstanceConstructor<CreateComponentPublicInstance<Props, RawBindings, D, C, M, Mixin, Extends, E, PP & Props, Defaults, true, {}, S>> & ComponentOptionsBase<Props, RawBindings, D, C, M, Mixin, Extends, E, EE, Defaults, {}, string, S> & PP;

interface App<HostElement = any> {
    version: string;
    config: AppConfig;
    use<Options extends unknown[]>(plugin: Plugin<Options>, ...options: Options): this;
    use<Options>(plugin: Plugin<Options>, options: Options): this;
    mixin(mixin: ComponentOptions): this;
    component(name: string): Component | undefined;
    component(name: string, component: Component | DefineComponent): this;
    directive<T = any, V = any>(name: string): Directive<T, V> | undefined;
    directive<T = any, V = any>(name: string, directive: Directive<T, V>): this;
    mount(rootContainer: HostElement | string, isHydrate?: boolean, namespace?: boolean | ElementNamespace): ComponentPublicInstance;
    unmount(): void;
    provide<T>(key: InjectionKey<T> | string, value: T): this;
    /**
     * Runs a function with the app as active instance. This allows using of `inject()` within the function to get access
     * to variables provided via `app.provide()`.
     *
     * @param fn - function to run with the app as active instance
     */
    runWithContext<T>(fn: () => T): T;
    _uid: number;
    _component: ConcreteComponent;
    _props: Data | null;
    _container: HostElement | null;
    _context: AppContext;
    _instance: ComponentInternalInstance | null;
    /**
     * v2 compat only
     */
    filter?(name: string): Function | undefined;
    filter?(name: string, filter: Function): this;
}
type OptionMergeFunction = (to: unknown, from: unknown) => any;
interface AppConfig {
    readonly isNativeTag: (tag: string) => boolean;
    performance: boolean;
    optionMergeStrategies: Record<string, OptionMergeFunction>;
    globalProperties: ComponentCustomProperties & Record<string, any>;
    errorHandler?: (err: unknown, instance: ComponentPublicInstance | null, info: string) => void;
    warnHandler?: (msg: string, instance: ComponentPublicInstance | null, trace: string) => void;
    /**
     * Options to pass to `@vue/compiler-dom`.
     * Only supported in runtime compiler build.
     */
    compilerOptions: RuntimeCompilerOptions;
    /**
     * @deprecated use config.compilerOptions.isCustomElement
     */
    isCustomElement?: (tag: string) => boolean;
    /**
     * TODO document for 3.5
     * Enable warnings for computed getters that recursively trigger itself.
     */
    warnRecursiveComputed?: boolean;
}
interface AppContext {
    app: App;
    config: AppConfig;
    mixins: ComponentOptions[];
    components: Record<string, Component>;
    directives: Record<string, Directive>;
    provides: Record<string | symbol, any>;
}
type PluginInstallFunction<Options = any[]> = Options extends unknown[] ? (app: App, ...options: Options) => any : (app: App, options: Options) => any;
type ObjectPlugin<Options = any[]> = {
    install: PluginInstallFunction<Options>;
};
type FunctionPlugin<Options = any[]> = PluginInstallFunction<Options> & Partial<ObjectPlugin<Options>>;
type Plugin<Options = any[]> = FunctionPlugin<Options> | ObjectPlugin<Options>;

type TeleportVNode = VNode<RendererNode, RendererElement, TeleportProps>;
interface TeleportProps {
    to: string | RendererElement | null | undefined;
    disabled?: boolean;
}
declare const TeleportImpl: {
    name: string;
    __isTeleport: boolean;
    process(n1: TeleportVNode | null, n2: TeleportVNode, container: RendererElement, anchor: RendererNode | null, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, namespace: ElementNamespace, slotScopeIds: string[] | null, optimized: boolean, internals: RendererInternals): void;
    remove(vnode: VNode, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, optimized: boolean, { um: unmount, o: { remove: hostRemove } }: RendererInternals, doRemove: boolean): void;
    move: typeof moveTeleport;
    hydrate: typeof hydrateTeleport;
};
declare enum TeleportMoveTypes {
    TARGET_CHANGE = 0,
    TOGGLE = 1,
    REORDER = 2
}
declare function moveTeleport(vnode: VNode, container: RendererElement, parentAnchor: RendererNode | null, { o: { insert }, m: move }: RendererInternals, moveType?: TeleportMoveTypes): void;
declare function hydrateTeleport(node: Node, vnode: TeleportVNode, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, slotScopeIds: string[] | null, optimized: boolean, { o: { nextSibling, parentNode, querySelector }, }: RendererInternals<Node, Element>, hydrateChildren: (node: Node | null, vnode: VNode, container: Element, parentComponent: ComponentInternalInstance | null, parentSuspense: SuspenseBoundary | null, slotScopeIds: string[] | null, optimized: boolean) => Node | null): Node | null;
declare const Teleport: {
    new (): {
        $props: VNodeProps & TeleportProps;
        $slots: {
            default(): VNode[];
        };
    };
    __isTeleport: true;
};

declare const Fragment: {
    new (): {
        $props: VNodeProps;
    };
    __isFragment: true;
};
declare const Text: unique symbol;
declare const Comment: unique symbol;
declare const Static: unique symbol;
type VNodeTypes = string | VNode | Component | typeof Text | typeof Static | typeof Comment | typeof Fragment | typeof Teleport | typeof TeleportImpl | typeof Suspense | typeof SuspenseImpl;
type VNodeRef = string | Ref | ((ref: Element | ComponentPublicInstance | null, refs: Record<string, any>) => void);
type VNodeNormalizedRefAtom = {
    i: ComponentInternalInstance;
    r: VNodeRef;
    k?: string;
    f?: boolean;
};
type VNodeNormalizedRef = VNodeNormalizedRefAtom | VNodeNormalizedRefAtom[];
type VNodeMountHook = (vnode: VNode) => void;
type VNodeUpdateHook = (vnode: VNode, oldVNode: VNode) => void;
type VNodeProps = {
    key?: string | number | symbol;
    ref?: VNodeRef;
    ref_for?: boolean;
    ref_key?: string;
    onVnodeBeforeMount?: VNodeMountHook | VNodeMountHook[];
    onVnodeMounted?: VNodeMountHook | VNodeMountHook[];
    onVnodeBeforeUpdate?: VNodeUpdateHook | VNodeUpdateHook[];
    onVnodeUpdated?: VNodeUpdateHook | VNodeUpdateHook[];
    onVnodeBeforeUnmount?: VNodeMountHook | VNodeMountHook[];
    onVnodeUnmounted?: VNodeMountHook | VNodeMountHook[];
};
type VNodeChildAtom = VNode | string | number | boolean | null | undefined | void;
type VNodeArrayChildren = Array<VNodeArrayChildren | VNodeChildAtom>;
type VNodeChild = VNodeChildAtom | VNodeArrayChildren;
type VNodeNormalizedChildren = string | VNodeArrayChildren | RawSlots | null;
interface VNode<HostNode = RendererNode, HostElement = RendererElement, ExtraProps = {
    [key: string]: any;
}> {
    type: VNodeTypes;
    props: (VNodeProps & ExtraProps) | null;
    key: string | number | symbol | null;
    ref: VNodeNormalizedRef | null;
    /**
     * SFC only. This is assigned on vnode creation using currentScopeId
     * which is set alongside currentRenderingInstance.
     */
    scopeId: string | null;
    children: VNodeNormalizedChildren;
    component: ComponentInternalInstance | null;
    dirs: DirectiveBinding[] | null;
    transition: TransitionHooks<HostElement> | null;
    el: HostNode | null;
    anchor: HostNode | null;
    target: HostElement | null;
    targetAnchor: HostNode | null;
    suspense: SuspenseBoundary | null;
    shapeFlag: number;
    patchFlag: number;
    appContext: AppContext | null;
}

type Data = Record<string, unknown>;
/**
 * For extending allowed non-declared props on components in TSX
 */
interface ComponentCustomProps {
}
/**
 * Default allowed non-declared props on component in TSX
 */
interface AllowedComponentProps {
    class?: unknown;
    style?: unknown;
}
interface ComponentInternalOptions {
    /**
     * Compat build only, for bailing out of certain compatibility behavior
     */
    __isBuiltIn?: boolean;
    /**
     * This one should be exposed so that devtools can make use of it
     */
    __file?: string;
    /**
     * name inferred from filename
     */
    __name?: string;
}
interface FunctionalComponent<P = {}, E extends EmitsOptions | Record<string, any[]> = {}, S extends Record<string, any> = any, EE extends EmitsOptions = ShortEmitsToObject<E>> extends ComponentInternalOptions {
    (props: P & EmitsToProps<EE>, ctx: Omit<SetupContext<EE, IfAny<S, {}, SlotsType<S>>>, 'expose'>): any;
    props?: ComponentPropsOptions<P>;
    emits?: EE | (keyof EE)[];
    slots?: IfAny<S, Slots, SlotsType<S>>;
    inheritAttrs?: boolean;
    displayName?: string;
    compatConfig?: CompatConfig;
}
/**
 * Concrete component type matches its actual value: it's either an options
 * object, or a function. Use this where the code expects to work with actual
 * values, e.g. checking if its a function or not. This is mostly for internal
 * implementation code.
 */
type ConcreteComponent<Props = {}, RawBindings = any, D = any, C extends ComputedOptions = ComputedOptions, M extends MethodOptions = MethodOptions, E extends EmitsOptions | Record<string, any[]> = {}, S extends Record<string, any> = any> = ComponentOptions<Props, RawBindings, D, C, M> | FunctionalComponent<Props, E, S>;
/**
 * A type used in public APIs where a component type is expected.
 * The constructor type is an artificial type returned by defineComponent().
 */
type Component<Props = any, RawBindings = any, D = any, C extends ComputedOptions = ComputedOptions, M extends MethodOptions = MethodOptions, E extends EmitsOptions | Record<string, any[]> = {}, S extends Record<string, any> = any> = ConcreteComponent<Props, RawBindings, D, C, M, E, S> | ComponentPublicInstanceConstructor<Props>;

type SetupContext<E = EmitsOptions, S extends SlotsType = {}> = E extends any ? {
    attrs: Data;
    slots: UnwrapSlotsType<S>;
    emit: EmitFn<E>;
    expose: (exposed?: Record<string, any>) => void;
} : never;
/**
 * We expose a subset of properties on the internal instance as they are
 * useful for advanced external libraries and tools.
 */
interface ComponentInternalInstance {
    uid: number;
    type: ConcreteComponent;
    parent: ComponentInternalInstance | null;
    root: ComponentInternalInstance;
    appContext: AppContext;
    /**
     * Vnode representing this component in its parent's vdom tree
     */
    vnode: VNode;
    /**
     * Root vnode of this component's own vdom tree
     */
    subTree: VNode;
    /**
     * Render effect instance
     */
    effect: ReactiveEffect;
    /**
     * Bound effect runner to be passed to schedulers
     */
    update: SchedulerJob;
    proxy: ComponentPublicInstance | null;
    exposed: Record<string, any> | null;
    exposeProxy: Record<string, any> | null;
    data: Data;
    props: Data;
    attrs: Data;
    slots: InternalSlots;
    refs: Data;
    emit: EmitFn;
    attrsProxy: Data | null;
    slotsProxy: Slots | null;
    isMounted: boolean;
    isUnmounted: boolean;
    isDeactivated: boolean;
}
type WatchCallback<V = any, OV = any> = (value: V, oldValue: OV, onCleanup: OnCleanup) => any;
type OnCleanup = (cleanupFn: () => void) => void;
interface WatchOptionsBase extends DebuggerOptions {
    flush?: 'pre' | 'post' | 'sync';
}
interface WatchOptions<Immediate = boolean> extends WatchOptionsBase {
    immediate?: Immediate;
    deep?: boolean;
    once?: boolean;
}
type WatchStopHandle = () => void;

/**
 * Vue `<script setup>` compiler macro for declaring component props. The
 * expected argument is the same as the component `props` option.
 *
 * Example runtime declaration:
 * ```js
 * // using Array syntax
 * const props = defineProps(['foo', 'bar'])
 * // using Object syntax
 * const props = defineProps({
 *   foo: String,
 *   bar: {
 *     type: Number,
 *     required: true
 *   }
 * })
 * ```
 *
 * Equivalent type-based declaration:
 * ```ts
 * // will be compiled into equivalent runtime declarations
 * const props = defineProps<{
 *   foo?: string
 *   bar: number
 * }>()
 * ```
 *
 * @see {@link https://vuejs.org/api/sfc-script-setup.html#defineprops-defineemits}
 *
 * This is only usable inside `<script setup>`, is compiled away in the
 * output and should **not** be actually called at runtime.
 */
declare function defineProps<PropNames extends string = string>(props: PropNames[]): Prettify<Readonly<{
    [key in PropNames]?: any;
}>>;
declare function defineProps<PP extends ComponentObjectPropsOptions = ComponentObjectPropsOptions>(props: PP): Prettify<Readonly<ExtractPropTypes<PP>>>;
declare function defineProps<TypeProps>(): DefineProps<LooseRequired<TypeProps>, BooleanKey<TypeProps>>;
type DefineProps<T, BKeys extends keyof T> = Readonly<T> & {
    readonly [K in BKeys]-?: boolean;
};
type BooleanKey<T, K extends keyof T = keyof T> = K extends any ? [T[K]] extends [boolean | undefined] ? K : never : never;
/**
 * Vue `<script setup>` compiler macro for declaring a component's emitted
 * events. The expected argument is the same as the component `emits` option.
 *
 * Example runtime declaration:
 * ```js
 * const emit = defineEmits(['change', 'update'])
 * ```
 *
 * Example type-based declaration:
 * ```ts
 * const emit = defineEmits<{
 *   // <eventName>: <expected arguments>
 *   change: []
 *   update: [value: string] // named tuple syntax
 * }>()
 *
 * emit('change')
 * emit('update', 1)
 * ```
 *
 * This is only usable inside `<script setup>`, is compiled away in the
 * output and should **not** be actually called at runtime.
 *
 * @see {@link https://vuejs.org/api/sfc-script-setup.html#defineprops-defineemits}
 */
declare function defineEmits<EE extends string = string>(emitOptions: EE[]): EmitFn<EE[]>;
declare function defineEmits<E extends EmitsOptions = EmitsOptions>(emitOptions: E): EmitFn<E>;
declare function defineEmits<T extends ((...args: any[]) => any) | Record<string, any[]>>(): T extends (...args: any[]) => any ? T : ShortEmits<T>;
type RecordToUnion<T extends Record<string, any>> = T[keyof T];
type ShortEmits<T extends Record<string, any>> = UnionToIntersection<RecordToUnion<{
    [K in keyof T]: (evt: K, ...args: T[K]) => void;
}>>;
/**
 * Vue `<script setup>` compiler macro for declaring a component's exposed
 * instance properties when it is accessed by a parent component via template
 * refs.
 *
 * `<script setup>` components are closed by default - i.e. variables inside
 * the `<script setup>` scope is not exposed to parent unless explicitly exposed
 * via `defineExpose`.
 *
 * This is only usable inside `<script setup>`, is compiled away in the
 * output and should **not** be actually called at runtime.
 *
 * @see {@link https://vuejs.org/api/sfc-script-setup.html#defineexpose}
 */
declare function defineExpose<Exposed extends Record<string, any> = Record<string, any>>(exposed?: Exposed): void;
/**
 * Vue `<script setup>` compiler macro for declaring a component's additional
 * options. This should be used only for options that cannot be expressed via
 * Composition API - e.g. `inheritAttrs`.
 *
 * @see {@link https://vuejs.org/api/sfc-script-setup.html#defineoptions}
 */
declare function defineOptions<RawBindings = {}, D = {}, C extends ComputedOptions = {}, M extends MethodOptions = {}, Mixin extends ComponentOptionsMixin = ComponentOptionsMixin, Extends extends ComponentOptionsMixin = ComponentOptionsMixin>(options?: ComponentOptionsWithoutProps<{}, RawBindings, D, C, M, Mixin, Extends> & {
    emits?: undefined;
    expose?: undefined;
    slots?: undefined;
}): void;
declare function defineSlots<S extends Record<string, any> = Record<string, any>>(): StrictUnwrapSlotsType<SlotsType<S>>;
type ModelRef<T, M extends string | number | symbol = string> = Ref<T> & [
    ModelRef<T, M>,
    Record<M, true | undefined>
];
type DefineModelOptions<T = any> = {
    get?: (v: T) => any;
    set?: (v: T) => any;
};
/**
 * Vue `<script setup>` compiler macro for declaring a
 * two-way binding prop that can be consumed via `v-model` from the parent
 * component. This will declare a prop with the same name and a corresponding
 * `update:propName` event.
 *
 * If the first argument is a string, it will be used as the prop name;
 * Otherwise the prop name will default to "modelValue". In both cases, you
 * can also pass an additional object which will be used as the prop's options.
 *
 * The the returned ref behaves differently depending on whether the parent
 * provided the corresponding v-model props or not:
 * - If yes, the returned ref's value will always be in sync with the parent
 *   prop.
 * - If not, the returned ref will behave like a normal local ref.
 *
 * @example
 * ```ts
 * // default model (consumed via `v-model`)
 * const modelValue = defineModel<string>()
 * modelValue.value = "hello"
 *
 * // default model with options
 * const modelValue = defineModel<string>({ required: true })
 *
 * // with specified name (consumed via `v-model:count`)
 * const count = defineModel<number>('count')
 * count.value++
 *
 * // with specified name and default value
 * const count = defineModel<number>('count', { default: 0 })
 * ```
 */
declare function defineModel<T, M extends string | number | symbol = string>(options: {
    required: true;
} & PropOptions<T> & DefineModelOptions<T>): ModelRef<T, M>;
declare function defineModel<T, M extends string | number | symbol = string>(options: {
    default: any;
} & PropOptions<T> & DefineModelOptions<T>): ModelRef<T, M>;
declare function defineModel<T, M extends string | number | symbol = string>(options?: PropOptions<T> & DefineModelOptions<T>): ModelRef<T | undefined, M>;
declare function defineModel<T, M extends string | number | symbol = string>(name: string, options: {
    required: true;
} & PropOptions<T> & DefineModelOptions<T>): ModelRef<T, M>;
declare function defineModel<T, M extends string | number | symbol = string>(name: string, options: {
    default: any;
} & PropOptions<T> & DefineModelOptions<T>): ModelRef<T, M>;
declare function defineModel<T, M extends string | number | symbol = string>(name: string, options?: PropOptions<T> & DefineModelOptions<T>): ModelRef<T | undefined, M>;
type NotUndefined<T> = T extends undefined ? never : T;
type InferDefaults<T> = {
    [K in keyof T]?: InferDefault<T, T[K]>;
};
type NativeType = null | number | string | boolean | symbol | Function;
type InferDefault<P, T> = ((props: P) => T & {}) | (T extends NativeType ? T : never);
type PropsWithDefaults<T, Defaults extends InferDefaults<T>, BKeys extends keyof T> = Readonly<Omit<T, keyof Defaults>> & {
    readonly [K in keyof Defaults]-?: K extends keyof T ? Defaults[K] extends undefined ? T[K] : NotUndefined<T[K]> : never;
} & {
    readonly [K in BKeys]-?: K extends keyof Defaults ? Defaults[K] extends undefined ? boolean | undefined : boolean : boolean;
};
/**
 * Vue `<script setup>` compiler macro for providing props default values when
 * using type-based `defineProps` declaration.
 *
 * Example usage:
 * ```ts
 * withDefaults(defineProps<{
 *   size?: number
 *   labels?: string[]
 * }>(), {
 *   size: 3,
 *   labels: () => ['default label']
 * })
 * ```
 *
 * This is only usable inside `<script setup>`, is compiled away in the output
 * and should **not** be actually called at runtime.
 *
 * @see {@link https://vuejs.org/guide/typescript/composition-api.html#typing-component-props}
 */
declare function withDefaults<T, BKeys extends keyof T, Defaults extends InferDefaults<T>>(props: DefineProps<T, BKeys>, defaults: Defaults): PropsWithDefaults<T, Defaults, BKeys>;

declare module '@vue/reactivity' {
    interface RefUnwrapBailTypes {
        runtimeCoreBailTypes: VNode | {
            $: ComponentInternalInstance;
        };
    }
}
// Note: this file is auto concatenated to the end of the bundled d.ts during
// build.
type _defineProps = typeof defineProps
type _defineEmits = typeof defineEmits
type _defineExpose = typeof defineExpose
type _defineOptions = typeof defineOptions
type _defineSlots = typeof defineSlots
type _defineModel = typeof defineModel
type _withDefaults = typeof withDefaults

declare global {
  const defineProps: _defineProps
  const defineEmits: _defineEmits
  const defineExpose: _defineExpose
  const defineOptions: _defineOptions
  const defineSlots: _defineSlots
  const defineModel: _defineModel
  const withDefaults: _withDefaults
}

declare module '@vue/reactivity' {
    interface RefUnwrapBailTypes {
        runtimeDOMBailTypes: Node | Window;
    }
}

declare function arrayAt<T>(array: T[], index: number): T | null;

declare function arrayFind<T>(array: T[], predicate: any): T | null;

declare function arrayFindLast<T>(array: T[], predicate: any): T | null;

declare function arrayPop<T>(array: T[]): T | null;

declare function arrayShift<T>(array: T[]): T | null;

declare interface Constructible {
    new (...args: any[]): any;
}

declare function isInstanceOf(value: any, type: Function): any;

declare function mapGet<K, V>(map: Map<K, V>, key: K): V | null;

declare function stringAt(str: string, pos: number): string | null;

declare function stringCodePointAt(str: string, pos: number): number | null;

declare class UniError extends Error {
    errSubject: string;
    errCode: number;
    cause?: Error;
    data?: any;
    constructor(errSubject?: string, errCode?: number | Record<string, any>, errMsg?: string);
    set errMsg(msg: string);
    get errMsg(): string;
    toString(): string;
    toJSON(): Record<string, any>;
}

declare const UTS: {
    arrayAt: typeof arrayAt;
    arrayFind: typeof arrayFind;
    arrayFindLast: typeof arrayFindLast;
    arrayPop: typeof arrayPop;
    arrayShift: typeof arrayShift;
    isInstanceOf: typeof isInstanceOf;
    UTSType: typeof UTSType;
    mapGet: typeof mapGet;
    stringAt: typeof stringAt;
    stringCodePointAt: typeof stringCodePointAt;
    weakMapGet: typeof weakMapGet;
    JSON: {
        parse: (text: string, reviver?: ((this: any, key: string, value: any) => any) | undefined, utsType?: Constructible | undefined) => any;
        parseArray(text: string, utsType?: typeof UTSType | undefined): any[] | null;
        parseObject(text: string, utsType?: typeof UTSType | undefined): any;
        stringify: (value: any, replacer?: any, space?: any) => string;
    };
};

declare const enum UTS_CLASS_METADATA_KIND {
    CLASS = 0,
    INTERFACE = 1,
    TYPE = 2
}

declare class UTSJSONObject_2 {
    [key: string]: any;
    static keys(obj: UTSJSONObject_2): string[];
    static assign(target: UTSJSONObject_2, ...sources: UTSJSONObject_2[]): UTSJSONObject_2;
    constructor(content?: Map<string, any> | Record<string, any>);
    private _resolveKeyPath;
    private _getValue;
    get(key: string): any | null;
    set(key: string, value: any): void;
    getAny(key: string, defaultValue: any): any | null;
    getString(key: string, defaultValue: string): string | null;
    getNumber(key: string, defaultValue: number): number | null;
    getBoolean(key: string, defaultValue: boolean): boolean | null;
    getJSON(key: string, defaultValue: UTSJSONObject_2): UTSJSONObject_2 | null;
    getArray<T = any>(key: string, defaultValue: Array<T>): Array<T> | null;
    toMap(): Map<string, any>;
    forEach(callback: (value: any, key: string) => void): void;
}


declare interface UTSMetadata {
    name: string;
    kind: UTS_CLASS_METADATA_KIND;
    interfaces?: Function[] | undefined;
    fields?: Record<string, UTSTypeFieldType>;
}

declare class UTSType {
    [key: string]: any;
    static get$UTSMetadata$(...args: any[]): UTSTypeMetadata;
    protected get $UTSMetadata$(): Required<UTSMetadata>;
    static withGenerics(parent: Constructible, generics: Array<any>, isJSONParse?: boolean): Constructible;
    constructor();
    static initProps(options: Record<string, any>, metadata: UTSTypeMetadata, isJSONParse?: boolean): Record<string, any>;
}

declare type UTSTypeFieldType = {
    type: Function;
    optional: boolean;
    jsonField?: string;
};

declare type UTSTypeMetadata = Required<UTSMetadata>;

declare abstract class UTSValueIterable {
}

declare function weakMapGet<K extends symbol | object, V>(map: WeakMap<K, V>, key: K): V | null;

export { type DefineNativeEmbedOptions, TinyEmitter as Emitter, type IAppVersionInfo, type ICapsuleMenuActionSheetItem, type ICapsuleStyle, type IInitConfig, type IOpenUniMPConfig, type IUniMP, type IWebNodeController, type NativeEmbedBuilderOptions, type NativeEmbedEvent, type PageComponent, type ReleaseWgtToRunPathCallback, TEMPLATE_PAGE_NAME, UTS, index_d as UTSHarmony, UTSJSONObject_2 as UTSJSONObject, UTSValueIterable, UniError, UniMP, WebNodeController, appAbilityEmitter, appLifeCycle$1 as appLifeCycle, callPageLifeCycle, capitalize, closeUniMP, createDownloadDelegate, defineAsyncApi, defineNativeEmbed, defineOffApi, defineOnApi, defineSyncApi, defineTaskApi, disableEnumerable, formatValueCeil, formatValueRound, freeze, getAbilityContext, getAppVersionInfo, getCurrentMP, getCurrentWebview, getCurrentWindow$1 as getCurrentWindow, getDeviceId, getEntryMetadata, getEnv, getOSRuntime, getRealPath, getResourceStr, getSafeAreaInsets, getServiceMethod, getTabBar, getType, getUniMP, getUniMPRunPath, getWindowInfo, getWindowStage$1 as getWindowStage, globalConfig, hasOwn, hmrGetUniAppWWWPath, hmrGetUniAppWWWPathInResfile, hmrOpenUniApp, hmrRestartUniApp, init, initAbility, initUniApi, isExistsApp, isPlainObject, isRealPlainObject, nativePagesManager, navigator, offSafeAreaInsetsChange, onBackPressCallbacks, onNativePageReady, onSafeAreaInsetsChange, openUniApp, openUniMP, pageLifeCycle, registerModule, registerServiceMethod, releaseCurrentWgtToRunPath, releaseWgtToRunPath, setOSRuntime, startPullDownRefresh, stopPullDownRefresh, telSchemeHandler, uni };
