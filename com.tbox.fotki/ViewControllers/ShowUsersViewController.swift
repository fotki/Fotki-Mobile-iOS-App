//
//  ShowUsersViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 3/22/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import UIKit
import Alamofire

class ShowUsersViewController: UIViewController {
    @IBOutlet weak var chooseAccountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var retryView: UIView!
    var logins = NSArray()
    var login = ""
    var imagesCache: [String:UIImage] = [:]
    var isGmailAccount: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        print(logins)
        let boldEmailText = UserDefaults.standard.object(forKey: kemail)! as? String
        let normalText = "We see you have multiple Fotki accounts registered with "
        chooseAccountLabel.adjustsFontSizeToFitWidth = true
        chooseAccountLabel.attributedText = self.getAttributedString(normalString: normalText, boldString: boldEmailText!)
        self.tableView.register(UINib(nibName: kUserTableViewCell, bundle: Bundle.main), forCellReuseIdentifier: kuserCell)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    
    @IBAction func cancelView(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: kemail)
        UserDefaults.standard.removeObject(forKey: kaccess_token)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(kGmailLogout), object: nil, userInfo: nil)
        NotificationCenter.default.post(name: NSNotification.Name(kFacebookLogout), object: nil, userInfo: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        retryView.isHidden = true
        let token = UserDefaults.standard.object(forKey: kaccess_token)! as? String
        if isGmailAccount {
            WebManager.getInstance(delegate: self)?.makeLoginWithGmail(accessToken: token!, userName: login)
        } else {
            WebManager.getInstance(delegate: self)?.makeLoginWithFacebook(accessToken: token!, userName: login)
        }
    }
    
    //Mark: get Attributed String
    func getAttributedString(normalString: String, boldString: String) -> NSAttributedString {
        let attrs = [NSAttributedString.Key.font.rawValue : UIFont.boldSystemFont(ofSize: 13),NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as! [String : Any]
        let attributedString = NSMutableAttributedString(string: boldString, attributes: attrs as? [NSAttributedString.Key : Any])
        let normalString = NSMutableAttributedString(string: normalString)
        let regularText = "."
        let regularString = NSMutableAttributedString(string:regularText)
        normalString.append(attributedString)
        normalString.append(regularString)
        return normalString 
    }

}

extension ShowUsersViewController: UITableViewDelegate, UITableViewDataSource {
    //MARK: UITableviewDelegate functions
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logins.count
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let token = UserDefaults.standard.object(forKey: kaccess_token)! as? String
        login = (((logins[indexPath.row]) as AnyObject).value(forKeyPath: klogin) as? String)!
        if isGmailAccount {
            WebManager.getInstance(delegate: self)?.makeLoginWithGmail(accessToken: token!, userName: login)
        } else {
            WebManager.getInstance(delegate: self)?.makeLoginWithFacebook(accessToken: token!, userName: login)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // let email = UserDefaults.standard.object(forKey: kemail)! as? String
        let imageUrl = ((logins[indexPath.row]) as AnyObject).value(forKeyPath: kavatar_url) as? String
        let memebershipDate = (((logins[indexPath.row]) as AnyObject).value(forKeyPath: kmember_since) as AnyObject).value(forKeyPath: kdate) as! String
        let space_used = ((logins[indexPath.row]) as AnyObject).value(forKeyPath: kspace_used) as? String
        let space: Int64? = Int64(space_used!)
        let cell = tableView.dequeueReusableCell(withIdentifier: kuserCell,for: indexPath) as! UserTableViewCell
        cell.contentView.tag = indexPath.row
        print(imageUrl!)
        if (imagesCache[imageUrl!] != nil) {
            cell.userImage.image = imagesCache[imageUrl!]
            cell.name.text = ((logins[indexPath.row]) as AnyObject).value(forKeyPath: klogin) as? String
            cell.creationDate.text = "since: \(memebershipDate)"
            cell.space.text = "space: \(ByteCountFormatter.string(fromByteCount: space!, countStyle: ByteCountFormatter.CountStyle.file))"
        } else {
            cell.name.text = ((logins[indexPath.row]) as AnyObject).value(forKeyPath: klogin) as? String
            cell.creationDate.text = "since: \(memebershipDate)"
            cell.space.text = "space: \(ByteCountFormatter.string(fromByteCount: space!, countStyle: ByteCountFormatter.CountStyle.file))"
            if imageUrl != "" {
                let fotkiImageRequest = FotkiImageDataRequest()
                fotkiImageRequest.imageDownloader(url: imageUrl!, index: indexPath.row) { (response,index) in
                    if cell.contentView.tag == index {
                        if let image = response.result.value {
                            self.imagesCache[imageUrl!] = image
                            cell.userImage.image = image
                        }
                    }
                }
            }
        }
        return cell
    }
}

extension ShowUsersViewController: WebManagerDelegate {
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>) {
        if response.result.value != nil{
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let login = data[klogin] as! String
                    let session = Session.getInstance()
                    session?.user.isFacebookLogin = true
                    session?.user.isGmailLogin = false
                    session?.saveSession()
                    UserDefaults.standard.setValue(login, forKey: klogin)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func successResponse(response: DataResponse<Any>) {
        if response.result.value != nil{
            if let result = response.result.value {
                let JSON = result as! NSDictionary
                print(JSON)
                let ok = JSON[kok] as! NSNumber
                if ok == 1 {
                    let data = JSON[kdata] as! NSDictionary
                    let login = data[klogin] as! String
                    let session = Session.getInstance()
                    session?.user.isGmailLogin = true
                    session?.user.isFacebookLogin = false
                    session?.saveSession()
                    UserDefaults.standard.setValue(login, forKey: klogin)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func networkFailureAction() {
        retryView.isHidden = false
    }
    
    func failureResponse(response: DataResponse<Any>) {
        let result = response.result.value
        let JSON = result as! NSDictionary
        let checkResult = JSON[kok] as! NSNumber
        if checkResult == 1 {
            _ = JSON[kdata]  as! NSDictionary
            Utility.showAlertWithSingleOption(controller: self, title: "", message:kYour_account_has_been_temporary_suspended_due_to_membership_expiration, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
        }
    }
}
