//
//  ReportLocation.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate {
    func locationReceived(location:[CLLocation])
}

class ReportLocation: NSObject, CLLocationManagerDelegate {

    // MARK: Properties
    
    let locManager = CLLocationManager()

    var delegate: LocationServiceDelegate?
    
    // MARK: Functions
    
    // Start Location
    func startLocation() {
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.startUpdatingLocation()
    }
    
    // Stop Location
    func stopLocation() {
        locManager.stopUpdatingLocation()
        locManager.delegate = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("New location received: \(locations.description)")
        
        if locations.first?.horizontalAccuracy < 0 {
            return
        }
        
        if locations.first?.horizontalAccuracy <= 500 {
            self.delegate!.locationReceived(locations)
        }
    }
    
    // Did fail with error
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error getting location: \(error.description)")
    }
}