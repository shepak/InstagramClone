//
//  SearchTableViewController.swift
//  InstagramApp
//
//  Created by Mustafin Ruslan on 21.02.2022.
//  Copyright © 2022 Gwinyai Nyatsoka. All rights reserved.
//

import UIKit

import FirebaseAuth

import FirebaseDatabase

class SearchTableViewController: UITableViewController, UISearchResultsUpdating {

    var filteredResults: [UserModel] = [UserModel]()
    
    var shouldShowSearchResults: Bool = false
    
    let tableRefreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *){
            
            tableView.refreshControl = tableRefreshControl
            
        }else{
            tableView.addSubview(tableRefreshControl)
        }
        
        tableView.tableFooterView = UIView()
        
        tableView.separatorStyle = .none
    
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchController.searchResultsController?.view.isHidden = false
        
        guard var searchQuery = searchController.searchBar.text else { return }
        
        tableRefreshControl.beginRefreshing()
        
        if searchQuery == "" {
            
            shouldShowSearchResults = false
            tableView.separatorStyle = .none
            tableRefreshControl.endRefreshing()
            tableView.reloadData()
            return
            
        }
        
        searchQuery = searchQuery.lowercased()
        
        guard let currentUser = Auth.auth().currentUser else { return }
        
        UserModel.collection.queryOrdered(byChild: "username").queryStarting(atValue: searchQuery).queryEnding(atValue: searchQuery + "\u{f8ff}").queryLimited(toLast: 30).observeSingleEvent(of: .value) { [weak self](snapshot) in
            
            guard let strongSelf = self else {return}
        }
        
        
        
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
