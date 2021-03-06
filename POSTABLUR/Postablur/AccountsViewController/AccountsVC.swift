//
//  AccountsVC.swift
//  Postablur
//
//  Created by Srinivas Peddinti on 1/23/18.
//  Copyright © 2018 MobiwareInc. All rights reserved.
//

import UIKit
import Toast_Swift
import Kingfisher

class AccountsVC: UIViewController
{
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var settingsBtn: UIButton!
    
    
    @IBOutlet var descriptionView: UIView!
    @IBOutlet var userProfileImage: UIImageView!
    @IBOutlet var connectBtn: UIButton!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var userDescTextView: UITextView!
    @IBOutlet var connectsView: UIView!
    @IBOutlet var connectsPHLabel: UILabel!
    @IBOutlet var connectsLabel: UILabel!
    @IBOutlet var thisWeekConnectionsLabel: UILabel!
    
    @IBOutlet var videoView: UIView!
    
    @IBOutlet var buttonsView: UIView!
    
    @IBOutlet var photoBtn: UIButton!
   
    
    
    @IBOutlet var dataView: UIView!
    @IBOutlet var feedsCollectionView: UICollectionView!
    @IBOutlet var noFeedsLbl: UILabel!
    
    @IBOutlet var activity: UIActivityIndicatorView!
    
    var blurOperations = [IndexPath : BlockOperation]()
    let blurOperationsQueue = OperationQueue()
    private let reuseIdentifier = "feedsCollectionCell"
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var feeds = [PBFeedItem]()
    var totalFeedCount = 0
    
    weak var tabContainerVC : PBTabsContainerVC? = nil
    
    var style = ToastStyle()
    
    var isLoadingFeeds = false
    let numberOfCellsPerRow: CGFloat = 3

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        
        self.style.messageColor = .white
        
        self.activity.isHidden = true
        self.noFeedsLbl.isHidden = true
        self.feedsCollectionView.isHidden = false
        
        self.connectBtn.layer.cornerRadius = 6
        if let userProfileUrlStr = UserDefaults.standard.object(forKey: Constants.kUserProfilePicURL) as? String
        {
            if let userProfileUrl = URL(string: userProfileUrlStr)
            {
                self.userProfileImage.kf.setImage(with: userProfileUrl)
            }
            else
            {
                self.userProfileImage.image = UIImage.init(named: "default_avatar")
            }
            
        }
        if let usernameStr = UserDefaults.standard.object(forKey: "UserName")
        {
            let username = "@ \(usernameStr)"
            self.usernameLabel.text = username
        }
        
        /*let value1 = "Hai "
        let attribute1 = NSMutableAttributedString(string: value1 as String, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 12)])
        let value2 = "CONNECTS"
        let attribute2 = NSMutableAttributedString(string: value2 as String, attributes: [NSAttributedStringKey.font : UIFont(name: "Arial", size: 12.0)!])
        
        let combination = NSMutableAttributedString()
        
        combination.append(attribute1)
        combination.append(attribute2)
        
        self.connectsLabel.attributedText = combination*/
        
        /*let connectsLabelStr = "1B CONNECTS"
        var myMutableString = NSMutableAttributedString()
        myMutableString = NSMutableAttributedString(string: connectsLabelStr as String, attributes: [NSAttributedStringKey.font:UIFont(name: "Arial", size: 12.0)!])
        myMutableString.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "AvenirNext-Medium", size: 12.0)!, range: NSRange(location:0,length:2))
        self.connectsLabel.attributedText = myMutableString*/
        
        feedsCollectionView.delegate = self
        feedsCollectionView.dataSource = self
        let nib = UINib(nibName: NibNamed.PBFeedsCollectionCell.rawValue, bundle: nil)
        self.feedsCollectionView.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.fontSet()
        
