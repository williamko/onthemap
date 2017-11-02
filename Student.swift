//
//  Student.swift
//  On The Map
//  The Student Struct
//  Created by William Ko on 3/24/16.
//  Copyright (c) 2016 William Ko. All rights reserved.
//

import Foundation


struct Student{
    
    var objectId:String?
    var uniqueKey:String
    var firstName:String
    var lastName: String
    var mapString: String?
    var mediaURL: String?
    var latitude: Double?
    var longtitude: Double?
    var students: [Student]?

    //Initialize a Student Object with only three attributes because at the point of login no other attributes are known
    init(uniqueKey:String, firstName: String, lastName:String){ //Initialize the required fields
        self.uniqueKey = uniqueKey
        self.firstName = firstName
        self.lastName = lastName
    }
    
    //Initialiser without using a dictionary.Might be used at some point
    init(objectId:String,uniqueKey:String, firstName: String, lastName:String,mapString:String, mediaURL:String, latitude:Double, longtitude:Double){ //Initialize the required fields
        self.init(uniqueKey: uniqueKey,firstName: lastName,lastName: firstName)
        self.objectId = objectId
        self.mapString = mapString
        self.mediaURL = mediaURL
        self.latitude = latitude
        self.longtitude = longtitude
    }
    
    //Initialise from dictionary
    init(dictionary: [String : AnyObject]) {
        
        objectId = dictionary[UdacityClient.JSONBody.objectId] as! String?
        uniqueKey = dictionary[UdacityClient.JSONBody.uniqueKey] as! String
        firstName = dictionary[UdacityClient.JSONBody.firstName] as! String
        lastName = dictionary[UdacityClient.JSONBody.lastName] as! String
        
        mapString = dictionary[UdacityClient.JSONBody.mapString] as! String?
        mediaURL = dictionary[UdacityClient.JSONBody.mediaURL] as! String?
        latitude = dictionary[UdacityClient.JSONBody.latitude] as! Double?
        longtitude = dictionary[UdacityClient.JSONBody.longitude] as! Double?
    }
    
    /* Helper: Given an array of dictionaries, convert them to an array of Student objects */
    static func studentsFromResults(results: [[String : AnyObject]]) -> [Student] {
        var students = [Student]()
        
        for result in results {
            students.append(Student(dictionary: result))
        }
        
        return students
    }



}