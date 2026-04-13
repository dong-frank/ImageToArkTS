import AbilityConstant from "@ohos.app.ability.AbilityConstant";
import { Configuration as Configuration } from "@ohos.app.ability.Configuration";
import UIAbility from "@ohos.app.ability.UIAbility";
import Want from "@ohos.app.ability.Want";
import window from '@ohos.window';
import '@dcloudio/uni-app-harmony';
import '@dcloudio/uni-app-modules';
import './WebViewBuilder';
import './MapBuilder';
import './PickerBuilder';
import './AdBuilder';
import { IInitConfig } from './types';
export default class EntryAbility extends UIAbility {
    constructor(appId: string, config?: IInitConfig);
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void;
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void;
    onShare(wantParam: Record<string, Object>): void;
    onWindowStageCreate(windowStage: window.WindowStage): void;
    onConfigurationUpdate(newConfig: Configuration): void;
}
