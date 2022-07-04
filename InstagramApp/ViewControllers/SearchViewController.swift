

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var searchController: UISearchController!
    
    var posts: NSMutableArray = []
    
    let PAGINATION_COUNT: UInt = 10
    
    var firstChild: DataSnapshot?
    
    
    var oldRef: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        collectionView.delegate = self
        
        collectionView.dataSource = self
        
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.obscuresBackgroundDuringPresentation = true
        
        searchController.searchBar.showsCancelButton = true
        
        for subView in searchController.searchBar.subviews {
            
            for subView1 in subView.subviews {
                
                if let textField = subView1 as? UITextField {
                    
                    textField.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
                    
                    textField.textAlignment = NSTextAlignment.center
                    
                }
                
            }
            
        }
        
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.definesPresentationContext = true
        
        searchController.hidesNavigationBarDuringPresentation = false
        
        let searchBarContainer = SearchBarContainerView(customSearchBar: searchController.searchBar)
        
        searchBarContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)

        navigationItem.titleView = searchBarContainer
        
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
            
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
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
                strongSelf.collectionView.reloadData()
            }
            
        })
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        if let lastIndex = self.collectionView.indexPathsForVisibleItems.last{
            
                
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
                        strongSelf.collectionView.insertItems(at: indexes)
                    }
                    
                    
                }
            }
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return posts.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreCollectionViewCell", for: indexPath) as! ExploreCollectionViewCell
        
        let post = posts[indexPath.row] as! postModel
        
        cell.exploreImage.sd_cancelCurrentImageLoad()
        
        cell.exploreImage.sd_setImage(with: post.imageURL, completed: nil)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let post = posts[indexPath.row] as! postModel
        
        let postStoryboard = UIStoryboard(name: "Post", bundle: nil)
        
        let postVC = postStoryboard.instantiateViewController(withIdentifier: "Post") as! PostViewController
        
        postVC.postModel = post
        
        navigationController?.pushViewController(postVC, animated: true)
        
    }

}
