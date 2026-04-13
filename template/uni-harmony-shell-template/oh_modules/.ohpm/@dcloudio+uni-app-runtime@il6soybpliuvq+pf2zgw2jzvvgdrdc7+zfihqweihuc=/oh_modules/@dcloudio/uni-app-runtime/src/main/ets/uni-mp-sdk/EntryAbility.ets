import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import window from '@ohos.window';
import { setOSRuntime, init, initAbility, openUniApp, appAbilityEmitter } from './sdk';
import '@dcloudio/uni-app-harmony'
import '@dcloudio/uni-app-modules'
import { WebBuilder } from './WebBuilder'
import { createSubPageState, createTabBarState, createTabBarItem } from './Page'
import './WebViewBuilder'
import './MapBuilder'
import './PickerBuilder'
import './AdBuilder'
import { previewImage, closePreviewImage } from './components/ImagePreviewer'
import { showLoading, hideLoading } from './components/ShowLoading'
import { IInitConfig } from './types';
import { setThemeState } from './theme'

setOSRuntime({
  WebBuilder,
  createSubPageState,
  createTabBarState,
  createTabBarItem,
  previewImage,
  closePreviewImage,
  showLoading,
  hideLoading,
  setThemeState
})

let entryAbilityAppID: string
let entryAbilityConfig: IInitConfig | undefined

export default class EntryAbility extends UIAbility {
  constructor(appId: string, config?: IInitConfig) {
    super()
    initAbility(this)
    entryAbilityAppID = appId
    entryAbilityConfig = config
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    appAbilityEmitter.emit('create', want, launchParam)
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    appAbilityEmitter.emit('newWant', want, launchParam)
  }

  onShare(wantParam: Record<string, Object>): void {
    appAbilityEmitter.emit('share', wantParam)
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    init(this, windowStage, entryAbilityConfig)
    openUniApp(entryAbilityAppID)
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    appAbilityEmitter.emit('configurationUpdate', newConfig)
  }
}
