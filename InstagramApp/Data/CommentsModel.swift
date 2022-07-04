//
//  CommentsModel.swift
//  InstagramApp
//
//  Created by Mustafin Ruslan on 05.10.2021.
//  Copyright © 2021 Gwinyai Nyatsoka. All rights reserved.
//

import Foundation

import FirebaseDatabase

class CommentsModel{
    
    static var collection: DatabaseReference{
        
        get {
            
            return Database.database(url: "https://instagram-clone-53fd6-default-rtdb.europe-west1.firebasedatabase.app").reference().child("comments")
            
        }
        
        
    }
    
    var userId: String
    
    var comment: String
    
    init?(_ snapshot: DataSnapshot){
        
        guard let value = snapshot.value as? [String:Any] else {return nil}
        
        guard let userId = value["user"] as? String else {return nil}
        
        guard  let comment = value["comment"] as? String else {return nil}
        
        self.userId = userId
        
        self.comment = comment
        
        
        
    }
    
    
    static func new(comment: String, userId: String, postID: String){
        
        guard let key = CommentsModel.collection.child(postID).childByAutoId().key else {return}
        
        let commentDict: [String:Any] = ["comment": comment, "user": userId]
        
        CommentsModel.collection.child(postID).updateChildValues(["\(key)": commentDict])
        
        
        
        
        
    }
    
    
}
