//
//  ViewController.swift
//  On The Map
//
//  Created by William Ko on 3/24/16.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,FBSDKLoginButtonDelegate,UINavigationControllerDelegate {

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton! // the facebook login button
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet var infoImageView: UIImageView! //Image view to for the nice display of a information message
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var tapRecognizer: UITapGestureRecognizer? = nil // It releases the keyboard if the user taps outside of the textboxes

    //Structures to check for network availability
    var networkReachability:Reachability = Reachability()
    var networkStatus:NetworkStatus = NotReachable

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        infoImageView?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.70)
        infoImageView.hidden = true
        infoLabel.hidden = true
        activityIndicator.hidden = true
        self.fbLoginButton.delegate = self
        self.fbLoginButton.loginBehavior = FBSDKLoginBehavior.Web
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)


        self.fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.onProfileUpdated(_:)), name:FBSDKProfileDidChangeNotification, object: nil)
 
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.handleSingleTap(_:)))
        tapRecognizer?.numberOfTapsRequired = 1

        //Initialize structure for checking network availability
        let networkReachability:Reachability = Reachability.reachabilityForInternetConnection()
        var _:NetworkStatus = networkReachability.currentReachabilityStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.hidden = true
        self.navigationController?.toolbar.hidden = true
        
        /* Add tap recognizer to dismiss keyboard */
        self.addKeyboardDismissRecognizer()
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
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    // MARK: - Button Actions
    @IBAction func basicLoginButtonTouch(sender: AnyObject) {
        self.view.endEditing(true)
        UdacityClient.sharedInstance().authenticateBasicLoginWithViewController(self) { (success, errorString) in
            if success {
                self.completeLogin()
            } else {
                self.displayMessage(errorString!)
            }
        }
    }
    
    
    @IBAction func touched(sender: FBSDKLoginButton) {
    }
    //It opens up Safari to create a new Account
    @IBAction func newAccount(sender: UIButton) {
        let request = NSURLRequest(URL: NSURL(string: "https://www.udacity.com/account/auth#!/signup")!)
        UIApplication.sharedApplication().openURL(request.URL!)
    }

    //MARK: - Other
    func displayError(errorString: String?) {
        dispatch_async(dispatch_get_main_queue(), {
            if let errorString = errorString {
                print(errorString)
            }
        })
    }
    
    func completeLogin(){ // prepares the display of the next view
        dispatch_async(dispatch_get_main_queue(), {

        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("AppTabBarController") as! UITabBarController
            self.navigationController!.presentViewController(detailController, animated: true) {
                self.navigationController?.popViewControllerAnimated(true)
                return ()
            }
        })
       indicator(false)
    }
    
    //For facebook login function. It returns from facebook to check for
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        indicator(true)
        UdacityClient.sharedInstance().authenticateFacebookLoginWithViewController(self) { (success, errorString) in
            if success {
                self.completeLogin()
            } else {
                self.displayMessage(errorString!)
            }
        }
    }
    
    func onProfileUpdated(notification: NSNotification)
    {
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    }
    
    //Displays a message in a nice manner on top of an image view with alpha value.
    func displayMessage(message:String){
        infoImageView.hidden = false
        infoLabel.hidden = false
        infoLabel.text = message
        
        let delay = 1.6 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.infoImageView.hidden = true
            self.infoLabel.hidden = true
        }
    }
    
    //Displays the indicator and an image view with alpha 0.8 to show background shaded
    func indicator(animate:Bool){
        if(animate){
            infoImageView.hidden = false
            infoLabel.hidden = true
            activityIndicator.startAnimating()
        }else{
            infoImageView.hidden = true
            infoLabel.hidden = true
            activityIndicator.stopAnimating()
        }
    }
    
    //Displays a basic alert box with the OK button and a message.
    func displayMessageBox(message:String){
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

}