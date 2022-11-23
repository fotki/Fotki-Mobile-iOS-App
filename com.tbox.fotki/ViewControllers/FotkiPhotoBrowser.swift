//
//  FotkiPhotoBrowser.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 2/16/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import Foundation
import SKPhotoBrowser
import AVKit
import AVFoundation

protocol FotkiPhotoBrowserDelegate {
    func getMoreAlbumData()
}

class FotkiPhotoBrowser: SKPhotoBrowser {
    var fDelegate: FotkiPhotoBrowserDelegate? = nil
    var playerController = AVPlayerViewController()
    var player: AVPlayer?
    var photo = FotkiSKPhoto()
    var aboveToolbar = UIToolbar()
    var addAboveToolbar: Bool = true
    var isOriginalDownloading = Bool()
    var shareBtn = UIButton(type: UIButton.ButtonType.custom) as UIButton
    let playBtn = UIButton(type: UIButton.ButtonType.custom) as UIButton
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureAboveToolbar()
        configureShareButton()
        self.delegate = self
        toolbar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        aboveToolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: 45)
        shareBtn.frame = CGRect(x: UIScreen.main.bounds.height - 70, y: 10, width: 70, height: 30)
        playBtn.frame = CGRect(x: (UIScreen.main.bounds.height/2.0) - 75, y: (UIScreen.main.bounds.width/2.0) - 75, width: 150, height: 150)
    }
    
    func configureAboveToolbar() {
        let screenSize = UIScreen.main.bounds
        aboveToolbar.backgroundColor = UIColor(red: 0, green: 0 , blue: 0, alpha: 0.5)
        aboveToolbar.clipsToBounds = true
        aboveToolbar.isTranslucent = true
        aboveToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        aboveToolbar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 45)
        for subview in self.view.subviews {
            if subview is UIButton {
                if addAboveToolbar {
                    self.view.insertSubview(aboveToolbar, belowSubview: subview)
                    addAboveToolbar = false
                }
            }
        }
    }
    
    func configureShareButton() {
        let screenSize = UIScreen.main.bounds
        shareBtn.setTitle(kShare, for: .normal)
        shareBtn.titleLabel?.textColor = .white
        shareBtn.frame = CGRect(x: screenSize.width - 70, y: 10, width: 70, height: 30)
        shareBtn.addTarget(self, action: #selector(self.showImageResizingAlert), for: .touchUpInside)
        self.view.addSubview(shareBtn)
    }
    
    @objc func playVideoButtonTapped() {
        let videoUrl = Utility.stringNullCheck(stringToCheck: photo.videoUrl as AnyObject)
        print(videoUrl)
        if videoUrl.contains("http") && videoUrl != "" {
            let movieUrl: NSURL? = NSURL(string: photo.videoUrl)
            if let Url = movieUrl {
                self.player = AVPlayer(url: Url as URL)
                self.playerController.player = self.player
            }
            self.present(self.playerController, animated: true, completion: {
                self.playerController.player?.play()
            })
        } else {
            Utility.showAlertWithSingleOption(controller: self, title: "", message: kError_loading_video_please_contact_Fotki_customer_service, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
        }
    }
    
    override func photoAtInd(index: Int) {
        super.photoAtInd(index: index)
        photo = photos[index] as! FotkiSKPhoto
        if (index+1 == photos.count) && (photos.count <= self.numberOfPhotos) {
            fDelegate?.getMoreAlbumData()
        }
        let screenSize = UIScreen.main.bounds
        for case let pagingSV as SKPagingScrollView in self.view.subviews {
            let page = pagingSV.pageDisplayedAtIndex(index)
            if photo.isVideo {
                let image = UIImage(named: kPlayImage) as UIImage?
                playBtn.frame = CGRect(x: (screenSize.width/2.0) - 75, y: (screenSize.height/2.0) - 75, width: 150, height: 150)
                playBtn.setImage(image, for: .normal)
                playBtn.addTarget(self, action: #selector(self.playVideoButtonTapped), for: .touchUpInside)
                page?.addSubview(playBtn)
            }
        }
    }
    
    @objc func showImageResizingAlert() {
        if !photo.isDeleted {
            if photo.isVideo  || (photo.isOriginal && photo.originalImageDimensions.width < 500 && photo.originalImageDimensions.height < 500){
                self.isOriginalDownloading = true
                self.shareFile()
            } else {
                let alert = UIAlertController(title: kShare_Media, message: "", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: self.getResizedTitle(), style: UIAlertAction.Style.default, handler: { action in
                    self.isOriginalDownloading = false
                    self.shareFile()
                }))
               if photo.isOriginal {
                    alert.addAction(UIAlertAction(title: self.getOriginalSizeTitle(), style: UIAlertAction.Style.default, handler: { action in
                        self.isOriginalDownloading = true
                        self.shareFile()
                    }))
                }
                alert.addAction(UIAlertAction(title: kCancel, style: UIAlertAction.Style.cancel , handler:nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func getOriginalSizeTitle() -> String {
        var sizeText = ""
        if(photo.imageSize as! Int > 0 ){
            sizeText = "(\(ByteCountFormatter.string(fromByteCount: Int64(truncating: photo.imageSize), countStyle: ByteCountFormatter.CountStyle.file)))"
        }
        
        return "Original \(Int(photo.originalImageDimensions.width))X\(Int(photo.originalImageDimensions.height)) \(sizeText)"
    }
   
    func getResizedTitle() -> String {
        if !photo.isOriginal {
            self.isOriginalDownloading = true
            return kResized
        } else {
            self.isOriginalDownloading = false
            var sizeText = ""
            if (photo.resizedImageSize as! Int > 0 ){
                sizeText = "(\(ByteCountFormatter.string(fromByteCount: Int64(truncating: photo.resizedImageSize), countStyle: ByteCountFormatter.CountStyle.file))"
            }
            
            return "Resized \(Int(photo.resizedImageDimensions.width))X\(Int(photo.resizedImageDimensions.height)) \(sizeText)"
        }
    }
    
    func shareFile() {
        let downloadFileViewController = DownloadFileViewController(nibName: kDownloadFileViewController, bundle: nil)
        if photo.isVideo {
            downloadFileViewController.videoUrl = photo.videoUrl
            downloadFileViewController.photoUrl = ""
        } else {
            if self.isOriginalDownloading {
                downloadFileViewController.photoUrl = photo.originalPhotoUrl
            } else {
                downloadFileViewController.photoUrl = photo.resizedPhotoUrl
            }
            downloadFileViewController.videoUrl = ""
        }
        downloadFileViewController.view.frame = self.view.frame
        downloadFileViewController.view.center = self.view.center
        self.addChild(downloadFileViewController)
        self.view.addSubview(downloadFileViewController.view)
        downloadFileViewController.didMove(toParent: self)
    }
    override var prefersStatusBarHidden: Bool {
      return true
    }
}

extension FotkiPhotoBrowser: SKPhotoBrowserDelegate {
    func controlsVisibilityToggled(hidden: Bool) -> Void {
        UIView.animate(withDuration: 0.35, animations: { () -> Void in
            let alpha: CGFloat = hidden ? 0.0 : 1.0
            self.shareBtn.alpha = alpha
            if hidden {
                self.shareBtn.frame = CGRect(x: self.shareBtn.frame.origin.x, y: -45, width: self.shareBtn.frame.size.width, height: self.shareBtn.frame.size.height)
                self.aboveToolbar.frame = CGRect(x: self.aboveToolbar.frame.origin.x, y: -45, width: self.aboveToolbar.frame.size.width, height: self.aboveToolbar.frame.size.height)
            } else {
                self.shareBtn.frame = CGRect(x: self.shareBtn.frame.origin.x, y: 10, width: self.shareBtn.frame.size.width, height: self.shareBtn.frame.size.height)
                self.aboveToolbar.frame = CGRect(x: self.aboveToolbar.frame.origin.x, y: 0, width: self.aboveToolbar.frame.size.width, height: self.aboveToolbar.frame.size.height)
            }
        }, completion: nil)
    }
}
