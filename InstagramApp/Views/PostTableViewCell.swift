

import UIKit

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var userNameTitleButton: UIButton!
    
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var likesCountLabel: UILabel!
    
    @IBOutlet weak var postCommentLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likesButton: UIButton!
    
    var post: Post?
    
    var postModel: postModel?
    
    var likesModel: LikesModel?{
        
        didSet{
            
            guard let likesModel = likesModel else {return}
            
            setup(likes: likesModel)
            
        }
        
        
        
    }
    
    var currentUserModel: UserModel?{
        
        didSet{
            
            guard let currentUser = currentUserModel else {return}
            
            setup(user: currentUser)
            
            
            
        }
        
    }
    
    
    weak var profileDelegate: ProfileDelegate?
    
    weak var feedDelegate: FeedDataDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        profileImage.layer.cornerRadius = profileImage.frame.width / 2
        
        profileImage.layer.masksToBounds = true
        
        selectionStyle = UITableViewCell.SelectionStyle.none
        
        likesButton.setImage(UIImage(named: "did_like"), for: .selected)
        
        likesButton.setImage(UIImage(named: "like_icon"), for: .normal)
        
    }
    
    
    func setup(user: UserModel){
        
        userNameTitleButton.setTitle(user.username, for: .normal)
        
        if let userProfileImage = user.profileImage {
            
            profileImage.sd_cancelCurrentImageLoad()
            
            profileImage.sd_setImage(with: userProfileImage, completed: nil)
        }
        
        
        
    }
    
    func setup(likes: LikesModel?){
        
        guard let likes = likes else {return}
        
        likesCountLabel.text = "\(likes.likesCount) likes"
        
        if likes.postDidLike{
            
            likesButton.isSelected = true
        }
        else{
            
            likesButton.isSelected = false
            
        }
        
        
    }
    
    
    @IBAction func userNameButtonDidTouch(_ sender: Any) {
        
        profileDelegate?.userNameDidTouch()
        
    }
    
    @IBAction func likeButtonDidTouch(_ sender: Any) {
        
        guard let postModel = postModel else {return}
        
        guard let likesModel = likesModel else {return}
        
        likesModel.postDidLike = !likesModel.postDidLike
        
        likesButton.isSelected = likesModel.postDidLike
        
        if likesModel.postDidLike {
            
            LikesModel.postLiked(postModel.key)
            
            likesModel.likesCount += 1
            
            
        }
        else{
            
            LikesModel.postUnliked(postModel.key)
            
            if likesModel.likesCount > 0 {
           
                likesModel.likesCount -= 1
           
            }
            
        }
        
        likesCountLabel.text = "\(likesModel.likesCount) likes"
        
        
        
    }
    
    
}
