//
//  MapController.swift
//  Aste
//
//  Created by Michele on 25/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import CoreLocation

class MapController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var mapView: MKMapView!

    var asta: FIRDataSnapshot?
    let regionRadius: CLLocationDistance = 1000
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager.activityType = .automotiveNavigation
        _locationManager.distanceFilter = 10.0  // Movement threshold for new events
        //  _locationManager.allowsBackgroundLocationUpdates = true // allow in background
        
        return _locationManager
    }()
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    
// MARK: - CLLocationManagerDelegate
extension MapController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        let initialLocation = locations.first!
        centerMapOnLocation(location: initialLocation)
        mapView.showsUserLocation = true
        let coordinates = asta?.childSnapshot(forPath: "Coordinate").value as? String
        if let assumedCoordinates = coordinates {
            var coordinatesArr = assumedCoordinates.components(separatedBy: ",")
            let latitude = Double(coordinatesArr[0])
            let longitude = Double(coordinatesArr[1])
            let initialLocation = CLLocation(latitude: latitude!, longitude: longitude!)
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = initialLocation.coordinate
            dropPin.subtitle = asta?.childSnapshot(forPath: "Indirizzo").value as? String
            dropPin.title = TableViewController.formatPrice(value: asta?.childSnapshot(forPath: "Prezzo").value)
            mapView.addAnnotation(dropPin)
        }
    }
        
}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

