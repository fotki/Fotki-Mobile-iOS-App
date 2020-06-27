//
//  MyTabViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 12/29/16.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import Alamofire

protocol MainTabViewControllerDelegate {
    func loadPrivateData(privateData: NSDictionary)
    func loadPublicData(publicData: NSDictionary)
    func networkFailureResponse()
}

class MainTabViewController: UITabBarController {
    var publicDelegate: MainTabViewControllerDelegate? = nil
    var privateDelegate: MainTabViewControllerDelegate? = nil
    var activityIndicator = UIActivityIndicatorView()
    var separate: UIView! = nil
    
    //MARK: view's life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        perform(#selector(setupTabBarSeparators), with: nil, afterDelay: 0.1)
    }
    
    func retryNetworkCall() {
        self.loadAccountTree()
    }
    
    func loadAccountTree() {
        self.activityIndicator = Utility.startSpinner(view: self.view)
        self.activityIndicator.hidesWhenStopped = true
        WebManager.getInstance(delegate: self)?.getAccountTree()
    }
    
    @objc func setupTabBarSeparators() {
        let itemWidth = floor(self.tabBar.frame.size.width / CGFloat(self.tabBar.items!.count))
        let separatorWidth: CGFloat = 0.5
        
        var separator: UIView? = nil
        var secondSeparator: UIView? = nil
        if (self.tabBar.viewWithTag(10001) != nil) {
            separator = self.tabBar.viewWithTag(10001)!
            separator?.frame = CGRect(x: itemWidth * CGFloat(0 + 1) - CGFloat(separatorWidth / 2), y: 0, width: CGFloat(separatorWidth), height: self.tabBar.frame.size.height)
            
        }else {
            separator =  UIView(frame: CGRect(x: itemWidth * CGFloat(0 + 1) - CGFloat(separatorWidth / 2), y: 0, width: CGFloat(separatorWidth), height: self.tabBar.frame.size.height))
            separator?.tag = 10001
            separator?.backgroundColor = UIColor.lightGray
            self.tabBar.addSubview(separator!)
        }
        
        if (self.tabBar.viewWithTag(10002) != nil) {
            secondSeparator = self.tabBar.viewWithTag(10002)!
            secondSeparator?.frame = CGRect(x: itemWidth * CGFloat(0 + 2), y: 0, width: CGFloat(separatorWidth), height: self.tabBar.frame.size.height)
        }else {
            secondSeparator = UIView(frame: CGRect(x: itemWidth * CGFloat(0 + 2), y: 0, width: CGFloat(separatorWidth), height: self.tabBar.frame.size.height))
            secondSeparator?.tag = 10002
            secondSeparator?.backgroundColor = UIColor.lightGray
            self.tabBar.addSubview(secondSeparator!)
        }

    }
    
    override func viewWillLayoutSubviews() {
        self.tabBar.itemPositioning = UITabBar.ItemPositioning.fill
//        self.tabBar.barTintColor = UIColor.black
    }
}

extension MainTabViewController: FoldersViewControllerDelegate {
    //MARK: FoldersViewControllerDelegate functions
    func reloadAccountTree() {
        WebManager.getInstance(delegate: self)?.getAccountTree()
    }
    func reloadAccountTreeWithIndicator() {
        self.loadAccountTree()
    }

}

extension MainTabViewController: FolderViewControllerDelegate {
    //MARK: FoldersViewControllerDelegate functions
    func reloadAccountTreeOnNetworkFailure() {
        WebManager.getInstance(delegate: self)?.getAccountTree()
    }
}

extension MainTabViewController: WebManagerDelegate {
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>){
        Utility.stopSpinner(activityIndicator: activityIndicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if response.result.value != nil{
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let accountTree = data[kaccount_tree] as! NSDictionary
                    let privateData = accountTree[kprivate] as! NSDictionary
                    let publicData = accountTree[kpublic] as! NSDictionary
                    if (privateDelegate != nil) {
                        privateDelegate?.loadPrivateData(privateData: privateData)
                    }
                    if (publicDelegate != nil) {
                        publicDelegate?.loadPublicData(publicData: publicData)
                    }
                } else {
                    self.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    func successResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if response.result.value != nil{
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let accountTree = data[kaccount_tree] as! NSDictionary
                    let privateData = accountTree[kprivate] as! NSDictionary
                    let publicData = accountTree[kpublic] as! NSDictionary
                    if (privateDelegate != nil) {
                        privateDelegate?.loadPrivateData(privateData: privateData)
                    }
                    if (publicDelegate != nil) {
                        publicDelegate?.loadPublicData(publicData: publicData)
                    }
                } else {
                    self.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    func networkFailureAction() {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if (privateDelegate != nil) {
            privateDelegate?.networkFailureResponse()
        }
        if (publicDelegate != nil) {
            publicDelegate?.networkFailureResponse()
        }
    }

    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}
