

import UIKit

import FirebaseDatabase

import FirebaseAuth

import FirebaseStorage

import SDWebImage

enum ProfileType {
    
    case personal, otherUser
    
}

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: NSMutableArray = []
    
    var userPostsRef: DatabaseReference? {
        
        guard let userId = Auth.auth().currentUser?.uid else {return nil}
        
        return UserModel.personalFeed.child(userId)
        
        
    }
    
    let PAGINATION_COUNT: UInt = 5
    
    var profileType: ProfileType = .personal

    var user: UserModel?
    
    private let imagePicker = UIImagePickerController()
    
    lazy var progressIndicator: UIProgressView = {
        
       let _progressIndicator = UIProgressView()
        
        _progressIndicator.trackTintColor = UIColor.lightGray
        
        _progressIndicator.progressTintColor = UIColor.black
        
        _progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        _progressIndicator.progress = Float(0)
        
        return _progressIndicator
        
        
        
    }()
    
    
    lazy var cancelButton: UIButton = {
       
        let _cancelButton = UIButton()
        
        _cancelButton.setTitle("Cancel Upload", for: .normal)
        
        _cancelButton.setTitleColor(UIColor.black, for: .normal)
        
        _cancelButton.addTarget(self, action: #selector(cancelUpload), for: .touchUpInside)
        
        _cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        return _cancelButton
        
        
    }()
    
    var firstChild: DataSnapshot?
    
    var uploadTask: StorageUploadTask?
    
    var newQuery: DatabaseQuery?
    
    var oldRef: DatabaseReference?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        
        tableView.tableFooterView = UIView()
        
        tableView.separatorStyle = .none
        
        view.addSubview(progressIndicator)
        
        view.addSubview(cancelButton)
        
        let constraints: [NSLayoutConstraint] = [
            
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor,constant: 0),
            
            progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: 0),
            
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -20),
            
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,constant: 0),
            
            cancelButton.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor,constant: 5)
            
            
            
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        progressIndicator.isHidden = true
        
        cancelButton.isHidden = true
        
        imagePicker.delegate = self
        
        loadData()
    }
    
    func loadData(){

        guard let userId = Auth.auth().currentUser?.uid else{return}


        let userRef = UserModel.collection.child(userId)

        let spinner = UIViewController.displayLoading(withView: self.view)
        userRef.observe(.value) {[weak self](snapshot) in

            guard let strongSelf = self else {return}

            UIViewController.remomeLoading(spinner: spinner)

            guard let user = UserModel(snapshot) else {return}

            strongSelf.user = user
//
//            DispatchQueue.main.async {
//                strongSelf.tableView.reloadData()
//            }



            strongSelf.getUserPosts()
        }
        
        
   }
    
    
    func getUserPosts(){
        
        guard let userPostsRef = userPostsRef else {return}
        
        let userRefquery = userPostsRef.queryOrderedByKey().queryLimited(toLast: PAGINATION_COUNT)
        
        userRefquery.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            
            guard let strongSelf = self else {return}
            
            for item in snapshot.children{
                
                guard let snapshot = item as? DataSnapshot else {continue}
                
                guard let post = postModel(snapshot) else {continue}
                
                strongSelf.posts.insert(post, at: 0)
                
                
            }
            
            strongSelf.firstChild = snapshot.children.allObjects.first as? DataSnapshot
            
            let lastChild = snapshot.children.allObjects.last as? DataSnapshot
            
            strongSelf.observeNewItems(lastChild,newRef: userPostsRef)
            
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
        
        oldRef?.removeAllObservers()
        
        oldRef = userPostsRef
        
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
    
    
    func uploadImage(data: Data){
        
        if let user = Auth.auth().currentUser{
            
            progressIndicator.isHidden = false
            
            cancelButton.isHidden = false
            
            progressIndicator.progress = Float(0)
            
            let imageId: String = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "_")
            
            let imageName = "\(imageId).jpg"
            
            let pathToPic = "images/\(user.uid)/\(imageName)"
            
            let storageRef = Storage.storage().reference(withPath: pathToPic)
            
            let metaData = StorageMetadata()
            
            metaData.contentType = "image/jpg"
            
            uploadTask = storageRef.putData(data, metadata: metaData, completion: { [weak self] (metaData, error) in
                guard let strongSelf = self else {return}
                
                DispatchQueue.main.async {
                    strongSelf.progressIndicator.isHidden = true
                    
                    strongSelf.cancelButton.isHidden = true
                }
                
                if let error = error{
                    
                    print(error.localizedDescription)
                    
                    let alert = Helper.errorAlert(title: "Upload Error", message: "There was a problem with uploading image")
                    
                    DispatchQueue.main.async {
                        strongSelf.present(alert,animated: true,completion: nil)
                    }
                    
                    
                }
                
                else {
                    
                    storageRef.downloadURL { (url, error) in
                        if let url = url ,error == nil{
                            
                            UserModel.collection.child(user.uid).updateChildValues(["profile_image": url.absoluteString])
                            
                        }
                        
                        else {
                            
                            let alert = Helper.errorAlert(title: "Upload Error", message: "There was a problem with uploading image")
                            
                            DispatchQueue.main.async {
                                strongSelf.present(alert,animated: true,completion: nil)
                            }
                            
                            
                            
                        }
                    }
                    
                        
                    
                    
                }
                
            })
            
            uploadTask!.observe(.progress) {[weak self] (snapshot) in
                guard let strongSelf = self else {return}
                
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                
                DispatchQueue.main.async {
                    strongSelf.progressIndicator.setProgress(Float(percentComplete), animated: true)
                }
            }
            
            }
        
        
        
    }
    
    
    @objc func cancelUpload(){
        
        progressIndicator.isHidden = true
        
        cancelButton.isHidden = true
        
        uploadTask?.cancel()
        
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        if let lastIndex = self.tableView.indexPathsForVisibleRows?.last{
            
            if lastIndex.section == 2{
                
                if lastIndex.row >= self.posts.count - 2{
                    
                    loadMore()
                    
                    
                }
                
                
            }
            
        }
        
        
    }
    
    
    func loadMore(){
        
        guard let userPostsRef =  userPostsRef else {return}
            
        var paginationQuery = userPostsRef.queryOrderedByKey().queryLimited(toLast: PAGINATION_COUNT+1)
        
        if let firstKey = firstChild?.key{
            
            paginationQuery = paginationQuery.queryEnding(atValue: firstKey)
            
            paginationQuery.observeSingleEvent(of: .value) {[weak self] (snapshot) in
                guard let strongSelf = self else {return}
                
                let items = snapshot.children.allObjects
                
                var indexes: [IndexPath] = []
                
                if items.count > 1{
                    
                    for i in 2...items.count{
                        
                        let data = items[items.count - i] as! DataSnapshot
                        
                        indexes.append(IndexPath(row: strongSelf.posts.count, section: 2))
                        
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
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            
            return 1
            
        }
        else if section == 1 {
            
            return 1
            
        }
        else {
            
            return posts.count
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let profileHeaderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ProfileHeaderTableViewCell") as! ProfileHeaderTableViewCell
            
            profileHeaderTableViewCell.profileType = profileType
            
            profileHeaderTableViewCell.nameLabel.text = ""
            
            profileHeaderTableViewCell.delegate = self
            
            if let user = user {
                
                profileHeaderTableViewCell.nameLabel.text = user.username
                
                if let profileImage = user.profileImage{
                
                profileHeaderTableViewCell.profileImageView.sd_cancelCurrentImageLoad()
                
                    profileHeaderTableViewCell.profileImageView.sd_setImage(with: profileImage, completed: nil)
                
                }
                
                
            }
            
            switch profileType {
                
            case .otherUser:
                
                profileHeaderTableViewCell.profileButton.setTitle("Follow", for: .normal)
                
            case .personal:
                
                profileHeaderTableViewCell.profileButton.setTitle("Logout", for: .normal)
                
                profileHeaderTableViewCell.profileButton.setTitleColor(UIColor.red, for: .normal)
                
            }
            
            return profileHeaderTableViewCell
            
        }
        else if indexPath.section == 1 {
            
            let profileViewStyleTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ProfileViewStyleTableViewCell") as! ProfileViewStyleTableViewCell
            
            return profileViewStyleTableViewCell
            
        }
        else if indexPath.section == 2 {
            
            let feedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell") as! FeedTableViewCell
            
            let post = posts[indexPath.row] as! postModel
            
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
            
            return feedTableViewCell
            
        }
        else {
            
            return UITableViewCell()
            
        }
        
    }
    
    deinit{
        
        newQuery?.removeAllObservers()
        
        oldRef?.removeAllObservers()
        
    }
    

}

extension ProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            if let resizedImage = pickedImage.resized(toWidth: 1080){
                
                if let imageData = resizedImage.jpegData(compressionQuality: 0.75){
                    
                    uploadImage(data: imageData)
                    
                }
                
                
                
            }
            
            
            
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    
}

extension ProfileViewController: FeedDataDelegate {
    
    func commentsDidTouch(post: postModel, likesModel:LikesModel, userModel: UserModel) {
        
        let postStoryboard = UIStoryboard(name: "Post", bundle: nil)
        
        let postVC = postStoryboard.instantiateViewController(withIdentifier: "Post") as! PostViewController
        
        //postVC.post = post
        
        postVC.postModel = post
        
        postVC.likesModel = likesModel
        
        postVC.userModel = userModel
        
        navigationController?.pushViewController(postVC, animated: true)
        
    }
    
}

extension ProfileViewController: ProfileHeaderDelegate{
    
    func profileImageDidTouch() {
        let alertController = UIAlertController(title: "Change Profile", message: "Choose an option to change your profile photo", preferredStyle: .actionSheet)
        
        let libriaryOption = UIAlertAction(title: "Import from libriary", style: .default) { (action) in
            self.imagePicker.allowsEditing = true
            
            self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        let takePhotoOption = UIAlertAction(title: "Take Photo", style: .default) { (action) in
            
            self.imagePicker.allowsEditing = true
            
            self.imagePicker.sourceType = .camera
            
            self.present(self.imagePicker, animated: true, completion: nil)
            
            
        }
        
        let cancelOption = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(libriaryOption)
        
        alertController.addAction(takePhotoOption)
        
        alertController.addAction(cancelOption)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
}

extension ProfileViewController: PostDeleteDelegate{
    
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
