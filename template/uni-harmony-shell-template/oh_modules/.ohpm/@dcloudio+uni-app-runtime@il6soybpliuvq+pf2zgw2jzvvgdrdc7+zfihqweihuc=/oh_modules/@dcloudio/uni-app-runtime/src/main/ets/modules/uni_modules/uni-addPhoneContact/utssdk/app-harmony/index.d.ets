import { UTSObject, UniError } from "@dcloudio/uni-app-framework";
type AddPhoneContact = (options: AddPhoneContactOptions) => void;
declare class AddPhoneContactSuccess extends UTSObject {
}
type AddPhoneContactSuccessCallback = (result: AddPhoneContactSuccess) => void;
type AddPhoneContactFail = UniError;
type AddPhoneContactFailCallback = (result: AddPhoneContactFail) => void;
type AddPhoneContactComplete = Object;
type AddPhoneContactCompleteCallback = (result: AddPhoneContactComplete) => void;
declare class AddPhoneContactOptions extends UTSObject {
    photoFilePath: string | null;
    nickName: string | null;
    lastName: string | null;
    middleName: string | null;
    firstName: string | null;
    remark: string | null;
    mobilePhoneNumber: string | null;
    weChatNumber: string | null;
    addressCountry: string | null;
    addressState: string | null;
    addressCity: string | null;
    addressStreet: string | null;
    addressPostalCode: string | null;
    organization: string | null;
    title: string | null;
    workFaxNumber: string | null;
    workPhoneNumber: string | null;
    hostNumber: string | null;
    email: string | null;
    url: string | null;
    workAddressCountry: string | null;
    workAddressState: string | null;
    workAddressCity: string | null;
    workAddressStreet: string | null;
    workAddressPostalCode: string | null;
    homeFaxNumber: string | null;
    homePhoneNumber: string | null;
    homeAddressCountry: string | null;
    homeAddressState: string | null;
    homeAddressCity: string | null;
    homeAddressStreet: string | null;
    homeAddressPostalCode: string | null;
    success: AddPhoneContactSuccessCallback | null;
    fail: AddPhoneContactFailCallback | null;
    complete: AddPhoneContactCompleteCallback | null;
}
declare const addPhoneContact: AddPhoneContact;
export { AddPhoneContact as AddPhoneContact, AddPhoneContactComplete as AddPhoneContactComplete, AddPhoneContactCompleteCallback as AddPhoneContactCompleteCallback, AddPhoneContactFail as AddPhoneContactFail, AddPhoneContactFailCallback as AddPhoneContactFailCallback, AddPhoneContactOptions as AddPhoneContactOptions, AddPhoneContactSuccess as AddPhoneContactSuccess, AddPhoneContactSuccessCallback as AddPhoneContactSuccessCallback };
export { addPhoneContact as addPhoneContact };
