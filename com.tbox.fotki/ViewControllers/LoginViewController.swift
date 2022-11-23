//
//  LoginViewController.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 12/27/16.
//  Copyright © 2016 TBoxSolutionz. All rights reserved.
//

import UIKit
import Alamofire
import SideMenuController
//import Google
//import GoogleSignIn
import FBSDKLoginKit
//import Crashlytics

class LoginViewController: UIViewController {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    var dictionary: [String: AnyObject]!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var versionLabel: UILabel!
    func testCrash(){
        let numbers = [0]
        let _ = numbers[1]
    }
    
    //MARK: IBAction Buttons
    @IBAction func login(_ sender: Any) {
//        self.testCrash()
        if username.text == "" || password.text == "" {
            Utility.showAlertWithSingleOption(controller: self, title: "", message: kUsername_or_Password_is_missing, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
        } else {
            activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
            WebManager.getInstance(delegate: self)?.makeLogin(username: username.text!,password: password.text!)
        }
    }
    
    @IBAction func fbSignIn(_ sender: Any) {
        let fbLoginManager: LoginManager = LoginManager()
        fbLoginManager.logIn(permissions: [kemail], from: self) { (result, error) in
            if error == nil {
                let fbLoginResult: LoginManagerLoginResult = result!
               // if fbLoginResult.grantedPermissions != nil {
                    if(fbLoginResult.grantedPermissions.contains(kemail)) {
                        self.getFBUserData()
                        //     fbLoginManager.logOut()
                    }
                //}
            }
        }
    }
    
    @IBAction func googleSignIn(_ sender: Any) {
//         GIDSignIn.sharedInstance().signIn()
    }
    
    //MARK: view's life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
//        if #available(iOS 13.0, *) {
//            overrideUserInterfaceStyle = .dark
//        } else {
//            // Fallback on earlier versions
//        }
        //        if #available(iOS 13.0, *) {
        //            overrideUserInterfaceStyle = .light
        //        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.gmailLogout), name: NSNotification.Name(kGmailLogout), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getGoogleLoginDetail), name: NSNotification.Name(kGoogleLogin), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.facebookLogout), name: NSNotification.Name(kFacebookLogout), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.logout), name: NSNotification.Name(kSessionExpired), object: nil)
        username.delegate = self
        password.delegate = self
        activityIndicator.hidesWhenStopped = true
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "Version \(version)"
        }
        self.hideKeyboardWhenTappedAround()
//        setGIDSignInDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let session = Session.getInstance()
        if (session?.user.isLogin)! {
            if (session?.user.isGmailLogin)! || (session?.user.isFacebookLogin)! {
                activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
            }
            perform(#selector(presentTabController), with: nil, afterDelay: 0.6)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kGmailLogout), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kGoogleLogin), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kFacebookLogout), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kSessionExpired), object: nil)
    }
    
    @objc func gmailLogout() {
//        GIDSignIn.sharedInstance().signOut()
        let session = Session.getInstance()
        if !((session?.user.isGmailLogin)!) {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc func logout() {
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc func facebookLogout() {
        let fbLoginManager: LoginManager = LoginManager()
        fbLoginManager.logOut()
        let session = Session.getInstance()
        if !((session?.user.isFacebookLogin)!) {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    //MARK: get google detail
    @objc func getGoogleLoginDetail(_ notification: NSNotification) {
        let token = notification.userInfo?[kaccess_token] as! String
        let email = notification.userInfo?[kemail] as! String
        UserDefaults.standard.setValue(token, forKey: kaccess_token)
        UserDefaults.standard.setValue(email, forKey: kemail)
        print(token)
        print(email)
        activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
        WebManager.getInstance(delegate: self)?.makeLoginWithGmail(accessToken: token, userName: "")
    }
    
    //MARK: load TabBar and side menu after login
    @objc func presentTabController() {
        let session = Session.getInstance()
        if (session?.user.isGmailLogin)! || (session?.user.isFacebookLogin)!{
            Utility.stopSpinner(activityIndicator: activityIndicator)
        }
        let sideMenuViewController = SideMenuController()
        sideMenuViewController.modalPresentationStyle = .fullScreen
        // create the view controllers for center containment
        let publicFolderViewController = FoldersViewController(nibName: kFoldersViewController, bundle: nil)
        let publicNavController = UINavigationController(rootViewController: publicFolderViewController)
        publicFolderViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: kpublic), tag: 1)
        publicFolderViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        publicFolderViewController.tabBarItem.title = kPublic
        let privateFolderViewController = FoldersViewController(nibName: kFoldersViewController, bundle: nil)
        let privateNavController = UINavigationController(rootViewController: privateFolderViewController)
        privateFolderViewController.tabBarItem = UITabBarItem(title: nil, image:UIImage(named: kprivate), tag:2)
        privateFolderViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        privateNavController.tabBarItem.title = kPrivate
        let uploadViewController = UploadViewController(nibName: kUploadViewController, bundle: nil)
        let uploadNavController = UINavigationController(rootViewController: uploadViewController)
        uploadViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: kuploadIcon), tag: 3)
        uploadViewController.tabBarItem.title = kUpload
        uploadViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        uploadViewController.uploadComplete = true
        let tabBarController = MainTabViewController()
        tabBarController.viewControllers = [publicNavController, privateNavController, uploadNavController]
        tabBarController.tabBar.tintColor = UIColor.black
        tabBarController.separate = setupTabBarSeparators(tabBarController: tabBarController)
        tabBarController.publicDelegate = publicFolderViewController
        tabBarController.privateDelegate = privateFolderViewController
        publicFolderViewController.foldersViewControllerDelegate = tabBarController
        privateFolderViewController.foldersViewControllerDelegate = tabBarController
        // create the side controller
        let sideController = MenuViewController(nibName: kMenuViewController, bundle: nil)
        // embed the side and center controllers
        sideMenuViewController.embed(sideViewController: sideController)
        sideMenuViewController.embed(centerViewController: tabBarController)
        // add the menu button to each view controller embedded in the tab bar controller
        [publicNavController, privateNavController, uploadNavController].forEach({controller in controller.addSideMenuButton()})
        show(sideMenuViewController, sender: nil)
        tabBarController.loadAccountTree()
    }
    
    func setupTabBarSeparators(tabBarController: MainTabViewController) -> UIView{
        let itemWidth = floor(tabBarController.tabBar.frame.size.width / CGFloat(tabBarController.tabBar.items!.count))
        let separatorWidth: CGFloat = 0.5
                var separator: UIView? = nil
        var secondSeparator: UIView? = nil
        if (tabBarController.tabBar.viewWithTag(10001) != nil) {
            separator = tabBarController.tabBar.viewWithTag(10001)!
            separator?.frame = CGRect(x: itemWidth * CGFloat(0 + 1) - CGFloat(separatorWidth / 2), y: 0, width: CGFloat(separatorWidth), height: tabBarController.tabBar.frame.size.height)
        }else {
            separator =  UIView(frame: CGRect(x: itemWidth * CGFloat(0 + 1) - CGFloat(separatorWidth / 2), y: 0, width: CGFloat(separatorWidth), height: tabBarController.tabBar.frame.size.height))
            separator?.tag = 10001
            separator?.backgroundColor = UIColor.lightGray
            tabBarController.tabBar.addSubview(separator!)
        }
        if (tabBarController.tabBar.viewWithTag(10002) != nil) {
            secondSeparator = tabBarController.tabBar.viewWithTag(10002)!
            secondSeparator?.frame = CGRect(x: itemWidth * CGFloat(0 + 2), y: 0, width: CGFloat(separatorWidth), height: tabBarController.tabBar.frame.size.height)
        }else {
            secondSeparator = UIView(frame: CGRect(x: itemWidth * CGFloat(0 + 2), y: 0, width: CGFloat(separatorWidth), height: tabBarController.tabBar.frame.size.height))
            secondSeparator?.tag = 10002
            secondSeparator?.backgroundColor = UIColor.lightGray
            tabBarController.tabBar.addSubview(secondSeparator!)
        }
        return separator!

    }
    
    //MARK: get fb data after login
    func getFBUserData() {
        if (AccessToken.current) != nil {
            GraphRequest(graphPath: kme, parameters: [kfields: "\(kid), \(kname), \(kfirst_name), \(klast_name), picture.type(large), \(kemail)"]).start(completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    self.dictionary = result as? [String: AnyObject]
                    print(result!)
                    print(self.dictionary as Any)
                    let email = self.dictionary[kemail]
                    let accessToken = AccessToken.current!.tokenString
                    UserDefaults.standard.setValue(accessToken, forKey: kaccess_token)
                    UserDefaults.standard.setValue(email, forKey: kemail)
                    WebManager.getInstance(delegate: self)?.makeLoginWithFacebook(accessToken: accessToken, userName: "")
                }
            })
        }
    }
    
