//
//  SongListTableViewController.swift
//  PitchPerfect
//
//  Created by iGuest on 11/24/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ScoresTableViewController: UITableViewController, SongsDelegate {
    
    let songs = Songs.shardInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Scores"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        songs.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    
    // MARK: Songs delegate
    func songsTitlesLoaded(songs: Songs) {
        self.tableView.reloadData()
    }
    
    func songsTitlesCacheLoaded(songs: Songs) {
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.list.count // - assuming it's an array
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        // Pull in song names from Data
        // Configure the cell...
        let song = songs.list[indexPath.row]
        cell.textLabel!.text = song.title
        cell.tag = indexPath.row
        return cell
    }
    

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "viewScoresForSongSegue" {
            print("Song CLicked Segue")
            let cell: UITableViewCell = sender as! UITableViewCell
            let selectedSong = self.songs.readSong(cell.tag)
            if let controller = segue.destinationViewController as? SongScoreTableViewController {
                controller.song = selectedSong!
            }
        }
    }
    
}