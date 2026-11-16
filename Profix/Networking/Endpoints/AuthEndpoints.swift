//
//  AuthEndpoints.swift
//  App
//
//  Created by MGAbouarab on 22/12/2023.
//

import Foundation
import Alamofire

struct AuthEndpoints {
    private init() {}
}

extension AuthEndpoints {
    
    static func introRequest() -> Endpoint<BaseResponse<IntroResponse>>{
        return .init(
            method: .get,
            path: "intro"
        )
    }
    
    static func login(model : LoginModel) -> Endpoint<BaseResponse<LoginResponse>>{
        return .init(
            method: .post,
            path: "login",
            body: [
                "phone": model.phone,
                "password": model.password,
                "device_id": UserDefaults.pushNotificationToken,
                "device_type": "ios",
                "type": "user",
                "country_key" : "00966"
            ]
        )
    }
    
    static func signup(model: SignupModel, uploads: [UploadData]) -> Endpoint<BaseResponse<LoginResponse>>{
        return .init(
            method: .post,
            path: "register",
            body:[
                "name" : model.name,
                "phone" : model.phone,
                "country_key" : "00966",
                "city_id" : model.cityId,
                "password" : model.password,
                "device_id": UserDefaults.pushNotificationToken,
                "device_type": "ios"
            ],
            uploads: uploads
        )
    }
    
    static func getCities(countryId : Int) -> Endpoint<BaseResponse<CityResponse>>{
        return .init(
            method: .get,
            path: "cities",
            queries: [
                "country_id" : countryId
            ]
        )
    }
    
    static func verification(code: String , token : String) -> Endpoint<BaseResponse<LoginResponse>> {
        return .init(
            method: .post,
            path: "account/activation",
            body: [
                "code": code
            ],
            headerType: .authorized(token: token)
        )
    }
    
    static func resendCode(token : String) -> Endpoint<BaseResponse<String>> {
        return .init(
            method: .post,
            path: "code/resend",
            headerType: .authorized(token: token)
        )
    }
    
    static func forgetPassword(phone: String) -> Endpoint<BaseResponse<LoginResponse>> {
        return .init(
            method: .post,
            path: "password/forget",
            body: [
                "phone": phone,
                "country_key": "00966"
            ]
        )
    }
    
    static func resetPassword(password : String , token : String) -> Endpoint<BaseResponse<String>> {
        return .init(
            method: .post,
            path: "password/reset",
            body: [
                "password" : password,
            ],
            headerType: .authorized(token: token)
        )
    }
}
