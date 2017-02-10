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
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager.activityType = .automotiveNavigation
        _locationManager.distanceFilter = 10.0  // Movement threshold for new events
        //  _locationManager.allowsBackgroundLocationUpdates = true // allow in background
        
        return _locationManager
    }()
    lazy var address: String? = self.asta?.childSnapshot(forPath: "Indirizzo").value as? String
    lazy var coordinates: String? = self.asta?.childSnapshot(forPath: "Coordinate").value as? String
    lazy var price: String? = TableViewController.formatPrice(value: self.asta?.childSnapshot(forPath: "Prezzo").value)
    
    override var prefersStatusBarHidden: Bool {
        get {            
            return false
        }
    }
    
    func centerMapOnLocation(userLocation: CLLocation, location: CLLocation) {
        
        var annotationPoint = MKMapPointForCoordinate(userLocation.coordinate);
        var zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        annotationPoint = MKMapPointForCoordinate(location.coordinate);
        let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        zoomRect = MKMapRectUnion(zoomRect, pointRect)
        var region = MKCoordinateRegionForMapRect(zoomRect);
        region.span.latitudeDelta *= 1.5;   // Increase span by 20% to add some margin
        region.span.longitudeDelta *= 1.5;
        mapView.setRegion(region, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detail = segue.destination as! DetailViewController
            detail.asta = asta
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        title = address
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    
// MARK: - CLLocationManagerDelegate
extension MapController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //add annotation just first time
        if mapView.annotations.isEmpty {
            locationManager.stopUpdatingLocation()
            let userLocation = locations.first!
            mapView.showsUserLocation = true
            if let assumedCoordinates = coordinates {
                var coordinatesArr = assumedCoordinates.components(separatedBy: ",")
                if coordinatesArr.count == 2 {
                    let latitude = Double(coordinatesArr[0])
                    let longitude = Double(coordinatesArr[1])
                    let astaLocation = CLLocation(latitude: latitude!, longitude: longitude!)
                    centerMapOnLocation(userLocation: userLocation, location: astaLocation)
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = astaLocation.coordinate
                    dropPin.subtitle = address
                    dropPin.title = price
                    mapView.addAnnotation(dropPin)
                }
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension MapController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.animatesDrop = true
            pinView?.pinTintColor = MKPinAnnotationView.redPinColor()
            pinView?.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if asta?.key != nil {
                performSegue(withIdentifier: "ShowDetail", sender: view)
            }
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

