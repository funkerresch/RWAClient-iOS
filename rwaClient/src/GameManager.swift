//
//  GameManager.swift
//  rwa client
//
//  Created by Admin on 28/12/15.
//  Copyright © 2015 beryllium design. All rights reserved.
//

import UIKit

var gameMgr: GameManager = GameManager();


//var someInts = [Int]()

struct rwagame
{
    var name = "default"
    var path = "default"
}

class GameManager: NSObject
{
    
    var rwaGames = [rwagame]()
    var gamesPath:String = Bundle.main.resourcePath!
    
    
    func addGame(_ name:String, path:String)
    {
        rwaGames.append(rwagame(name:name, path:path))
        print("APPEND GAME, COUNT IS \(rwaGames.count)")
    }
    
    func populateGames()
    {
        let fileManager = FileManager.default
        let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: gamesPath)!
        while let element = enumerator.nextObject() as? String
        {
            if element.hasSuffix("rwa")
            {
                print(element)
                addGame(element, path: "")
                
            }
        }
    }
}
