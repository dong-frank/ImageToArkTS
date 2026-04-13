import webview from '@ohos.web.webview';
import { window } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { getAbilityContext, appAbilityEmitter } from './sdk'
import { fullScreenState } from './components/FullScreen';
import { themeState } from './theme';

let lastPreferredOrientation: window.Orientation | null = null;

function requestFullScreen(fullScreen: boolean) {
  if (!fullScreen && !fullScreenState.isFullScreen) {
    return
  }
  window.getLastWindow(getAbilityContext()).then((lastWindow) => {
    // 保存当前的屏幕方向
    if (fullScreen) {
      try {
        lastPreferredOrientation = lastWindow.getPreferredOrientation()
      } catch (error) {
      }
    }
    lastWindow.setPreferredOrientation(fullScreen ? window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED :
      lastPreferredOrientation)
      .then(() => {
        fullScreenState.isFullScreen = fullScreen
      })
      .catch(() => {
        fullScreenState.isFullScreen = false
        lastWindow.setPreferredOrientation(lastPreferredOrientation ?? window.Orientation.PORTRAIT)
      })
  });
}

interface JavaScriptProxy {
  object: object;
  name: string;
  methodList: Array<string>;
  controller: WebviewController;
}

interface WebBuilderOptions extends WebOptions {
  darkmode: boolean
  scrollIndicator: string
  controller: webview.WebviewController
  javaScriptProxy: JavaScriptProxy
  safeAreaEdges: Array<SafeAreaEdge>
  backgroundColor?: string
  bounce?: string
  onPageBegin: () => void
  onPageEnd: () => void
  onFocus: () => void
  onBlur: () => void
  onPageVisible: () => void
  onInterceptRequest: () => WebResourceResponse
  onNativeEmbedLifecycleChange: (event: NativeEmbedDataInfo) => void
  onNativeEmbedGestureEvent: (event: NativeEmbedTouchInfo) => void
  onAreaChange: (oldValue: Area, newValue: Area) => void
  onControllerAttached: () => void
}

export const WEB_PAGE_END = 'WebPageEnd'

let isFirstPageEnd = true

@Builder
export function WebBuilder(options: WebBuilderOptions) {

  Scroll() {
    Column() {
      WebComponent(options)
    }
    .width('100%')
    .height('100%')
  }
  .edgeEffect(options?.bounce !== 'none' ? EdgeEffect.Fade : EdgeEffect.None)
  .width('100%')
  .height('100%')
}

