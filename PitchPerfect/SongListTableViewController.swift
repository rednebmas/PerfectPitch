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

class SongListTableViewController: UITableViewController, SongsDelegate {
    
    let songs = Songs.shardInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hides empty cells
        self.tableView.tableFooterView = UIView();
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //
    // MARK: - Table view data source
    //

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.list.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        // Configure the cell...
        let song = songs.list[indexPath.row]
        cell.textLabel!.text = song.title
        cell.tag = indexPath.row
        return cell
    }
    
    //
    // MARK: Songs delegate
    //
    
    func songsTitlesLoaded(songs: Songs) {
        self.tableView.reloadData()
    }
    
    func songsTitlesCacheLoaded(songs: Songs) {
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation

    /**
     * In a storyboard-based application, you will often want to do a little preparation before 
     * navigation.
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
        if segue.identifier == "SongClickedSegue" {
            print("Song CLicked Segue")
            let cell: UITableViewCell = sender as! UITableViewCell
            let selectedSong = self.songs.readSong(cell.tag)
            
            if let controller = segue.destinationViewController as? GameViewController {
                controller.song = selectedSong!
            }
            print("Completed Prepeare for segue")
        }
    }
    
    /**
     * Can not figure out why this is not working...
     */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}