    func setViewToItsPosition() {
        var frame = buttonContainerView.frame
        frame.origin.y = 191
        buttonContainerView.frame = frame
        networkLabel.isHidden = true
    }
}

//extension UIViewController: GIDSignInUIDelegate {
//    // Present a view that prompts the user to sign in with Google
//    public func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
//        self.present(viewController, animated: true, completion: nil)
//    }
//
//    // Dismiss the "Sign in with Google" view
//    public func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
//        self.dismiss(animated: true, completion: nil)
//    }
//
//    func setGIDSignInDelegate() {
//        GIDSignIn.sharedInstance().uiDelegate = self
//    }
//}

extension LoginViewController: UITextFieldDelegate {
    //MARK: textFieldDelegate functions
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if username.isFirstResponder {
            password.becomeFirstResponder()
        } else if password.isFirstResponder {
            password.resignFirstResponder()
        }
        return true
    }
}

extension LoginViewController: WebManagerDelegate {
    func successFbLoginResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        self.setViewToItsPosition()
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            print(JSON)
            let checkResult = JSON[kok] as! NSNumber
            let checkRequestUrl = (response.request?.description)! as String
            if checkRequestUrl.contains(knew_session) {
                if checkResult == 1 {
                    username.text = ""
                    password.text = ""
                    let data = JSON[kdata] as! NSDictionary
                    print(data[ksession_id] ?? String.self)
                    //user info is saved in our instance
                    let session = Session.getInstance()
                    session?.sessionId = data[ksession_id] as! String
                    session?.user.isLogin = true
                    session?.user.isFacebookLogin = false
                    session?.saveSession()
                    presentTabController()
                } else {
                    print(JSON)
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_username_or_password_is_not_correct_Try_again, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                }
            } else {
                if checkResult == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let accounts = JSON[kaccounts_found] as! Int
                    if accounts == 0 {
//                        GIDSignIn.sharedInstance().signOut()
                        Utility.showAlertWithSingleOption(controller: self, title: "", message: kNo_accounts_found_against_this_email, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                    } else if accounts == 1 {
                        let session = Session.getInstance()
                        session?.sessionId = data[ksession_id] as! String
                        let login = data[klogin] as! String
                        UserDefaults.standard.setValue(login, forKey: klogin)
                        session?.user.isFacebookLogin = true
                        session?.user.isGmailLogin = false
                        session?.user.isLogin = true
                        session?.saveSession()
                        presentTabController()
                    } else {
                        let logins = data[klogins] as! NSArray
                        let showUsersViewController = ShowUsersViewController(nibName: kShowUsersViewController, bundle: nil)
                        showUsersViewController.modalPresentationStyle = .fullScreen
                        showUsersViewController.logins = logins
                        showUsersViewController.isGmailAccount = false
                        self.present(showUsersViewController, animated: true, completion: nil)
                    }
                } else {
                    let fbLoginManager: LoginManager = LoginManager()
                    fbLoginManager.logOut()
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kNo_accounts_found_against_this_email, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                }
            }
        }

    }
    func successResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        self.setViewToItsPosition()
        if let result = response.result.value {
            let JSON = result as! NSDictionary
            print(JSON)
            let checkResult = JSON[kok] as! NSNumber
            let checkRequestUrl = (response.request?.description)! as String
            if checkRequestUrl.contains(knew_session) {
                if checkResult == 1 {
                    username.text = ""
                    password.text = ""
                    let data = JSON[kdata] as! NSDictionary
                    print(data[ksession_id] ?? String.self)
                    //user info is saved in our instance
                    let session = Session.getInstance()
                    session?.sessionId = data[ksession_id] as! String
                    session?.user.isLogin = true
                    session?.user.isGmailLogin = false
                    session?.saveSession()
                    presentTabController()
                } else {
                    print(JSON)
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_username_or_password_is_not_correct_Try_again, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                }
            } else {
                if checkResult == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let accounts = JSON[kaccounts_found] as! Int
                    if accounts == 0 {
//                        GIDSignIn.sharedInstance().signOut()
                        Utility.showAlertWithSingleOption(controller: self, title: "", message: kNo_accounts_found_against_this_email, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                    } else if accounts == 1 {
                        let session = Session.getInstance()
                        session?.sessionId = data[ksession_id] as! String
                        let login = data[klogin] as! String
                        UserDefaults.standard.setValue(login, forKey: klogin)
                        session?.user.isGmailLogin = true
                        session?.user.isFacebookLogin = false
                        session?.user.isLogin = true
                        session?.saveSession()
                        presentTabController()
                    } else {
                        let logins = data[klogins] as! NSArray
                        let showUsersViewController = ShowUsersViewController(nibName: kShowUsersViewController, bundle: nil)
                        showUsersViewController.modalPresentationStyle = .fullScreen
                        showUsersViewController.logins = logins
                        showUsersViewController.isGmailAccount = true
                        self.present(showUsersViewController, animated: true, completion: nil)
                    }
                } else {
//                    GIDSignIn.sharedInstance().signOut()
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kNo_accounts_found_against_this_email, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                }
            }
        }
    }
    
    func networkFailureAction() {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        var frame = buttonContainerView.frame
        frame.origin.y = frame.origin.y + 50
        buttonContainerView.frame = frame
        networkLabel.isHidden = false
    }
    
    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIImage
{
    class func imageWithColor(color: UIColor, size: CGSize) -> UIImage
    {
        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
