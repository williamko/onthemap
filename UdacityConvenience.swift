//
//  UdacityConvenience.swift
//  On The Map
//
//  Created by William Ko on 3/24/16.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import UIKit
import Foundation

extension UdacityClient {
    
    //Login authentication with using Udacity Username and Password
    func authenticateBasicLoginWithViewController(hostViewController: LoginViewController, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        
        if(hostViewController.usernameTextField.text != nil && hostViewController.passwordTextField != nil){
            if(networkStatus.rawValue != NotReachable.rawValue){// Before quering fοr an existing location check if there is an available internet connection
                hostViewController.indicator(true)
                self.getSessionID( hostViewController.usernameTextField.text! , password: hostViewController.passwordTextField.text!) { result, errorString in
                    if (result != nil) {
                        self.getPublicUserData(self.uniqueKey!)  { account,errorString in
                            if account != nil{
                                completionHandler(success: true, errorString: nil)
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            hostViewController.indicator(false)
                            completionHandler(success: false, errorString: "Wrong Username/Password")
                        })
                    }
                }
            }else{
                hostViewController.indicator(false)
                completionHandler(success: false, errorString: "No Network Connection")
            }
        }
    }
    
    //Login authentication with using Facebook Account
    func authenticateFacebookLoginWithViewController(hostViewController: LoginViewController, completionHandler: (success: Bool, errorString: String?) -> Void) {
        hostViewController.indicator(true)
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.getSessionFacebookID(FBSDKAccessToken.currentAccessToken().tokenString){ result, errorString in
                if let _ = errorString{
                    completionHandler(success: false, errorString: "Could not Login to Udacity")
                } else {
                    if (result != nil) {
                        self.getPublicUserData(UdacityClient.sharedInstance().uniqueKey!)  { account,errorString in
                            if account != nil{ // It gets the account data.(User's account from Udacity)
                                dispatch_async(dispatch_get_main_queue(), {
                                    completionHandler(success: true, errorString: nil)
                                })
                            }else{
                                completionHandler(success: false, errorString: "Could not Login to Udacity")
                                dispatch_async(dispatch_get_main_queue(), {
                                    hostViewController.navigationController?.popToRootViewControllerAnimated(true)
                                    return
                                })
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            hostViewController.indicator(false)
                            completionHandler(success: false, errorString: "Could not Login to Facebook")
                        })
                    }
                }
            }
        }else{
            //FBSDKLoginButton does not say when the button was pressed and so we cannot check for network connectivity and stop going to safari, but when coming back we can display the proper message.
            let networkReachability = Reachability.reachabilityForInternetConnection()
            let networkStatus = networkReachability.currentReachabilityStatus()
            hostViewController.indicator(false)
            if (networkStatus.rawValue == NotReachable.rawValue) {
                completionHandler(success: false, errorString: "No Network Connection")
            }else{
                completionHandler(success: false, errorString: "Could not Login to Facebook")
            }
        }

    }
    //Authenticate to get the Students location using the unique key in the same way that authenticateFacebookLoginWithViewController and authenticateBasicLoginWithViewController was done
    //(Not very sure about it)
    func authenticateStudentLocationsWithViewController(hostViewController: UIViewController, completionHandler: (success: [Bool], errorString: String?) -> Void) {
        UdacityClient.sharedInstance().queryStudentLocation(UdacityClient.sharedInstance().account!.uniqueKey){ result,errorString in
            if let _ = errorString {
                completionHandler(success: [false,false], errorString: "Couldn't query for Student Location")

            }else{
                if result != nil{//THen it is an update
                    dispatch_async(dispatch_get_main_queue()){
                        completionHandler(success: [true,true], errorString: nil)
                    }
                }else{//Not an update. New record will be created(update variable remains false)
                    completionHandler(success: [true,false], errorString: nil)
                }
            }
        }
    }

    
    
    //Gets the Session ID from Udacity API required for Login.
    func getSessionID(username: String,password: String, completionHandler: (result: String?, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let mutableMethod : String = Methods.AuthenticationSessionNew
        let udacityBody: [String:AnyObject] = [UdacityClient.JSONBody.Username: username, UdacityClient.JSONBody.Password : password ]
        let jsonBody : [String:AnyObject] = [ UdacityClient.JSONBody.Udacity: udacityBody ]
        
        /* 2. Make the request */
        _ = taskForPOSTMethod(mutableMethod,parse:false, parameters: nil , jsonBody: jsonBody) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let results = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Session)?.valueForKey(UdacityClient.JSONResponseKeys.Id) as? String {
                    self.sessionID = results // Setting the session ID
                    if let key = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Account)?.valueForKey(UdacityClient.JSONResponseKeys.Key) as? String{
                        self.uniqueKey = key
                    }
                    completionHandler(result: results, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "postToSession parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse postToSession"]))
                }
            }
        }
        
    }
    //Get facebook session ID when loggin in using the facebook button.
    func getSessionFacebookID(access_token: String, completionHandler: (result: String?, error: NSError?) -> Void) {

        let mutableMethod : String = Methods.AuthenticationSessionNew
        let udacityBody: [String:AnyObject] = [ UdacityClient.JSONResponseKeys.AccessToken: access_token ]
        let jsonBody : [String:AnyObject] = [ UdacityClient.JSONResponseKeys.FacebookMobile: udacityBody ]

        /* 2. Make the request */
        _ = taskForPOSTMethod(mutableMethod, parse: false,parameters: nil , jsonBody: jsonBody) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let results = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Session)?.valueForKey(UdacityClient.JSONResponseKeys.Id) as? String {
                    self.sessionID = results // Setting the session ID
                    if let key = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Account)?.valueForKey(UdacityClient.JSONResponseKeys.Key) as? String{
                        self.uniqueKey = key
                    }
                    completionHandler(result: results, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "postToSessionFacebookID parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse postToSessionFacebookID"]))
                }
            }
        }
    }
    //Get the public User location data. It doesn't require a session id or any other key.
    func getPublicUserData(uniqueKey: String,completionHandler: (result: Student?, error: String?) -> Void) {
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters:[String:AnyObject] = [String:AnyObject]()
        let method = Methods.UserData + uniqueKey
        /* 2. Make the request */
        taskForGETMethod(method,parse: false, parameters: parameters) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let _ = error{
                completionHandler(result: nil, error: "Failed to get User Data")
            } else {
                if let lastname = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.User)?.valueForKey(UdacityClient.JSONResponseKeys.Last_Name) as? String {
                    if let firstname = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.User)?.valueForKey(UdacityClient.JSONResponseKeys.First_Name) as? String {
                        if let uniqueKey = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.User)?.valueForKey(UdacityClient.JSONResponseKeys.Key) as? String {
                            self.account = Student(uniqueKey: uniqueKey, firstName: firstname, lastName: lastname)
                            completionHandler(result: self.account , error: nil)
                        }
                    }
                } else {
                    completionHandler(result: nil, error: "Failed to retrieve User Data")
                }
            }
        }
    }
    
    //Get the student locations. It accept the parameters limit and skip to fetch the data in a network conscious manner.
    func getStudentLocations(let limit limit:Int, let skip:Int,completionHandler: (result: [Student]?, error: String?) -> Void){
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        var parameters:[String:AnyObject] = [String:AnyObject]()
        parameters["limit"] = limit
        parameters["skip"] = skip
        parameters["order"] = "-updatedAt"
        let method = Methods.StudentLocations + UdacityClient.escapedParameters(parameters)
        /* 2. Make the request */
        taskForGETMethod(method,parse: true, parameters: nil) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let _ = error{
                completionHandler(result: nil, error: "Failed to get User Data")
            } else {
                if let results = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Results) as? [[String : AnyObject]] {
                    let students = Student.studentsFromResults(results)

                    if let _ = self.account?.students{
                        self.account?.students! += students
                    }else{
                        self.account?.students = students
                    }
                    
                    completionHandler(result: students , error: nil)
                } else {
                    completionHandler(result: nil, error: "Failed to retrieve User Data")
                }
            }
        }
    }
    
    //Search if a student's location exists. It requires the unique Key.
    func queryStudentLocation(uniqueKey: String,completionHandler: (result: Student?, error: String?) -> Void) {
        var parameters:[String:AnyObject] = [String:AnyObject]()
        
        parameters["where"] = "%7B%22uniqueKey%22%3A%22\(uniqueKey)%22%7D" //Dirty solution to create a json object string for the url.
        
        let method = Methods.StudentLocations + UdacityClient.escapedParameters(parameters)
        /* 2. Make the request */
        taskForGETMethod(method,parse: true, parameters: nil) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let _ = error{
                completionHandler(result: nil, error: "Failed to get User Data")
            } else {
                if let results = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.Results) as? [[String : AnyObject]] {
                    var student:Student?
                    if(results.count > 0){
                        student = Student(dictionary: results[0])
                        UdacityClient.sharedInstance().account = student
                    }else{
                        student = nil
                    }
                    completionHandler(result: student , error: nil)
                } else {
                    completionHandler(result: nil, error: "Failed to retrieve User Data")
                }
            }
        }
    }
    //Post a new Student-Location record.
    func saveAccountLocation(account:Student,completionHandler: (result: Bool?, error: NSError?) -> Void) {
        let method = Methods.StudentLocations
        
        let jsonBody: [String:AnyObject] = [ UdacityClient.JSONBody.uniqueKey: account.uniqueKey,UdacityClient.JSONBody.firstName:account.firstName,UdacityClient.JSONBody.lastName:account.lastName,UdacityClient.JSONBody.mapString:account.mapString!,UdacityClient.JSONBody.mediaURL:account.mediaURL!,UdacityClient.JSONBody.latitude:account.latitude!,UdacityClient.JSONBody.longitude:account.longtitude! ]
        
        /* 2. Make the request */
        _ = taskForPOSTMethod(method, parse: true,parameters: nil , jsonBody: jsonBody) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let _ = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.ObjectID) as? String {
                    completionHandler(result: true, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "saveAccountLocation parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse saveAccountLocation"]))
                }
            }
        }
    }
    //Update an existing Student location 
    func updateAccountLocation(account:Student,completionHandler: (result: Bool?, error: NSError?) -> Void) {
        let method = Methods.StudentLocations + "/" + account.objectId!
        
        let jsonBody: [String:AnyObject] = [ UdacityClient.JSONBody.uniqueKey: account.uniqueKey,UdacityClient.JSONBody.firstName:account.firstName,UdacityClient.JSONBody.lastName:account.lastName,UdacityClient.JSONBody.mapString:account.mapString!,UdacityClient.JSONBody.mediaURL:account.mediaURL!,UdacityClient.JSONBody.latitude:account.latitude!,UdacityClient.JSONBody.longitude:account.longtitude! ]
        
        /* 2. Make the request */
        _ = taskForPUTMethod(method,parameters: nil , jsonBody: jsonBody) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let _ = JSONResult.valueForKey(UdacityClient.JSONResponseKeys.UpdatedAt) as? String {
                    completionHandler(result: true, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "updateAccountLocation parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse updateAccountLocation"]))
                }
            }
        }
    }
}

