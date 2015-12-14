//
//  SongScoreViewController.swift
//  PerfectPitch
//
//  Created by Megan Hodge on 12/9/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit

class SongScoreTableViewController: UITableViewController {
    
    
    let scores = [121,12,15,19]
    
    var songTitle : String = ""
    
    var song = Song(title: "tester")
    
    //@IBOutlet weak var scoreTestLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = songTitle
        //self.scoreTestLabel.text = String(song.highScore)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //size of score arrays
        //self.song.scores.count
        return scores.count
        
        //return self.songs.list.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        
        var sortedScores = scores.sort {  return $0 > $1    }
              
        
        let score = Int(sortedScores[indexPath.row])
        cell.textLabel!.text = String(score)
        //cell.tag = indexPath.row
        return cell
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
