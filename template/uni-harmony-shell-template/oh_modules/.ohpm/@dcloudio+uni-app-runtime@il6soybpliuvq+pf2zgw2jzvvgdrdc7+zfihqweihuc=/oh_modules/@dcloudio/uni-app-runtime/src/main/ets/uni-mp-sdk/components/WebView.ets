import harmonyWebView from '@ohos.web.webview'
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, Permissions, bundleManager } from '@kit.AbilityKit';
import { createDownloadDelegate, getCurrentMP, telSchemeHandler, getAbilityContext, getRealPath } from '../sdk'

interface Detail {}

interface Event {
  detail: Detail
}

interface TitleUpdateEventDetail {
  title?: string
}

interface TitleUpdateEvent extends Event {
  detail: TitleUpdateEventDetail
}

@Component
export struct WebView {
  @Prop @Watch('setSrc') src: string
  onMessage?: (event: Event) => void = undefined
  onTitleUpdate?: (event: TitleUpdateEvent) => void = undefined
  onPostMessageToService?: (event: Event) => void = undefined
  onControllerAttached?: () => void = undefined
  controller?: harmonyWebView.WebviewController

  build() {
    Web({
      src: this.src,
      controller: this.controller
    })
      .backgroundColor(Color.Transparent)
      .metaViewport(true)
      .overScrollMode(OverScrollMode.NEVER)
      .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_VISUAL)
      .geolocationAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .imageAccess(true)
      .onlineImageAccess(true)
      .darkMode(WebDarkMode.Auto)
      .mixedMode(MixedMode.All)
      .mediaPlayGestureAccess(false)
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
          const context = getContext(this) as common.UIAbilityContext;
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
      .onControllerAttached(() => {
        const delegate = createDownloadDelegate() as harmonyWebView.WebDownloadDelegate
        this.controller?.setDownloadDelegate(delegate)
        const userAgent = getCurrentMP()!.userAgent.fullUserAgent as string
        this.controller?.setCustomUserAgent(userAgent)
        // TODO 调用 setCustomUserAgent 后必须重新 loadUrl，否则 controller 上方法会失效
        this.controller?.loadUrl(getRealPath(this.src))
        this.controller?.setWebSchemeHandler('tel', telSchemeHandler)
        this.onControllerAttached?.()
      })
      .onLoadIntercept((event) => {
        let url = event.data.getRequestUrl()
        if (url.startsWith('file:/')) {
          this.controller?.setPathAllowingUniversalAccess([])
          return false
        }
        const context = this.getUIContext().getHostContext()
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
              this.controller?.setPathAllowingUniversalAccess(allowingUniversalAccess)
            } else {
              allowingUniversalAccess.push(
                context.cacheDir,
                context.getApplicationContext().cacheDir,
                context.tempDir,
                context.getApplicationContext().tempDir
              )
              this.controller?.setPathAllowingUniversalAccess(allowingUniversalAccess)
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
              // console.error('Webview failed to open link: ' + url)
            }
          } catch (e) {
            // console.error('Webview failed to open link: ' + url + '. ' + e)
          }
        }
        return false
      })
      .onTitleReceive(event => {
        this.onTitleUpdate?.({
          detail: {
            title: event?.title
          }
        })
      })
      .onConsole(event => {
        if (event) {
          console.log('getMessage: ' + JSON.stringify(event.message.getMessage()))
        }
        return false
      })
      .onAlert((event) => {
        if (event) {
          AlertDialog.show({
            message: event.message,
            autoCancel: false,
            alignment: DialogAlignment.Center,
            confirm: {
              value: 'OK',
              action: () => {
                event.result.handleConfirm()
              }
            }
          })
        }
        return true;
      })
      .onErrorReceive(event => {
        if (event) {
          console.error(event.error.getErrorInfo())
        }
      })
      .onSslErrorEventReceive((event) => {
        event.handler.handleConfirm()
      })
      .javaScriptProxy({
        object: {
          postMessage: (data: string) => {
            if (this.onMessage) {
              this.onMessage({ detail: JSON.parse(data) })
            }
          },
          postMessageToService: (data: string) => {
            if (this.onPostMessageToService) {
              this.onPostMessageToService({ detail: JSON.parse(data) })
            }
          }
        },
        name: '__uniapp_x_',
        methodList: ['postMessage', 'postMessageToService'],
        controller: this.controller
      })
      .onGeolocationShow((event) => {
        const context = getContext(this) as common.UIAbilityContext;
        const atManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(context,
          ["ohos.permission.APPROXIMATELY_LOCATION", "ohos.permission.LOCATION"]).then((data) => {
          if (data.authResults.some(item => item === 0)) {
            event.geolocation.invoke(event.origin, true, true);
          } else {
            event.geolocation.invoke(event.origin, false, false);
          }
        }).catch((error: BusinessError) => {
          console.error(`Failed to request permissions from user. Code is ${error.code}, message is ${error.message}`);
          event.geolocation.invoke(event.origin, false, false);
        })
      })
  }

  setSrc() {
    if (!this.src) {
      return
    }
    this.controller?.loadUrl(this.src)
  }
}
