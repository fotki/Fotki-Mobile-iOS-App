//
//  FolderViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 12/29/16.
//  Copyright © 2016 TBoxSolutionz. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
protocol FoldersViewControllerDelegate {
    func reloadAccountTree()
    func reloadAccountTreeWithIndicator()
}

class FoldersViewController: UIViewController {
    var foldersViewControllerDelegate: FoldersViewControllerDelegate? = nil
    public var foldersData: NSDictionary? = nil
    @IBOutlet weak var emptyFolderView: UIView!
    @IBOutlet weak var folderName: UITextView!
    @IBOutlet var table: UITableView? = nil
   // @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var folderDetail: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailIcon: UIImageView!
    @IBOutlet weak var retryView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    var activityIndicator = UIActivityIndicatorView()
    var dataArray = NSMutableArray()
    let rightBarDropDown = DropDown()
    var uploadViewController: UploadViewController? = nil
    var imagesCache: [String:UIImage] = [:]
    var folder = Folder()
    var tapCell = Bool()
    var refresher:UIRefreshControl!
    var isWebManagerDelegate = Bool()

    //MARK: setup dropdown and its actions
    func setupRightBarDropDown() {
        rightBarDropDown.anchorView = navigationItem.rightBarButtonItem
        if folder.folderName == kPrivate_Home || folder.folderName == kPublic_Home {
            rightBarDropDown.dataSource = [kCreate_Folder, kCreate_Album, kRefresh]
        } else {
            rightBarDropDown.dataSource = [kCreate_Folder, kUpdate_Folder, kCreate_Album, kRefresh,kShareFolderLink, kCopyToClipboard]
        }
        rightBarDropDown.selectionAction = { [unowned self] (index, item) in
            print(item)
            if item == kCreate_Folder {
                self.callingActionView(sendAction: kCreate_Folder)
            } else if item == kCreate_Album {
                self.callingActionView(sendAction: kCreate_Album)
            } else if item == kUpdate_Folder {
                self.callingActionView(sendAction: kUpdate_Folder)
            } else if item == kCopyToClipboard {
                self.addLinkToClipboard()
            } else if item == kRefresh {
                self.reloadFolderData()
            } else if item == kShareFolderLink {
                self.shareLink()
            }
        }
    }
    
    @objc func actionTapped() {
        self.rightBarDropDown.show()
    }
    
    @objc func reloadFolderData() {
        self.dataArray.removeAllObjects()
        tapCell = true
        self.collectionView.reloadData()
        self.imagesCache.removeAll()
        self.recallApi()
    }
    
    func shareLink () {
        let text = folder.url 
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems:textToShare, applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
        self.present(activityViewController, animated: true)
        activityViewController.completionWithItemsHandler = self.completionHandler
    }

    
    func addLinkToClipboard() {
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = folder.url
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kLinkCopiedToClipboard, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }

    func completionHandler(activityType: UIActivity.ActivityType?, shared: Bool, items: [Any]?, error: Error?) {
        if shared {
            print ("Shared")
        } else {
            print("Cancelled")
        }
    }

    
    func callingActionView(sendAction: String) {
        let actionsViewController = ActionsViewController(nibName: kActionsViewController, bundle: nil)
        actionsViewController.getAction = sendAction
        actionsViewController.actionDelegate = self
        actionsViewController.folder = folder
        self.navigationController?.pushViewController(actionsViewController, animated: true)
    }
    
    func setupDropDowns() {
        setupRightBarDropDown()
    }
    
