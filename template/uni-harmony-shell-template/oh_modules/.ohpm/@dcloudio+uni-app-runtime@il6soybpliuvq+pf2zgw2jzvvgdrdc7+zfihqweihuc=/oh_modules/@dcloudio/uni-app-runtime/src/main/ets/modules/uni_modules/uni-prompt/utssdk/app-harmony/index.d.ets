import { IUniError, UTSObject, string } from "@dcloudio/uni-app-framework";
type PromptErrorCode = 1 | 1001;
interface IPromptError extends IUniError {
    errCode: PromptErrorCode;
}
declare class ShowToastSuccess extends UTSObject {
}
type ShowToastFail = IPromptError;
type ShowToastSuccessCallback = (res: ShowToastSuccess) => void;
type ShowToastFailCallback = (res: ShowToastFail) => void;
type ShowToastCompleteCallback = (res: Object) => void;
type Icon = "success" | "error" | "fail" | "exception" | "loading" | "none";
type ShowToastPosition = "top" | "center" | "bottom";
declare class ShowToastOptions extends UTSObject {
    title: string;
    icon: Icon | null;
    image: string.ImageURIString | null;
    mask: boolean | null;
    duration: number | null;
    position: ShowToastPosition | null;
    success: ShowToastSuccessCallback | null;
    fail: ShowToastFailCallback | null;
    complete: ShowToastCompleteCallback | null;
}
type ShowToast = (options: ShowToastOptions) => void;
type HideToast = () => void;
declare class ShowLoadingSuccess extends UTSObject {
}
type ShowLoadingFail = IPromptError;
type ShowLoadingSuccessCallback = (res: ShowLoadingSuccess) => void;
type ShowLoadingFailCallback = (res: ShowLoadingFail) => void;
type ShowLoadingCompleteCallback = (res: Object) => void;
declare class ShowLoadingOptions extends UTSObject {
    title: string;
    mask: boolean | null;
    success: ShowLoadingSuccessCallback | null;
    fail: ShowLoadingFailCallback | null;
    complete: ShowLoadingCompleteCallback | null;
}
type ShowLoading = (options: ShowLoadingOptions) => void;
type HideLoading = () => void;
declare class ShowModalSuccess extends UTSObject {
    confirm: boolean;
    cancel: boolean;
    content: string | null;
}
type ShowModalFail = IPromptError;
type ShowModalSuccessCallback = (res: ShowModalSuccess) => void;
type ShowModalFailCallback = (res: ShowModalFail) => void;
type ShowModalCompleteCallback = (res: Object) => void;
declare class ShowModalOptions extends UTSObject {
    title: string | null;
    content: string | null;
    showCancel: boolean | null;
    cancelText: string | null;
    cancelColor: string.ColorString | null;
    confirmText: string | null;
    confirmColor: string.ColorString | null;
    editable: boolean | null;
    placeholderText: string | null;
    success: ShowModalSuccessCallback | null;
    fail: ShowModalFailCallback | null;
    complete: ShowModalCompleteCallback | null;
}
type ShowModal = (options: ShowModalOptions) => void;
declare class ShowActionSheetSuccess extends UTSObject {
    tapIndex: number;
}
declare class Popover extends UTSObject {
    top: number;
    left: number;
    width: number;
    height: number;
}
type ShowActionSheetFail = IPromptError;
type ShowActionSheetSuccessCallback = (res: ShowActionSheetSuccess) => void;
type ShowActionSheetFailCallback = (res: ShowActionSheetFail) => void;
type ShowActionSheetCompleteCallback = (res: Object) => void;
declare class ShowActionSheetOptions extends UTSObject {
    title: string | null;
    alertText: string | null;
    itemList: string[];
    itemColor: string.ColorString | null;
    popover: Popover | null;
    success: ShowActionSheetSuccessCallback | null;
    fail: ShowActionSheetFailCallback | null;
    complete: ShowActionSheetCompleteCallback | null;
}
type ShowActionSheet = (options: ShowActionSheetOptions) => void;
declare const showToast: ShowToast;
declare const hideToast: HideToast;
declare const showModal: ShowModal;
declare const showActionSheet: ShowActionSheet;
declare const showLoading: ShowLoading;
declare const hideLoading: HideLoading;
export { showToast as showToast, hideToast as hideToast };
export { showModal as showModal };
export { showActionSheet as showActionSheet };
export { showLoading as showLoading, hideLoading as hideLoading };
export { ShowLoading as ShowLoading, ShowLoadingOptions as ShowLoadingOptions, ShowLoadingSuccess as ShowLoadingSuccess, ShowLoadingFail as ShowLoadingFail, HideLoading as HideLoading, ShowModal as ShowModal, ShowModalOptions as ShowModalOptions, ShowModalSuccess as ShowModalSuccess, ShowModalFail as ShowModalFail, ShowActionSheet as ShowActionSheet, ShowActionSheetOptions as ShowActionSheetOptions, ShowActionSheetSuccess as ShowActionSheetSuccess, ShowActionSheetFail as ShowActionSheetFail, Popover as Popover, ShowActionSheetCompleteCallback as ShowActionSheetCompleteCallback, ShowActionSheetFailCallback as ShowActionSheetFailCallback, ShowActionSheetSuccessCallback as ShowActionSheetSuccessCallback, ShowLoadingCompleteCallback as ShowLoadingCompleteCallback, ShowLoadingFailCallback as ShowLoadingFailCallback, ShowLoadingSuccessCallback as ShowLoadingSuccessCallback, ShowModalCompleteCallback as ShowModalCompleteCallback, ShowModalFailCallback as ShowModalFailCallback, ShowModalSuccessCallback as ShowModalSuccessCallback };
export { HideToast as HideToast, IPromptError as IPromptError, Icon as Icon, PromptErrorCode as PromptErrorCode, ShowToast as ShowToast, ShowToastCompleteCallback as ShowToastCompleteCallback, ShowToastFail as ShowToastFail, ShowToastFailCallback as ShowToastFailCallback, ShowToastOptions as ShowToastOptions, ShowToastPosition as ShowToastPosition, ShowToastSuccess as ShowToastSuccess, ShowToastSuccessCallback as ShowToastSuccessCallback };
