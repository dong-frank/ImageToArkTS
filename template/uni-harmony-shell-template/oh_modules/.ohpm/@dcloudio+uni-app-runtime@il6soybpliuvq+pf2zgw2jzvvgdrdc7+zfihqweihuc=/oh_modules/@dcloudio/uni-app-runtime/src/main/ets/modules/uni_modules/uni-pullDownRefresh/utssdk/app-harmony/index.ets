import { IUniError, UTSObject, AsyncApiSuccessResult, AsyncApiResult, defineAsyncApi, defineSyncApi } from "@dcloudio/uni-app-framework";
import { startPullDownRefresh as internalStartPullDownRefresh, stopPullDownRefresh as internalStopPullDownRefresh } from "@dcloudio/uni-app-framework";
type PullDownRefreshErrorCode = 4;
interface StartPullDownRefreshFail extends IUniError {
    errCode: PullDownRefreshErrorCode;
}
class StartPullDownRefreshOptions extends UTSObject {
    success: StartPullDownRefreshSuccessCallback | null = null;
    fail: StartPullDownRefreshFailCallback | null = null;
    complete: StartPullDownRefreshCompleteCallback | null = null;
}
type StartPullDownRefreshSuccess = AsyncApiSuccessResult;
type StartPullDownRefreshSuccessCallback = (result: StartPullDownRefreshSuccess) => void;
type StartPullDownRefreshFailCallback = (result: StartPullDownRefreshFail) => void;
type StartPullDownRefreshComplete = AsyncApiResult;
type StartPullDownRefreshCompleteCallback = (result: StartPullDownRefreshComplete) => void;
type StartPullDownRefresh = (options: StartPullDownRefreshOptions) => void;
type StopPullDownRefresh = () => void;
const API_START_PULL_DOWN_REFRESH = 'startPullDownRefresh';
const API_STOP_PULL_DOWN_REFRESH = 'stopPullDownRefresh';
const startPullDownRefresh = defineAsyncApi<StartPullDownRefreshOptions, StartPullDownRefreshSuccess>(API_START_PULL_DOWN_REFRESH, (_, res)=>{
    internalStartPullDownRefresh();
    res.resolve();
}) as StartPullDownRefresh;
const stopPullDownRefresh = defineSyncApi<void>(API_STOP_PULL_DOWN_REFRESH, ()=>{
    internalStopPullDownRefresh();
}) as StopPullDownRefresh;
export { PullDownRefreshErrorCode as PullDownRefreshErrorCode, StartPullDownRefresh as StartPullDownRefresh, StartPullDownRefreshComplete as StartPullDownRefreshComplete, StartPullDownRefreshCompleteCallback as StartPullDownRefreshCompleteCallback, StartPullDownRefreshFail as StartPullDownRefreshFail, StartPullDownRefreshFailCallback as StartPullDownRefreshFailCallback, StartPullDownRefreshOptions as StartPullDownRefreshOptions, StartPullDownRefreshSuccess as StartPullDownRefreshSuccess, StartPullDownRefreshSuccessCallback as StartPullDownRefreshSuccessCallback, StopPullDownRefresh as StopPullDownRefresh };
export { startPullDownRefresh as startPullDownRefresh };
export { stopPullDownRefresh as stopPullDownRefresh };
