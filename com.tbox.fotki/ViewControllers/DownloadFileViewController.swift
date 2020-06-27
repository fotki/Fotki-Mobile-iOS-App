//
//  DownloadFileViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 2/17/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import Alamofire

class DownloadFileViewController: UIViewController {
    @IBOutlet weak var retryView: UIView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var image: UIImageView!
    var videoUrl = String()
    var photoUrl = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        downloadFiles()
    }
    
    func downloadFiles() {
        if Utility.isInternetConnected() {
            if videoUrl != "" {
                print(videoUrl)
                downloadFile(url: videoUrl)
            } else {
                print(photoUrl)
                downloadFile(url: photoUrl)
            }
        } else {
            retryView.isHidden = false
        }
    }
    
    func downloadFile(url: String) {
        retryView.isHidden = true
        self.progressView.progress = 0
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var fileName = String()
            if self.videoUrl != "" {
                fileName = kTempMp4
            } else {
                fileName = kTempPng
            }
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent(fileName)
            return (documentsURL, [.removePreviousFile])
        }
        Alamofire.download(url, to: destination).downloadProgress(closure: { progress in
            print(progress.fractionCompleted)
            self.progressView.progress = Float(progress.fractionCompleted)
        }).responseData { response in
            if let destinationUrl = response.destinationURL {
                print(destinationUrl)
                var activityViewController: UIActivityViewController
                if self.videoUrl == "" {
                    let data:NSData? = NSData(contentsOf : destinationUrl)
                    let imageDownloaded = UIImage(data : data! as Data)
                    activityViewController = UIActivityViewController(activityItems: [imageDownloaded ?? UIImage()], applicationActivities: nil)
                } else {
                    let videoURL = NSURL(fileURLWithPath: destinationUrl.path)
                    let activityItems = [videoURL]
                    activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
                }
                self.present(activityViewController, animated: true)
                activityViewController.completionWithItemsHandler = self.completionHandler
            }
        }
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        self.downloadFiles()
    }

    func completionHandler(activityType: UIActivity.ActivityType?, shared: Bool, items: [Any]?, error: Error?) {
        if shared {
            var message = ""
            if activityType == UIActivity.ActivityType.postToVimeo || activityType == UIActivity.ActivityType.postToFacebook || activityType == UIActivity.ActivityType.postToFlickr || activityType == UIActivity.ActivityType.postToVimeo || activityType == UIActivity.ActivityType.postToWeibo || activityType == UIActivity.ActivityType.postToTencentWeibo {
                message = kFile_has_been_shared
            } else if activityType == UIActivity.ActivityType.saveToCameraRoll {
                message = kFile_has_been_saved
            } else if activityType == UIActivity.ActivityType.copyToPasteboard {
                message = kFile_has_been_copied
            } else if activityType == UIActivity.ActivityType.mail || activityType == UIActivity.ActivityType.message {
                message = kFile_has_been_shared
            } else if activityType == UIActivity.ActivityType.assignToContact {
                message = kFile_has_been_assigned_to_contact
            } else if activityType == UIActivity.ActivityType.print {
                message = kFile_has_been_printed
            } else if activityType == UIActivity.ActivityType.addToReadingList {
                message = kFile_has_been_added_to_reading_list
            } else if activityType == UIActivity.ActivityType(kActivityTypeNotes) {
                message = kFile_has_been_added_to_notes
            } else {
                message = kFile_has_been_shared
            }
            Utility.showAlertWithSingleOption(controller: self, title: "", message: message, preferredStyle: .alert, buttonText: kOK, buttonHandler: { (action: UIAlertAction!) in
                self.willMove(toParent: nil)
                self.view.removeFromSuperview()
                self.removeFromParent()
            })
            
        } else {
            print("Cancelled")
            self.view.removeFromSuperview()
        }
    }
}