    @objc func setFolderDetail() {
        if folder.folderName != kPublic_Home && folder.folderName != kPrivate_Home && folder.folderName != "" {
            self.detailContainerView.alpha = 1.0
            self.folderName.text = folder.folderName
            if folderName.contentSize.height > 85 {
                self.folderName.frame.size.height = 85
                self.folderName.isScrollEnabled = true
            } else {
                self.folderName.frame.size.height = folderName.contentSize.height
                self.folderName.isUserInteractionEnabled = false
            }
            self.folderName.setContentOffset(.zero, animated: false)
            self.folderName.isEditable = false
            self.descriptionTextView.frame.origin.y = self.folderName.frame.origin.y + self.folderName.frame.size.height + 6
            descriptionTextView.text = folder.description
            self.descriptionTextView.isEditable = false
            self.folderDetail.text = "\(folder.folders.count) folders | \(folder.albums.count) albums"
            if self.folder.description == "" {
                self.descriptionTextView.frame.size.height = 0.0
            } else {
                let contentSize = self.descriptionTextView.sizeThatFits(self.descriptionTextView.bounds.size)
                if contentSize.height > 65 {
                    self.descriptionTextView.frame.size.height = 65
                    self.descriptionTextView.isScrollEnabled = true
                } else {
                    self.descriptionTextView.frame.size.height = contentSize.height
                    self.descriptionTextView.isScrollEnabled = false
                }
            }
            self.descriptionTextView.setContentOffset(.zero, animated: false)
            self.detailView.frame.origin.y = self.descriptionTextView.frame.origin.y + self.descriptionTextView.frame.size.height + 2
            self.detailContainerView.frame.size.height = self.detailView.frame.origin.y + self.detailView.frame.size.height + 5
            self.collectionViewTopConstraint.constant = self.detailContainerView.frame.size.height + 64
        }
    }
    
