

import UIKit

import FirebaseAuth

import FirebaseDatabase


class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: NSMutableArray = []

    let PAGINATION_COUNT: UInt = 5
    
    var firstChild: DataSnapshot?
    
    var newQuery: DatabaseQuery?
    
    var oldRef: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = CGFloat(88.0)
        
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        
        tableView.register(UINib(nibName: "StoriesTableViewCell", bundle: nil), forCellReuseIdentifier: "StoriesTableViewCell")
        
        tableView.dataSource = self
        
        tableView.delegate = self
        
        tableView.tableFooterView = UIView()
        
        var leftBarItemImage = UIImage(named: "camera_nav_icon")
        
        leftBarItemImage = leftBarItemImage?.withRenderingMode(.alwaysOriginal)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftBarItemImage, style: .plain, target: self, action: #selector(newPostButtonDidTouch))
        
        let profileImageView = UIImageView(image: UIImage(named: "logo_nav_icon"))
        
        self.navigationItem.titleView = profileImageView
        
        loadData()
    }
    
    func loadData(){
        
        let postsRef: DatabaseReference = postModel.collection
        
        let postsQuery = postsRef.queryOrderedByKey().queryLimited(toLast: PAGINATION_COUNT)
        
        postsQuery.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            
            guard let strongSelf = self else {return}
            
            for item in snapshot.children{
                
                guard let snapshot = item as? DataSnapshot else {continue}
                
                guard let post = postModel(snapshot) else {continue}
                
                strongSelf.posts.insert(post, at: 0)
                
                
            }
            
            strongSelf.firstChild = snapshot.children.allObjects.first as? DataSnapshot
            
            let lastChild = snapshot.children.allObjects.last as? DataSnapshot
            
            strongSelf.observeNewItems(lastChild,newRef: postsRef)
            
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
        
        oldRef?.removeAllObservers()
        
        oldRef = postsRef
        
        oldRef?.observe(.childRemoved, with: {[weak self] (snapshot) in
            
            guard let strongSelf = self else {return}
            
            for item in strongSelf.posts{
                
                if let post = item as? postModel, snapshot.key == post.key{
                    
                    strongSelf.posts.remove(item)
                    
                }
                
                
            }
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
            
        })
        
    }
    
    func observeNewItems(_ lastChild: DataSnapshot?, newRef: DatabaseReference){
        
        
        newQuery?.removeAllObservers()
        
        newQuery = newRef.queryOrderedByKey()
        
        if let startKey = lastChild?.key{
            
            newQuery = newQuery?.queryStarting(atValue: startKey)
            
        }
        
        newQuery?.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else {return}
            
            if snapshot.key != lastChild?.key {
                
                if let post = postModel(snapshot){
                    
                    strongSelf.posts.insert(post, at: 0)
                    
                    DispatchQueue.main.async {
                        strongSelf.tableView.reloadData()
                    }
                }
                
            }
        })
        
    }
    
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        if let lastIndex = self.tableView.indexPathsForVisibleRows?.last{
            
                
            if lastIndex.row >= self.posts.count - 2{
                
                loadMore()
                
                
            }
            
            
        }
        
        
    }
    
    func loadMore(){
        
        let postsRef: DatabaseReference = postModel.collection
            
        var paginationQuery = postsRef.queryOrderedByKey().queryLimited(toLast: PAGINATION_COUNT+1)
        
        if let firstKey = firstChild?.key{
            
            paginationQuery = paginationQuery.queryEnding(atValue: firstKey)
            
            paginationQuery.observeSingleEvent(of: .value) {[weak self] (snapshot) in
                guard let strongSelf = self else {return}
                
                let items = snapshot.children.allObjects
                
                var indexes: [IndexPath] = []
                
                if items.count > 1{
                    
                    for i in 2...items.count{
                        
                        let data = items[items.count - i] as! DataSnapshot
                        
                        indexes.append(IndexPath(row: strongSelf.posts.count, section: 0))
                        
                        if let post = postModel(data){
                            
                            strongSelf.posts.add(post)
                            
                        }
                        
                        
                    }
                    
                    strongSelf.firstChild = snapshot.children.allObjects.first as? DataSnapshot
                    
                    DispatchQueue.main.async {
                        strongSelf.tableView.insertRows(at: indexes, with: .fade)
                    }
                    
                    
                }
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count + 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "StoriesTableViewCell") as! StoriesTableViewCell
            
            return cell
            
        }
        
        let feedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell") as! FeedTableViewCell
        
        let currentIndex = indexPath.row - 1
        
        let post = posts[currentIndex] as! postModel
        
        feedTableViewCell.postImage.sd_cancelCurrentImageLoad()
        
        feedTableViewCell.postImage.sd_setImage(with: post.imageURL, completed: nil)
        
        feedTableViewCell.postCommentLabel.text = post.caption
        
        feedTableViewCell.userRef = UserModel.collection.child(post.userID)
        
        feedTableViewCell.postImage.backgroundColor = UIColor.lightGray
        
        feedTableViewCell.likesRef = LikesModel.collection.child(post.key)
        
        feedTableViewCell.postModel = post
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "dd MMM, yyyy hh:mm"
        
        feedTableViewCell.dateLabel.text = dateFormatter.string(from: post.date)
        
        feedTableViewCell.feedDelegate = self
        
        feedTableViewCell.deletePostDelegate = self
        
        
//        if postData.comments.count > 0 {
//
//            let commentTitle = postData.comments.count == 1 ? "View 1 comment" : "View all \(postData.comments.count) comments"
//
//            cell.commentCountButton.setTitle(commentTitle, for: .normal)
//
//            cell.commentCountButton.isEnabled = true
//
//        }
//        else {
//
//            cell.commentCountButton.setTitle("0 comments", for: .normal)
//
//            cell.commentCountButton.isEnabled = false
//
//        }
        
        feedTableViewCell.postModel = post
        
        return feedTableViewCell
        
    }
    
    @objc func newPostButtonDidTouch() {
        
        let newPostStoryboard = UIStoryboard(name: "NewPost", bundle: nil)
        
        let newPostVC = newPostStoryboard.instantiateViewController(withIdentifier: "NewPost") as! NewPostViewController
        
        let navController = UINavigationController(rootViewController: newPostVC)
        
        present(navController, animated: true, completion: nil)
        
    }
    
    deinit{
        
        newQuery?.removeAllObservers()
        
        oldRef?.removeAllObservers()
        
    }

}

extension HomeViewController: FeedDataDelegate {
    
    func commentsDidTouch(post: postModel, likesModel: LikesModel, userModel: UserModel) {
        
        let postStoryboard = UIStoryboard(name: "Post", bundle: nil)
        
        let postVC = postStoryboard.instantiateViewController(withIdentifier: "Post") as! PostViewController
        
       // postVC.post = post
        
        postVC.postModel = post
        
        postVC.likesModel = likesModel
        
        postVC.userModel = userModel
        
        navigationController?.pushViewController(postVC, animated: true)
        
    }
    
}

extension HomeViewController: ProfileDelegate {
    
    func userNameDidTouch() {
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        
        let profileVC = profileStoryboard.instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
        
        profileVC.profileType = .otherUser
        
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
}

extension HomeViewController: PostDeleteDelegate{
    
    func confirmDelete(postID: String){
        
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you would like to delete post?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            
            postModel.deletePost(id:postID)
            
            alert.dismiss(animated: true, completion: nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert,animated: true,completion: nil)
    }
    
}
