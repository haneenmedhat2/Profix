//
//  UpdateProfileModel.swift
//  Esterad
//
//  Created by Haneen on 03/11/2025.
//

import Foundation

struct UpdateProfileModel: Codable {
    var avatar : Data?
    var name : String?
    var cityId : Int?
    
    var uploadData: [UploadData] {
        var files = [UploadData]()
        if let avatarData = avatar {
            files.append(UploadData(
                key: "avatar",
                data: avatarData,
                mimeType: .jpeg,
                fileName: "\(Date().timeIntervalSince1970).jpeg"
            ))
        }
        return files
    }
    
    enum CodingKeys: String, CodingKey {
        case avatar
        case name
        case cityId = "city_id"
    }
}