    //MARK: view's life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavBarItems()
        table?.register(UINib(nibName: kTableViewCell, bundle: Bundle.main), forCellReuseIdentifier: kcell)
        table?.dataSource = self
        table?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: NSNotification.Name(kReloadData), object: nil)
        self.collectionView?.register(UINib(nibName: "SectionOneCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "sectionOne")
        self.collectionView?.register(UINib(nibName: "SectionTwoCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "sectionTwo")
        self.collectionViewTopConstraint.constant = 64
        self.detailContainerView.alpha = 0.0
        self.emptyFolderView.alpha = 0.0
        self.refresher = UIRefreshControl()
        self.collectionView!.alwaysBounceVertical = true
        self.refresher.tintColor = UIColor.black
        self.refresher.addTarget(self, action: #selector(reloadFolderData), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        loadData(isViewLoaded: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tapCell = true
        self.collectionView?.reloadData()
      //  setFolderDetail()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kReloadData), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.uploadViewController = (self.tabBarController?.viewControllers?[2] as! UINavigationController?)!.viewControllers.first as! UploadViewController?
        if (self.uploadViewController?.uploadComplete)! {
            appDelegate.isAlbum = false
        }
    }

    //MARK: load navBar items
    func loadNavBarItems() {
        let logo = UIImage(named: klogoImage)
        let logoImageView = UIImageView(image: logo)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        logoImageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.navigationItem.titleView = logoImageView
        let actionBtn = UIButton()
        actionBtn.setTitle(kAction, for: UIControl.State.normal)
        let rightButton = UIBarButtonItem(image: UIImage (named: kdot), style: .plain, target: self, action: #selector(actionTapped))
        navigationController?.navigationBar.tintColor = .black
        self.navigationItem.rightBarButtonItem = rightButton
    }
    
    func stopRefresher() {
        self.refresher.endRefreshing()
    }
    
    //MARK: load data in table view
    func parseFolders(folders: NSArray) -> NSMutableArray{
        //loop the folders array
        // of each folder make a folder
        // call parse folders on folders
        // call parse albums on albums
        let parsedFolders = NSMutableArray()
        for folder in folders as! [NSDictionary] {
            let mFolder = Folder()
            var subalbumCount: Int = 0
            var subFolderCount: Int = 0
            var folders: NSMutableArray = NSMutableArray()
            var albums: NSMutableArray = NSMutableArray()
            if (folder[knumber_of_albums] as? Int)  != nil{
                subalbumCount =  folder[knumber_of_albums] as! Int
            }
            if (folder[knumber_of_folders] as? Int) != nil{
                subFolderCount =  folder[knumber_of_folders] as! Int
            }
            if (folder[kfolders] as! NSArray).count > 0{
                folders = parseFolders(folders:folder[kfolders] as! NSArray)
            }
            if(folder[kalbums] as! NSArray).count > 0 {
                albums = parseAlbums(albums: folder[kalbums] as! NSArray)
            }
            mFolder.setData(folderIdEnc: folder[kfolder_id_enc] as! NSNumber, folderName: folder[kfolder_name] as! String, description: folder[kdesc] as! String, albums: albums, folders: folders, subFoldersCount: subFolderCount, subAlbumsCount: subalbumCount, url: Utility.stringNullCheck(stringToCheck: folder[kurl] as AnyObject))
            parsedFolders.add(mFolder)
        }
        return parsedFolders
    }
    
    func parseAlbums(albums: NSArray) -> NSMutableArray {
        let parsedAlbums = NSMutableArray()
        for album in albums as! [NSDictionary] {
            let mAlbum = Album()
            let videosCount = album[knumber_of_videos]
            let photosCount = album[knumber_of_photos]
            if videosCount is String && photosCount is String {
                mAlbum.setData(albumIdEnc: album[kalbum_id_enc] as! NSNumber, albumName: album[kname] as! String, description: album[kdesc] as! String, coverUrl: Utility.stringNullCheck(stringToCheck: album[kcover_photo_url] as AnyObject), videoCount: Int(videosCount as! String)!, photoCount: Int(photosCount as! String)!, url: Utility.stringNullCheck(stringToCheck: album[kurl] as AnyObject))
            } else if videosCount is Int {
                mAlbum.setData(albumIdEnc: album[kalbum_id_enc] as! NSNumber, albumName: album[kname] as! String, description: album[kdesc] as! String, coverUrl: Utility.stringNullCheck(stringToCheck: album[kcover_photo_url] as AnyObject), videoCount: videosCount as! Int, photoCount: photosCount as! Int, url: Utility.stringNullCheck(stringToCheck: album[kurl] as AnyObject))
            }
            parsedAlbums.add(mAlbum)
        }
        return parsedAlbums
    }
    
    func loadFolder(data: NSDictionary) {
        var subalbumCount: Int = 0
        var subFolderCount: Int = 0
        var folders: NSMutableArray = NSMutableArray()
        var albums: NSMutableArray = NSMutableArray()
        if (data[knumber_of_albums] as? Int)  != nil{
            subalbumCount =  data[knumber_of_albums] as! Int
        }
        if (data[knumber_of_folders] as? Int) != nil{
            subFolderCount =  data[knumber_of_folders] as! Int
        }
        if (data[kfolders] as! NSArray).count > 0{
            folders = parseFolders(folders:data[kfolders] as! NSArray)
        }
        if(data[kalbums] as! NSArray).count > 0 {
            albums = parseAlbums(albums: data[kalbums] as! NSArray)
        }
        folder.setData(folderIdEnc: data[kfolder_id_enc] as! NSNumber, folderName: data[kfolder_name] as! String, description: data[kdesc] as! String, albums: albums, folders: folders, subFoldersCount: subFolderCount, subAlbumsCount: subalbumCount, url: Utility.stringNullCheck(stringToCheck: data[kurl] as AnyObject))
        Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.setFolderDetail), userInfo: nil, repeats: false)
//        if self.isViewLoaded {
//            self.setFolderDetail()
//        }
    }
    
    @IBAction func createAlbum(_ sender: Any) {
        self.callingActionView(sendAction: kCreate_Album)
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        retryView.isHidden = true
        self.recallApi()
    }

    func loadData(isViewLoaded: Bool) {
        dataArray.removeAllObjects()
        for folder in folder.folders {
            dataArray.add(folder)
        }
        for album in folder.albums {
            dataArray.add(album)
        }
        if folder.folderName != kPublic_Home && folder.folderName != kPrivate_Home && folder.folderName != "" && isViewLoaded {
            if dataArray.count == 0 {
                self.emptyFolderView.alpha = 1.0
                self.detailContainerView.alpha = 0.0
            } else {
                self.emptyFolderView.alpha = 0.0
                self.detailContainerView.alpha = 1.0
                Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.setFolderDetail), userInfo: nil, repeats: false)            }
        } else if !isViewLoaded {
            let _ = self.view
            if dataArray.count == 0 {
                self.emptyFolderView.alpha = 1.0
                self.detailContainerView.alpha = 0.0
            } else {
                self.emptyFolderView.alpha = 0.0
                self.detailContainerView.alpha = 1.0
                Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.setFolderDetail), userInfo: nil, repeats: false)            }
        }

        self.setupDropDowns()
        self.collectionView?.reloadData()
    }
    
    @objc func reloadTable() {
        self.table?.reloadData()
    }
}

