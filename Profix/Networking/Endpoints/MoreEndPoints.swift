//
//  MoreEndPoints.swift
//  Waraqa
//
//  Created by Haneen on 21/08/2025.
//

import Foundation
import Alamofire

struct MoreEndpoints {
    private init() {}
}

extension MoreEndpoints {
    
    static func profile() -> Endpoint<BaseResponse<ProfileResponseModel>>{
        return .init(
            method: .get,
            path: "profile/show",
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func updateProfile(model:UpdateProfileModel, uploads: [UploadData]) -> Endpoint<BaseResponse<ProfileResponseModel>>{
        return .init(
            method: .post,
            path: "profile/update",
            body: [
                "name": model.name,
                "city_id": model.cityId
            ],
            headerType: .authorized(token: Session.token ?? ""),
            uploads: uploads
        )
    }
    
    static func checkPassword(password: String) -> Endpoint<BaseResponse<CurrentPasswordResponse>>{
        return .init(
            method: .post,
            path: "check-password",
            body: [
                "password" : password
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func newPhone(phone : String) -> Endpoint<BaseResponse<LoginResponse>>{
        return .init(
            method: .post,
            path: "new-phone",
            body: [
                "phone": phone,
                "country_key" : "00966"
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func newPhoneActivation(code:String) -> Endpoint<BaseResponse<LoginResponse>>{
        return .init(
            method: .post,
            path: "new-phone-active",
            body: [
                "code": code
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func resendNewPhoneCode(phone:String) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "code/resend-new",
            body: [
                "phone" : phone,
                "country_key" : "00966"
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func changePassword(model:ChangePasswordModel) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "change-password",
            body: [
                "old_password": model.currentPassword,
                "new_password" : model.password
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func switchNotification() -> Endpoint<BaseResponse<SwitchNotification>>{
        return .init(
            method: .patch,
            path: "switch-notification",
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func changeLanguage() -> Endpoint<BaseResponse<User>>{
        return .init(
            method: .patch,
            path: "change-lang",
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func deleteAccount() -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "profile/delete",
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
        static func showWallet() -> Endpoint<BaseResponse<WalletResponse>>{
            return .init(
                method: .get,
                path: "wallet",
                headerType: .authorized(token: Session.token ?? "")
            )
        }
    
        static func chargeWallet( amount: Double) -> Endpoint<BaseResponse<PayOrderResponse>>{
            return .init(
                method: .post,
                path: "charge-wallet",
                body: ["price" : amount],
                headerType: .authorized(token: Session.token ?? "")
            )
        }
    
        static func aboutUs() -> Endpoint<BaseResponse<AboutUsResponse>>{
            return .init(
                method: .get,
                path: "about-us"
            )
        }
    
        static func termsAndConditions() -> Endpoint<BaseResponse<TermsResponse>>{
            return .init(
                method: .get,
                path: "terms"
            )
        }
    
    static func privacyPolicy() -> Endpoint<BaseResponse<PrivacyPolicyResponse>>{
        return .init(
            method: .get,
            path: "policy"
        )
    }
    
    static func termsOfUse() -> Endpoint<BaseResponse<TermsOfUseResponse>>{
        return .init(
            method: .get,
            path: "terms-of-use"
        )
    }
    
    static func getComplaints(status: String ) -> Endpoint<BaseResponse<ComplaintsResponse>>{
            return .init(
                method: .get,
                path: "get-tickets",
                queries: [
                    "status" : status
                ],
                headerType: .authorized(token: Session.token ?? "")
            )
        }
    
        static func complaintDetails(id:Int) -> Endpoint<BaseResponse<ComplaintsDetailsResponse>>{
            return .init(
                method: .get,
                path: "single-ticket",
                queries: [
                    "ticket_id" : id
                ],
                headerType: .authorized(token: Session.token ?? "")
            )
        }
    
        static func addNewComplaint(model: AddComplaintsModel) -> Endpoint<BaseResponse<AddComplaintsResponse>>{
            return .init(
                method: .post,
                path: "create-ticket",
                body: [
                    "subject": model.subject,
                    "text" : model.text
                ],
                headerType: .authorized(token: Session.token ?? ""),
                uploads: model.uploadData
            )
        }
    
    static func contactUs(token:String,model: ContactUsModel) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "contact-us",
            body: [
                "name" : model.name,
                "phone" : model.phone,
                "message" : model.message
            ],
            headerType: .authorized(token: token)
        )
    }

    static func contactUs(model: ContactUsModel) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "contact-us",
            body: [
                "name" : model.name,
                "phone" : model.phone,
                "message" : model.message
            ]
        )
    }
        
    static func sitePhone() -> Endpoint<BaseResponse<SitePhoneResponse>>{
        return .init(
            method: .get,
            path: "site-phone"
        )
    }

    static func signout() -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "logout",
            body: [
                "device_id": UserDefaults.pushNotificationToken
            ],
            headerType: .authorized(token: Session.token ?? "" )
        )
    }
}
