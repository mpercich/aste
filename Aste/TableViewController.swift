//
//  TableViewController.swift
//  Aste
//
//  Created by Michele on 23/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications


class TableViewController: UITableViewController {
    // your data source, you can replace this with your own model if you wish
    var aste: Array<FIRDataSnapshot> = []
    lazy var asteRef: FIRDatabaseReference = FIRDatabase.database().reference()
    var asteQuery: FIRDatabaseQuery?
    var refHandle: FIRDatabaseHandle?
    var selectedAsta: FIRDataSnapshot?
    var rowToScroll: String?
    var read: Array<String> = []
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        read = defaults.object(forKey: "Read") as! Array<String>
        aste.removeAll()
        self.tableView.reloadData()
        var ignoreItems = true;
        // initialize the ref in viewDidLoad
        asteQuery = asteRef.queryOrdered(byChild: "Prezzo")
        asteRef.observeSingleEvent(of: .value, with: { (snapshot) in
            //let asteDict = snapshot.child as? [FIRDataSnapshot]
            ignoreItems = false
            for snap in snapshot.children {
                self.insertRow(content: snap as! FIRDataSnapshot)
            }
            self.scroll()
        })
        asteRef.observe(.childAdded, with: { (snapshot) -> Void in
            if (!ignoreItems) {
                self.insertRow(content: snapshot)
            }
        })
        // Listen for deleted aste in the Firebase database
        asteRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexBySnapshotKey(snapshot: snapshot)
            self.aste.remove(at: index)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
        })
        // [END child_event_listener]
        // [START post_value_event_listener]
        //        refHandle = asteQuery?.observe(.value, with: { (snapshot) in
        //            let asteDict = snapshot.value as? [String: AnyObject] ?? [:]
        //            for snap in asteDict
        //            {
        //                self.aste.append(snap)
        //                self.tableView.insertRows(at: [IndexPath(row: self.aste.count-1, section: 0)], with: UITableViewRowAnimation.automatic)
        //            }
        
        
        // [START_EXCLUDE]
        //self.asta.setValuesForKeys(asteDict)
        //self.tableView.reloadData()
        //self.navigationItem.title = self.asta.title
        // [END_EXCLUDE]
        //})
        // [END post_value_event_listener]
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func scroll() {
        if let row = self.rowToScroll {
            let index = self.indexByKey(key: row)
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
            self.rowToScroll = nil
        }
    }
    
    func insertRow(content: FIRDataSnapshot) {
        let index = self.indexBySnapshotPrice(snapshot: content)
        self.aste.insert(content, at: index)
        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
    }
    
    func indexBySnapshotKey(snapshot: FIRDataSnapshot) -> Int {
        var index = 0
        for asta in self.aste {
            if snapshot.key == asta.key {
                return index
            }
            index += 1
        }
        return 0
    }
    
    func indexByKey(key: String) -> Int {
        var index = 0
        for asta in self.aste {
            if asta.key == key {
                return index
            }
            index += 1
        }
        return 0
    }
    
    func indexBySnapshotPrice(snapshot: FIRDataSnapshot) -> Int {
        var index = 0
        for asta in self.aste {
            if (snapshot.childSnapshot(forPath: "Prezzo").value as! Int) >= (asta.childSnapshot(forPath: "Prezzo").value as! Int) {
                return index
            }
            index += 1
        }
        return index
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return aste.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! TableViewCell

        // Configure the cell...
        cell.key.text = aste[indexPath.row].key
        cell.price.text = TableViewController.formatPrice(value: aste[indexPath.row].childSnapshot(forPath: "Prezzo").value)
        cell.date.text = aste[indexPath.row].childSnapshot(forPath: "Data").value as? String
        cell.type.text = aste[indexPath.row].childSnapshot(forPath: "Tipologia").value as? String
        cell.property.text = aste[indexPath.row].childSnapshot(forPath: "Lotto").value as? String
        cell.sale.text = aste[indexPath.row].childSnapshot(forPath: "Vendita").value as? String
        cell.address.text = aste[indexPath.row].childSnapshot(forPath: "Indirizzo").value as? String
        cell.attachment.text = aste[indexPath.row].childSnapshot(forPath: "Allegati").value as? String
        var swipeGesture = UISwipeGestureRecognizer.init(target: self, action: #selector(cellSwipped(sender:)))
        cell.addGestureRecognizer(swipeGesture)
        swipeGesture = UISwipeGestureRecognizer.init(target: self, action: #selector(cellSwipped(sender:)))
        swipeGesture.direction = UISwipeGestureRecognizerDirection.left
        cell.addGestureRecognizer(swipeGesture)
        cell.contentView.layer.opacity = 1
        if (read.contains(aste[indexPath.row].key)) {
            cell.contentView.layer.opacity = 0.5
        }
        return cell
    }
    
    func cellSwipped(sender: UISwipeGestureRecognizer) {
        let swipeLocation = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: swipeLocation)
        let cell = self.tableView.cellForRow(at: indexPath!)
        let defaults = UserDefaults.standard
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.right:
            cell?.contentView.layer.opacity = 1
            if let index = read.index(of: aste[(indexPath?.row)!].key) {
                read.remove(at: index)
            }
        case UISwipeGestureRecognizerDirection.left:
            cell?.contentView.layer.opacity = 0.5
            read.append(aste[(indexPath?.row)!].key)
        default:
            break
        }        
        defaults.set(read, forKey: "Read")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create a variable that you want to send based on the destination view controller
        // You can get a reference to the data by using indexPath shown below
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAsta = aste[indexPath.row]
        var segueIdentifier: String
        if ((selectedAsta?.childSnapshot(forPath: "Coordinate").value as? String) != nil)  {
            segueIdentifier = "ShowMap"
        } else {
            segueIdentifier = "ShowDetail"
        }
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: segueIdentifier, sender: self)
        }        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
            case "ShowMap":
                if let destinationVC = segue.destination as? MapController {
                    destinationVC.asta = selectedAsta
                }
            case "ShowDetail":
                if let destinationVC = segue.destination as? DetailViewController {
                    destinationVC.key = (selectedAsta?.key)
                    print("\(destinationVC.key)")
                }
            default: break
        }
    }

    class func formatPrice(value: Any?) -> String {
        var result: String?
        let assumedPrice = value as? NSNumber
        if let price = assumedPrice {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "it_IT")
            formatter.numberStyle = .currency
            result = formatter.string(from: price)!
        }
        return result ?? ""
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
        
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}


