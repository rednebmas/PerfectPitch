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

class SongListTableViewController: UITableViewController {
    
    var songList : [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchData("https://dl.dropboxusercontent.com/u/5301042/songs.json")
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchData(url: String) {
        Alamofire.request(.GET, url).responseString() { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    self.parseData(value)
                }
            case .Failure(let error):
                print(error)
            }
            self.tableView.reloadData()
        }
    }
    
    func parseData(data: AnyObject) {
        if let dataFromString = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString) //cast into SwiftyJSON
            let songs = json.array
            for songData in songs! {
                if songData["data-base-64"] != nil {
                    let songTitle = songData["title"].stringValue
                    let base64String = songData["data-base-64"].stringValue
                    print("song data in parse data    ")
                    print(songData)
                    songList.append(Song(withBase64DataString: base64String, title: songTitle))
                }
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count // - assuming it's an array
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        // Pull in song names from Data
        // Configure the cell...
        let song = songList[indexPath.row]
        cell.textLabel!.text = song.title
        cell.tag = indexPath.row
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /*
        
        This wasn't working because prepareForSegue was called before this method. I fixed it by
        setting the tag of the cell to be equal to its indexPath.row
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let selectedSongTitle = cell?.textLabel?.text!
        for song in songList {
            if song.title == selectedSongTitle {
                selectedSong = song
            }
        }
        */
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
        if segue.identifier == "SongClickedSegue" {
            let cell: UITableViewCell = sender as! UITableViewCell
            let selectedSong = self.songList[cell.tag]
            
            if let controller = segue.destinationViewController as? GameViewController {
                controller.song = selectedSong
            }
        }
    }
}