        self.loadMyPostsDetails()
    
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let flowLayout = feedsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        {
            let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing
            let cellWidth = (view.frame.width - max(0, numberOfCellsPerRow - 1)*horizontalSpacing)/numberOfCellsPerRow
            flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        }
        
        if appDelegate.needToReloadFeeds == true
        {
            appDelegate.needToReloadFeeds = false
            loadMyPostsDetails()
        }
        else if appDelegate.needToJustRefreshView == true
        {
            appDelegate.needToJustRefreshView = false
            self.feedsCollectionView.reloadData()
        }
        
    }
    
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.userDescTextView.scrollRangeToVisible(NSRange(location: 0, length: 1))
    }
    
    func loadMyPostsDetails()
    {
        let urlString = String(format: "%@/MyPostsDetails", arguments: [Urls.mainUrl]);
        guard let userId = UserDefaults.standard.string(forKey: "UserId") else
        {
            return
        }
        let requestDict = ["UserId": userId,"StartValue": "1","Endvalue": "20"] as [String : Any]
        
        self.activity.startAnimating()
        self.activity.isHidden = false
        PBServiceHelper().post(url: urlString, parameters: requestDict as NSDictionary) { (responseObject : AnyObject?, error : Error?) in
                
            self.activity.stopAnimating()
            self.activity.isHidden = true
                
            if error == nil
            {
                if responseObject != nil
                {
                    if let responseDict = responseObject as? [String : AnyObject]
                    {
                            
                        if let error = responseDict["Error"] as? String
                        {
                            self.appDelegate.alert(vc: self, message: error , title: "Error")
                            return
                        }
                        else
                        {
                                let count = responseDict["Count"] as! Int
                                self.totalFeedCount = count
                            
                                if count == 0
                                {
                                    self.noFeedsLbl.isHidden = false
                                    self.feedsCollectionView.isHidden = true
                                }
                                else
                                {
                                      self.feeds.removeAll()
                                      if let resultArray = responseDict["Results"] as! [NSDictionary]!
                                      {
                                         for result in resultArray
                                         {
                                             let feedItem = PBFeedItem()
                                             feedItem.PostId = result["PostId"] as? String
                                             feedItem.UserLikeStatus = result["UserLikeStatus"] as? Int == 1 ? true : false
                                             feedItem.UserDisLikeStatus = result["UserDisLikeStatus"] as? Int == 1 ? true : false
                                             feedItem.UserName = result["UserName"] as? String
                                             feedItem.Location = result["Location"] as? String
                                             feedItem.PostTitle = result["PostTitle"] as? String
                                             feedItem.Email = result["Email"] as? String
                                             feedItem.Description = result["Description"] as? String
                                             feedItem.CurrentLikesCount = result["CurrentLikesCount"] as? Int
                                             feedItem.CurrentDisLikesCount = result["CurrentDisLikesCount"] as? Int
                                            feedItem.likesGoal = result["LikeLimit"] as? Int
                                             feedItem.Profileurl = result["Profileurl"] as? String
                                        
                                             let mediaArray = result["PostMediaData"] as! [NSDictionary]!
                                             for media in mediaArray!
                                             {
                                                 let mediaItem = PBFeedMedia()
                                                 mediaItem.PostId = media["PostId"] as? String
                                                 mediaItem.PostUrl = media["PostUrl"] as? String
                                                 mediaItem.PostThumbUrl = media["PostThumbUrl"] as? String
                                                 mediaItem.MediaType = media["MediaType"] as? String
                                                 feedItem.mediaList.append(mediaItem)
                                             }
                                        
                                             self.feeds.append(feedItem)
                                          }
                                    
                                          self.feedsCollectionView.reloadData()
                                      }
                                }
                        }
                            
                    }
                    if let responseStr = responseObject as? String
                    {
                        self.appDelegate.alert(vc: self, message: responseStr, title: "Error")
                        return
                    }
                        
                }
                else
                {
                    self.appDelegate.alert(vc: self, message: "Something went wrong", title: "Error")
                        return
                }
            }
            else
            {
                self.appDelegate.alert(vc: self, message: (error?.localizedDescription)!, title: "Error")
                    return
            }
        }
    }
    
    
    func loadFeedsMore()
    {
        let urlString = String(format: "%@/MyPostsDetails", arguments: [Urls.mainUrl]);
        guard let userId = UserDefaults.standard.string(forKey: "UserId") else
        {
            return
        }
        
        let startIndex = String(self.feeds.count + 1)
        let endIndex  =  String(self.feeds.count + Constants.loadMoreFeedPageSize)
        
        let requestDict = ["UserId": userId,"StartValue": startIndex,"Endvalue": endIndex] as [String : Any]
        
        self.activity.startAnimating()
        self.activity.isHidden = false
        
        self.isLoadingFeeds = true
        PBServiceHelper().post(url: urlString, parameters: requestDict as NSDictionary) { (responseObject : AnyObject?, error : Error?) in
            
            self.isLoadingFeeds = false
            
            if error == nil
            {
                if responseObject != nil
                {
                    if let responseDict = responseObject as? [String : AnyObject]
                    {
                        
                        if let error = responseDict["Error"] as? String
                        {
                            self.activity.stopAnimating()
                            self.appDelegate.alert(vc: self, message: error , title: "Error")
                            return
                        }
                        else
                        {
                            
                            if let resultArray = responseDict["Results"] as! [NSDictionary]!
                            {
                                for result in resultArray
                                {
                                    let feedItem = PBFeedItem()
                                    feedItem.PostId = result["PostId"] as? String
                                    feedItem.UserLikeStatus = result["UserLikeStatus"] as? Int == 1 ? true : false
                                    feedItem.UserDisLikeStatus = result["UserDisLikeStatus"] as? Int == 1 ? true : false
                                    feedItem.UserName = result["UserName"] as? String
                                    feedItem.Location = result["Location"] as? String
                                    feedItem.PostTitle = result["PostTitle"] as? String
                                    feedItem.Email = result["Email"] as? String
                                    feedItem.Description = result["Description"] as? String
                                    feedItem.CurrentLikesCount = result["CurrentLikesCount"] as? Int
                                    feedItem.CurrentDisLikesCount = result["CurrentDisLikesCount"] as? Int
                                    feedItem.likesGoal = result["LikeLimit"] as? Int
                                    feedItem.Profileurl = result["Profileurl"] as? String
                                    
                                    let mediaArray = result["PostMediaData"] as! [NSDictionary]!
                                    for media in mediaArray!
                                    {
                                        let mediaItem = PBFeedMedia()
                                        mediaItem.PostId = media["PostId"] as? String
                                        mediaItem.PostUrl = media["PostUrl"] as? String
                                        mediaItem.PostThumbUrl = media["PostThumbUrl"] as? String
                                        mediaItem.MediaType = media["MediaType"] as? String
                                        feedItem.mediaList.append(mediaItem)
                                    }
                                    
                                    let count = result["TotalCount"] as! Int
                                    self.totalFeedCount = count
                                    self.feeds.append(feedItem)
                                }
                                
                                if self.feeds.count <= 0
                                {
                                    self.activity.stopAnimating()
                                    self.noFeedsLbl.isHidden = false
                                    self.feedsCollectionView.isHidden = true
                                }
                                else
                                {
                                    self.noFeedsLbl.isHidden = true
                                    self.feedsCollectionView.isHidden = false
                                }
                                
                                self.feedsCollectionView.reloadData()
                            }
                        }
                        
                    }
                    if let responseStr = responseObject as? String
                    {
                        self.activity.stopAnimating()
                        self.appDelegate.alert(vc: self, message: responseStr, title: "Error")
                        return
                    }
                    
                }
                else
                {
                    self.activity.stopAnimating()
                    self.appDelegate.alert(vc: self, message: "Something went wrong", title: "Error")
                    return
                }
            }
            else
            {
                self.activity.stopAnimating()
                self.appDelegate.alert(vc: self, message: (error?.localizedDescription)!, title: "Error")
                return
            }
        }
    }
    
    func fontSet()
    {
        let screenWidth = UIScreen.main.bounds.size.width
        if screenWidth == 320
        {
            let fontSize = 12
            self.connectBtn.titleLabel?.font = self.connectBtn.titleLabel?.font.withSize(CGFloat(10))
            self.usernameLabel.font = self.usernameLabel.font.withSize(CGFloat(fontSize))
            self.userDescTextView.font = self.userDescTextView.font?.withSize(CGFloat(fontSize))
            self.connectsPHLabel.font = self.connectsPHLabel.font.withSize(CGFloat(fontSize))
            self.connectsLabel.font = self.connectsLabel.font.withSize(CGFloat(fontSize))
            self.thisWeekConnectionsLabel.font = self.thisWeekConnectionsLabel?.font.withSize(CGFloat(10))
        }
    }
    
   
    
    @IBAction func settingsBtnAction(_ sender: UIButton)
    {
        
        let accountSettingsVC = AccountSettingsVC(nibName: "AccountSettingsVC", bundle: nil)
        self.navigationController?.pushViewController(accountSettingsVC, animated: true)

    }
    
    @IBAction func connectBtnAction(_ sender: UIButton)
    {
        //self.view.makeToast("coming soon...", duration: 3.0, position: .center, style: style)
        
    }
    
    @IBAction func photoBtnAction(_ sender: UIButton)
    {
        
    }
    
    
    func saveImage(image : UIImage, withName name : String)
    {
        if let data = UIImageJPEGRepresentation(image, 0.7) {
            let filename = getDocumentsDirectory().appendingPathComponent("\(name)")
            try? data.write(to: filename)
        }
    }
    
    func getImage(withName name : String) -> UIImage?
    {
        let fileManager = FileManager.default
        let imagePAth = self.getDocumentsDirectory().appendingPathComponent("\(name).jpg")
        if fileManager.fileExists(atPath: imagePAth.path)
        {
            let image =  UIImage(contentsOfFile: imagePAth.path)
            return image
        }
        else
        {
            return nil
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    /*@IBAction func audioBtnAction(_ sender: UIButton)
    {
        self.view.makeToast("Audio coming soon...", duration: 3.0, position: .center, style: style)
        //self.appDelegate.alert(vc: self, message: "Stats coming soon...", title: "Error")
    }
    
    @IBAction func videoBtnAction(_ sender: UIButton)
    {
        self.view.makeToast("Video coming soon...", duration: 3.0, position: .center, style: style)
        //self.appDelegate.alert(vc: self, message: "Stats coming soon...", title: "Error")
    }*/
    
    deinit
    {
        
        blurOperationsQueue.cancelAllOperations()
        blurOperations.removeAll()
    }
    
}

extension AccountsVC : UICollectionViewDelegate, UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
         return feeds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PBFeedsCollectionCell
        //cell.feedImageView.alpha = 0
        //cell.feedImageView.kf.setImage(with : nil)
        
        
        let feedItem = self.feeds[indexPath.row]
        let likeCount = feedItem.CurrentLikesCount!
        
        var cachedImgFound = false
        if let savedImg  = self.getImage(withName: "sfi\(feedItem.PostId!)_\(feedItem.CurrentLikesCount!).jpg")
        {
            cell.feedImageView.image =  savedImg
            cell.feedImageView.alpha = 1
            cachedImgFound = true
        }
        
        guard cachedImgFound == false else
        {
            return cell
        }
        
        cell.feedImageView.alpha = 0
        
        let mediaList = feedItem.mediaList
        
        if mediaList.count > 0
        {
            let firstMedia = mediaList.first!
            if let thumburlString = firstMedia.PostThumbUrl
            {
                if let thumbUrl = URL(string: thumburlString)
                {
                    let resource = ImageResource(downloadURL: thumbUrl, cacheKey: thumburlString)
                    cell.feedImageView.kf.setImage(with: resource, completionHandler: { (image, error, cacheType, imageUrl) in
                        
                        
                        cell.feedImageView.kf.setImage(with: nil)
                        guard let img = image else
                        {
                            self.activity.stopAnimating()
                            return
                        }
                        
                        let blurOperation = BlockOperation()
                        weak var weakOperation = blurOperation
                        weak var weakSelf = self
                        weak var weakCell = cell
                        weak var weakImg = img
                        weak var weakFeedItem = feedItem
                        blurOperation.addExecutionBlock {
                            
                            guard let img = weakImg else
                            {
                                return
                            }
                            guard let feedItem = weakFeedItem else
                            {
                                return
                            }
                            let im = PBUtility.blurEffect(image: img, blurRadius : Constants.maxBlurRadius - likeCount * (Constants.maxBlurRadius / feedItem.likesGoal!))
                            
                            
                            
                            weakSelf?.saveImage(image: im, withName : "sfi\(feedItem.PostId!)_\(feedItem.CurrentLikesCount!)")
                            
                            OperationQueue.main.addOperation {
                                
                                guard let operation = weakOperation else
                                {
                                    return
                                }
                                
                                if (operation.isCancelled == false)
                                {
                                    guard weakSelf != nil else
                                    {
                                        return
                                    }
                                    weakSelf?.activity.stopAnimating()
                                    
                                    weakCell?.feedImageView.image = im
                                    weakCell?.feedImageView.alpha = 1
                                    weakSelf?.blurOperations.removeValue(forKey: indexPath)
                                    
                                }
                            }
                        }
                        
                        cell.feedImageView.alpha = 0
                        self.blurOperations[indexPath] = blurOperation
                        self.blurOperationsQueue.addOperation(blurOperation)
                    })
                    
                }
                else
                {
                    cell.feedImageView.kf.setImage(with: nil)
                    
                }
            }
            else
            {
                cell.feedImageView.kf.setImage(with: nil)
                
            }
        }
        else
        {
            cell.feedImageView.kf.setImage(with: nil)
            
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        
        self.activity.stopAnimating()
        
        
        if indexPath.row == self.feeds.count - 1
        {
            guard self.totalFeedCount > self.feeds.count else
            {
                return
            }
            if self.isLoadingFeeds == false
            {
                self.loadFeedsMore()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        
        guard let cell = cell as? PBFeedsCollectionCell else
        {
            return
        }
        cell.feedImageView.kf.cancelDownloadTask()
        
        let indexPaths = collectionView.indexPathsForVisibleItems
        guard indexPaths.count > 0 else
        {
            self.blurOperations.removeAll()
            self.blurOperationsQueue.cancelAllOperations()
            return
        }
        let matchingVisibleIndPaths = indexPaths.filter({ (inPath) -> Bool in
            
            return inPath == indexPath
        })
        
        if matchingVisibleIndPaths.count == 0
        {
            let ongoingBlurOperation = self.blurOperations[indexPath]
            if (ongoingBlurOperation != nil)
            {
                ongoingBlurOperation?.cancel()
                self.blurOperations.removeValue(forKey: indexPath)
            }
            return
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        
        let selectedFeed = self.feeds[indexPath.row]
        
        let interactionVC = PBFeedsInteractionVC()
        interactionVC.feeds = self.feeds
        interactionVC.selectedFeedID = selectedFeed.PostId
        interactionVC.totalFeedCount = self.totalFeedCount
        interactionVC.scrollToIndexPath = indexPath
        interactionVC.fromWhichVC = "AccountsVC"
        
        self.navigationController?.pushViewController(interactionVC, animated: true)
    }
}
