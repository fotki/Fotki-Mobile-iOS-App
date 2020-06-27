//
//  UserInfo.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 12/27/16.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
let kfname = "fname"
let klname = "lname"
let k_id = "id"
let k_user = "user"
let kisLogin = false
let kisGmailLogin = false

class User: NSObject, NSCoding {
    var fname: String
    var lname: String
    var isLogin: Bool
    var isGmailLogin: Bool
    var isFacebookLogin: Bool
    
    // MARK: init methods
    init(firstname: String, lastname: String, login: Bool, gmailLogin: Bool, facebookLogin: Bool) {
        self.fname = firstname
        self.lname = lastname
        self.isLogin = login
        self.isGmailLogin = gmailLogin
        self.isFacebookLogin = facebookLogin
    }
    
    class func getInstance() -> User? {
        if let data = UserDefaults.standard.object(forKey: k_user) as? NSData {
            return NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? User
        }
        return User(firstname: "", lastname: "", login: false, gmailLogin: false, facebookLogin: false)
    }

    func saveUser() {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        UserDefaults.standard.set(data, forKey: k_user)
    }
    
    func removeUser() {
        self.fname = ""
        self.lname = ""
        self.isLogin = false
        self.isGmailLogin = false
        self.isFacebookLogin = false
        saveUser()
    }
    
    //MARK: ecoding/decoding methods for custom objects
    required convenience init(coder decoder: NSCoder) {
        let fname = decoder.decodeObject(forKey: kfname) as! String
        let lname = decoder.decodeObject(forKey: klname) as! String
        let isLogin: Bool = decoder.decodeBool(forKey: klogin)
        let isGmailLogin: Bool = decoder.decodeBool(forKey: kgmailLogin)
        let isFacebookLogin: Bool = decoder.decodeBool(forKey: kfacebookLogin)
        self.init(firstname: fname, lastname: lname, login: isLogin, gmailLogin: isGmailLogin, facebookLogin: isFacebookLogin)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.fname, forKey: kfname)
        coder.encode(self.lname, forKey: klname)
        coder.encode(self.isLogin, forKey: klogin)
        coder.encode(self.isGmailLogin, forKey: kgmailLogin)
        coder.encode(self.isFacebookLogin, forKey: kfacebookLogin)
    }
}
