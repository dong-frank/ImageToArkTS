import { IUniError, UTSObject, string, ProtocolOptions, ApiOptions, defineAsyncApi, ApiExecutor, UTSHarmony } from "@dcloudio/uni-app-framework";
import { ShowLoadingOptions as ShowLoadingOptionsNative, showLoading as showLoadingNative, hideLoading as hideLoadingNative } from "./loading-native";
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
import { promptAction, PromptAction } from '@kit.ArkUI';
import promptAction__1 from '@ohos.promptAction';
type PromptErrorCode = 1 | 1001;
interface IPromptError extends IUniError {
    errCode: PromptErrorCode;
}
class ShowToastSuccess extends UTSObject {
}
type ShowToastFail = IPromptError;
type ShowToastSuccessCallback = (res: ShowToastSuccess) => void;
type ShowToastFailCallback = (res: ShowToastFail) => void;
type ShowToastCompleteCallback = (res: Object) => void;
type Icon = "success" | "error" | "fail" | "exception" | "loading" | "none";
type ShowToastPosition = "top" | "center" | "bottom";
class ShowToastOptions extends UTSObject {
    title!: string;
    icon: Icon | null = null;
    image: string.ImageURIString | null = null;
    mask: boolean | null = null;
    duration: number | null = null;
    position: ShowToastPosition | null = null;
    success: ShowToastSuccessCallback | null = null;
    fail: ShowToastFailCallback | null = null;
    complete: ShowToastCompleteCallback | null = null;
}
type ShowToast = (options: ShowToastOptions) => void;
type HideToast = () => void;
class ShowLoadingSuccess extends UTSObject {
}
type ShowLoadingFail = IPromptError;
type ShowLoadingSuccessCallback = (res: ShowLoadingSuccess) => void;
type ShowLoadingFailCallback = (res: ShowLoadingFail) => void;
type ShowLoadingCompleteCallback = (res: Object) => void;
class ShowLoadingOptions extends UTSObject {
    title!: string;
    mask: boolean | null = null;
    success: ShowLoadingSuccessCallback | null = null;
    fail: ShowLoadingFailCallback | null = null;
    complete: ShowLoadingCompleteCallback | null = null;
}
type ShowLoading = (options: ShowLoadingOptions) => void;
type HideLoading = () => void;
class ShowModalSuccess extends UTSObject {
    confirm!: boolean;
    cancel!: boolean;
    content: string | null = null;
}
type ShowModalFail = IPromptError;
type ShowModalSuccessCallback = (res: ShowModalSuccess) => void;
type ShowModalFailCallback = (res: ShowModalFail) => void;
type ShowModalCompleteCallback = (res: Object) => void;
class ShowModalOptions extends UTSObject {
    title: string | null = null;
    content: string | null = null;
    showCancel: boolean | null = true;
    cancelText: string | null = null;
    cancelColor: string.ColorString | null = null;
    confirmText: string | null = null;
    confirmColor: string.ColorString | null = null;
    editable: boolean | null = false;
    placeholderText: string | null = null;
    success: ShowModalSuccessCallback | null = null;
    fail: ShowModalFailCallback | null = null;
    complete: ShowModalCompleteCallback | null = null;
}
type ShowModal = (options: ShowModalOptions) => void;
class ShowActionSheetSuccess extends UTSObject {
    tapIndex!: number;
}
class Popover extends UTSObject {
    top!: number;
    left!: number;
    width!: number;
    height!: number;
}
type ShowActionSheetFail = IPromptError;
type ShowActionSheetSuccessCallback = (res: ShowActionSheetSuccess) => void;
type ShowActionSheetFailCallback = (res: ShowActionSheetFail) => void;
type ShowActionSheetCompleteCallback = (res: Object) => void;
class ShowActionSheetOptions extends UTSObject {
    title: string | null = null;
    alertText: string | null = null;
    itemList!: string[];
    itemColor: string.ColorString | null = null;
    popover: Popover | null = null;
    success: ShowActionSheetSuccessCallback | null = null;
    fail: ShowActionSheetFailCallback | null = null;
    complete: ShowActionSheetCompleteCallback | null = null;
}
type ShowActionSheet = (options: ShowActionSheetOptions) => void;
const API_SHOW_TOAST = 'showToast';
const ShowToastProtocol = new Map<string, ProtocolOptions>([
    [
        'title',
        {
            type: 'string',
            required: true
        }
    ],
    [
        'duration',
        {
            type: 'number'
        }
    ]
]);
const ShowToastApiOptions: ApiOptions<ShowToastOptions> = {
    formatArgs: new Map<string, Function | string | number>([
        [
            "title",
            ""
        ],
        [
            "duration",
            1500
        ]
    ])
};
const API_HIDE_TOAST = 'hideToast';
const PRIMARY_COLOR = '#007aff';
const API_SHOW_MODAL = 'showModal';
const ShowModalProtocol = new Map<string, ProtocolOptions>([
    [
        "title",
        {
            type: "string"
        }
    ],
    [
        "content",
        {
            type: "string"
        }
    ],
    [
        "showCancel",
        {
            type: "boolean"
        }
    ],
    [
        "cancelText",
        {
            type: "string"
        }
    ],
    [
        "cancelColor",
        {
            type: "string"
        }
    ],
    [
        "confirmText",
        {
            type: "string"
        }
    ],
    [
        "confirmColor",
        {
            type: "string"
        }
    ]
]);
const ShowModalApiOptions: ApiOptions<ShowModalOptions> = {
    formatArgs: new Map<string, Function | string | boolean>([
        [
            "title",
            ""
        ],
        [
            "content",
            ""
        ],
        [
            "placeholderText",
            ""
        ],
        [
            "showCancel",
            true
        ],
        [
            "editable",
            false
        ],
        [
            "cancelColor",
            "#000000"
        ],
        [
            "confirmColor",
            PRIMARY_COLOR
        ]
    ])
};
const API_SHOW_ACTION_SHEET = 'showActionSheet';
const ShowActionSheetProtocol = new Map<string, ProtocolOptions>([
    [
        "title",
        {
            type: "string"
        }
    ],
    [
        "itemList",
        {
            type: "array",
            required: true
        }
    ],
    [
        "itemColor",
        {
            type: "string"
        }
    ]
]);
const ShowActionSheetApiOptions: ApiOptions<ShowActionSheetOptions> = {
    formatArgs: new Map<string, string>([
        [
            "itemColor",
            "#000000"
        ]
    ])
};
const API_SHOW_LOADING = 'showLoading';
const ShowLoadingProtocol = new Map<string, ProtocolOptions>([
    [
        'title',
        {
            type: 'string'
        }
    ],
    [
        'mask',
        {
            type: 'boolean'
        }
    ]
]);
const ShowLoadingApiOptions: ApiOptions<ShowLoadingOptions> = {
    formatArgs: new Map<string, Function | string | boolean>([
        [
            "title",
            ""
        ],
        [
            "mask",
            false
        ]
    ])
};
const API_HIDE_LOADING = 'hideLoading';
let openToastPromiseTimer: number | null = null;
let openToastPromise: Promise<number> | null = null;
const showToast: ShowToast = defineAsyncApi<ShowToastOptions, ShowToastSuccess>(API_SHOW_TOAST, (options: ShowToastOptions, res: ApiExecutor<ShowToastSuccess>)=>{
    try {
        const showToastOptions: promptAction.ShowToastOptions = {
            message: options.title,
            duration: options.duration == null ? undefined : options.duration,
            alignment: Alignment.Center
        };
        if (options.position) {
            switch(options.position){
                case 'top':
                    showToastOptions.alignment = Alignment.Top;
                    break;
                case 'bottom':
                    showToastOptions.alignment = Alignment.Bottom;
                    break;
            }
        }
        const window = UTSHarmony.getCurrentWindow();
        const promptActionIns = window.getUIContext().getPromptAction() as PromptAction;
        if (deviceInfo.sdkApiVersion >= 18) {
            if (openToastPromiseTimer != null) {
                clearTimeout(openToastPromiseTimer);
                openToastPromiseTimer = null;
            }
            openToastPromise = promptActionIns.openToast(showToastOptions).then((id)=>{
                res.resolve({} as ShowToastSuccess);
                return id;
            }).catch((err: BusinessError)=>{
                res.reject(err.message);
                return 0;
            });
            openToastPromiseTimer = setTimeout(()=>{
                openToastPromiseTimer = null;
                openToastPromise = null;
            }, showToastOptions.duration ?? 1500);
        } else {
            promptActionIns.showToast(showToastOptions);
            res.resolve({} as ShowToastSuccess);
        }
    } catch (error) {
        let message = (error as BusinessError).message;
        res.reject(message);
    }
}, ShowToastProtocol, ShowToastApiOptions) as ShowToast;
const hideToast: HideToast = defineAsyncApi(API_HIDE_TOAST, (_, res: ApiExecutor<Object>)=>{
    if (deviceInfo.sdkApiVersion >= 18) {
        const window = UTSHarmony.getCurrentWindow();
        const promptActionIns = window.getUIContext().getPromptAction() as PromptAction;
        if (openToastPromiseTimer != null) {
            clearTimeout(openToastPromiseTimer);
            openToastPromiseTimer = null;
        }
        openToastPromise?.then((id)=>{
            promptActionIns.closeToast(id);
        }).finally(()=>{
            openToastPromise = null;
        });
    }
    res.resolve();
}) as HideToast;
const showModal: ShowModal = defineAsyncApi<ShowModalOptions, ShowModalSuccess>(API_SHOW_MODAL, async (args: ShowModalOptions, res: ApiExecutor<ShowModalSuccess>): Promise<void> =>{
    const modalRes = await new Promise<ShowModalSuccess>((resolve, reject)=>{
        const confirmButton: AlertDialogButtonOptions = {
            value: args.confirmText ?? '确定',
            fontColor: args.confirmColor! as string,
            action: ()=>{
                resolve({
                    "confirm": true
                } as ShowModalSuccess);
            }
        };
        const cancelButton: AlertDialogButtonOptions = {
            value: args.cancelText ?? '取消',
            fontColor: (args.cancelColor ?? '#000000') as string,
            action: ()=>{
                resolve({
                    "cancel": true
                } as ShowModalSuccess);
            }
        };
        const buttons: Array<AlertDialogButtonOptions> = [];
        if (args.showCancel) {
            buttons.push(cancelButton);
        }
        buttons.push(confirmButton);
        const window = UTSHarmony.getCurrentWindow();
        window.getUIContext().showAlertDialog({
            title: args.title ?? '',
            message: args.content ?? '',
            autoCancel: false,
            alignment: DialogAlignment.Center,
            buttons,
            cancel: ()=>{
                resolve({
                    'cancel': true
                } as ShowModalSuccess);
            }
        } as AlertDialogParamWithOptions);
    });
    if (modalRes.confirm) {
        modalRes.cancel = false;
    }
    if (modalRes.cancel) {
        modalRes.confirm = false;
    }
    modalRes.content = null;
    res.resolve(modalRes as ShowModalSuccess);
}, ShowModalProtocol, ShowModalApiOptions) as ShowModal;
const showActionSheet: ShowActionSheet = defineAsyncApi<ShowActionSheetOptions, ShowActionSheetSuccess>(API_SHOW_ACTION_SHEET, async (options: ShowActionSheetOptions, res: ApiExecutor<ShowActionSheetSuccess>): Promise<void> =>{
    const actionItemList = options.itemList.filter(Boolean);
    if (actionItemList.length === 0) {
        return;
    }
    type ActionMenuButtons = [promptAction__1.Button, promptAction__1.Button?, promptAction__1.Button?, promptAction__1.Button?, promptAction__1.Button?, promptAction__1.Button?];
    const actionMenuButtons: ActionMenuButtons = [
        {
            text: actionItemList[0],
            color: options.itemColor!
        }
    ];
    actionItemList.slice(1).forEach((item)=>{
        actionMenuButtons.push({
            text: item,
            color: options.itemColor!
        } as promptAction__1.Button);
    });
    const window = UTSHarmony.getCurrentWindow();
    window.getUIContext().getPromptAction().showActionMenu({
        title: options.title,
        buttons: actionMenuButtons
    } as promptAction__1.ActionMenuOptions).then((showACtionSheetRes)=>{
        res.resolve({
            tapIndex: showACtionSheetRes.index
        } as ShowActionSheetSuccess);
    }).catch((e: Error)=>{
        if (e.message === 'cancel') {
            res.reject('cancel');
            return;
        }
        res.reject(e.message);
    });
}, ShowActionSheetProtocol, ShowActionSheetApiOptions) as ShowActionSheet;
interface IHideLoadingOptions {
}
interface IHideLoadingSuccess {
}
const showLoading: ShowLoading = defineAsyncApi<ShowLoadingOptions, ShowLoadingSuccess>(API_SHOW_LOADING, async (options: ShowLoadingOptions, exec: ApiExecutor<ShowLoadingSuccess>): Promise<void> =>{
    const window = UTSHarmony.getCurrentWindow();
    const uiContext = window.getUIContext();
    showLoadingNative(uiContext, {
        title: options.title,
        mask: options.mask
    } as ShowLoadingOptionsNative);
    exec.resolve({} as ShowLoadingSuccess);
}, ShowLoadingProtocol, ShowLoadingApiOptions) as ShowLoading;
const hideLoading: HideLoading = defineAsyncApi<IHideLoadingOptions, IHideLoadingSuccess>(API_HIDE_LOADING, (options: IHideLoadingOptions, exec: ApiExecutor<IHideLoadingSuccess>)=>{
    const window = UTSHarmony.getCurrentWindow();
    const uiContext = window.getUIContext();
    hideLoadingNative(uiContext);
    exec.resolve({} as IHideLoadingSuccess);
}) as HideLoading;
export { showToast as showToast, hideToast as hideToast };
export { showModal as showModal };
export { showActionSheet as showActionSheet };
export { showLoading as showLoading, hideLoading as hideLoading };
export { ShowLoading as ShowLoading, ShowLoadingOptions as ShowLoadingOptions, ShowLoadingSuccess as ShowLoadingSuccess, ShowLoadingFail as ShowLoadingFail, HideLoading as HideLoading, ShowModal as ShowModal, ShowModalOptions as ShowModalOptions, ShowModalSuccess as ShowModalSuccess, ShowModalFail as ShowModalFail, ShowActionSheet as ShowActionSheet, ShowActionSheetOptions as ShowActionSheetOptions, ShowActionSheetSuccess as ShowActionSheetSuccess, ShowActionSheetFail as ShowActionSheetFail, Popover as Popover, ShowActionSheetCompleteCallback as ShowActionSheetCompleteCallback, ShowActionSheetFailCallback as ShowActionSheetFailCallback, ShowActionSheetSuccessCallback as ShowActionSheetSuccessCallback, ShowLoadingCompleteCallback as ShowLoadingCompleteCallback, ShowLoadingFailCallback as ShowLoadingFailCallback, ShowLoadingSuccessCallback as ShowLoadingSuccessCallback, ShowModalCompleteCallback as ShowModalCompleteCallback, ShowModalFailCallback as ShowModalFailCallback, ShowModalSuccessCallback as ShowModalSuccessCallback };
export { HideToast as HideToast, IPromptError as IPromptError, Icon as Icon, PromptErrorCode as PromptErrorCode, ShowToast as ShowToast, ShowToastCompleteCallback as ShowToastCompleteCallback, ShowToastFail as ShowToastFail, ShowToastFailCallback as ShowToastFailCallback, ShowToastOptions as ShowToastOptions, ShowToastPosition as ShowToastPosition, ShowToastSuccess as ShowToastSuccess, ShowToastSuccessCallback as ShowToastSuccessCallback };
