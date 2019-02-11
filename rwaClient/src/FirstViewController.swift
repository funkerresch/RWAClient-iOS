//
//  FirstViewController.swift
//  rwa client
//
//  Created by Thomas Resch on 28/12/15.
//  Copyright © 2015 beryllium design. All rights reserved.
//

import UIKit

var hero:RwaEntity = RwaEntity(name: "me")
var compassAzimuth:Float = Float()
var currentGame:String = ""

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PdListener {

    @IBOutlet var gameTable:UITableView!
    
    var rwaimport:RwaImport = RwaImport()
    var games:GameManager = GameManager()
    
    func loadGameAndInitDynamicPatchers(game: String) {
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            self.rwaimport.readRwa(currentGame)
            rwagameloop.initDynamicPatchers()
            group.leave()
        }
        
        group.notify(queue: .main) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Game Loaded"), object: nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        games.populateGames()
        hero.coordinates.latitude = 47.5546492;
        hero.coordinates.longitude = 7.5594406;
        
        if games.rwaGames.count == 1 {
            
            loadGameAndInitDynamicPatchers(game: games.rwaGames[0].name)
            currentGame = games.rwaGames[0].name
            
            if(tabBarController != nil){
                tabBarController?.selectedIndex = 1
                if let tabBarController = self.tabBarController {
                    let indexToRemove = 0
                    if indexToRemove < (tabBarController.viewControllers?.count)! {
                        var viewControllers = tabBarController.viewControllers
                        viewControllers?.remove(at: indexToRemove)
                        tabBarController.viewControllers = viewControllers
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        gameTable.reloadData()
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return games.rwaGames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Default")

        cell.textLabel!.text = games.rwaGames[indexPath.row].name
        cell.detailTextLabel!.text = games.rwaGames[indexPath.row].path
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cell = tableView.cellForRow(at: indexPath)
        currentGame = (cell?.textLabel?.text)!
        if(tabBarController != nil) {
            tabBarController?.selectedIndex = 1 }
        
        loadGameAndInitDynamicPatchers(game: (cell?.textLabel?.text)!)
    }
}

