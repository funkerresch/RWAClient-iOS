//
//  AppDelegate.swift
//  rwa client
//
//  Created by Admin on 28/12/15.
//  Copyright © 2015 beryllium design. All rights reserved.
//

import UIKit

var coreLocationController:CoreLocationController?
var registered = false;
var headtrackerID = ""
var rwaCreatorIP = ""
var inverseElevation = true;

struct defaultsKeys {
    static let headtrackerId = "rwaht01"
    static let simulatorIp = "192.168.43.163"
    static let inverseElevation = "true";
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var audioController:PdAudioController?
 
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        audioController = PdAudioController()
        
        let defaults = UserDefaults.standard
        if let simulatorIp = defaults.string(forKey: defaultsKeys.simulatorIp) {
            rwaCreatorIP = simulatorIp
        }
        else {
            rwaCreatorIP = "192.168.1.1"
        }
        
        if let headtracker = defaults.string(forKey: defaultsKeys.headtrackerId) {
            headtrackerID = headtracker
        }
        else {
            headtrackerID = "rwaht00"
        }
        
        if let eleInv = defaults.string(forKey: defaultsKeys.inverseElevation) {
            if eleInv == "true" {
                inverseElevation = true;
            }
            else {
                inverseElevation = false;
            }
        }
        else {
            inverseElevation = true;
        }
       
        if let c = audioController
        {
            
           // let s = c.configureAmbient(withSampleRate: 44100, numberChannels: 2, mixingEnabled: true).toPdAudioControlStatus()
            
          
            let s = c.configurePlayback(withSampleRate: 44100, numberChannels: 2, inputEnabled: true, mixingEnabled: true).toPdAudioControlStatus()
            //let s = c.configurePlaybackWithSampleRate(44100, numberChannels: 2, inputEnabled: false, mixingEnabled: true).toPdAudioControlStatus()
            c.configureTicksPerBuffer(16)
            switch s{
            case .OK:
                print("succes");
            default:
                print("no succes");
                
            }
        }
        else
        {
            print("Could not init audiocontroller")
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }


    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
            //audioController?.configureTicksPerBuffer(512)
            audioController?.isActive = true
       }

    func applicationWillTerminate(_ application: UIApplication) {
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

//MARK: - CONVERT ENUM FOR SWIFT

extension PdAudioStatus {
    enum PdAudioControlStatus {
        case OK
        case Error
        case PropertyChanged
    }
    func toPdAudioControlStatus() -> PdAudioControlStatus {
        switch self.rawValue {
        case 0: //
            return .OK
        case -1: //
            return .Error
        default: //
            return .PropertyChanged
        }
    }
}

