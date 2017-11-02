//
//  WebViewController.swift
//  On The Map
//  It displays a simple web view and loads a url which was most probably passed from
//  Another view.
//  Created by William Ko on 3/24/16.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    @IBOutlet var webView: UIWebView!
    
    var url:NSURL? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let u = url{
            let req = NSURLRequest(URL:u)
            self.webView!.loadRequest(req)
        }
    }
}
