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

class DetailViewController: UIViewController {

    
    var webView: WKWebView!
    var asta: FIRDataSnapshot?
    
    @IBAction func share(_ sender: Any) {
        if let asta = asta {
            let subject = "Asta in " + (asta.childSnapshot(forPath: "Indirizzo").value as! String) + " prezzo: " + TableViewController.formatPrice(value: asta.childSnapshot(forPath: "Prezzo").value)
            let content = "http://www.astegiudiziarie.it" + (asta.childSnapshot(forPath: "Link").value as! String).replacingOccurrences(of: "Scheda", with: "secondasel").replacingOccurrences(of: "idl", with: "id")
            let objectsToShare = [content]
            let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityViewController.setValue(subject, forKey: "Subject")
            present(activityViewController, animated: true, completion: {})
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
