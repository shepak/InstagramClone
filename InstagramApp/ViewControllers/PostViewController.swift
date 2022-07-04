

import UIKit

import FirebaseDatabase

import FirebaseAuth

import SDWebImage
class PostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var commentTextView: UITextView!
    
    var post: Post!
    
    var postModel: postModel!
    
    var userModel: UserModel!
    
    var likesModel: LikesModel!
    
    var commentTextViewIsActive: Bool = false

    var comments: NSMutableArray = []
    
    var newQuery: DatabaseQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.estimatedRowHeight = CGFloat(88.0)
        
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "PostTableViewCell")
        
        tableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "CommentTableViewCell")
        
        tableView.dataSource = self
        
        tableView.delegate = self
        
        tableView.separatorStyle = .none
        
        commentTextView.delegate = self
        
        title = "Post"
        
        commentTextView.font = UIFont(name: "Roboto-Regular", size: 15)
        
        commentTextView.inputAccessoryView = nil
        
        commentTextView.inputView = nil
        
        loadData()
        
    }
    
    func loadData(){
        
        let commentsQuery = CommentsModel.collection.child(postModel.key).queryOrderedByKey()
        
        commentsQuery.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {return}
            
            strongSelf.comments.removeAllObjects()
            
            for item in snapshot.children{
                
                guard let snapshot = item as? DataSnapshot else {continue}
                
                guard let comment = CommentsModel(snapshot) else {continue}
                
                strongSelf.comments.insert(comment, at: strongSelf.comments.count)
                
                
            }
            
            let lastChild = snapshot.children.allObjects.last as? DataSnapshot
            
            strongSelf.observeNewItems(lastChild)
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
            
            
        }
        
        
        
    }
    
    
    func observeNewItems(_ lastChild: DataSnapshot?){
        
        newQuery?.removeAllObservers()
        
        newQuery = CommentsModel.collection.child(postModel.key).queryOrderedByKey()
        
        if let startKey = lastChild?.key{
            
            newQuery = newQuery?.queryStarting(atValue: startKey)
            
        }
        
        newQuery?.observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else {return}
            
            if snapshot.key != lastChild?.key {
                
                if let comment = CommentsModel(snapshot){
                    
                    strongSelf.comments.insert(comment, at:strongSelf.comments.count)
                    
                    let lastIndex = IndexPath(row: strongSelf.comments.count - 1, section: 1)
                    
                    DispatchQueue.main.async {
                        strongSelf.tableView.insertRows(at: [lastIndex], with: .bottom)
                        
                        strongSelf.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
                    }
                    
                }
                
            }
        })
        
    }
    
    
    @objc func dismissKeyboard() {
        
        if commentTextViewIsActive {
            
            view.endEditing(true)
            
        }
        
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        
        let rect:CGRect = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
        
        let duration = ((notification as NSNotification).userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        
        self.keyboardConstraint.constant = rect.height - (self.tabBarController?.tabBar.frame.size.height ?? 49.0)
        
        UIView.animate(withDuration: duration!, animations: {
            
            self.view.layoutSubviews()
            
        })
        
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        
        let duration = ((notification as NSNotification).userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        
        self.keyboardConstraint.constant = 0
        
        UIView.animate(withDuration: duration!, animations: {
            
            self.view.layoutSubviews()
            
        })
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            
            return 1
            
        }
        else {
            
            return comments.count
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            return
            
        }
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        
        let profileVC = profileStoryboard.instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
        
        profileVC.profileType = .otherUser
        
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
            
            //cell.profileImage.image = post.user.profileImage
            
            cell.postImage.sd_cancelCurrentImageLoad()
            
            cell.postImage.sd_setImage(with: postModel.imageURL, completed: nil)
            
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateFormat = "dd MMM, yyyy hh:mm"
            
            cell.dateLabel.text = dateFormatter.string(from: postModel.date)
            
           // cell.likesCountLabel.text = "\(post.likesCount) likes"
            
            cell.postCommentLabel.text = postModel.caption
            
            //cell.userNameTitleButton.setTitle(post.user.name, for: .normal)
            
            cell.likesModel = likesModel
            
            cell.postModel = postModel
            
            cell.currentUserModel = userModel
            
            cell.profileDelegate = self
            
            cell.feedDelegate = self
            
            return cell
            
        }
        
        
        let comment = comments[indexPath.row] as! CommentsModel
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as! CommentTableViewCell
        
        
        cell.commentLabel.text = comment.comment
        
        cell.commentIndex = indexPath.row
        
        //cell.delegate = self
        
        cell.userRef = UserModel.collection.child(comment.userId)
        
        return cell
        
    }
    
    @IBAction func postCommentButtonDidTouch(_ sender: Any) {
        
        guard let comment = commentTextView.text else {return}
        
        guard let userId = Auth.auth().currentUser?.uid else {return}
        
        CommentsModel.new(comment: comment, userId: userId, postID: postModel.key)
        
        commentTextView.text = nil
        
        view.endEditing(true)
    
        
    }
    
    deinit {
        print("post view controller did deinit")
        
        newQuery?.removeAllObservers()
    }
    
    
}

extension PostViewController: ProfileDelegate {
    
    func userNameDidTouch() {
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        
        let profileVC = profileStoryboard.instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
        
        profileVC.profileType = .otherUser
        
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
}

extension PostViewController: FeedDataDelegate {
    
    func commentsDidTouch(post: postModel, likesModel: LikesModel, userModel: UserModel) {
        
        
        
    }
    
}

extension PostViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        commentTextViewIsActive = true
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        commentTextViewIsActive = false
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return true
        
    }
    
}
