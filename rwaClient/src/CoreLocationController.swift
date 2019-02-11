//
//  CoreLocationController.swift
//  rwa client
//
//  Created by Admin on 29/12/15.
//  Copyright © 2015 beryllium design. All rights reserved.
//

import Foundation
import CoreLocation

class CoreLocationController:NSObject, CLLocationManagerDelegate{

    var locationManager:CLLocationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true;
        self.locationManager.pausesLocationUpdatesAutomatically = false;
        //self.locationManager.headingFilter = 1
        //self.locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus")
        
        switch status {
        case .notDetermined:
            print(".NotDetermined")
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .authorizedAlways:
            print(".Authorized")
            self.locationManager.startUpdatingLocation()
            break
            
        case .denied:
            print(".Denied")
            break
            
        default:
            print("Unhandled authorization status")
            break
            
        }
    }
    
   /* func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        print (heading.magneticHeading)
        compassAzimuth = Float(heading.magneticHeading)
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last! as CLLocation
        hero.location = location
        hero.coordinates = location.coordinate
        hero.timeSinceLastGpsUpdate = 0.0        
    }
}
