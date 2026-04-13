// TODO 从js内导出的变量会遇到一些难以理解的编译顺序问题，EventHub、setGlobalVar必须放在此处
import { EventHub } from './utils'
import { setGlobalVar } from './polyfill/polyfill'
import EntryAbility from './EntryAbility'
import EntryAbilityDev from './EntryAbilityDev'
import { UniMP } from './types/index'

import './Page'
import { getCurrentMP as SDKGetCurrentMP } from './sdk'
export {
  defineAsyncApi,
  defineOffApi,
  defineOnApi,
  defineSyncApi,
  defineTaskApi,
} from '@dcloudio/uni-app-harmony'

export * from '@dcloudio/uni-app-harmony'

export {
  uni,
  isPlainObject,
  getType,
  hasOwn,
  disableEnumerable,
  getWindowInfo,
  getDeviceId,
  getCurrentWebview,
  navigator,
  getEnv,
  getOSRuntime,
  onNativePageReady,
  getRealPath,
  getResourceStr,
  getAbilityContext,
  getTabBar,
  Emitter,
  startPullDownRefresh,
  stopPullDownRefresh,
  WebNodeController,
  callPageLifeCycle,
  init,
  openUniApp,
  openUniMP,
  releaseWgtToRunPath,
  isExistsApp,
  getUniMPRunPath,
  getCurrentWindow,
  defineNativeEmbed,
  getAppVersionInfo,
  registerModule,
  hmrOpenUniApp,
  hmrRestartUniApp,
  hmrGetUniAppWWWPath,
  hmrGetUniAppWWWPathInResfile,
  UTSHarmony,
  UniMP,
  initUniApi,
} from './sdk'

export { EventHub, setGlobalVar }

export function getCurrentMP(): UniMP {
  return SDKGetCurrentMP() as UniMP
}

export {
  EntryAbility as UniEntryAbility,
  EntryAbilityDev as UniEntryAbilityDev
}