@Builder
export function WebComponent(options: WebBuilderOptions) {
  Web(options)
    .darkMode(options.darkmode && themeState.isDark ? WebDarkMode.On : WebDarkMode.Off)
    .keyboardAvoidMode(WebKeyboardAvoidMode.OVERLAYS_CONTENT)
    .backgroundColor(options.backgroundColor || Color.Transparent)
    .javaScriptProxy(options.javaScriptProxy)
    // app-harmony.scrollIndicator  all|vertical|horizontal|none
    .horizontalScrollBarAccess(options.scrollIndicator === 'horizontal' || options.scrollIndicator === 'all')
    .verticalScrollBarAccess(options.scrollIndicator === 'vertical' || options.scrollIndicator === 'all')
    .onFocus(() => {
      options.onFocus()
    })
    .allowDrop(null)
    .onBlur(() => {
      options.onBlur()
    })
    .onConsole(event => {
      if (event) {
        console.log(event.message.getMessage())
      }
      return false
    })
    .onErrorReceive(event => {
      if (event) {
        console.error(event.error.getErrorInfo())
      }
    })
    .onDisAppear(() => {
      webview.WebCookieManager.saveCookieAsync()
      requestFullScreen(false);
    })
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.PARENT_FIRST
    })
    .onSslErrorEventReceive((event) => {
      event.handler.handleConfirm()
    })
    .onPageBegin(() => {
      options.onPageBegin()

      if (!isFirstPageEnd) {
        appAbilityEmitter.emit(WEB_PAGE_END)
      }
    })
    .onPageEnd(() => {
      options.onPageEnd()
      if (deviceInfo.sdkApiVersion < 21) {
        options.controller?.setPathAllowingUniversalAccess([])
      }
      if (isFirstPageEnd) {
        isFirstPageEnd = false
        appAbilityEmitter.emit(WEB_PAGE_END)
      }
    })
    .mixedMode(MixedMode.All)
    .onPageVisible(options.onPageVisible)
    .onInterceptRequest(options.onInterceptRequest)
    .enableNativeEmbedMode(true)
    .onNativeEmbedLifecycleChange(options.onNativeEmbedLifecycleChange)
    .onNativeEmbedGestureEvent(options.onNativeEmbedGestureEvent)
    .fileAccess(true)
    .imageAccess(true)
    .onlineImageAccess(true)
    .domStorageAccess(true)
    .overScrollMode(OverScrollMode.NEVER)
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], options.safeAreaEdges)
    .metaViewport(true)
    .mediaPlayGestureAccess(false)
    .onAreaChange(options.onAreaChange)
    .onControllerAttached(options.onControllerAttached)
    .onPermissionRequest((event) => {
      const request = event.request
      const requestedResources = request.getAccessibleResource()
      const permissions: Permissions[] = []
      const resources: ProtectedResourceType[] = []
      if (requestedResources.includes(ProtectedResourceType.VIDEO_CAPTURE)) {
        permissions.push('ohos.permission.CAMERA')
        resources.push(ProtectedResourceType.VIDEO_CAPTURE)
      }
      if (requestedResources.includes(ProtectedResourceType.AUDIO_CAPTURE)) {
        permissions.push('ohos.permission.MICROPHONE')
        resources.push(ProtectedResourceType.AUDIO_CAPTURE)
      }
      if (permissions.length > 0) {
        const context = getContext() as common.UIAbilityContext;
        const atManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(context, permissions).then((data) => {
          const granted: ProtectedResourceType[] =
            resources.filter((resource, index) => data.authResults[index] === 0)
          if (granted.length === 0) {
            request.deny()
            return
          }
          request.grant(granted)
        }).catch((error: BusinessError) => {
          console.error(`Failed to request permissions from user. Code is ${error.code}, message is ${error.message}`);
          request.deny()
        })
      }
    })
    .onLoadIntercept((event) => {
      let url = event.data.getRequestUrl()
      if (url.startsWith('file:/')) {
        options.controller?.setPathAllowingUniversalAccess([])
        return false
      }
      const context = getContext()
      if (context) {
        let allowingUniversalAccess = [
          context.filesDir,
          context.getApplicationContext().filesDir,
          context.resourceDir,
          context.getApplicationContext().resourceDir
        ].filter(item => !!item).map(item => item + '/apps')
        try {
          if (deviceInfo.sdkApiVersion < 21) {
            if (
              (url.includes(context.tempDir) || url.includes(context.getApplicationContext().tempDir) ||
              url.includes(context.cacheDir) || url.includes(context.getApplicationContext().cacheDir))
            ) {
              allowingUniversalAccess = []
            }
            options.controller?.setPathAllowingUniversalAccess(allowingUniversalAccess)
          } else {
            allowingUniversalAccess.push(
              context.cacheDir,
              context.getApplicationContext().cacheDir,
              context.tempDir,
              context.getApplicationContext().tempDir
            )
            options.controller?.setPathAllowingUniversalAccess(allowingUniversalAccess)
          }
        } catch (error) {
          console.error('[runtime-harmony] Webview setPathAllowingUniversalAccess error: ' + error)
        }
      }
      // 兼容 mailto:// 等协议
      if (!(/https{0,1}:\/\//.test(url) || url.startsWith('file:/')) && /\w+:/.test(url)) {
        const scheme = (url.match(/(\w+:)\w/) ?? [])[1]
        if (scheme) {
          url = url.replace(scheme, scheme + '//')
        }
        try {
          let canOpen = bundleManager.canOpenLink(url);
          if (canOpen) {
            getAbilityContext()?.openLink(url)
            return true
          } else {
            // console.error('[runtime-harmony] Web failed to open link: ' + url)
          }
        } catch (e) {
          // console.error('[runtime-harmony] Web failed to open link: ' + url + '. ' + e)
        }
      }
      return false
    })
    .onFullScreenEnter((event) => {
      requestFullScreen(true);
    })
    .onFullScreenExit(() => {
      requestFullScreen(false);
    })
}
