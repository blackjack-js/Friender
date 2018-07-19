//
//  DataService.swift
//  Friender
//
//  Created by mac on 7/19/18.
//  Copyright © 2018 storm. All rights reserved.
//

import Foundation
import Firebase

let DB_BASE = Database.database().reference()
class DataService {
    static let instance = DataService()
    
    private var _REF_BASE = DB_BASE
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_EVENTS = DB_BASE.child("events")
    
    var REF_BASE:DatabaseReference {
        return _REF_BASE
    }
    var REF_USERS:DatabaseReference {
        return _REF_USERS
    }
    var REF_EVENTS:DatabaseReference {
        return _REF_EVENTS
    }
    
    func createDBUser(uid: String, userData: Dictionary<String, Any>) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
}