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
var downloadManager = DownloadManager.shared
var documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
var games2Download = [String]()
var gameIsInDocumentsFolder:Bool = Bool();
var fullGamePath:String = String();
var fullAssetPath:String = String();

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, PdListener {

    @IBOutlet var gameTable:UITableView!
    @IBOutlet var motherIp: UITextField!
    @IBOutlet var fetch: UIButton!
    
    var rwaimport:RwaImport = RwaImport()
    var games:GameManager = GameManager()
    
    func emptyDocumentsDirectory()
    {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
                print("remove " + fileURL.lastPathComponent )
            }
        } catch  {
            print(error)
        }
    }
    
    func createDirectoryInDocuments(dirName:String)
    {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        if let documentsURL = documentsURL
        {
            let destURL = documentsURL.appendingPathComponent("assets")
            FileManager.createDirectory(myDir: destURL)
            print(destURL.relativePath)
        }
    }
    
    func copyRwaGamesFromBundleToDocumentsFolder()
    {
        if let resPath = Bundle.main.resourcePath {
            do
            {
                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
                let filteredFiles = dirContents.filter{ $0.contains(".rwa")}
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                {
                    for fileName in filteredFiles {
                        
                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
                        let destURL = documentsURL.appendingPathComponent(fileName)
                        do {
                            FileManager.default.secureCopyItem(at: sourceURL, to: destURL)
                        }
                    }
                }
            } catch { }
        }
    }
    
    func copyRwaAssetsFromBundleToDocumentsFolder()
    {
        if let resPath = Bundle.main.resourcePath {
            do
            {
                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
                var filteredFiles = dirContents.filter{ $0.contains(".aif")}
                filteredFiles += dirContents.filter{ $0.contains(".wav")}
                filteredFiles += dirContents.filter{ $0.contains(".pd")}
                
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                {
                    for fileName in filteredFiles {
                        
                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
                        let destURL = documentsURL.appendingPathComponent("assets").appendingPathComponent(fileName)
                        do {
                            FileManager.default.secureCopyItem(at: sourceURL, to: destURL)
                        }
                    }
                }
            } catch { }
        }
    }
    
    @ objc func nameOfFunction(notif: NSNotification) {
        
        for game in games2Download
        {
            let remoteUrl = URL(string: "http://"+rwaCreatorIP+":8088/" + game)!
            downloadManager.startDownload(url: remoteUrl)
        }
    }
    
    @ objc func updateGamesList(notif: NSNotification) {
        print("Recievied updte Gamelist")
        games.populateGames()
        
        DispatchQueue.main.async {
            self.gameTable.reloadData()
        }
    }
    
    @IBAction func fetchGames(_ sender: UIButton)
    {
        self.games.clear()
        let remoteURL = URL(string: "http://"+rwaCreatorIP+":8088/allfiles.txt")!
        downloadManager.startDownload(url: remoteURL)
    }
    
    func loadGameAndInitDynamicPatchers(game: String) {
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            self.rwaimport.readRwa(game)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.nameOfFunction), name: NSNotification.Name(rawValue: "receivedGameList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateGamesList), name: NSNotification.Name(rawValue: "receivedGame"), object: nil)
        
        createDirectoryInDocuments(dirName: "assets")
        copyRwaGamesFromBundleToDocumentsFolder();
        copyRwaAssetsFromBundleToDocumentsFolder();
        self.games.populateGames()
        self.gameTable.reloadData()
        
        motherIp.text = rwaCreatorIP
        hero.coordinates.latitude = 47.5546492;
        hero.coordinates.longitude = 7.5594406;
        motherIp.delegate = self
        
        if games.rwaGames.count == 1 {
            print(games.rwaGames[0].path)
            print(games.rwaGames[0].name)
//            loadGameAndInitDynamicPatchers(game: games.rwaGames[0].name)
//            currentGame = games.rwaGames[0].name
//            if let tabBarController = self.tabBarController {
//                tabBarController.selectedIndex = 1
//            }
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
        
        let comps = currentGame.components(separatedBy: "/")
        if(comps.count > 1) {
            fullAssetPath = (cell?.detailTextLabel?.text)! + "/" + comps[0] + "/assets"
        }
        else {
            fullAssetPath = (cell?.detailTextLabel?.text)! + "/" + "assets"
            gameIsInDocumentsFolder = true;
        }
        
        fullGamePath =  (cell?.detailTextLabel?.text)! + "/" + currentGame

        print(fullGamePath)
        print(fullAssetPath)
      
        loadGameAndInitDynamicPatchers(game: fullGamePath)
        
        if(tabBarController != nil) {
            tabBarController?.selectedIndex = 1 }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder();
        let defaults = UserDefaults.standard
        rwaCreatorIP = motherIp.text!
        defaults.set(motherIp.text, forKey: defaultsKeys.rwaCreatorIP)
        return true;
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        return true
    }
}

