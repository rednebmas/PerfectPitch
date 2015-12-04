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
}

class Songs
{
    static let shardInstance: Songs = Songs()
    var delegate: SongsDelegate?
    private(set) var list: [Song]
    
    init() {
        self.list = []
        self.loadTitles()
    }
    
    func loadTitles() {
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[0] + "/"
        
        let titlesPath = documentsPath + "titles.json"
        print(titlesPath)
        
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(titlesPath) {
            
        } else {
            self.fetchData(Constants.REMOTE_SONGS_URL)
        }
    }
    
    // MARK: Network methods
    
    func fetchData(url: String) {
        Alamofire.request(.GET, url).responseString() { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    if let dataFromString = value.dataUsingEncoding(
                        NSUTF8StringEncoding,
                        allowLossyConversion: false)
                    {
                        let json = JSON(data: dataFromString) //cast into SwiftyJSON
                        let songs = json.array
                        self.parseSongsJSON(songs!)
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
        for songInfo in songs {
            let title = songInfo["title"].stringValue
            let song = Song(title: title)
            self.list.append(song)
            
            self.saveSong(title, base64String: songInfo["data-base-64"].stringValue)
        }
        
        if self.delegate != nil {
            self.delegate?.songsTitlesLoaded(self)
        }
    }
    
    func saveSong(title: String, base64String: String) {
        
    }
}