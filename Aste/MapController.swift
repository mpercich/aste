//
//  MapController.swift
//  Aste
//
//  Created by Michele on 25/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import MapKit

class MapController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var mapView: MKMapView!

    var coordinates: String?
    let regionRadius: CLLocationDistance = 1000
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var initialLocation: CLLocation
        if let assumedCoordinates = coordinates {
            var coordinatesArr = assumedCoordinates.components(separatedBy: ",")
            let latitude = Double(coordinatesArr[0])
            let longitude = Double(coordinatesArr[1])
            initialLocation = CLLocation(latitude: latitude!, longitude: longitude!)
            
            centerMapOnLocation(location: initialLocation)
        }
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
