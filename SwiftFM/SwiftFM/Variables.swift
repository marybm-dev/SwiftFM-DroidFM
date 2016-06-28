//
//  Variables.swift
//  SwiftFM
//
//  Created by Mary Martinez on 6/27/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

struct Variables {
    static let fmUsername = "admin"
    static let fmPassword = "password"
    static let hostUsername = "admin"
    static let hostPassword = "password"
    static let host = "myHost.net"
    static let fmIP = Variables.getHost(fmUsername, password: fmPassword)
    static let hostIP = Variables.getHost(hostUsername, password: hostPassword)
    static let fmXml = "/fmi/xml/fmresultset.xml?-db=swiftfm&-lay=person"
    static let findall = "&-findall"
    static let myPeople = "\(fmIP)\(fmXml)\(findall)"
    static let fmScript = "-script=createRecordWithImage&-script.param="
    static let phpScript = "/uploadImage.php"
    
    static func getHost(username: String, password: String) -> String {
        return "https://\(username):\(password)@\(host)"
    }
}