func isEqual<T: Equatable>(type: T.Type, objectA: Any, objectB: Any) -> Bool? {
    guard let objectA = objectA as? T, let objectB = objectB as? T else { return nil }
    return objectA == objectB
}




extension FoldersViewController: MainTabViewControllerDelegate {
    //MARK: mainTabViewControllerDelegate functions
    func loadPrivateData(privateData: NSDictionary) {
        loadFolder(data: privateData)
        loadData(isViewLoaded: false)
        if (self.refresher) != nil {
            self.stopRefresher()
        }
    }
    
    func loadPublicData(publicData: NSDictionary) {
        loadFolder(data: publicData)
        loadData(isViewLoaded: false)
        if (self.refresher) != nil {
            self.stopRefresher()
        }
    }
    
    func networkFailureResponse() {
         let _ = self.view
        self.retryView.isHidden = false
        isWebManagerDelegate = false
    }
}

extension FoldersViewController: UITableViewDelegate, UITableViewDataSource {
    //MARK: UITableviewDelegate functions
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataArray.count == 0 {
            return 0
        } else {
            return (dataArray.count)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tapCell == true {
            tapCell = false
            let item = dataArray[indexPath.row]
            if  item is Folder {
                let folderViewController = FoldersViewController(nibName: kFoldersViewController, bundle: nil)
                folderViewController.folder = item as! Folder
                self.navigationController?.pushViewController(folderViewController, animated: true)
            } else {
                let albumViewController = AlbumViewController(nibName: kAlbumViewController, bundle: nil)
                albumViewController.album = item as! Album
                self.navigationController?.pushViewController(albumViewController, animated: true)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kcell,for: indexPath) as! TableViewCell
        cell.contentView.tag = indexPath.row
        var folderName = String()
        var albumName = String()
        var coverUrl: String = ""
        var totalAlbumFiles: String = ""
        let item = dataArray[indexPath.row]
        if  item is Folder {
            folderName = (item as! Folder).folderName
        } else {
            albumName = (item as! Album).name
            coverUrl = (item as! Album).coverUrl
            totalAlbumFiles = "\((item as! Album).noOfPhotos + (item as! Album).noOfVideos) files"
        }
        if (imagesCache[folderName] != nil) {
            cell.fileImage?.image = imagesCache[folderName]
            cell.fileName.text = folderName
            // will be replaced by origional values after the api changes
            cell.noOfFiles.text = "\((item as! Folder).noOfSubFolders) folders \((item as! Folder).noOfSubAlbums) albums"
        } else if (imagesCache[coverUrl] != nil) {
            cell.fileImage?.image = imagesCache[coverUrl]
            cell.fileName.text = albumName
            cell.noOfFiles.text = totalAlbumFiles
        } else {
            if item is Folder {
                cell.fileName?.text = folderName
                // will be replaced by origional values after the api changes
                cell.noOfFiles.text = "\((item as! Folder).noOfSubFolders) folders \((item as! Folder).noOfSubAlbums) albums"
                imagesCache[folderName] = UIImage(named: kfolderImage)
                cell.fileImage?.image = UIImage(named: kfolderImage)
            } else {
                cell.fileName?.text = albumName
                cell.noOfFiles.text = totalAlbumFiles
                cell.fileImage?.image = UIImage(named: kalbumImage)
                if coverUrl != "" {
                    let fotkiImageRequest = FotkiImageDataRequest()
                    fotkiImageRequest.imageDownloader(url: coverUrl, index: indexPath.row) { (response,index) in
                        if cell.contentView.tag == index {
                            if let image = response.result.value {
                                self.imagesCache[coverUrl] = image
                                cell.fileImage?.image = image
                            }
                        }
                    }
                }
            }
        }
        return cell
    }
}

extension FoldersViewController: WebManagerDelegate {
    func successFbLoginResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if response.result.value != nil {
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata]  as! NSDictionary
                    loadFolder(data: data)
                    loadData(isViewLoaded: true)
                if (self.refresher) != nil {
                        self.stopRefresher()
                    }
                }
            }
        }
    }

    func successResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if response.result.value != nil {
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata]  as! NSDictionary
                    loadFolder(data: data)
                    loadData(isViewLoaded: true)
                    if (self.refresher) != nil {
                        self.stopRefresher()
                    }
                }
            }
        }
    }
    
    func networkFailureAction() {
        retryView.isHidden = false
        isWebManagerDelegate = true
    }
    
    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}

