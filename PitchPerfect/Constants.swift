//
//  Constants.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/28/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import Foundation

extension UIColor {
    convenience init(hex : Int) {
        let blue = CGFloat(hex & 0xFF)
        let green = CGFloat((hex >> 8) & 0xFF)
        let red = CGFloat((hex >> 16) & 0xFF)
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1)
    }
}

class Constants {
    
    static var LAST_GAME_MODE = Game.Mode.NoteByNote
    
    static let REMOTE_SONGS_URL = "https://dl.dropboxusercontent.com/u/5301042/songs.json"
    static let PITCH_PERFECT_COLOR = UIColor(hex: 0x3e9ec1)
    
    //
    // http://www.skytopia.com/project/articles/midi.html
    //
    static let MIDI_NOTE_NUMBER_TO_NAME_STRING = [
        0x7F: "G9",
        0x7E: "Gb9",
        0x7D: "F9",
        0x7C: "E9",
        0x7B: "Eb9",
        0x7A: "D9",
        0x79: "Db9",
        0x78: "C9",
        0x77: "B8",
        0x76: "Bb8",
        0x75: "A8",
        0x74: "Ab8",
        0x73: "G8",
        0x72: "Gb8",
        0x71: "F8",
        0x70: "E8",
        0x6F: "Eb8",
        0x6E: "D8",
        0x6D: "Db8",
        0x6C: "C8",
        0x6B: "B7",
        0x6A: "Bb7",
        0x69: "A7",
        0x68: "Ab7",
        0x67: "G7",
        0x66: "Gb7",
        0x65: "F7",
        0x64: "E7",
        0x63: "Eb7",
        0x62: "D7",
        0x61: "Db7",
        0x60: "C7",
        0x5F: "B6",
        0x5E: "Bb6",
        0x5D: "A6",
        0x5C: "Ab6",
        0x5B: "G6",
        0x5A: "Gb6",
        0x59: "F6",
        0x58: "E6",
        0x57: "Eb6",
        0x56: "D6",
        0x55: "Db6",
        0x54: "C6",
        0x53: "B5",
        0x52: "Bb5",
        0x51: "A5",
        0x50: "Ab5",
        0x4F: "G5",
        0x4E: "Gb5",
        0x4D: "F5",
        0x4C: "E5",
        0x4B: "Eb5",
        0x4A: "D5",
        0x49: "Db5",
        0x48: "C5",
        0x47: "B4",
        0x46: "Bb4",
        0x45: "A4",
        0x44: "Ab4",
        0x43: "G4",
        0x42: "Gb4",
        0x41: "F4",
        0x40: "E4",
        0x3F: "Eb4",
        0x3E: "D4",
        0x3D: "Db4",
        0x3C: "C4",
        0x3B: "B3",
        0x3A: "Bb3",
        0x39: "A3",
        0x38: "Ab3",
        0x37: "G3",
        0x36: "Gb3",
        0x35: "F3",
        0x34: "E3",
        0x33: "Eb3",
        0x32: "D3",
        0x31: "Db3",
        0x30: "C3",
        0x2F: "B2",
        0x2E: "Bb2",
        0x2D: "A2",
        0x2C: "Ab2",
        0x2B: "G2",
        0x2A: "Gb2",
        0x29: "F2",
        0x28: "E2",
        0x27: "Eb2",
        0x26: "D2",
        0x25: "Db2",
        0x24: "C2",
        0x23: "B1",
        0x22: "Bb1",
        0x21: "A1",
        0x20: "Ab1",
        0x1F: "G1",
        0x1E: "Gb1",
        0x1D: "F1",
        0x1C: "E1",
        0x1B: "Eb1",
        0x1A: "D1",
        0x19: "Db1",
        0x18: "C1",
        0x17: "B0",
        0x16: "Bb0",
        0x15: "A0",
        0x14: "Ab0",
        0x13: "G0",
        0x12: "Gb0",
        0x11: "F0",
        0x10: "E0",
        0x0F: "Eb0",
        0x0E: "D0",
        0x0D: "Db0",
        0x0C: "C0"
    ]
}
