//
//   SegFaultDebugger.swift
//  Fotki
//
//  Created by Si on 10/2/19.
//  Copyright © 2019 TBoxSolutionz. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage
import Agrume
import SKPhotoBrowser
import DKImagePickerController
//import ESPullToRefresh

class AlbummViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView? = nil
    var imagesCache: [String: UIImage] = [:]
    let rightBarDropDown = DropDown()
    var album = Album()
    var images: [SKPhotoProtocol] = []
    var addBelowSpinner = Bool()
    var itemsCount = Int()
    var page = Int()
    var browser: FotkiPhotoBrowser? = nil
    var refresher:UIRefreshControl!
    var uploadViewController: UploadViewController? = nil
  
   
    
    func shareLink () {
        let text = album.url
        let linkToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: linkToShare, applicationActivities: nil)
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
        pasteBoard.string = album.url
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kLinkCopiedToClipboard, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
    
    func stopRefresher() {
        self.refresher.endRefreshing()
    }
    
   
    
    @objc func actionTapped() {
        self.rightBarDropDown.show()
    }
    
    func completionHandler(activityType: UIActivity.ActivityType?, shared: Bool, items: [Any]?, error: Error?) {
        if shared {
            print ("Shared")
        } else {
            print("Cancelled")
        }
    }
    
    //MARK: load NavBar Items
    func loadNavBarItems() {
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        self.collectionView?.frame.origin.x = navigationBarHeight
        let logo = UIImage(named: klogoImage)
        let logoImageView = UIImageView(image: logo)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        logoImageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.navigationItem.titleView = logoImageView
        let rightButton = UIBarButtonItem(image: UIImage(named: kdot), style: .plain, target: self, action: #selector(actionTapped))
        navigationController?.navigationBar.tintColor = .black
        self.navigationItem.rightBarButtonItem = rightButton
    }
    
    //MARK: SkPhoto's Data Setup
    func setupViewerData() {
        images = createLocalPhotos()
        if browser != nil {
            browser?.photos = images
            browser?.reloadData()
        }
    }
    
    func createLocalPhotos() -> [SKPhotoProtocol] {
        return (self.album.items).map { (item: Item) -> SKPhotoProtocol in
            let photo = FotkiSKPhoto()
            if item.isDeleted {
                photo.videoUrl = ""
                photo.setPhotoUrl(photoUrl: "")
                photo.setIsDeleted(isDeleted: item.isDeleted)
            } else {
                photo.setPhotoUrl(photoUrl: item.viewUrl)
                photo.setIsDeleted(isDeleted: item.isDeleted)
                if item.isVideo == true {
                    photo.setIsVideo(isVideo: true)
                    photo.videoUrl = item.originalUrl
                } else {
                    photo.setIsOriginal(isOriginal: item.isOriginal)
                    if item.isOriginal {
                        photo.setOriginalImageDimensions(originalImageDimensions: CGSize(width: item.imageWidth, height: item.imageHeight))
                    }
                    photo.setResizedPhotoUrl(resizedPhotoUrl: item.viewUrl)
                    photo.setOriginalPhotoUrl(originalPhotoUrl: item.originalUrl)
                    photo.setResizedImageDimensions(resizedImageDimensions: CGSize(width: item.resizedImageWidth, height: item.resizedImageHeight))
                    photo.setImageSize(imageSize: item.imageSize)
                    photo.setResizedImageSize(resizedImageSize: item.resizedImageSize)
                }
            }
            return photo
        }
    }
    
    
    
   
}
extension AlbummViewController: WebManagerDelegate {
    