extension FoldersViewController: ActionViewControllerDelegate {
    func recallApi() {
        if folder.folderName != kPublic_Home && folder.folderName != kPrivate_Home {
            if !self.refresher.isRefreshing {
                self.activityIndicator = Utility.startSpinner(view: self.view)
                self.activityIndicator.hidesWhenStopped = true
            }
            WebManager.getInstance(delegate: self)?.getFolderContent(folderId: (folder.folderIdEnc))
        }else {
            if !self.refresher.isRefreshing {
                self.foldersViewControllerDelegate?.reloadAccountTreeWithIndicator()
                self.foldersViewControllerDelegate?.reloadAccountTree()
            } else {
                self.foldersViewControllerDelegate?.reloadAccountTree()
            }
        }
    }
}

extension FoldersViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK: collectionViewDelegate functions
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = Double(UIScreen.main.bounds.size.width)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if indexPath.section == 0 {
                return CGSize(width: (width/4 - 8), height: 50)
            } else {
                var squareSize = width/5 - 8
                if squareSize<145 {
                    squareSize = width/4-8
                }
                return CGSize(width: squareSize, height: squareSize)
            }
        } else {
            if indexPath.section == 0 {
                return CGSize(width: (width/2 - 8), height: 50)
            } else {
                var squareSize = width/3 - 8
                if squareSize<125 {
                    squareSize = width/2-8
                }
                return CGSize(width: squareSize, height: squareSize)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if tapCell == true {
            tapCell = false
            var index = 0
            if indexPath.section == 0 {
                index = indexPath.row
            } else {
                index = indexPath.row + folder.folders.count
            }
            let item = dataArray[index]
            if  item is Folder {
                let folderViewController = FoldersViewController(nibName: kFoldersViewController, bundle: nil)
                folderViewController.folder = item as! Folder
                self.navigationController?.pushViewController(folderViewController, animated: true)
            } else {
                let albumViewController = AlbumViewController(nibName: kAlbumViewController, bundle: nil)
                albumViewController.album = item as! Album
                self.navigationController?.pushViewController(albumViewController, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if dataArray.count > 0 {
            if section == 0 {
                print("folder\(folder.folders.count)")
                return folder.folders.count
            } else  {
                print("folder\(folder.albums.count)")
                return folder.albums.count
            }
        } else{
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var folderName = String()
        var albumName = String()
        var coverUrl: String = ""
        
        if indexPath.section == 0 {
            let item = dataArray[indexPath.row]
            folderName = (item as! Folder).folderName
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sectionOne", for: indexPath) as! SectionOneCollectionViewCell
            cell.fileName.text = folderName
            cell.fileImage.image = nil
            cell.fileImage.image = UIImage(named: kfolderImage)
            
            cell.noOfFiles.text = "\((item as! Folder).noOfSubFolders) folders \((item as! Folder).noOfSubAlbums) albums"
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                cell.fileName.font = UIFont(name: cell.fileName.font.fontName, size: 14)
                break
            default: break
            }
            return cell

        } else {
            let item = dataArray[indexPath.row + folder.folders.count]
            albumName = (item as! Album).name
            coverUrl = (item as! Album).coverUrl
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sectionTwo", for: indexPath) as! SectionTwoCollectionViewCell
            cell.fileImage.image = nil
            cell.contentView.tag = indexPath.row
            cell.fileImage?.image = UIImage(named: kalbumImage)
            cell.noOfFiles.text = "\((item as! Album).noOfPhotos + (item as! Album).noOfVideos) files"
            
            if imagesCache[coverUrl] != nil {
                cell.fileImage?.image = imagesCache[coverUrl]
                cell.fileName.text = albumName
            } else {
                cell.fileName.text = albumName
                let imageRequest = FotkiImageDataRequest()
                imageRequest.imageDownloader(url: coverUrl, index: indexPath.row) { (response,index) in
                    if cell.contentView.tag == index {
                        if let image = response.result.value {
                            self.imagesCache[coverUrl] = image
                            cell.fileImage?.image = image
                        }
                    }
                }
            }
            return cell
        }
    }
}

////////////////////////////////////////////testing

