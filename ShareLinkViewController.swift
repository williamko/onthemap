//
//  map.swift
//  test
//
//  Created by William Ko on 3/24/16.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import UIKit
import MapKit

class ShareLinkViewController: UIViewController {
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var shareLink: UITextField!
    var tapRecognizer: UITapGestureRecognizer? = nil
    var placeMark: MKPlacemark? = nil
    var locationString: String? = nil
//    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        submitButton.layer.cornerRadius = 10
        submitButton.clipsToBounds = true
        submitButton.backgroundColor = UIColor.whiteColor()
        submitButton.alpha = 0.8
        shareLink.text = "Enter a Link to Share Here"
//        imageView.hidden = true
//        imageView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        myActivityIndicator.hidden = true

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(cancel as Void -> Void))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()

        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Browse", style: .Plain, target: self, action: #selector(ShareLinkViewController.browse))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.whiteColor()

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ShareLinkViewController.handleSingleTap(_:)))
        tapRecognizer?.numberOfTapsRequired = 1
        
        
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.removeKeyboardDismissRecognizer()
    }
    

    // MARK: - Keyboard Fixes
    
    func addKeyboardDismissRecognizer() {
        self.view.addGestureRecognizer(tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer() {
        self.view.removeGestureRecognizer(tapRecognizer!)
    }
    
    //Action to dismiss the keyboard when a tap was performed outside the text view
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.addKeyboardDismissRecognizer()
        let applicationDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
        if let sl = applicationDelegate.shareLink{
            shareLink.text = sl
        }
        
        //The geocoding
        if let address = locationString{
            let geocoder = CLGeocoder()
            geoCodingStarted() // handles the blackness of the image view and the display of the activity indicator
            self.myActivityIndicator.hidden = false
            self.myActivityIndicator.startAnimating()
            geocoder.geocodeAddressString(address, completionHandler: { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                if let _ = error {
                    let alert = UIAlertController(title: "", message: "Geocoding failed", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancel))
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    if let placemark = placemarks?[0] {
                        self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
                        self.placeMark = MKPlacemark(placemark: placemark)
                        //Center the map
                        let p = MKPlacemark(placemark: placemark)
                        let span = MKCoordinateSpanMake(5, 5)
                        let region = MKCoordinateRegion(center: p.location!.coordinate, span: span)
                        self.mapView.setRegion(region, animated: true)
                        self.myActivityIndicator.startAnimating()
                    }
                }
                self.geoCodingStoped() // handles the blackness of the image view and the display of the activity indicator
                self.myActivityIndicator.hidden = true
                self.myActivityIndicator.stopAnimating()

            })
        }
    }
    
    //MARK: BUtton Actions
    //Browse for a URL.
    func browse(){
        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("SubmitLinkViewController") as! SubmitLinkViewController
        self.navigationController?.pushViewController(detailController, animated: true)
    }
    
    func cancel(){
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Cancel action from an Alert view
    func cancel(action:UIAlertAction! ){
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Check for a valid URL
    func checkURL(str:String) -> Bool{
        if (str.characters.count < 7){
            return false
        }else{
            return str.substringWithRange(str.startIndex.advancedBy(0) ..< str.startIndex.advancedBy(7)) == "http://"
        }
    }
    
    //Submit the Location and link.
    @IBAction func submitAction(sender: UIButton) {
        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        if (networkStatus.rawValue == NotReachable.rawValue) {// Before quering for an existing location check if there is an available internet connection
            displayMessageBox("No Network Connection")
        } else {
            if shareLink.text ==  "Enter a Link to Share Here" || !checkURL(shareLink.text!){
                displayMessageBox("You should enter a Valid URL")
            }else{
                if placeMark == nil{
                    displayMessageBox("We didn't find any location. Try Again")
                }else{
                    //Set the Account's next retrieved fields (First Name,Last Name was already retrieved from loging in)
                    UdacityClient.sharedInstance().account?.mapString = locationString
                    UdacityClient.sharedInstance().account?.mediaURL = shareLink.text
                    UdacityClient.sharedInstance().account?.latitude = placeMark!.coordinate.latitude
                    UdacityClient.sharedInstance().account?.longtitude = placeMark!.coordinate.longitude
                    
                    _ = UdacityClient.sharedInstance().account?.objectId //Get the objectId to update the record
                    if let _ = UdacityClient.sharedInstance().account?.objectId {
                        UdacityClient.sharedInstance().updateAccountLocation(UdacityClient.sharedInstance().account!){ result,error in
                            if error != nil{
                                dispatch_async(dispatch_get_main_queue(),{
                                    self.displayMessageBox("Could not update Location")
                                })
                            }else if let r = result {
                                if r {
                                    dispatch_async(dispatch_get_main_queue(),{
                                        let alert = UIAlertController(title: "", message: "Location updated", preferredStyle: UIAlertControllerStyle.Alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancel))
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    })
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),{
                                        self.displayMessageBox("Could not save Location")
                                    })
                                }
                            }
                        }
                    }else{ //If the record was not present create a new record.
                        UdacityClient.sharedInstance().saveAccountLocation(UdacityClient.sharedInstance().account!){ result,error in
                            if error != nil{
                                dispatch_async(dispatch_get_main_queue(),{
                                    self.displayMessageBox("Could not save Location")
                                })
                            }else if let r = result {
                                if r {
                                    dispatch_async(dispatch_get_main_queue(),{
                                        let alert = UIAlertController(title: "", message: "Location Saved", preferredStyle: UIAlertControllerStyle.Alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancel))
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    })
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),{
                                        self.displayMessageBox("Could not save Location")
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //MARK: Other
    // Start showing Activity indicator and the black transparent image view
    func geoCodingStarted(){
//        imageView.hidden = false
        myActivityIndicator.startAnimating()
    }
    
    // Start showing Activity indicator and the black transparent image view
    func geoCodingStoped(){
//        imageView.hidden = true
        myActivityIndicator.stopAnimating()
    }
    
    
    //Displays a basic alert box with the OK button and a message.
    func displayMessageBox(message:String){
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
