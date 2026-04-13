import { IUniError, UTSObject, AsyncApiSuccessResult, AsyncApiResult } from "@dcloudio/uni-app-framework";
type PullDownRefreshErrorCode = 4;
interface StartPullDownRefreshFail extends IUniError {
    errCode: PullDownRefreshErrorCode;
}
declare class StartPullDownRefreshOptions extends UTSObject {
    success: StartPullDownRefreshSuccessCallback | null;
    fail: StartPullDownRefreshFailCallback | null;
    complete: StartPullDownRefreshCompleteCallback | null;
}
type StartPullDownRefreshSuccess = AsyncApiSuccessResult;
type StartPullDownRefreshSuccessCallback = (result: StartPullDownRefreshSuccess) => void;
type StartPullDownRefreshFailCallback = (result: StartPullDownRefreshFail) => void;
type StartPullDownRefreshComplete = AsyncApiResult;
type StartPullDownRefreshCompleteCallback = (result: StartPullDownRefreshComplete) => void;
type StartPullDownRefresh = (options: StartPullDownRefreshOptions) => void;
type StopPullDownRefresh = () => void;
declare const startPullDownRefresh: StartPullDownRefresh;
declare const stopPullDownRefresh: StopPullDownRefresh;
export { PullDownRefreshErrorCode as PullDownRefreshErrorCode, StartPullDownRefresh as StartPullDownRefresh, StartPullDownRefreshComplete as StartPullDownRefreshComplete, StartPullDownRefreshCompleteCallback as StartPullDownRefreshCompleteCallback, StartPullDownRefreshFail as StartPullDownRefreshFail, StartPullDownRefreshFailCallback as StartPullDownRefreshFailCallback, StartPullDownRefreshOptions as StartPullDownRefreshOptions, StartPullDownRefreshSuccess as StartPullDownRefreshSuccess, StartPullDownRefreshSuccessCallback as StartPullDownRefreshSuccessCallback, StopPullDownRefresh as StopPullDownRefresh };
export { startPullDownRefresh as startPullDownRefresh };
export { stopPullDownRefresh as stopPullDownRefresh };
