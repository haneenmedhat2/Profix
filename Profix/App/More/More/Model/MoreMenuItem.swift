//
//  UserMode.swift
//  Profix
//
//  Created by Haneen on 21/12/2025.
//


import Foundation
import UIKit

enum UserMode {
    case guest
    case authenticated
    
    static var current: UserMode {
        Session.isGuest == true ? .guest : .authenticated
    }
}

enum MoreMenuItem : CaseIterable {
    case profile
    case settings
    case wallet
    case aboutUs
    case usagePolicy
    case privacyPolicy
    case termsAndConditions
    case complaints
    case rateUs
    case contactUs
    case editProfile
    case changePhone
    case changePassword
    case changeLanguage
    case deleteAccount
    case login
    case logout
    case fcm


    
    var icon : String {
        switch self {
        case .profile:
            return "profile"
        case .settings:
            return "settings"
        case .wallet:
            return "wallet"
        case .aboutUs:
            return "aboutUs"
        case .usagePolicy:
            return "usagePolicy"
        case .privacyPolicy:
            return "privacyPolicy"
        case .termsAndConditions:
            return "terms"
        case .complaints:
            return "terms"
        case .rateUs:
            return "rate"
        case .contactUs:
            return "contactUS"
        case .editProfile:
            return "updateProfile"
        case .changePhone:
            return "changePhone"
        case .changePassword:
            return "changePassword"
        case .changeLanguage:
            return "changeLang"
        case .deleteAccount:
            return "deleteAccount"
        case .login:
            return "login"
        case .logout:
            return "logout-01"
        case .fcm:
            return "notification-02"
        }
    }
    
    var title : String {
        switch self {
        case .profile:
            return "profile".localized
        case .settings:
            return "settings".localized
        case .wallet:
            return "wallet".localized
        case .aboutUs:
            return "about_app".localized
        case .usagePolicy:
            return "usage_policy".localized
        case .privacyPolicy:
            return "privacy_policy".localized
        case .termsAndConditions:
            return "terms_conditions".localized
        case .complaints:
            return "complaints_inquiries".localized
        case .rateUs:
            return "rate_us".localized
        case .contactUs:
            return "contact_us".localized
        case .editProfile:
            return "edit_profile".localized
        case .changePhone:
            return "change_phone".localized
        case .changePassword:
            return "change_password".localized
        case .changeLanguage:
            return "change_language".localized
        case .deleteAccount:
            return "delete_account".localized
        case .login:
            return "login".localized
        case .logout:
            return "logout".localized
        case .fcm:
            return "enable_notifications".localized
        }
    }
    
    var fontColor : UIColor {
        switch self {
        case .profile,.settings ,.wallet, .aboutUs,.usagePolicy, .privacyPolicy,.termsAndConditions,.complaints, .rateUs ,.contactUs ,.editProfile, .changePhone, .changePassword,.changeLanguage:
            return .black
            case .deleteAccount:
            return .error
        case .login, .logout ,.fcm:
            return .main
        }
    }
    
    var isNotifyHidden : Bool {
        switch self {
        case .profile,.settings ,.wallet, .aboutUs,.usagePolicy, .privacyPolicy,.termsAndConditions,.complaints, .rateUs ,.contactUs ,.editProfile, .changePhone, .changePassword,.changeLanguage , .deleteAccount , .login, .logout:
            return true
        case .fcm:
            return false
        }
    }
    
    static func moreItems(for userType: UserMode) -> [MoreMenuItem] {
        switch userType {
        case .guest:
            return [ .aboutUs ,.usagePolicy ,.privacyPolicy , .termsAndConditions , .contactUs]
        case .authenticated:
            return [.profile, .settings, .wallet, .aboutUs ,.usagePolicy ,.privacyPolicy , .termsAndConditions ,.complaints, .rateUs,.contactUs]
        }
    }
    
    static func settingsItems(for userType: UserMode) -> [MoreMenuItem] {
        switch userType {
        case .guest:
            return []
        case .authenticated:
            return [.editProfile, .changePhone, .changePassword, .changeLanguage, .deleteAccount]
        }
    }
}
