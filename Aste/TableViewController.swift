//
//  TableViewController.swift
//  Aste
//
//  Created by Michele on 23/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import Firebase

class TableViewController: UITableViewController {
    
    // your data source, you can replace this with your own model if you wish
    var aste: Array<FIRDataSnapshot> = []
    lazy var asteRef: FIRDatabaseReference = FIRDatabase.database().reference()
    lazy var asteQuery: FIRDatabaseQuery = self.asteRef.queryOrdered(byChild: "Prezzo")
    var selectedAsta: FIRDataSnapshot?
    var rowToScroll: String?
    var read: Array<String> = []
    lazy var hideRead: Bool =  UserDefaults.standard.bool(forKey: "HideRead")
    let cellHeight: CGFloat = 132;
    
    @IBAction func leftButtonClicked(_ sender: UIBarButtonItem) {
        hideRead = !hideRead
        if hideRead {
            sender.title = "Show All"
        } else {
            sender.title = "Hide Read"
        }
        UserDefaults.standard.set(hideRead, forKey: "HideRead")
        tableView.reloadSections([0], with: UITableViewRowAnimation.automatic)
    }
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        if hideRead {
            navigationItem.leftBarButtonItem?.title = "Show All"
        } else {
            navigationItem.leftBarButtonItem?.title = "Hide Read"
        }
        if let readUnwrapped = UserDefaults.standard.object(forKey: "Read") {
            read = readUnwrapped as! Array<String>
        }
        FIRDatabase.database().persistenceEnabled = true
        asteQuery.keepSynced(true)
        asteQuery.observeSingleEvent(of: .value, with: { (snapshot) in
            for snap in snapshot.children {
                self.aste.append(snap as! FIRDataSnapshot)
            }
            self.aste.sort{$0.childSnapshot(forPath: "Prezzo").value as! Int > $1.childSnapshot(forPath: "Prezzo").value as! Int}
            self.tableView.reloadData()
            self.scroll()
            self.setObservers()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func setObservers() {
        asteQuery.observe(.childAdded, with: { (snapshot) -> Void in
            if self.indexBySnapshotKey(snapshot: snapshot) == nil {
                self.insertRow(content: snapshot)
            }
        })
        asteQuery.observe(.childChanged, with: { (snapshot) -> Void in
            if let index = self.indexBySnapshotKey(snapshot: snapshot) {
                let indexPath = IndexPath(row: index, section: 0)
                self.removeRead(at: indexPath)
                self.aste[index] = snapshot
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            }
        })
        asteQuery.observe(.childRemoved, with: { (snapshot) -> Void in
            if let index = self.indexBySnapshotKey(snapshot: snapshot) {
                let indexPath = IndexPath(row: index, section: 0)
                self.removeRead(at: indexPath)
                self.aste.remove(at: index)
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            }
        })
    }
    
    func scroll() {
        if let row = rowToScroll {
            if let index = indexByKey(key: row) {
                let indexPath = IndexPath(row: index, section: 0)
                removeRead(at: indexPath)                
                tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
                rowToScroll = nil
            }
        }
    }
    
    func insertRow(content: FIRDataSnapshot) {
        let index = indexBySnapshotPrice(snapshot: content)
        aste.insert(content, at: index)
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
    }
    
    func indexBySnapshotKey(snapshot: FIRDataSnapshot) -> Int? {
        var index = 0
        for asta in aste {
            if snapshot.key == asta.key {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func indexByKey(key: String) -> Int? {
        var index = 0
        for asta in aste {
            if asta.key == key {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func indexBySnapshotPrice(snapshot: FIRDataSnapshot) -> Int {
        var index = 0
        for asta in aste {
            if snapshot.childSnapshot(forPath: "Prezzo").value as! Int >= asta.childSnapshot(forPath: "Prezzo").value as! Int {
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
    
    func cellSwipped(sender: UISwipeGestureRecognizer) {
        let swipeLocation = sender.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: swipeLocation)
        let cell = tableView.cellForRow(at: indexPath!)
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.right:
            cell?.contentView.layer.opacity = 1
            if let indexPathUnwrapped = indexPath {
                removeRead(at: indexPathUnwrapped)
            }
        case UISwipeGestureRecognizerDirection.left:
            cell?.contentView.layer.opacity = 0.5
            if let row = indexPath?.row {
                if !read.contains(aste[row].key) {
                    read.append(aste[row].key)
                    UserDefaults.standard.set(read, forKey: "Read")
                    tableView.reloadRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                }
            }
        default:
            break
        }
        
    }
    
    func removeRead(at: IndexPath) {
        if let index = read.index(of: aste[(at.row)].key) {
            read.remove(at: index)
            UserDefaults.standard.set(read, forKey: "Read")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create a variable that you want to send based on the destination view controller
        // You can get a reference to the data by using indexPath shown below
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAsta = aste[indexPath.row]
        var segueIdentifier: String
        if selectedAsta?.childSnapshot(forPath: "Coordinate").value as! String != ""  {
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
                    destinationVC.asta = selectedAsta
                    print("\(destinationVC.asta?.key)")
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
        if read.contains(aste[indexPath.row].key) {
            cell.contentView.layer.opacity = 0.5
        }
        return cell
    }    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if hideRead && read.index(of: aste[(indexPath.row)].key) != nil {
            return 0;
        }
        return cellHeight;
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


