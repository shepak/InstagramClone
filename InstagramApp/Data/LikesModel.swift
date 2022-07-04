//
//  LikesModel.swift
//  InstagramApp
//
//  Created by Mustafin Ruslan on 30.09.2021.
//  Copyright © 2021 Gwinyai Nyatsoka. All rights reserved.
//

import Foundation

import FirebaseDatabase

import FirebaseAuth

class LikesModel{
    
    
    static var collection: DatabaseReference{
        
        get {
            
            return Database.database(url: "https://instagram-clone-53fd6-default-rtdb.europe-west1.firebasedatabase.app").reference().child("likes")
        }
        
    }
    
    var postDidLike: Bool = false
    
    var likesCount: Int = 0
    
    init? (_ snapshot: DataSnapshot){
        
        
        guard let userId = Auth.auth().currentUser?.uid else {return nil}
        
        self.likesCount = snapshot.children.allObjects.count
        
        for item in snapshot.children{
            
            guard let snapshot = item as? DataSnapshot else {continue}
            
            if snapshot.key == userId{
                
                postDidLike = true
                
                break
            }
            
        }
        
        
        
    }
    
    
    static func postLiked(_ postKey: String){
        
        if let userId = Auth.auth().currentUser?.uid{
            
            let likeRef = LikesModel.collection.child(postKey)
            
            likeRef.updateChildValues([userId: true])
            
        }
        
        
    }
    
    
    static func postUnliked(_ postKey : String){
        
        
        if let userId = Auth.auth().currentUser?.uid{
            
            let likeRef = LikesModel.collection.child(postKey).child(userId)
            
            likeRef.removeValue()
            
        }
    }
    
}