    //not workng corectly but errors fixeed
    //    func successResponse(response: DataResponse<Any>) {
    //        if let result = response.result.value {
    //                        let JSON = result as! NSDictionary
    //            _ = JSON[kok] as! NSNumber
    //                        if (self.refresher) != nil {
    //                            self.stopRefresher()
    //                        }
    //    }
    //    }
    //
    //    func successFbLoginResponse(response: DataResponse<Any>) {
    //        if let result = response.result.value {
    //                       let JSON = result as! NSDictionary
    //            _ = JSON[kok] as! NSNumber
    //                      if (self.refresher) != nil {
    //                           self.stopRefresher()
    //                      }    }
    //    }
    ///// untill here
    
    
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>) {
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if (self.refresher) != nil {
                self.stopRefresher()
            }
            if ok == 1 {
                let data = JSON[kdata] as! NSDictionary
                print(data)
                let checkRequestUrl = (response.request?.description)! as String
                if checkRequestUrl.contains(kget_album_content) {
                    let album = data[kalbum] as AnyObject
                    self.album.name = album.value(forKeyPath: kalbum_name) as! String
                    self.album.description = album.value(forKey: kalbum_description) as! String
                    self.album.url = Utility.stringNullCheck(stringToCheck: album.value(forKeyPath: kurl) as AnyObject)
                    let getId = album.value(forKey: kid) as! String
                    if let convertedId = Int(getId) {
                        self.album.albumIdEnc = NSNumber(value: convertedId)
                    }
                    var imgThumbnailArray = NSMutableArray()
                    imgThumbnailArray = NSMutableArray(array: data[kphotos] as! NSArray)
                    for (index, item) in imgThumbnailArray.enumerated() {
                        let itemObj = Item()
                        itemObj.id = (item as AnyObject).value(forKeyPath: kid) as! NSNumber
                        itemObj.albumIdEnc = self.album.albumIdEnc
                        itemObj.viewUrl = (item as AnyObject).value(forKeyPath: kview_url) as! String
                        itemObj.originalUrl = Utility.stringNullCheck(stringToCheck: ((item as AnyObject).value(forKeyPath: koriginal_url) as! String) as AnyObject)
                        itemObj.thumbnailUrl = (item as AnyObject).value(forKeyPath: kthumbnail_url) as! String
                        itemObj.title = (item as AnyObject).value(forKeyPath: ktitle) as! String
                        let num = ((imgThumbnailArray[index]) as AnyObject).value(forKeyPath: kvideo)!
                        let fileSizes: NSDictionary = ((item as AnyObject).value(forKeyPath: kfile_sizes) as? NSDictionary)!
                        if (String(describing: type(of: num))) == kNSCFNumber {
                            itemObj.isVideo = false
                            if (item as AnyObject).value(forKeyPath:khas_original) as? NSNumber == 1 {
                                itemObj.isOriginal = true
                                itemObj.imageHeight = Int(((item as AnyObject).value(forKeyPath: koriginal_img_height) as? String!)!)!
                                itemObj.imageWidth = Int(((item as AnyObject).value(forKeyPath: koriginal_img_width) as? String!)!)!
                                itemObj.imageSize = fileSizes[kor_size] is NSNull ? 0 : fileSizes[kor_size] as! NSNumber
                            } else {
                                itemObj.isOriginal = false
                            }
                            itemObj.resizedImageHeight = Int(((item as AnyObject).value(forKeyPath: kview_img_height) as? String!)!)!
                            itemObj.resizedImageWidth = Int(((item as AnyObject).value(forKeyPath: kview_img_width) as? String!)!)!
                            itemObj.resizedImageSize = fileSizes[kvi_size] is NSNull ? 0 : fileSizes[kvi_size] as! NSNumber
                        } else {
                            itemObj.isVideo = true
                        }
                        itemObj.isDeleted = fileSizes[kth_size] is NSNull ? true : false
                        self.album.items.append(itemObj)
                    }
                    let noOfPhotos = album.value(forKey: knumber_of_photos) as! NSNumber
                    let noOfVideos = album.value(forKey: knumber_of_videos) as! NSNumber
                    self.album.noOfVideos = Int(truncating: noOfVideos)
                    self.album.noOfPhotos = Int(truncating: noOfPhotos)
                    self.albumName.text = self.album.name
                    Utility.stopSpinner(activityIndicator: activityIndicator)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.collectionView?.reloadData()
                    setupViewerData()
                } else if (checkRequestUrl.contains(kget_album_items_count)) {
                    let getCount = data[kitems_count] as! String
                    if let convertedCount = Int(getCount) {
                        itemsCount = convertedCount
                    }
                    if itemsCount == 0 {
                        self.emptyAlbumView.alpha = 1
                        self.detailContainerView.alpha = 0
                    } else {
                        self.emptyAlbumView.alpha = 0
                        self.detailContainerView.alpha = 1
                        self.albumName.text = self.album.name
                        self.albumName.isEditable = false
                        if self.albumName.contentSize.height > 85 {
                            self.albumName.frame.size.height = 85
                            self.albumName.isScrollEnabled = true
                        } else {
                            self.albumName.frame.size.height = self.albumName.contentSize.height
                            self.albumName.isUserInteractionEnabled = false
                        }
                        self.albumName.setContentOffset(.zero, animated: false)
                        self.descriptionTextView.frame.origin.y = self.albumName.frame.origin.y + self.albumName.frame.size.height + 6
                        self.descriptionTextView.text = self.album.description
                        if self.album.description == "" {
                            self.descriptionTextView.frame.size.height = 0.0
                        } else {
                            self.descriptionTextView.isEditable = false
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
                        self.collectionViewTopContraint.constant = self.detailContainerView.frame.size.height + 64
                        let videoCount = data.value(forKey: knumber_of_videos) as! NSNumber
                        let photoCount = data.value(forKey: knumber_of_photos) as! NSNumber
                        let size = data.value(forKey: ksize) as! String
                        let spaceUsed: Int64? = Int64(size)
                        let detailText = "\(itemsCount) files, \(videoCount)"
                        let sizeText = ByteCountFormatter.string(fromByteCount: spaceUsed!, countStyle: ByteCountFormatter.CountStyle.file)
                        self.albumDetail.text = "\(detailText) videos | \(photoCount) photos \(sizeText)"
                    }
                }
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
        
    }
    
    func successResponse(response: DataResponse<Any>) {
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if (self.refresher) != nil {
                self.stopRefresher()
            }
            if ok == 1 {
                let data = JSON[kdata] as! NSDictionary
                print(data)
                let checkRequestUrl = (response.request?.description)! as String
                if checkRequestUrl.contains(kget_album_content) {
                    let album = data[kalbum] as AnyObject
                    self.album.name = album.value(forKeyPath: kalbum_name) as! String
                    self.album.description = album.value(forKey: kalbum_description) as! String
                    self.album.url = Utility.stringNullCheck(stringToCheck: album.value(forKeyPath: kurl) as AnyObject)
                    let getId = album.value(forKey: kid) as! String
                    if let convertedId = Int(getId) {
                        self.album.albumIdEnc = NSNumber(value: convertedId)
                    }
                    var imgThumbnailArray = NSMutableArray()
                    imgThumbnailArray = NSMutableArray(array: data[kphotos] as! NSArray)
                    for (index, item) in imgThumbnailArray.enumerated() {
                        let itemObj = Item()
                        itemObj.id = (item as AnyObject).value(forKeyPath: kid) as! NSNumber
                        itemObj.albumIdEnc = self.album.albumIdEnc
                        itemObj.viewUrl = (item as AnyObject).value(forKeyPath: kview_url) as! String
                        itemObj.originalUrl = Utility.stringNullCheck(stringToCheck: ((item as AnyObject).value(forKeyPath: koriginal_url) as! String) as AnyObject)
                        itemObj.thumbnailUrl = (item as AnyObject).value(forKeyPath:kthumbnail_url) as! String
                        itemObj.title = (item as AnyObject).value(forKeyPath: ktitle) as! String
                        let num = ((imgThumbnailArray[index]) as AnyObject).value(forKeyPath: kvideo)!
                        let fileSizes: NSDictionary = ((item as AnyObject).value(forKeyPath:kfile_sizes) as? NSDictionary)!
                        if (String(describing: type(of: num))) == kNSCFNumber {
                            itemObj.isVideo = false
                            if (item as AnyObject).value(forKeyPath:khas_original) as? NSNumber == 1 {
                                itemObj.isOriginal = true
                                itemObj.imageHeight = Int(((item as AnyObject).value(forKeyPath:koriginal_img_height) as? String!)!)!
                                itemObj.imageWidth = Int(((item as AnyObject).value(forKeyPath:koriginal_img_width) as? String!)!)!
                                itemObj.imageSize = fileSizes[kor_size] is NSNull ? 0 : fileSizes[kor_size] as! NSNumber
                            } else {
                                itemObj.isOriginal = false
                            }
                            itemObj.resizedImageHeight = Int(((item as AnyObject).value(forKeyPath:kview_img_height) as? String!)!)!
                            itemObj.resizedImageWidth = Int(((item as AnyObject).value(forKeyPath:kview_img_width) as? String!)!)!
                            itemObj.resizedImageSize = fileSizes[kvi_size] is NSNull ? 0 : fileSizes[kvi_size] as! NSNumber
                        } else {
                            itemObj.isVideo = true
                        }
                        itemObj.isDeleted = fileSizes[kth_size] is NSNull ? true : false
                        self.album.items.append(itemObj)
                    }
                    let noOfPhotos = album.value(forKey: knumber_of_photos) as! NSNumber
                    let noOfVideos = album.value(forKey: knumber_of_videos) as! NSNumber
                    self.album.noOfVideos = Int(truncating: noOfVideos)
                    self.album.noOfPhotos = Int(truncating: noOfPhotos)
                    Utility.stopSpinner(activityIndicator: activityIndicator)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.collectionView?.reloadData()
                    setupViewerData()
                } else if (checkRequestUrl.contains(kget_album_items_count)) {
                    let getCount = data[kitems_count] as! String
                    if let convertedCount = Int(getCount) {
                        itemsCount = convertedCount
                    }
                    if itemsCount == 0 {
                        self.emptyAlbumView.alpha = 1
                        self.detailContainerView.alpha = 0
                    } else {
                        self.emptyAlbumView.alpha = 0
                        self.detailContainerView.alpha = 1
                        self.albumName.text = self.album.name
                        self.albumName.isEditable = false
                        if self.albumName.contentSize.height > 85 {
                            self.albumName.frame.size.height = 85
                            self.albumName.isScrollEnabled = true
                        } else {
                            self.albumName.frame.size.height = self.albumName.contentSize.height
                            self.albumName.isUserInteractionEnabled = false
                        }
                        self.albumName.setContentOffset(.zero, animated: false)
                        self.descriptionTextView.frame.origin.y = self.albumName.frame.origin.y + self.albumName.frame.size.height + 6
                        self.descriptionTextView.text = self.album.description
                        self.descriptionTextView.isEditable = false
                        if self.album.description == "" {
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
                        self.collectionViewTopContraint.constant = self.detailContainerView.frame.size.height + 64
                        let videoCount = data.value(forKey: knumber_of_videos) as! NSNumber
                        let photoCount = data.value(forKey: knumber_of_photos) as! NSNumber
                        let size = data.value(forKey: ksize) as! String
                        let convertedSize = Double(size)
                        let sizeInMB = convertedSize! / 1000000
                        let sizeText = String(format: "%.2f", arguments: [sizeInMB])
                        let detailText = "\(itemsCount) files, \(videoCount)"
                        self.albumDetail.text = "\(detailText) videos | \(photoCount) photos (\(sizeText) MB)"
                    }
                }
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func networkFailureAction() {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        retryView.isHidden = false
    }
    
    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        print(response.result.error!.localizedDescription)
        if response.result.error!.localizedDescription == kThe_Internet_connection_appears_to_be_offline {
            Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
        } else {
            Utility.showAlertWithSingleOption(controller: self, title: "", message: kSomething_went_wrong_with_this_album, preferredStyle: .alert, buttonText: kCancel, buttonHandler: { (action: UIAlertAction!) in
                _ = self.navigationController?.popViewController(animated: true)
            })
        }
    }
}
