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
protocol FolderViewControllerDelegate {
    func reloadAccountTreeOnNetworkFailure()
}

class FolderViewController: UIViewController {
    var folderViewControllerDelegate: FolderViewControllerDelegate? = nil
    public var foldersData: NSDictionary? = nil
    @IBOutlet weak var retryView: UIView!
    @IBOutlet var table: UITableView? = nil
    var dataArray = NSMutableArray()
    let rightBarDropDown = DropDown()
    var imagesCache: [String:UIImage] = [:]
    var folder = Folder()
    var tapCell = Bool()
    var isWebManagerDelegate = Bool()
    
    //MARK: setup dropdown and its actions
    func setupRightBarDropDown() {
        rightBarDropDown.anchorView = navigationItem.rightBarButtonItem
        if folder.folderName == kPrivate_Home || folder.folderName == kPublic_Home {
            rightBarDropDown.dataSource = [kCreate_Folder, kCreate_Album]
        } else {
            rightBarDropDown.dataSource = [kCreate_Folder, kUpdate_Folder, kCreate_Album]
        }
        rightBarDropDown.selectionAction = { [unowned self] (index, item) in
            print(item)
            if item == kCreate_Folder {
                self.callingActionView(sendAction: kCreate_Folder)
            } else if item == kCreate_Album {
                self.callingActionView(sendAction: kCreate_Album)
            } else if item == kUpdate_Folder {
                self.callingActionView(sendAction: kUpdate_Folder)
            }
        }
    }
    
    @objc func actionTapped() {
        rightBarDropDown.show()
    }
    
    func callingActionView(sendAction: String) {
        let actionsViewController = ActionsViewController(nibName: kActionsViewController, bundle: nil)
        actionsViewController.getAction = sendAction
        self.navigationController?.pushViewController(actionsViewController, animated: true)
    }
    
    func setupDropDowns() {
        setupRightBarDropDown()
    }
    
    //MARK: view's life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavBarItems()
        loadData()
        table?.register(UINib(nibName: kTableViewCell, bundle: Bundle.main), forCellReuseIdentifier: kcell)
        table?.dataSource = self
        table?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTable), name: NSNotification.Name(kReloadData), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tapCell = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kReloadData), object: nil)
    }
    
    //MARK: load navBar items
    func loadNavBarItems() {
        let logo = UIImage(named: klogoImage)
        let logoImageView = UIImageView(image: logo)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 0, height: 40)
        logoImageView.contentMode = UIView.ContentMode.scaleAspectFill
        self.navigationItem.titleView = logoImageView
        let actionBtn = UIButton()
        actionBtn.setTitle(kAction, for: UIControl.State.normal)
        let rightButton = UIBarButtonItem(image: UIImage (named: kdot), style: .plain, target: self, action: #selector(actionTapped))
        navigationController?.navigationBar.tintColor = .black
        self.navigationItem.rightBarButtonItem = rightButton
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
            mFolder.setData(folderIdEnc: folder[kfolder_id_enc] as! NSNumber, folderName: folder[kfolder_name] as! String, description: folder[kdesc] as! String, albums: parseAlbums(albums: folder[kalbums] as! NSArray), folders: parseFolders(folders:folder[kfolders] as! NSArray), subFoldersCount: folder[knumber_of_folders] as! Int, subAlbumsCount: folder[knumber_of_albums] as! Int, url: folder[kurl] as! String)
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
        folder.setData(folderIdEnc: data[kfolder_id_enc] as! NSNumber, folderName: data[kfolder_name] as! String, description: data[kdesc] as! String, albums: parseAlbums(albums: data[kalbums] as! NSArray), folders: parseFolders(folders:data[kfolders] as! NSArray), subFoldersCount: data[knumber_of_folders] as! Int, subAlbumsCount: data[knumber_of_albums] as! Int, url: data[kurl] as! String)
    }
    
    func loadData() {
        dataArray.removeAllObjects()
        for folder in folder.folders {
            dataArray.add(folder)
        }
        for album in folder.albums {
            dataArray.add(album)
        }
        setupDropDowns()
        self.table?.reloadData()
    }
    
    @objc func reloadTable() {
        self.table?.reloadData()
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        retryView.isHidden = true
        if isWebManagerDelegate {
            self.recallApi()
        } else {
            folderViewControllerDelegate?.reloadAccountTreeOnNetworkFailure()
        }
    }
}

extension FolderViewController: MainTabViewControllerDelegate {
    //MARK: mainTabViewControllerDelegate functions
    func loadPrivateData(privateData: NSDictionary) {
        loadFolder(data: privateData)
        loadData()
    }
    
    func loadPublicData(publicData: NSDictionary) {
        loadFolder(data: publicData)
        loadData()
    }
    
    func networkFailureResponse() {
        retryView.isHidden = false
        isWebManagerDelegate = false
    }
}

extension FolderViewController: UITableViewDelegate, UITableViewDataSource {
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
                let folderViewController = FolderViewController(nibName: kFolderViewController, bundle: nil)
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

extension FolderViewController: WebManagerDelegate {
    func successFbLoginResponse(response: DataResponse<Any>){
        if response.result.value != nil {
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata]  as! NSDictionary
                    loadFolder(data: data)
                    loadData()
                }
            }
        }
    }
    
    func successResponse(response: DataResponse<Any>) {
        if response.result.value != nil {
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata]  as! NSDictionary
                    loadFolder(data: data)
                    loadData()
                }
            }
        }
    }
    
    func networkFailureAction() {
        retryView.isHidden = false
        isWebManagerDelegate = true
    }

    func failureResponse(response: DataResponse<Any>) {
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}

extension FolderViewController: ActionViewControllerDelegate {
    func recallApi() {
        WebManager.getInstance(delegate: self)?.getFolderContent(folderId: (folder.folderIdEnc))
    }
}
