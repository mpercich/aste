//
//  DetailViewController.swift
//  Aste
//
//  Created by Michele on 11/12/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import FIRStorage

class DetailViewController: UIViewController {

    var key: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = key
        // Create a reference with an initial file path and name
        let storage = FIRStorage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.referenceForURL("gs://aste-404d3.appspot.com")
        let astaRef = storageRef.child(key)

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
