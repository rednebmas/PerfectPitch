//
//  Songs.swift
//  PitchPerfect
//
//  Created by Sam Bender on 12/3/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol SongsDelegate
{
    func songsTitlesLoaded(songs: Songs)
    func songsTitlesCacheLoaded(songs: Songs)
}

class Songs
{
    static let shardInstance: Songs = Songs()
    var delegate: SongsDelegate?
    
    private(set) var list: [Song]
    private let documentsPath: String
    
    init() {
        self.list = []
        self.documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[0] + "/"
        
        self.loadTitles()
    }
    
    func loadTitles() {
        let titlesPath = documentsPath + "titles.json"
        
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(titlesPath) {
            // unarchive song list
            let list = NSKeyedUnarchiver.unarchiveObjectWithFile(titlesPath) as? [Song]
            if list != nil {
                self.list = list!
            } else {
                print("Error loading song titles cache")
            }
            
            if delegate != nil {
                delegate!.songsTitlesCacheLoaded(self)
            }
        }
        //self.getData()
        
        //self.fetchData()
    }
    
    // MARK: Network methods
    
    func fetchData() {
        Alamofire.request(.GET, Constants.REMOTE_SONGS_URL).responseString() { response in
            switch response.result {
            case .Success:
                //self.getData()
                
                
                if let value = response.result.value {
                    
                    if let dataFromString = value.dataUsingEncoding(
                        NSUTF8StringEncoding,
                        allowLossyConversion: false)
                    {
                        let json = JSON(data: dataFromString) //cast into SwiftyJSON
                        let songs = json.array
                        self.parseSongsJSON(songs!)
                        //Store data
                    }
                    else
                    {
                        print("Error converting data to string")
                    }
                }
            case .Failure(let error):
                print(error)
            }
        }
    }
    
    func parseSongsJSON(songs: [JSON]) {
        self.list.removeAll()
        
        for songInfo in songs {
            let title = songInfo["title"].stringValue
            let data = songInfo["data-base-64"].stringValue
            let song = Song(title: title)
            self.list.append(song)
            
            self.saveSong(title, base64String: data)
        }
        
        if self.delegate != nil {
            self.delegate?.songsTitlesLoaded(self)
        }
        
        let titlesPath = documentsPath + "titles.json"
        let success = NSKeyedArchiver.archiveRootObject(self.list, toFile: titlesPath)
        if !success {
            print ("Failed writing song titles to file.")
        }
    }
    
    // MARK: Filesystem methods
    
    func filePathForTitle(title: String) -> String {
        let unsafeChars = NSCharacterSet.alphanumericCharacterSet().invertedSet
        let strippedTitle = title
            .componentsSeparatedByCharactersInSet(unsafeChars)
            .joinWithSeparator("")
        let filePath = self.documentsPath + strippedTitle + ".mid"
        return filePath
    }
    
    func saveSong(title: String, base64String: String) -> Bool {
        let filePath = self.filePathForTitle(title)
        
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filePath) {
            print("File already exists")
            return false
        } else {
            print("Writing " + title + " to file")
            let song = Song(withBase64DataString: base64String, title: title)
            let success = NSKeyedArchiver.archiveRootObject(song, toFile: filePath)
            if !success {
                print ("Failed writing " + title  + " to file.")
                return false
            }
        }
        
        return true
    }
    
    func readSong(atIndex: Int) -> Song? {
        if atIndex >= self.list.count {
            print("Method readSongAtIndex: called but index was out of bounds")
            return nil
        }
        
        let filePath = self.filePathForTitle(self.list[atIndex].title)
        return NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? Song
    }
    
}