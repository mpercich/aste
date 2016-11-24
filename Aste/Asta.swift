//
//  Asta.swift
//  Aste
//
//  Created by Percich Michele (UniCredit Business Integrated Solutions) on 24/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit

class Asta: NSObject {
    var key: String
    var content: Dictionary<String, Bool>?
    
    init(key: String) {
        self.key = key
    }
    
    convenience override init() {
        self.init(key: "")
    }
}
