//
//  Note.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import Foundation

struct Note : CustomStringConvertible {
    let frequency : Float
    
    var description: String {
        return ""
    }
    
    init(frequency: Float) {
        self.frequency = frequency
    }
}