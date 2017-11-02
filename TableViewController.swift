//
//  UdacityTableViewController.swift
//  On The Map
//
//  Created by William Ko on 02/04/2016.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var pinButton = UIBarButtonItem()// THe button that will update/save Student's location and other data
    var logoutButton = UIBarButtonItem()
    var reloadButton = UIBarButtonItem()
    var count = 0 //Keeps track of the number of Students
    var update = false // Indicates whether the update/save location button will update or create a new entry to in the student's API
    var myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var account: Student?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        reloadButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(TableViewController.reload))
        pinButton = UIBarButtonItem(image: UIImage(named: "mappin_30x30"), landscapeImagePhone:UIImage(named: "mappin_30x30"), style: .Plain, target: self, action: #selector(TableViewController.newLocation))
        logoutButton = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(TableViewController.logout))
        let _ = UIImage(contentsOfFile: "mappin_30x30")
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItems = [logoutButton]
        self.navigationItem.rightBarButtonItems = [reloadButton, pinButton]
        self.navigationItem.title = "On The Map"
        
        myActivityIndicator.center = view.center
        view.addSubview(myActivityIndicator)

    }

    override func viewDidAppear(animated: Bool) {
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view Related
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s = account?.students {
            count = s.count
        }
        
        print(count)
        return count
    }

    //populates the table view. (First Names and Last Names)
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath) 

        var student = Student(uniqueKey: "a",firstName: "a",lastName: "a")//Dummy struct. It will be updated next

        if let s = account?.students?[indexPath.row]{
            student = s
        }
        cell.textLabel?.text = student.firstName + " " + student.lastName
        cell.imageView?.image = UIImage(named: "mappin_18x18")
        // Configure the cell...
        if (indexPath.row == (account?.students!.count)! - 1){
            getNextResults()
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {

        if let string = (account?.students![indexPath.row].mediaURL),url = NSURL(string:string){
            let request = NSURLRequest(URL: url)
            UIApplication.sharedApplication().openURL(request.URL!)

        }

    }

    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false}

    
    //MARK: Get Next Results
    //Whenever it is called it retrieves the next batch of 14 records with the help of global variable count
    //We chose 14 because this is the maximum(approximately) that a page can display
    func getNextResults(){
        
        self.myActivityIndicator.startAnimating()

        UdacityClient.sharedInstance().getStudentLocations(limit: 14,skip: count){result, errorString in
            if let _ = errorString{
                self.displayMessageBox("Couldn't get Student Details")
            }else{
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if (result != nil) {
                        if (result!.count > 0 ){
                            self.tableView.reloadData()
                        }
                    }
                    
                    self.myActivityIndicator.stopAnimating()

                    return
                })
            }
        }
    }
    
    //MARK: Button Actions
    
    //Reload all data
    func reload(){

        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        if (networkStatus.rawValue == NotReachable.rawValue) {// Before reloading check if there is an available internet connection
            displayMessageBox("No Network Connection")

        }else{
            // If the reload was pressed all the data will be reloaded and the array of student's should be nullified
            count = 0
            account?.students = nil
            getNextResults()

        }
    }
    
    //logs out of every application
    func logout() {
        
        UdacityClient.sharedInstance().logout()
        dispatch_async(dispatch_get_main_queue()) {
            _ = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
        
    }
    
    //The action of the first new location button(top left)
    func newLocation(){
        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        if (networkStatus.rawValue == NotReachable.rawValue) {// Before quering for an existing location check if there is an available internet connection
            displayMessageBox("No Network Connection")
        }else{
            UdacityClient.sharedInstance().queryStudentLocation(UdacityClient.sharedInstance().account!.uniqueKey){ result,errorString in
                if let _ = errorString {
                    self.displayMessageBox("Couldn't query for Student Location")
                }else{
                    if result != nil{//THen it is an update
                        dispatch_async(dispatch_get_main_queue()){
                            
                            let alert = UIAlertController(title: "", message: "You Have Already Posted a Student Location. Would You Like to Overwrite Your Current Location", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Overwrite", style: UIAlertActionStyle.Default, handler: self.overwrite))
                            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                            self.navigationController!.presentViewController(alert, animated: true){
                                return ()
                            }
                        }
                    }else{//Not an update. New record will be created(update variable remains false)
                        dispatch_async(dispatch_get_main_queue()){
                            self.presentEnterLocationViewController()
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Other
    
    //if it is an overwrite set the apropriate variable to signify the update and present the next view.
    func overwrite(alert: UIAlertAction!){
        self.update = true //Mark for overwrite(update)
        self.presentEnterLocationViewController()
    }
    
    
    //presents the Enter Location View
    func presentEnterLocationViewController(){
        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("EnterLocationViewController") as! EnterLocationViewController
        detailController.update = self.update // Mark if it is for update or not
        let navController = UINavigationController(rootViewController: detailController) // Creating a navigation controller with detailController at the root of the navigation stack.
        self.navigationController!.presentViewController(navController, animated: true) {
            self.navigationController?.popViewControllerAnimated(true)
            return ()
        }
    }
    
    //Displays a basic alert box with the OK button and a message.
    func displayMessageBox(message:String){
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }


}
