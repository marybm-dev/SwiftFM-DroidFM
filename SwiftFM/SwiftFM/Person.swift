//
//  Person.swift
//  SwiftFM
//
//  Created by Mary Martinez on 1/9/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

class Person {
    let name  : String?
    let email : String?
    let photo : String?
    
    init(name: String?, email: String?, photo: String?) {
        self.name  = name ?? ""
        self.email = email ?? ""
        self.photo = photo ?? ""
    }
}