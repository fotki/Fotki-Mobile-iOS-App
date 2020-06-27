//
//  MenuViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/2/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import Alamofire
import SideMenuController

class MenuViewController: UIViewController {
    @IBOutlet weak var imgView: UIView!
    @IBOutlet weak var itemsLabel: UILabel!
    @IBOutlet weak var itemsProgressView: UIProgressView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var img: UIImageView!
    var sessionCount = 0
    var imageY = CGFloat()
    var nameLabelY = CGFloat()
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: IBAction Buttons
    @IBAction func logout(_ sender: Any) {
        Utility.showAlertWithOptions(controller: self, title: "", message: kAre_you_sure_you_want_to_logout, preferredStyle: .alert, rightBtnText: kno, leftBtnText: kyes, leftBtnhandler: { (action: UIAlertAction!) in
            let session = Session.getInstance()
            if (session?.user.isGmailLogin)! {
                NotificationCenter.default.post(name: NSNotification.Name(kGmailLogout), object: nil, userInfo: nil)
                session?.user.isGmailLogin = false
            } else if (session?.user.isFacebookLogin)! {
                NotificationCenter.default.post(name: NSNotification.Name(kFacebookLogout), object: nil, userInfo: nil)
                session?.user.isFacebookLogin = false
            }
            session?.sessionId = ""
            session?.user.isLogin = false
            session?.saveSession()
            self.dismiss(animated: false, completion: nil)
        })
    }
  
    @IBAction func openUploadScreen(_ sender: Any) {
        if itemsProgressView.alpha == 1 {
            self.perform(#selector(uploadScreen), with: nil, afterDelay: 0.2)
        }
    }
    
    @objc func uploadScreen() {
        self.sideMenuController?.toggle()
        (self.sideMenuController?.centerViewController as! UITabBarController).selectedIndex = 2
    }
    
    //MARK: view's lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDetails()
        NotificationCenter.default.addObserver(self, selector: #selector(self.showProgress(_:)), name: NSNotification.Name(kUploadProgress), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showCompletion), name: NSNotification.Name(kcompletion), object: nil)
        self.perform(#selector(setUpperViewDesign), with: nil, afterDelay: 0.2)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kUploadProgress), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kcompletion), object: nil)
    }
    
    @objc func setUpperViewDesign() {
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            imgView.frame = CGRect(x: imgView.frame.origin.x, y: imageY, width: imgView.frame.width, height: imgView.frame.height)
            userName.frame = CGRect(x: userName.frame.origin.x, y: nameLabelY, width: userName.frame.width, height: userName.frame.height)
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
                imgView.frame = CGRect(x: imgView.frame.origin.x, y: 2, width: imgView.frame.width, height: imgView.frame.height)
                userName.frame = CGRect(x: userName.frame.origin.x, y: 82, width: userName.frame.width, height: userName.frame.height)
            }
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
                imgView.frame = CGRect(x: imgView.frame.origin.x, y: 2, width: imgView.frame.width, height: imgView.frame.height)
                userName.frame = CGRect(x: userName.frame.origin.x, y: 82, width: userName.frame.width, height: userName.frame.height)
            }
        } else {
            imgView.frame = CGRect(x: imgView.frame.origin.x, y: imageY, width: imgView.frame.width, height: imgView.frame.height)
            userName.frame = CGRect(x: userName.frame.origin.x, y: nameLabelY, width: userName.frame.width, height: userName.frame.height)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            imgView.frame = CGRect(x: imgView.frame.origin.x, y: imageY, width: imgView.frame.width, height: imgView.frame.height)
            userName.frame = CGRect(x: userName.frame.origin.x, y: nameLabelY, width: userName.frame.width, height: userName.frame.height)
        } else {
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
                imgView.frame = CGRect(x: imgView.frame.origin.x, y: 2, width: imgView.frame.width, height: imgView.frame.height)
                userName.frame = CGRect(x: userName.frame.origin.x, y: 82, width: userName.frame.width, height: userName.frame.height)
            }
        }
    }
    
    //MARK: functions for show progress in sideMenu
    @objc func showProgress(_ notification: NSNotification) {
        itemsProgressView.alpha = 1
        itemsLabel.alpha = 1
        let uploadedItems = notification.userInfo?[kuploadedCount] as! Int
        let totalItems = notification.userInfo?[ktotalCount] as! Int
        itemsLabel.text = "\(uploadedItems) \(kof) \(totalItems) \(kfiles_have_been_uploaded)"
        itemsProgressView.progress = Float(uploadedItems)/Float(totalItems)
    }
    
    @objc func showCompletion() {
        itemsProgressView.alpha = 0
        itemsLabel.alpha = 0
    }
    
    //MARK: load user details in side menu
    func loadUserDetails() {
        activityIndicator.hidesWhenStopped = true
        imageY = imgView.frame.origin.y
        nameLabelY = userName.frame.origin.y
        itemsProgressView.alpha = 0
        itemsLabel.alpha = 0
        self.view.layoutIfNeeded()
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2
        self.imgView.clipsToBounds = true
        activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
        WebManager.getInstance(delegate: self)?.getAccountInfo()
    }
}

extension MenuViewController: WebManagerDelegate {
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if ok == 1 {
                let data = JSON[kdata]  as! NSDictionary
                let accountInfo = data[kaccount_info]  as! NSDictionary
                let avatar = accountInfo[kavatar]  as! NSDictionary
                let name = accountInfo[kdisp_name] as! NSString
                let imageUrl = avatar[kurl] as! String
                self.userName.text = name as String
                WebManager.loadImage(imageUrl: imageUrl,imageView: self.img)
            } else {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }

    func successResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            let ok = JSON[kok] as! NSNumber
            if ok == 1 {
                let data = JSON[kdata]  as! NSDictionary
                let accountInfo = data[kaccount_info]  as! NSDictionary
                let avatar = accountInfo[kavatar]  as! NSDictionary
                let name = accountInfo[kdisp_name] as! NSString
                let imageUrl = avatar[kurl] as! String
                self.userName.text = name as String
                WebManager.loadImage(imageUrl: imageUrl,imageView: self.img)
            } else {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func networkFailureAction() {
        Utility.stopSpinner(activityIndicator: activityIndicator)
    }
    
    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}
