import { BusinessError } from '@kit.BasicServicesKit';
import { UTSObject, UniError, ApiOptions, ProtocolOptions, defineAsyncApi, ApiExecutor, UTSHarmony } from "@dcloudio/uni-app-framework";
import harmonyWindow from '@ohos.window';
type SetScreenBrightness = (options: SetScreenBrightnessOptions) => void;
class SetScreenBrightnessSuccess extends UTSObject {
}
type SetScreenBrightnessSuccessCallback = (result: SetScreenBrightnessSuccess) => void;
type SetScreenBrightnessFail = UniError;
type SetScreenBrightnessFailCallback = (result: SetScreenBrightnessFail) => void;
type SetScreenBrightnessComplete = Object;
type SetScreenBrightnessCompleteCallback = (result: SetScreenBrightnessComplete) => void;
class SetScreenBrightnessOptions extends UTSObject {
    value!: number;
    success: SetScreenBrightnessSuccessCallback | null = null;
    fail: SetScreenBrightnessFailCallback | null = null;
    complete: SetScreenBrightnessCompleteCallback | null = null;
}
type GetScreenBrightness = (options: GetScreenBrightnessOptions) => void;
class GetScreenBrightnessSuccess extends UTSObject {
    value!: number;
}
type GetScreenBrightnessSuccessCallback = (result: GetScreenBrightnessSuccess) => void;
type GetScreenBrightnessFail = UniError;
type GetScreenBrightnessFailCallback = (result: GetScreenBrightnessFail) => void;
type GetScreenBrightnessComplete = Object;
type GetScreenBrightnessCompleteCallback = (result: GetScreenBrightnessComplete) => void;
class GetScreenBrightnessOptions extends UTSObject {
    success: GetScreenBrightnessSuccessCallback | null = null;
    fail: GetScreenBrightnessFailCallback | null = null;
    complete: GetScreenBrightnessCompleteCallback | null = null;
}
type SetKeepScreenOn = (options: SetKeepScreenOnOptions) => void;
class SetKeepScreenOnSuccess extends UTSObject {
    errMsg!: string;
}
type SetKeepScreenOnSuccessCallback = (result: SetKeepScreenOnSuccess) => void;
type SetKeepScreenOnFail = UniError;
type SetKeepScreenOnFailCallback = (result: SetKeepScreenOnFail) => void;
type SetKeepScreenOnComplete = Object;
type SetKeepScreenOnCompleteCallback = (result: SetKeepScreenOnComplete) => void;
class SetKeepScreenOnOptions extends UTSObject {
    keepScreenOn!: Boolean;
    success: SetScreenBrightnessSuccessCallback | null = null;
    fail: SetScreenBrightnessFailCallback | null = null;
    complete: SetScreenBrightnessCompleteCallback | null = null;
}
const API_SET_SCREEN_BRIGHTNESS = 'setScreenBrightness';
const API_GET_SCREEN_BRIGHTNESS = 'getScreenBrightness';
const API_SET_KEEP_SECREEN_ON = 'setKeepScreenOn';
const SetScreenBrightnessApiOptions: ApiOptions<SetScreenBrightnessOptions> = {
    formatArgs: new Map<string, Function>([
        [
            'value',
            (value: number, params: SetScreenBrightnessOptions)=>{
                if (value < 0) {
                    params.value = 0;
                }
                if (value > 1) {
                    params.value = 1;
                }
            }
        ]
    ])
};
const SetScreenBrightnessApiProtocol = new Map<string, ProtocolOptions>([
    [
        'value',
        {
            type: 'number',
            required: true
        }
    ]
]);
const setScreenBrightness: SetScreenBrightness = defineAsyncApi<SetScreenBrightnessOptions, SetScreenBrightnessSuccess>(API_SET_SCREEN_BRIGHTNESS, (options: SetScreenBrightnessOptions, res: ApiExecutor<SetScreenBrightnessSuccess>)=>{
    const windowStage: harmonyWindow.WindowStage = UTSHarmony.getWindowStage() as harmonyWindow.WindowStage;
    windowStage.getMainWindow((err: BusinessError, window)=>{
        const errCode: number = err.code;
        if (errCode) {
            res.reject(`setScreenBrightness:fail. code: ${err.code}, message: ${err.message}`);
            return;
        }
        let brightness: number = options.value;
        try {
            window.setWindowBrightness(brightness, (err: BusinessError)=>{
                const errCode: number = err.code;
                if (errCode) {
                    res.reject(`setScreenBrightness:fail. code: ${err.code}, message: ${err.message}`);
                    return;
                }
                res.resolve();
            });
        } catch (exception) {
            res.reject(`setScreenBrightness:fail. code: ${exception.code}, message: ${exception.message}`);
        }
    });
}, SetScreenBrightnessApiProtocol, SetScreenBrightnessApiOptions) as SetScreenBrightness;
function formatOutputForDotNumber(num: number, n: number): number {
    if (isNaN(num)) {
        return -1;
    }
    const factor = Math.pow(10, n);
    const rounded = Math.round(num * factor) / factor;
    return rounded;
}
const getScreenBrightness: GetScreenBrightness = defineAsyncApi<GetScreenBrightnessOptions, GetScreenBrightnessSuccess>(API_GET_SCREEN_BRIGHTNESS, (_: GetScreenBrightnessOptions, res: ApiExecutor<GetScreenBrightnessSuccess>)=>{
    const windowStage: harmonyWindow.WindowStage = UTSHarmony.getWindowStage() as harmonyWindow.WindowStage;
    windowStage.getMainWindow((err: BusinessError, window)=>{
        const errCode: number = err.code;
        if (errCode) {
            res.reject(`setScreenBrightness:fail. code: ${err.code}, message: ${err.message}`);
            return;
        }
        try {
            let brightness = window.getWindowProperties().brightness;
            res.resolve({
                value: formatOutputForDotNumber(brightness, 2)
            } as GetScreenBrightnessSuccess);
        } catch (exception) {
            res.reject(`setScreenBrightness:fail. code: ${exception.code}, message: ${exception.message}`);
        }
    });
}) as GetScreenBrightness;
const setKeepScreenOn: SetKeepScreenOn = defineAsyncApi<SetKeepScreenOnOptions, SetKeepScreenOnSuccess>(API_SET_KEEP_SECREEN_ON, (option: SetKeepScreenOnOptions, res: ApiExecutor<SetKeepScreenOnSuccess>)=>{
    const windowStage: harmonyWindow.WindowStage = UTSHarmony.getWindowStage() as harmonyWindow.WindowStage;
    windowStage.getMainWindow((err: BusinessError, window)=>{
        const errCode: number = err.code;
        if (errCode) {
            res.reject(`setKeepScreenOn:fail. code: ${err.code}, message: ${err.message}`);
            return;
        }
        try {
            window.setWindowKeepScreenOn(Boolean(option.keepScreenOn), (err: BusinessError)=>{
                const errCode: number = err.code;
                if (errCode) {
                    res.reject(`setKeepScreenOn:fail. code: ${err.code}, message: ${err.message}`);
                    return;
                }
                res.resolve();
            });
        } catch (exception) {
            res.reject(`setScreenBrightness:fail. code: ${exception.code}, message: ${exception.message}`);
        }
    });
}) as SetKeepScreenOn;
export { GetScreenBrightness as GetScreenBrightness, GetScreenBrightnessComplete as GetScreenBrightnessComplete, GetScreenBrightnessCompleteCallback as GetScreenBrightnessCompleteCallback, GetScreenBrightnessFail as GetScreenBrightnessFail, GetScreenBrightnessFailCallback as GetScreenBrightnessFailCallback, GetScreenBrightnessOptions as GetScreenBrightnessOptions, GetScreenBrightnessSuccess as GetScreenBrightnessSuccess, GetScreenBrightnessSuccessCallback as GetScreenBrightnessSuccessCallback, SetKeepScreenOn as SetKeepScreenOn, SetKeepScreenOnComplete as SetKeepScreenOnComplete, SetKeepScreenOnCompleteCallback as SetKeepScreenOnCompleteCallback, SetKeepScreenOnFail as SetKeepScreenOnFail, SetKeepScreenOnFailCallback as SetKeepScreenOnFailCallback, SetKeepScreenOnOptions as SetKeepScreenOnOptions, SetKeepScreenOnSuccess as SetKeepScreenOnSuccess, SetKeepScreenOnSuccessCallback as SetKeepScreenOnSuccessCallback, SetScreenBrightness as SetScreenBrightness, SetScreenBrightnessComplete as SetScreenBrightnessComplete, SetScreenBrightnessCompleteCallback as SetScreenBrightnessCompleteCallback, SetScreenBrightnessFail as SetScreenBrightnessFail, SetScreenBrightnessFailCallback as SetScreenBrightnessFailCallback, SetScreenBrightnessOptions as SetScreenBrightnessOptions, SetScreenBrightnessSuccess as SetScreenBrightnessSuccess, SetScreenBrightnessSuccessCallback as SetScreenBrightnessSuccessCallback };
export { setScreenBrightness as setScreenBrightness };
export { getScreenBrightness as getScreenBrightness };
export { setKeepScreenOn as setKeepScreenOn };
