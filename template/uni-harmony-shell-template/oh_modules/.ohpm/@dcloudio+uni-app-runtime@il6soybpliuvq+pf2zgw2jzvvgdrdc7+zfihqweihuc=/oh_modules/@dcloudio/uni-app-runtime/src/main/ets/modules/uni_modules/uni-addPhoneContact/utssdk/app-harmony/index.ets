import { BusinessError } from '@kit.BasicServicesKit';
import { UTSObject, UniError, ApiOptions, ProtocolOptions, defineAsyncApi, ApiExecutor, UTSHarmony } from "@dcloudio/uni-app-framework";
import { contact } from '@kit.ContactsKit';
type AddPhoneContact = (options: AddPhoneContactOptions) => void;
class AddPhoneContactSuccess extends UTSObject {
}
type AddPhoneContactSuccessCallback = (result: AddPhoneContactSuccess) => void;
type AddPhoneContactFail = UniError;
type AddPhoneContactFailCallback = (result: AddPhoneContactFail) => void;
type AddPhoneContactComplete = Object;
type AddPhoneContactCompleteCallback = (result: AddPhoneContactComplete) => void;
class AddPhoneContactOptions extends UTSObject {
    photoFilePath: string | null = null;
    nickName: string | null = null;
    lastName: string | null = null;
    middleName: string | null = null;
    firstName: string | null = null;
    remark: string | null = null;
    mobilePhoneNumber: string | null = null;
    weChatNumber: string | null = null;
    addressCountry: string | null = null;
    addressState: string | null = null;
    addressCity: string | null = null;
    addressStreet: string | null = null;
    addressPostalCode: string | null = null;
    organization: string | null = null;
    title: string | null = null;
    workFaxNumber: string | null = null;
    workPhoneNumber: string | null = null;
    hostNumber: string | null = null;
    email: string | null = null;
    url: string | null = null;
    workAddressCountry: string | null = null;
    workAddressState: string | null = null;
    workAddressCity: string | null = null;
    workAddressStreet: string | null = null;
    workAddressPostalCode: string | null = null;
    homeFaxNumber: string | null = null;
    homePhoneNumber: string | null = null;
    homeAddressCountry: string | null = null;
    homeAddressState: string | null = null;
    homeAddressCity: string | null = null;
    homeAddressStreet: string | null = null;
    homeAddressPostalCode: string | null = null;
    success: AddPhoneContactSuccessCallback | null = null;
    fail: AddPhoneContactFailCallback | null = null;
    complete: AddPhoneContactCompleteCallback | null = null;
}
const API_ADD_PHONE_CONTACT = 'addPhoneContact';
const AddPhoneContactApiOptions: ApiOptions<AddPhoneContactOptions> = {
    formatArgs: new Map<string, ((firstName: string) => string | undefined)>([
        [
            'firstName',
            (firstName: string)=>{
                if (!firstName) {
                    return 'addPhoneContact:fail parameter error: parameter.firstName should not be empty;';
                }
                return undefined;
            }
        ]
    ])
};
const AddPhoneContactApiProtocol = new Map<string, ProtocolOptions>([
    [
        'firstName',
        {
            type: 'string',
            required: true
        }
    ],
    [
        'photoFilePath',
        {
            type: 'string'
        }
    ],
    [
        'nickName',
        {
            type: 'string'
        }
    ],
    [
        'lastName',
        {
            type: 'string'
        }
    ],
    [
        'middleName',
        {
            type: 'string'
        }
    ],
    [
        'remark',
        {
            type: 'string'
        }
    ],
    [
        'mobilePhoneNumber',
        {
            type: 'string'
        }
    ],
    [
        'weChatNumber',
        {
            type: 'string'
        }
    ],
    [
        'addressCountry',
        {
            type: 'string'
        }
    ],
    [
        'addressState',
        {
            type: 'string'
        }
    ],
    [
        'addressCity',
        {
            type: 'string'
        }
    ],
    [
        'addressStreet',
        {
            type: 'string'
        }
    ],
    [
        'addressPostalCode',
        {
            type: 'string'
        }
    ],
    [
        'organization',
        {
            type: 'string'
        }
    ],
    [
        'title',
        {
            type: 'string'
        }
    ],
    [
        'workFaxNumber',
        {
            type: 'string'
        }
    ],
    [
        'workPhoneNumber',
        {
            type: 'string'
        }
    ],
    [
        'hostNumber',
        {
            type: 'string'
        }
    ],
    [
        'email',
        {
            type: 'string'
        }
    ],
    [
        'url',
        {
            type: 'string'
        }
    ],
    [
        'workAddressCountry',
        {
            type: 'string'
        }
    ],
    [
        'workAddressState',
        {
            type: 'string'
        }
    ],
    [
        'workAddressCity',
        {
            type: 'string'
        }
    ],
    [
        'workAddressStreet',
        {
            type: 'string'
        }
    ],
    [
        'workAddressPostalCode',
        {
            type: 'string'
        }
    ],
    [
        'homeFaxNumber',
        {
            type: 'string'
        }
    ],
    [
        'homePhoneNumber',
        {
            type: 'string'
        }
    ],
    [
        'homeAddressCountry',
        {
            type: 'string'
        }
    ],
    [
        'homeAddressState',
        {
            type: 'string'
        }
    ],
    [
        'homeAddressCity',
        {
            type: 'string'
        }
    ],
    [
        'homeAddressStreet',
        {
            type: 'string'
        }
    ],
    [
        'homeAddressPostalCode',
        {
            type: 'string'
        }
    ]
]);
const addPhoneContact: AddPhoneContact = defineAsyncApi<AddPhoneContactOptions, AddPhoneContactSuccess>(API_ADD_PHONE_CONTACT, (args: AddPhoneContactOptions, executor: ApiExecutor<AddPhoneContactSuccess>)=>{
    UTSHarmony.requestSystemPermission([
        'ohos.permission.WRITE_CONTACTS'
    ], (allRight: boolean)=>{
        if (allRight) {
            const photoFilePath = args.photoFilePath, _args_nickName = args.nickName, nickName = _args_nickName == null ? '' : _args_nickName, _args_lastName = args.lastName, lastName = _args_lastName == null ? '' : _args_lastName, _args_middleName = args.middleName, middleName = _args_middleName == null ? '' : _args_middleName, _args_firstName = args.firstName, firstName = _args_firstName == null ? '' : _args_firstName, _args_remark = args.remark, remark = _args_remark == null ? '' : _args_remark, _args_mobilePhoneNumber = args.mobilePhoneNumber, mobilePhoneNumber = _args_mobilePhoneNumber == null ? '' : _args_mobilePhoneNumber, _args_addressCountry = args.addressCountry, addressCountry = _args_addressCountry == null ? '' : _args_addressCountry, _args_addressState = args.addressState, addressState = _args_addressState == null ? '' : _args_addressState, _args_addressCity = args.addressCity, addressCity = _args_addressCity == null ? '' : _args_addressCity, _args_addressStreet = args.addressStreet, addressStreet = _args_addressStreet == null ? '' : _args_addressStreet, _args_addressPostalCode = args.addressPostalCode, addressPostalCode = _args_addressPostalCode == null ? '' : _args_addressPostalCode, _args_organization = args.organization, organization = _args_organization == null ? '' : _args_organization, _args_url = args.url, url = _args_url == null ? '' : _args_url, _args_workPhoneNumber = args.workPhoneNumber, workPhoneNumber = _args_workPhoneNumber == null ? '' : _args_workPhoneNumber, _args_workFaxNumber = args.workFaxNumber, workFaxNumber = _args_workFaxNumber == null ? '' : _args_workFaxNumber, _args_hostNumber = args.hostNumber, hostNumber = _args_hostNumber == null ? '' : _args_hostNumber, _args_email = args.email, email = _args_email == null ? '' : _args_email, _args_title = args.title, title = _args_title == null ? '' : _args_title, _args_workAddressCountry = args.workAddressCountry, workAddressCountry = _args_workAddressCountry == null ? '' : _args_workAddressCountry, _args_workAddressState = args.workAddressState, workAddressState = _args_workAddressState == null ? '' : _args_workAddressState, _args_workAddressCity = args.workAddressCity, workAddressCity = _args_workAddressCity == null ? '' : _args_workAddressCity, _args_workAddressStreet = args.workAddressStreet, workAddressStreet = _args_workAddressStreet == null ? '' : _args_workAddressStreet, workAddressPostalCode = args.workAddressPostalCode, _args_homeFaxNumber = args.homeFaxNumber, homeFaxNumber = _args_homeFaxNumber == null ? '' : _args_homeFaxNumber, _args_homePhoneNumber = args.homePhoneNumber, homePhoneNumber = _args_homePhoneNumber == null ? '' : _args_homePhoneNumber, _args_homeAddressCountry = args.homeAddressCountry, homeAddressCountry = _args_homeAddressCountry == null ? '' : _args_homeAddressCountry, _args_homeAddressState = args.homeAddressState, homeAddressState = _args_homeAddressState == null ? '' : _args_homeAddressState, _args_homeAddressCity = args.homeAddressCity, homeAddressCity = _args_homeAddressCity == null ? '' : _args_homeAddressCity, _args_homeAddressStreet = args.homeAddressStreet, homeAddressStreet = _args_homeAddressStreet == null ? '' : _args_homeAddressStreet, _args_homeAddressPostalCode = args.homeAddressPostalCode, homeAddressPostalCode = _args_homeAddressPostalCode == null ? '' : _args_homeAddressPostalCode;
            const contactInfo: contact.Contact = {
                name: {
                    givenName: firstName!,
                    fullName: lastName! + middleName! + firstName!
                }
            };
            if (nickName) {
                contactInfo.nickName = {
                    nickName: nickName!
                } as contact.NickName;
            }
            if (lastName) {
                contactInfo.name!.familyName = lastName;
            }
            if (middleName) {
                contactInfo.name!.middleName = middleName;
            }
            if (email) {
                contactInfo.emails = [
                    {
                        email: email!,
                        displayName: '邮箱'
                    } as contact.Email
                ];
            }
            if (photoFilePath) {
                contactInfo.portrait = {
                    uri: photoFilePath
                } as contact.Portrait;
            }
            if (url) {
                contactInfo.websites = [
                    {
                        website: url
                    } as contact.Website
                ];
            }
            if (remark) {
                contactInfo.note = {
                    noteContent: remark
                } as contact.Note;
            }
            if (organization) {
                contactInfo.organization = {
                    name: organization,
                    title: title!
                } as contact.Organization;
            }
            const phoneNumbers: contact.PhoneNumber[] = [];
            if (homePhoneNumber) {
                phoneNumbers.push({
                    phoneNumber: homePhoneNumber!,
                    labelId: contact.PhoneNumber.NUM_HOME
                } as contact.PhoneNumber);
            }
            if (mobilePhoneNumber) {
                phoneNumbers.push({
                    phoneNumber: mobilePhoneNumber!,
                    labelId: contact.PhoneNumber.NUM_MOBILE
                } as contact.PhoneNumber);
            }
            if (homeFaxNumber) {
                phoneNumbers.push({
                    phoneNumber: homeFaxNumber!,
                    labelId: contact.PhoneNumber.NUM_FAX_HOME
                } as contact.PhoneNumber);
            }
            if (workFaxNumber) {
                phoneNumbers.push({
                    phoneNumber: workFaxNumber!,
                    labelId: contact.PhoneNumber.NUM_FAX_WORK
                } as contact.PhoneNumber);
            }
            if (workPhoneNumber) {
                phoneNumbers.push({
                    phoneNumber: workPhoneNumber!,
                    labelId: contact.PhoneNumber.NUM_WORK
                } as contact.PhoneNumber);
            }
            if (hostNumber) {
                phoneNumbers.push({
                    phoneNumber: hostNumber!,
                    labelId: contact.PhoneNumber.NUM_COMPANY_MAIN
                } as contact.PhoneNumber);
            }
            if (phoneNumbers.length) contactInfo.phoneNumbers = phoneNumbers;
            const postalAddresses: contact.PostalAddress[] = [];
            if (homeAddressCity || homeAddressCountry || homeAddressPostalCode || homeAddressStreet) {
                postalAddresses.push({
                    city: homeAddressCity!,
                    country: homeAddressCountry!,
                    postcode: homeAddressPostalCode!,
                    street: homeAddressStreet!,
                    postalAddress: `${homeAddressCountry!}${homeAddressState!}${homeAddressCity!}${homeAddressStreet!}`,
                    labelId: contact.PostalAddress.ADDR_HOME
                } as contact.PostalAddress);
            }
            if (workAddressCity || workAddressCountry || workAddressPostalCode || workAddressStreet) {
                postalAddresses.push({
                    city: workAddressCity!,
                    country: workAddressCountry!,
                    postcode: workAddressPostalCode!,
                    street: workAddressStreet!,
                    postalAddress: `${workAddressCountry!}${workAddressState!}${workAddressCity!}${workAddressStreet!}`,
                    labelId: contact.PostalAddress.ADDR_WORK
                } as contact.PostalAddress);
            }
            if (addressCity || addressCountry || addressPostalCode || addressStreet) {
                postalAddresses.push({
                    city: addressCity!,
                    country: addressCountry!,
                    postcode: addressPostalCode!,
                    street: addressStreet!,
                    postalAddress: `${addressCountry!}${addressState!}${addressCity!}${addressStreet!}`,
                    labelId: contact.PostalAddress.CUSTOM_LABEL
                } as contact.PostalAddress);
            }
            if (postalAddresses.length) contactInfo.postalAddresses = postalAddresses;
            contact.addContact(UTSHarmony.getUIAbilityContext()!, contactInfo).then((contactId)=>{
                executor.resolve(contactId);
            }).catch((err: BusinessError)=>{
                executor.reject(err.message);
            });
        } else {
            executor.reject('Permission denied');
        }
    }, ()=>executor.reject('Permission denied'));
}, AddPhoneContactApiProtocol, AddPhoneContactApiOptions) as AddPhoneContact;
export { AddPhoneContact as AddPhoneContact, AddPhoneContactComplete as AddPhoneContactComplete, AddPhoneContactCompleteCallback as AddPhoneContactCompleteCallback, AddPhoneContactFail as AddPhoneContactFail, AddPhoneContactFailCallback as AddPhoneContactFailCallback, AddPhoneContactOptions as AddPhoneContactOptions, AddPhoneContactSuccess as AddPhoneContactSuccess, AddPhoneContactSuccessCallback as AddPhoneContactSuccessCallback };
export { addPhoneContact as addPhoneContact };
