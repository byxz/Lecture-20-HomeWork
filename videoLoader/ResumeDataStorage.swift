//
//  ResumeDataStorage.swift
//  videoLoader
//
//  Created by Mac on 07.07.2018.
//  Copyright © 2018 testOrg. All rights reserved.
//

import Foundation

class ResumeDataStorage {
    private let key = "Data"
    private let storage = UserDefaults.standard
    
    var data: Data? {
        return storage.data(forKey: key)
    }
    
    func save(data: Data) {
        storage.set(data, forKey: key)
    }
    
    func clear() {
        storage.removeObject(forKey: key)
    }
}
