import { ComponentContent as ComponentContent } from "@ohos.arkui.node";
import promptAction from "@ohos.promptAction";
import { UIContext as UIContext } from "@ohos.arkui.UIContext";
export declare class PromptAction {
    static ctx: UIContext;
    static contentNode: ComponentContent<Object>;
    static options: promptAction.BaseDialogOptions;
    static setContext(context: UIContext): void;
    static setContentNode(node: ComponentContent<Object>): void;
    static setOptions(options: promptAction.BaseDialogOptions): void;
    static openDialog(): void;
    static closeDialog(): void;
    static updateDialog(options: promptAction.BaseDialogOptions): void;
}
interface IPreviewImageOptions {
    urls: string[];
    current?: string;
    showmenu?: boolean;
}
export declare function previewImage(options: IPreviewImageOptions, page: Object): void;
export declare function closePreviewImage(): void;
export {};
