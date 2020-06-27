//
//  Utility.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 1/11/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import Alamofire

class Utility: NSObject{
    
    class func startSpinner(view: UIView, activityIndicator: UIActivityIndicatorView) -> UIActivityIndicatorView {
//        let transform: CGAffineTransform = CGAffineTransform(scaleX: 3, y: 3)
//        activityIndicator.transform = transform
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.color = UIColor.darkGray
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        return activityIndicator
    }
    
    class func isInternetConnected() -> Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    class func startSpinner(view: UIView) -> UIActivityIndicatorView {
        var activityIndicator = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        activityIndicator.color = UIColor.darkGray
//        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//        let transform: CGAffineTransform = CGAffineTransform(scaleX: 3, y: 3)
  //      activityIndicator.transform = transform
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        return activityIndicator
    }
        
    class func stopSpinner(activityIndicator: UIActivityIndicatorView) {
        activityIndicator.stopAnimating()
    }
    
    class func showAlertWithOptions(controller: UIViewController, title: String, message: String, preferredStyle: UIAlertController.Style, rightBtnText: String, leftBtnText: String, leftBtnhandler: ((UIAlertAction) -> Swift.Void)? = nil, rightBtnhandler: ((UIAlertAction) -> Swift.Void)? = nil) {
        // create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        // add an action (button)
        alert.addAction(UIAlertAction(title: leftBtnText, style: UIAlertAction.Style.default, handler: leftBtnhandler))
        alert.addAction(UIAlertAction(title: rightBtnText, style: UIAlertAction.Style.default, handler: rightBtnhandler))
        // show the alert
        controller.present(alert, animated: true, completion: nil)
    }
    
    class func showAlertWithSingleOption(controller: UIViewController, title: String, message: String, preferredStyle: UIAlertController.Style, buttonText: String, buttonHandler: ((UIAlertAction) -> Swift.Void)? = nil) {
        // create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        // add an action (button)
        alert.addAction(UIAlertAction(title: buttonText, style: UIAlertAction.Style.default, handler: buttonHandler))
        // show the alert
        controller.present(alert, animated: true, completion: nil)
    }
    
    class func stringNullCheck(stringToCheck: AnyObject) -> String {
        if stringToCheck is NSNull {
            return ""
        } else {
            return stringToCheck as! String
        }
    }
    
    //Mark: Attribueted alert text
    class func getAttributedAlertText(regularText: String) -> NSAttributedString {
        let greyText  = " (photos only)."
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.lightGray] as [NSAttributedString.Key : Any]
        let attributedString = NSMutableAttributedString(string:greyText, attributes: attrs )
        let regularString = NSMutableAttributedString(string:regularText)
        regularString.append(attributedString)
        return regularString
    }
    
    //Mark: image resizing method
    class  func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
