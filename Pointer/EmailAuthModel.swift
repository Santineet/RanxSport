//
//  EmailAuthModel.swift
//  Pointer
//
//  Created by Mairambek on 3/5/20.
//  Copyright © 2020 Pointer. All rights reserved.
//

import Foundation

struct UserData: Decodable {
    
    var token: String?
    var fcm_token: String?
}
