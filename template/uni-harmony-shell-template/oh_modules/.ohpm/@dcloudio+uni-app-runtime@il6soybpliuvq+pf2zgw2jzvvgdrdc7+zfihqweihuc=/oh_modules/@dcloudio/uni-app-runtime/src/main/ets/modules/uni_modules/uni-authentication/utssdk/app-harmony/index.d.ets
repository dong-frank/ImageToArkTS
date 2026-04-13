import { UTSObject, UniError } from "@dcloudio/uni-app-framework";
type StartSoterAuthentication = (options: StartSoterAuthenticationOptions) => void;
type SoterAuthMode = 'fingerPrint' | 'facial' | 'speech';
declare class StartSoterAuthenticationSuccess extends UTSObject {
    errCode: number;
    authMode: SoterAuthMode;
    resultJSON: string | null;
    resultJSONSignature: string | null;
    errMsg: string;
}
type StartSoterAuthenticationSuccessCallback = (result: StartSoterAuthenticationSuccess) => void;
type StartSoterAuthenticationFail = UniError;
type StartSoterAuthenticationFailCallback = (result: StartSoterAuthenticationFail) => void;
type StartSoterAuthenticationComplete = Object;
type StartSoterAuthenticationCompleteCallback = (result: StartSoterAuthenticationComplete) => void;
declare class StartSoterAuthenticationOptions extends UTSObject {
    requestAuthModes: SoterAuthMode[];
    challenge: string | null;
    authContent: string | null;
    success: StartSoterAuthenticationSuccessCallback | null;
    fail: StartSoterAuthenticationFailCallback | null;
    complete: StartSoterAuthenticationCompleteCallback | null;
}
type CheckIsSupportSoterAuthentication = (options: CheckIsSupportSoterAuthenticationOptions) => void;
declare class CheckIsSupportSoterAuthenticationSuccess extends UTSObject {
    supportMode: SoterAuthMode[];
    errMsg: string;
}
type CheckIsSupportSoterAuthenticationSuccessCallback = (result: CheckIsSupportSoterAuthenticationSuccess) => void;
type CheckIsSupportSoterAuthenticationFail = UniError;
type CheckIsSupportSoterAuthenticationFailCallback = (result: CheckIsSupportSoterAuthenticationFail) => void;
type CheckIsSupportSoterAuthenticationComplete = Object;
type CheckIsSupportSoterAuthenticationCompleteCallback = (result: CheckIsSupportSoterAuthenticationComplete) => void;
declare class CheckIsSupportSoterAuthenticationOptions extends UTSObject {
    success: CheckIsSupportSoterAuthenticationSuccessCallback | null;
    fail: CheckIsSupportSoterAuthenticationFailCallback | null;
    complete: CheckIsSupportSoterAuthenticationCompleteCallback | null;
}
type CheckIsSoterEnrolledInDevice = (options: CheckIsSoterEnrolledInDeviceOptions) => void;
declare class CheckIsSoterEnrolledInDeviceSuccess extends UTSObject {
    isEnrolled: boolean;
    errMsg: string;
}
type CheckIsSoterEnrolledInDeviceSuccessCallback = (result: CheckIsSoterEnrolledInDeviceSuccess) => void;
type CheckIsSoterEnrolledInDeviceFail = UniError;
type CheckIsSoterEnrolledInDeviceFailCallback = (result: CheckIsSoterEnrolledInDeviceFail) => void;
type CheckIsSoterEnrolledInDeviceComplete = Object;
type CheckIsSoterEnrolledInDeviceCompleteCallback = (result: CheckIsSoterEnrolledInDeviceComplete) => void;
declare class CheckIsSoterEnrolledInDeviceOptions extends UTSObject {
    checkAuthMode: SoterAuthMode;
    success: CheckIsSoterEnrolledInDeviceSuccessCallback | null;
    fail: CheckIsSoterEnrolledInDeviceFailCallback | null;
    complete: CheckIsSoterEnrolledInDeviceCompleteCallback | null;
}
declare const startSoterAuthentication: StartSoterAuthentication;
declare const checkIsSupportSoterAuthentication: CheckIsSupportSoterAuthentication;
declare const checkIsSoterEnrolledInDevice: CheckIsSoterEnrolledInDevice;
export { CheckIsSoterEnrolledInDevice as CheckIsSoterEnrolledInDevice, CheckIsSoterEnrolledInDeviceComplete as CheckIsSoterEnrolledInDeviceComplete, CheckIsSoterEnrolledInDeviceCompleteCallback as CheckIsSoterEnrolledInDeviceCompleteCallback, CheckIsSoterEnrolledInDeviceFail as CheckIsSoterEnrolledInDeviceFail, CheckIsSoterEnrolledInDeviceFailCallback as CheckIsSoterEnrolledInDeviceFailCallback, CheckIsSoterEnrolledInDeviceOptions as CheckIsSoterEnrolledInDeviceOptions, CheckIsSoterEnrolledInDeviceSuccess as CheckIsSoterEnrolledInDeviceSuccess, CheckIsSoterEnrolledInDeviceSuccessCallback as CheckIsSoterEnrolledInDeviceSuccessCallback, CheckIsSupportSoterAuthentication as CheckIsSupportSoterAuthentication, CheckIsSupportSoterAuthenticationComplete as CheckIsSupportSoterAuthenticationComplete, CheckIsSupportSoterAuthenticationCompleteCallback as CheckIsSupportSoterAuthenticationCompleteCallback, CheckIsSupportSoterAuthenticationFail as CheckIsSupportSoterAuthenticationFail, CheckIsSupportSoterAuthenticationFailCallback as CheckIsSupportSoterAuthenticationFailCallback, CheckIsSupportSoterAuthenticationOptions as CheckIsSupportSoterAuthenticationOptions, CheckIsSupportSoterAuthenticationSuccess as CheckIsSupportSoterAuthenticationSuccess, CheckIsSupportSoterAuthenticationSuccessCallback as CheckIsSupportSoterAuthenticationSuccessCallback, SoterAuthMode as SoterAuthMode, StartSoterAuthentication as StartSoterAuthentication, StartSoterAuthenticationComplete as StartSoterAuthenticationComplete, StartSoterAuthenticationCompleteCallback as StartSoterAuthenticationCompleteCallback, StartSoterAuthenticationFail as StartSoterAuthenticationFail, StartSoterAuthenticationFailCallback as StartSoterAuthenticationFailCallback, StartSoterAuthenticationOptions as StartSoterAuthenticationOptions, StartSoterAuthenticationSuccess as StartSoterAuthenticationSuccess, StartSoterAuthenticationSuccessCallback as StartSoterAuthenticationSuccessCallback };
export { startSoterAuthentication as startSoterAuthentication };
export { checkIsSupportSoterAuthentication as checkIsSupportSoterAuthentication };
export { checkIsSoterEnrolledInDevice as checkIsSoterEnrolledInDevice };
