import * as window from '@ohos.window';
import window__default from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import common from '@ohos.app.ability.common';

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
 *      "unixVer": "4.61"
 *    }
 *   }
 * }
 */
declare function devicePX2px(px: number): number;

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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
 *    }
 *   }
 * }
 */
declare function exit(): void;

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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
 *    }
 *   }
 * }
 */
declare function onAppAbilityWindowStageCreate(callback: OnWindowStageCreate): void;

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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
 *    }
 *   }
 * }
 */
declare function getCurrentWindow(): window.default.Window;

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
 *      "unixVer": "4.61"
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
 *      "unixVer": "4.61"
 *    }
 *   }
 * }
 */
declare function getResourcePath(filePath: string): string;

interface IAppBaseInfoAppVersion {
  name: string
  code: string
}

export interface IUTSHarmony {
  convert2AbsFullPath: typeof convert2AbsFullPath,
  devicePX2px: typeof devicePX2px,
  exit: typeof exit,
  getCurrentWindow: typeof getCurrentWindow,
  getResourcePath: typeof getResourcePath,
  getUIAbilityContext: typeof getUIAbilityContext,
  onAppAbilityCreate: typeof onAppAbilityCreate,
  onAppAbilityNewWant: typeof onAppAbilityNewWant,
  onAppAbilityShare: typeof onAppAbilityShare,
  onAppAbilityWindowStageCreate: typeof onAppAbilityWindowStageCreate,
  requestSystemPermission: typeof requestSystemPermission,
  getAppId: () => string,
  getAppName: () => string,
  getAppTheme: () => string,
  getOsTheme: () => string,
  getAppVersion: () => IAppBaseInfoAppVersion,
  getUniCompilerVersion: () => string,
  getUniRuntimeVersion: () => string,
  isUniAppX: () => boolean,
  getUserAgent: () => string,
  getExtensionFromMimeType: (contentType: string) => string | null,
  getMimeTypeFromExtension: (contentType: string) => string | null,
  getPrivacyAgree: () => boolean,
  resetPrivacyAgree: () => void,
  onPrivacyAgreeChange: (callback: (agree: boolean) => void) => void,
  offPrivacyAgreeChange: (callback: (agree: boolean) => void) => void,
  getWindowStage: () => window__default.WindowStage
}
