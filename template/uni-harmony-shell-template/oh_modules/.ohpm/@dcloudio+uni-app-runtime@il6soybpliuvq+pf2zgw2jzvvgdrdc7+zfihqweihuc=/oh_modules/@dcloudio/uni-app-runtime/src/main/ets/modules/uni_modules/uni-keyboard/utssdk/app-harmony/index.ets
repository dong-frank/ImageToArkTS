import inputMethod from '@ohos.inputMethod';
import { UTSObject, defineAsyncApi, ApiExecutor } from "@dcloudio/uni-app-framework";
const API_HIDE_KEYBOARD = 'hideKeyboard';
class HideKeyboardSuccess extends UTSObject {
}
class HideKeyboardFail extends UTSObject {
}
type HideKeyboardSuccessCallback = (res: HideKeyboardSuccess) => void;
type HideKeyboardFailCallback = (res: HideKeyboardFail) => void;
type HideKeyboardCompleteCallback = (res: Object) => void;
class HideKeyboardOptions extends UTSObject {
    success: HideKeyboardSuccessCallback | null = null;
    fail: HideKeyboardFailCallback | null = null;
    complete: HideKeyboardCompleteCallback | null = null;
}
type OnKeyboardHeightChangeCallback = (res: OnKeyboardHeightChangeCallbackResult) => void;
class OnKeyboardHeightChangeCallbackResult extends UTSObject {
    height!: number;
}
type HideKeyboard = (options?: HideKeyboardOptions | null) => void;
type OnKeyboardHeightChange = (callback: OnKeyboardHeightChangeCallback) => number;
type OffKeyboardHeightChange = (id?: number | null) => void;
const hideKeyboard: HideKeyboard = defineAsyncApi<HideKeyboardOptions, HideKeyboardSuccess>(API_HIDE_KEYBOARD, (options: HideKeyboardOptions, exec: ApiExecutor<HideKeyboardSuccess>)=>{
    inputMethod.getController().hideTextInput().then(()=>{
        exec.resolve();
    }, (err: Error)=>{
        exec.reject(err.message);
    });
}) as HideKeyboard;
export { HideKeyboard as HideKeyboard, HideKeyboardCompleteCallback as HideKeyboardCompleteCallback, HideKeyboardFail as HideKeyboardFail, HideKeyboardFailCallback as HideKeyboardFailCallback, HideKeyboardOptions as HideKeyboardOptions, HideKeyboardSuccess as HideKeyboardSuccess, HideKeyboardSuccessCallback as HideKeyboardSuccessCallback, OffKeyboardHeightChange as OffKeyboardHeightChange, OnKeyboardHeightChange as OnKeyboardHeightChange, OnKeyboardHeightChangeCallback as OnKeyboardHeightChangeCallback, OnKeyboardHeightChangeCallbackResult as OnKeyboardHeightChangeCallbackResult };
export { hideKeyboard as hideKeyboard };
