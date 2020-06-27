//
//  Session.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 1/11/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import Foundation
let ksession = "session"
let ksession_id = "session_id"
let kcreation_date = "creation_date"

class Session: NSObject, NSCoding {
    var sessionId: String
    var creationDate: Date?
    var user: User
    
    //MARK: init methods
    init(sessionId: String, creationDate: Date, user: User) {
        self.sessionId = sessionId
        self.creationDate = creationDate
        self.user = user
    }
    
    class func getInstance() -> Session? {
        if let data = UserDefaults.standard.object(forKey: ksession) as? NSData {
            return NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? Session
        }
        return Session(sessionId: "", creationDate: Date(), user: User.getInstance()!)
    }
    
    func saveSession() {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        UserDefaults.standard.set(data, forKey: ksession)
    }
    
    func removeSession() {
        self.sessionId = ""
        self.creationDate = nil
        self.user.removeUser()
        saveSession()
    }
    
    //MARK: ecoding/decoding methods for custom objects
    required convenience init(coder decoder: NSCoder) {
        let sessionId = decoder.decodeObject(forKey: ksession_id) as! String
        let user = decoder.decodeObject(forKey: k_user) as! User
        let creationDate = decoder.decodeObject(forKey: kcreation_date) as! Date
        self.init(sessionId: sessionId, creationDate: creationDate, user: user)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.sessionId, forKey: ksession_id)
        coder.encode(self.user, forKey: k_user)
        coder.encode(self.creationDate, forKey: kcreation_date)
    }
}
