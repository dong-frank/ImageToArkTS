import { UTSObject, UniError } from "@dcloudio/uni-app-framework";
type SetScreenBrightness = (options: SetScreenBrightnessOptions) => void;
declare class SetScreenBrightnessSuccess extends UTSObject {
}
type SetScreenBrightnessSuccessCallback = (result: SetScreenBrightnessSuccess) => void;
type SetScreenBrightnessFail = UniError;
type SetScreenBrightnessFailCallback = (result: SetScreenBrightnessFail) => void;
type SetScreenBrightnessComplete = Object;
type SetScreenBrightnessCompleteCallback = (result: SetScreenBrightnessComplete) => void;
declare class SetScreenBrightnessOptions extends UTSObject {
    value: number;
    success: SetScreenBrightnessSuccessCallback | null;
    fail: SetScreenBrightnessFailCallback | null;
    complete: SetScreenBrightnessCompleteCallback | null;
}
type GetScreenBrightness = (options: GetScreenBrightnessOptions) => void;
declare class GetScreenBrightnessSuccess extends UTSObject {
    value: number;
}
type GetScreenBrightnessSuccessCallback = (result: GetScreenBrightnessSuccess) => void;
type GetScreenBrightnessFail = UniError;
type GetScreenBrightnessFailCallback = (result: GetScreenBrightnessFail) => void;
type GetScreenBrightnessComplete = Object;
type GetScreenBrightnessCompleteCallback = (result: GetScreenBrightnessComplete) => void;
declare class GetScreenBrightnessOptions extends UTSObject {
    success: GetScreenBrightnessSuccessCallback | null;
    fail: GetScreenBrightnessFailCallback | null;
    complete: GetScreenBrightnessCompleteCallback | null;
}
type SetKeepScreenOn = (options: SetKeepScreenOnOptions) => void;
declare class SetKeepScreenOnSuccess extends UTSObject {
    errMsg: string;
}
type SetKeepScreenOnSuccessCallback = (result: SetKeepScreenOnSuccess) => void;
type SetKeepScreenOnFail = UniError;
type SetKeepScreenOnFailCallback = (result: SetKeepScreenOnFail) => void;
type SetKeepScreenOnComplete = Object;
type SetKeepScreenOnCompleteCallback = (result: SetKeepScreenOnComplete) => void;
declare class SetKeepScreenOnOptions extends UTSObject {
    keepScreenOn: Boolean;
    success: SetScreenBrightnessSuccessCallback | null;
    fail: SetScreenBrightnessFailCallback | null;
    complete: SetScreenBrightnessCompleteCallback | null;
}
declare const setScreenBrightness: SetScreenBrightness;
declare const getScreenBrightness: GetScreenBrightness;
declare const setKeepScreenOn: SetKeepScreenOn;
export { GetScreenBrightness as GetScreenBrightness, GetScreenBrightnessComplete as GetScreenBrightnessComplete, GetScreenBrightnessCompleteCallback as GetScreenBrightnessCompleteCallback, GetScreenBrightnessFail as GetScreenBrightnessFail, GetScreenBrightnessFailCallback as GetScreenBrightnessFailCallback, GetScreenBrightnessOptions as GetScreenBrightnessOptions, GetScreenBrightnessSuccess as GetScreenBrightnessSuccess, GetScreenBrightnessSuccessCallback as GetScreenBrightnessSuccessCallback, SetKeepScreenOn as SetKeepScreenOn, SetKeepScreenOnComplete as SetKeepScreenOnComplete, SetKeepScreenOnCompleteCallback as SetKeepScreenOnCompleteCallback, SetKeepScreenOnFail as SetKeepScreenOnFail, SetKeepScreenOnFailCallback as SetKeepScreenOnFailCallback, SetKeepScreenOnOptions as SetKeepScreenOnOptions, SetKeepScreenOnSuccess as SetKeepScreenOnSuccess, SetKeepScreenOnSuccessCallback as SetKeepScreenOnSuccessCallback, SetScreenBrightness as SetScreenBrightness, SetScreenBrightnessComplete as SetScreenBrightnessComplete, SetScreenBrightnessCompleteCallback as SetScreenBrightnessCompleteCallback, SetScreenBrightnessFail as SetScreenBrightnessFail, SetScreenBrightnessFailCallback as SetScreenBrightnessFailCallback, SetScreenBrightnessOptions as SetScreenBrightnessOptions, SetScreenBrightnessSuccess as SetScreenBrightnessSuccess, SetScreenBrightnessSuccessCallback as SetScreenBrightnessSuccessCallback };
export { setScreenBrightness as setScreenBrightness };
export { getScreenBrightness as getScreenBrightness };
export { setKeepScreenOn as setKeepScreenOn };
