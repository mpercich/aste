//
//  DetailViewController.swift
//  Aste
//
//  Created by Michele on 11/12/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import FirebaseStorage
import SSZipArchive

class DetailViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var webView: UIWebView!

    var key: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = key
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
            if (error != nil) {
                return
            } else {
                do {
                    try FileManager.default.removeItem(at: targetURL)
                }
                catch {
                    print("remove failed!")
                }
                SSZipArchive.unzipFile(atPath: sourceURL.path, toDestination: targetURL.path)
                do {
                    let data = try NSData(contentsOf: targetFile, options: NSData.ReadingOptions())
                    self.webView.load(data as Data, mimeType: "text/html", textEncodingName: "UTF-8", baseURL: targetURL);
                }
                catch {
                    print("NSData failed!")
                }
            }
        }
        // Do any additional setup after loading the view.
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
extension DetailViewController : UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.isHidden = false
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print(error)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print(request)
        var url = request.url
        let urlString = request.url?.path
        if !(urlString?.hasSuffix(key))! && !(urlString?.hasSuffix(".pdf"))! && !(urlString?.hasSuffix(".html"))!  {
            url = url?.appendingPathExtension("pdf")
            do {
                try FileManager.default.moveItem(at: request.url!, to: url!)
            }
            catch {
                print("rename failed!")
                return true
            }
            webView.loadRequest(URLRequest(url: url!))
            return false
        }
        return true
    }
}
