//
//  AppDelegate.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 12/27/16.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import SideMenuController
import Fabric
import Crashlytics
import Google
import Alamofire
import GoogleSignIn
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var viewController: LoginViewController?
    var isAlbum = Bool()
       
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions:launchOptions)
        gmailDelegateSetting()
        // Override point for customization after application launch.
        makeSideMenuSettings()
        //calling login view controller
        self.window = UIWindow(frame: UIScreen.main.bounds)
        viewController = LoginViewController(nibName: kLoginViewController, bundle: nil) as LoginViewController
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
        Fabric.with([Crashlytics.self])
        return true
    }
    
    //MARK: Helper for gmail delegate init
    func gmailDelegateSetting() {
        // Initialize sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
        GIDSignIn.sharedInstance().delegate = self
    }
    
    //MARK: setup the side Menu
    func makeSideMenuSettings() {
        //Setting the size of sidebar menu
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        SideMenuController.preferences.drawing.menuButtonImage = UIImage(named: kmenuImage)
        SideMenuController.preferences.drawing.sidePanelPosition = .overCenterPanelLeft
        SideMenuController.preferences.drawing.sidePanelWidth = screenWidth * 0.3
        SideMenuController.preferences.drawing.centerPanelShadow = true
        SideMenuController.preferences.animating.statusBarBehaviour = .horizontalPan
        SideMenuController.preferences.animating.transitionAnimator = FadeAnimator.self
    }
    
    //MARK: Application Delegate functions
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.activateApp()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        if #available(iOS 9.0, *) {
            if GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,                                                         annotation: options[UIApplication.OpenURLOptionsKey.annotation]) {
                return true
            } else {
                return ApplicationDelegate.shared.application(app, open: url,sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
            }
        } else {
            // Fallback on earlier versions
        }
        return true
    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
        } else {
            // Perform any operations on signed in user here.
            let userId = user.userID
            let idToken = user.authentication.idToken
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            let accessToken = user.authentication.accessToken
            print(userId!)
            print(idToken!)
            print(fullName!)
            print(givenName!)
            print(familyName!)
            print(email!)
            let progressDictionary:[String: String] = [kemail: email!, kaccess_token: accessToken!]
            // post a notification
            NotificationCenter.default.post(name: NSNotification.Name(kGoogleLogin), object: nil, userInfo: progressDictionary)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        
    }
}
