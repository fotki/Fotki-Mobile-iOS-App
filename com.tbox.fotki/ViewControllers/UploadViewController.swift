//
//  UploadViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/25/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import UIKit
import Alamofire
import DKImagePickerController
import AVFoundation
import Photos

protocol UploadViewControllerDelegate {
    func recallApi()
}

class UploadViewController: UIViewController {
    var delegate: UploadViewControllerDelegate? = nil
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var multipleFileProgressLabel: UILabel!
    @IBOutlet weak var retryView: UIView!
    @IBOutlet weak var noUploadLabel: UILabel!
    @IBOutlet weak var multipleFileProgressView: UIProgressView!
    @IBOutlet weak var singleFileProgressLabel: UILabel!
    @IBOutlet weak var singleFileProgressView: UIProgressView!
    @IBOutlet weak var uploadbutton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    var assets: [DKAsset]?
    var totalItems = Int()
    var newAsset = Bool()
    var isOriginalUploadingOn = Bool()
    var isPublicFile = Bool()
    var uploadComplete = Bool()
    var currentUploadingCount = Int()
    var albumId = NSNumber()
    var resizingSize = Float()
    var videoData: [Data] = []
    var isUploadingFailed = Bool()
    @IBOutlet weak var startUpload: UILabel!
    
