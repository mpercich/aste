//
//  DetailViewController.swift
//  Aste
//
//  Created by Michele on 11/12/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import SSZipArchive
import WebKit
import NHCalendarActivity
import EventKitUI

class DetailViewController: UIViewController {

    
    var webView: WKWebView!
    var asta: FIRDataSnapshot?
    
    @IBAction func share(_ sender: Any) {
        if let asta = asta {
            if let address = asta.childSnapshot(forPath: "Indirizzo").value as? String {
                let subject = "Asta in " + address + " prezzo: " + TableViewController.formatPrice(value: asta.childSnapshot(forPath: "Prezzo").value)
                let content = "http://www.astegiudiziarie.it" + (asta.childSnapshot(forPath: "Link").value as! String).replacingOccurrences(of: "Scheda", with: "secondasel").replacingOccurrences(of: "idl", with: "id")
                var objectsToShare: [Any] = [content]
                var applicationActivities: [UIActivity] = []
                var calendarActivity: NHCalendarActivity? = nil
                if let dateString = (asta.childSnapshot(forPath: "Data").value as? String)?.replacingOccurrences(of: "ore ", with: "") {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMMM y HH.mm"
                    dateFormatter.locale = NSLocale(localeIdentifier: "it-IT") as Locale!
                    let date = dateFormatter.date(from: dateString)
                    let calendarEvent = NHCalendarEvent()
                    calendarEvent.title = subject;
                    calendarEvent.notes = content;
                    calendarEvent.startDate = date;
                    calendarEvent.endDate = date?.addingTimeInterval(1*60*60);
                    calendarEvent.allDay = false;
                    objectsToShare.append(calendarEvent)
                    calendarActivity = NHCalendarActivity()
                    applicationActivities.append(calendarActivity!)
                    calendarActivity?.delegate = self
                    //applicationActivities?.append(NHCalendarActivity())
                }
                let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: applicationActivities)
                activityViewController.setValue(subject, forKey: "Subject")
                present(activityViewController, animated: true, completion: {})
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let key = asta?.key {
            // Create a reference with an initial file path and name
            let storage = FIRStorage.storage()
            // Create a storage reference from our storage service
            let storageRef = storage.reference(forURL: "gs://aste-404d3.appspot.com")
            let fileName = key + ".zip"
            let astaRef = storageRef.child(fileName)
            let sourceURL: URL! = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) as URL!
            let targetURL: URL! = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(key) as URL!
            let targetFile: URL! = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(key)?.appendingPathComponent("main.html") as URL!
            // Download to the local filesystem        
            astaRef.write(toFile: sourceURL) { (URL, error) -> Void in
                if error != nil {
                    return
                } else {
                    do {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    catch {
                        print("remove failed!")
                    }
                    SSZipArchive.unzipFile(atPath: sourceURL.path, toDestination: targetURL.path)
                    self.webView.loadFileURL(targetFile, allowingReadAccessTo: targetFile)
                }
            }
        }
    }

    override func loadView() {
        super.loadView()
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    func displayShareSheet(shareContent: String) {
        let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    func createCalendarEvent() -> NHCalendarEvent {
        let calendarEvent = NHCalendarEvent()
        calendarEvent.title = "Long-expected Party";
        calendarEvent.location = "The Shire";
        calendarEvent.notes = "Bilbo's eleventy-first birthday.";
        //calendarEvent.startDate = [NSDate dateWithTimeIntervalSinceNow:3600];
        //calendarEvent.endDate = [NSDate dateWithTimeInterval:3600 sinceDate:calendarEvent.startDate];
        //calendarEvent.allDay = NO;
        return calendarEvent;
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

// MARK: - UIWebViewDelegate
extension DetailViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        print("webView:\(webView) didFailNavigation:\(navigation) withError:\(error)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        print(navigationAction.request)
        var url = navigationAction.request.url
        let urlString = navigationAction.request.url?.path
        if let key = asta?.key {
            if !(urlString?.hasSuffix(key))! && !(urlString?.hasSuffix(".pdf"))! && !(urlString?.hasSuffix(".html"))! && !(urlString?.hasSuffix(".aspx"))!  {
                url = url?.appendingPathExtension("pdf")
                do {
                    try FileManager.default.moveItem(at: navigationAction.request.url!, to: url!)
                }
                catch {
                    print("rename failed!")
                    decisionHandler(.cancel)
                    return
                }
                webView.load(URLRequest(url: url!))
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
        return
    }
}

// MARK: - NHCalendarActivityDelegate
extension DetailViewController: NHCalendarActivityDelegate {
    
    func calendarActivityDidFinish(_ event: NHCalendarEvent) {
        let store = EKEventStore()
        store.requestAccess(to: EKEntityType.event, completion: {
            granted, error in
            if granted {
                print("Got access")
            } else {
                print("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
            }
        })
        let calendar = store.defaultCalendarForNewEvents
        let alert = UIAlertController(title: "New Event", message: "Event added to calendar \(calendar.title): \(event.title!)\nDo you want to edit it?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            // Use an event store instance to create and properly configure an NSPredicate
            let eventsPredicate = store.predicateForEvents(withStart: event.startDate, end: event.endDate, calendars: [calendar])
            // Use the configured NSPredicate to find and return events in the store that match
            let events = store.events(matching: eventsPredicate)
            let eventController = EKEventEditViewController()
            let thisEvent = events[0] as EKEvent
            eventController.event = thisEvent
            eventController.editViewDelegate = self
            self.present(eventController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        print("Event created from \(event.startDate) to \(event.endDate)")
    }
    
    func calendarActivityDidFail(_ event: NHCalendarEvent!, withError error: Error!) {
        print("calendarActivityDidFail: \(error.localizedDescription)")
    }
    
    func calendarActivityDidFailWithError(_ error: Error!) {
        print("calendarActivityDidFailWithError: \(error.localizedDescription)")
    }
}

// MARK: - EKEventEditViewDelegate
extension DetailViewController: EKEventEditViewDelegate {

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch (action) {
            case .saved:
                do {
                    try controller.eventStore.save(controller.event!, span: .futureEvents)
                }
                catch {
                    print("EKEventEditViewAction .saved failed!")
                }
            case .deleted:
                do {
                    try controller.eventStore.remove(controller.event!, span: .futureEvents)
                }
                catch {
                    print("EKEventEditViewAction .delete failed!")
                }
            default:
                break
        }
        self.dismiss(animated: true, completion: nil)
    }
}