    //MARK: view controller life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavBarItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setInitialView()
    }
    
    func setInitialView() {
        if newAsset == true && uploadComplete == false {
            self.scrollView.isHidden = false
            self.noUploadLabel.isHidden = true
            self.uploadView.isHidden = true
            self.singleFileProgressView.progress = 0
            self.multipleFileProgressView.progress = 0
            //uploadFiles()
            newAsset = false
            showImageResizingAlert()
        }
        if uploadComplete == true {
            DispatchQueue.main.async { 
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if !appDelegate.isAlbum {
                self.uploadbutton.isHidden = true
                self.noUploadLabel.isHidden = false
                self.noUploadLabel.text = kPlease_select_album_to_upload
            } else {
                self.noUploadLabel.isHidden = true
                self.uploadbutton.isHidden = false
            }
            self.uploadView.isHidden = false
            self.scrollView.isHidden = true
          //  self.noUploadLabel.isHidden = false
        }
    }
    }
    
    func showImageResizingAlert() {
        isOriginalUploadingOn = false
        let alert = UIAlertController(title: kResize_photos_before_uploading, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.setValue(Utility.getAttributedAlertText(regularText: kImage_resize_option_text), forKey: kattributedMessage)
        alert.addAction(UIAlertAction(title: kResized, style: UIAlertAction.Style.default, handler: { action in
            self.isOriginalUploadingOn = false
            self.resizingSize = 1400;
            self.uploadFiles()
        }))
        alert.addAction(UIAlertAction(title: kOriginals, style: UIAlertAction.Style.default, handler: { action in
            self.isOriginalUploadingOn = true
            self.uploadFiles()
        }))
        alert.addAction(UIAlertAction(title: kCancel, style: UIAlertAction.Style.default , handler:  { action in
            self.singleFileProgressView.progress = 0
            self.multipleFileProgressView.progress = 0
            self.uploadComplete = true
            self.scrollView.isHidden = true
            self.uploadView.isHidden = false
            self.noUploadLabel.isHidden = true
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: upload files
    func uploadItem(item: DKAsset) {
//if DKAssetType.video.rawValue == 1 {
        if item.type == .video {
            item.fetchAVAsset { (video, info) in
                if(video == nil){
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kiCloud_error_message, preferredStyle: .alert, buttonText: kok) { UIAlertAction in
                        self.dismiss(animated: false, completion: nil)
                    }
                    return;
                }
                let url = video?.value(forKeyPath: kURL)!
                print(url!)
                let videoData = (NSData(contentsOf: url as! URL) as Data?)
                 DispatchQueue.main.async {
                WebManager.getInstance(delegate: self)?.uploadItemWithAlamofire(controller: self, data: videoData!, isVideo: true, image: self.videoPreviewImage(fileName: url as! URL)!, isGif: false, startUpload: self.startUpload)
                }}
        } else {
            let options = PHImageRequestOptions()
                    options.isSynchronous = false
                    options.isNetworkAccessAllowed = true
                    options.deliveryMode = .opportunistic
                    options.version = .current
                    options.resizeMode = .exact
            item.fetchImageData(options:options, completeBlock: { data, info in
                if(data == nil){
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kiCloud_error_message, preferredStyle: .alert, buttonText: kok) { UIAlertAction in
                        self.dismiss(animated: false, completion: nil)
                    }
                    return;
                }
                print("data format: \(data!.format)")
                var image: UIImage?
                if data!.format == "gif" {
                    if let imageData = data {
                        image = UIImage.gifImageWithData(imageData)
                    }
                    WebManager.getInstance(delegate: self)?.uploadItemWithAlamofire(controller: self, data: data!, isVideo: false, image: image!, isGif: true, startUpload: self.startUpload)
                } else {
                    if let imageData = data {
                        image = UIImage(data: imageData)
                    }
                    let heightInPoints = (image?.size.height)
                    let heightInPixels = heightInPoints! * (image?.scale)!
                    let widthInPoints = (image?.size.width)
                    let widthtInPixels = widthInPoints! * (image?.scale)!
                    var maxResolation = CGFloat()
                    maxResolation = heightInPixels
                    if !self.isOriginalUploadingOn {
                        if heightInPixels > 1400 || widthtInPixels > 1400 {
                            image = Utility.resizeImage(image: image!, targetSize: CGSize(width: 1400, height: 1400))
                            maxResolation = 1400
                        } 
                    }
                    let correctOrientedImage = self.rotateCameraImageToProperOrientation(imageSource: image!,maxResolution: maxResolation)
                    let imageData = correctOrientedImage.jpegData(compressionQuality: 1.0)
                    WebManager.getInstance(delegate: self)?.uploadItemWithAlamofire(controller: self, data: imageData!, isVideo: false, image: image!, isGif: false, startUpload: self.startUpload)
                }
            })
        }
    }
    
    func rotateCameraImageToProperOrientation(imageSource : UIImage, maxResolution : CGFloat) -> UIImage {
        let imgRef = imageSource.cgImage
        let width = CGFloat(imgRef!.width)
        let height = CGFloat(imgRef!.height)
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        var scaleRatio : CGFloat = 1
        if width > maxResolution || height > maxResolution {
            scaleRatio = min(maxResolution / bounds.size.width, maxResolution / bounds.size.height)
            bounds.size.height = bounds.size.height * scaleRatio
            bounds.size.width = bounds.size.width * scaleRatio
        }
        var transform = CGAffineTransform.identity
        let orient = imageSource.imageOrientation
        let imageSize = CGSize(width: imgRef!.width, height: imgRef!.height)
        switch imageSource.imageOrientation {
        case .up :
            transform = CGAffineTransform.identity
        case .upMirrored :
            transform = CGAffineTransform(translationX: imageSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down :
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .downMirrored :
            transform = CGAffineTransform(translationX: 0, y: imageSize.height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransform(translationX: 0, y: imageSize.width)
            transform = transform.rotated(by: 3.0 * CGFloat.pi / 2.0)
        case .leftMirrored :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: 3.0 * CGFloat.pi / 2.0)
        case .right :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .rightMirrored :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransform(scaleX: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context = UIGraphicsGetCurrentContext()
        if orient == .right || orient == .left {
            
            context!.scaleBy(x: -scaleRatio, y: scaleRatio)
            context!.translateBy(x: -height, y: 0)
        } else {
            context!.scaleBy(x: scaleRatio, y: -scaleRatio)
            context!.translateBy(x: 0, y: -height)
        }
        context!.concatenate(transform)
        context!.draw(imgRef!, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageCopy!
    }
    
    func uploadFiles() {
        totalItems = (assets?.count)!
        if !(isUploadingFailed) {
            currentUploadingCount = 0
        }
        if currentUploadingCount < 1 {
            let progressDictionary:[String: Int] = [kuploadedCount: self.currentUploadingCount, ktotalCount: self.totalItems]
            // post a notification
            NotificationCenter.default.post(name: NSNotification.Name(kUploadProgress), object: nil, userInfo: progressDictionary)
        }
        isUploadingFailed = false
        self.multipleFileProgressLabel.text = "\(self.currentUploadingCount) \(kof) \(self.totalItems) \(kfiles_have_been_uploaded)"
        self.uploadItem(item: (assets?[currentUploadingCount])!)
    }
    
    //MARK: load NavBar Items
    func loadNavBarItems() {
        let logo = UIImage(named: klogoImage)
        let logoImageView = UIImageView(image: logo)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        logoImageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.navigationItem.titleView = logoImageView
    }
    
    //MARK: get video thumbnail from local directory
    func videoPreviewImage(fileName: URL) -> UIImage? {
        let asset = AVURLAsset(url: fileName)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timeStamp = CMTime(seconds: 2, preferredTimescale: 60)
        do {
            let imageRef = try generator.copyCGImage(at: timeStamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print("\(error)")
            return nil
        }
    }
    @IBAction func openPhotoGallery(_ sender: Any) {
        uploadComplete = false
        let pickerController = DKImagePickerController()
            pickerController.didSelectAssets = { (assets: [DKAsset]) in
                if assets.count != 0 {
                    self.assets = assets
                    self.newAsset = true
                    self.uploadComplete = false
                    //pickerController.deselectAll()
                    pickerController.deselectAll()
//                    pickerController.deselectAllAssets()
                   // deselectAllAssets()   deselectAll()
                    self.setInitialView()
                }
            }
           pickerController.modalPresentationStyle = .fullScreen
            self.present(pickerController, animated: true) {}
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        self.singleFileProgressView.progress = 0
        retryView.isHidden = true
        isUploadingFailed = true
        uploadFiles()
    }
}

extension UploadViewController: WebManagerDelegate {
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>) {
        print(response)
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if ok == 1 {
                self.currentUploadingCount += 1
                self.multipleFileProgressView.progress = Float(self.currentUploadingCount)/Float(self.totalItems)
                self.multipleFileProgressLabel.text = "\(self.currentUploadingCount) \(kof) \(self.totalItems) \(kfiles_have_been_uploaded)"
                let progressDictionary: [String: Int] = [kuploadedCount: self.currentUploadingCount, ktotalCount: self.totalItems]
                // post a notification
                NotificationCenter.default.post(name: NSNotification.Name(kUploadProgress), object: nil, userInfo: progressDictionary)
                if self.currentUploadingCount < self.totalItems {
                    self.uploadItem(item: (self.assets?[self.currentUploadingCount])!)
                } else {
                    self.assets?.removeAll()
                    self.singleFileProgressView.progress = 0
                    self.singleFileProgressLabel.text = kZeroPercent
                    self.multipleFileProgressView.progress = 0
                    self.uploadComplete = true
                    delegate?.recallApi()
                    NotificationCenter.default.post(name: NSNotification.Name(kcompletion), object: nil, userInfo: nil)
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kUpload_is_done, preferredStyle: .alert, buttonText: kReturn, buttonHandler: { (action: UIAlertAction!) in
                        // _ = self.navigationController?.popViewController(animated: true)
                        if self.isPublicFile {
                            self.tabBarController?.selectedIndex = 0
                        } else {
                            self.tabBarController?.selectedIndex = 1
                        }
                        
                    })
                }
            } else {
               self.uploadItem(item: (self.assets?[self.currentUploadingCount])!)
            }
        } else {
            self.singleFileProgressView.progress = 0
            networkFailureAction()
        }
    }

    func successResponse(response: DataResponse<Any>) {
        print(response)
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if ok == 1 {
                self.currentUploadingCount += 1
                self.multipleFileProgressView.progress = Float(self.currentUploadingCount)/Float(self.totalItems)
                self.multipleFileProgressLabel.text = "\(self.currentUploadingCount) \(kof) \(self.totalItems) \(kfiles_have_been_uploaded)"
                let progressDictionary: [String: Int] = [kuploadedCount: self.currentUploadingCount, ktotalCount: self.totalItems]
                // post a notification
                NotificationCenter.default.post(name: NSNotification.Name(kUploadProgress), object: nil, userInfo: progressDictionary)
                if self.currentUploadingCount < self.totalItems {
                    self.uploadItem(item: (self.assets?[self.currentUploadingCount])!)
                } else {
                    self.assets?.removeAll()
                    self.singleFileProgressView.progress = 0
                    self.singleFileProgressLabel.text = kZeroPercent
                    self.multipleFileProgressView.progress = 0
                    self.uploadComplete = true
                    delegate?.recallApi()
                    NotificationCenter.default.post(name: NSNotification.Name(kcompletion), object: nil, userInfo: nil)
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kUpload_is_done, preferredStyle: .alert, buttonText: kReturn, buttonHandler: {
                        (action: UIAlertAction!) in
                        if self.isPublicFile {
                            self.tabBarController?.selectedIndex = 0
                        } else {
                            self.tabBarController?.selectedIndex = 1
                        }
                        
                    })
                }
            } else {
                self.uploadItem(item: (self.assets?[self.currentUploadingCount])!)
            }
        } else {
            self.singleFileProgressView.progress = 0
            networkFailureAction()
        }
    }
    
    func networkFailureAction() {
        retryView.isHidden = false
    }
    
    func failureResponse(response: DataResponse<Any>) {
        print(response)
        if self.currentUploadingCount < self.totalItems {
            self.uploadItem(item: (self.assets?[self.currentUploadingCount])!)
        } else {
            self.assets?.removeAll()
            self.singleFileProgressView.progress = 0
            self.singleFileProgressLabel.text = kZeroPercent
            delegate?.recallApi()
            NotificationCenter.default.post(name: NSNotification.Name(kcompletion), object: nil, userInfo: nil)
            Utility.showAlertWithSingleOption(controller: self, title: "", message: kUpload_is_done, preferredStyle: .alert, buttonText: kReturn, buttonHandler: { (action: UIAlertAction!) in
                _ = self.navigationController?.popViewController(animated: true)
            })
        }
    }
}

extension Data {
    var format: String {
        let array = [UInt8](self)
        let ext: String
        switch (array[0]) {
        case 0xFF:
            ext = "jpg"
        case 0x89:
            ext = "png"
        case 0x47:
            ext = "gif"
        case 0x49, 0x4D :
            ext = "tiff"
        default:
            ext = "unknown"
        }
        return ext
    }
}
