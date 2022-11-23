//
//  WebManager.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 12/28/16.
//  Copyright © 2016 TBoxSolutionz. All rights reserved.
//

import Foundation
import Alamofire
import AVFoundation

protocol WebManagerDelegate {
    func successResponse(response: DataResponse<Any>)
    func successFbLoginResponse(response: DataResponse<Any>)
    func failureResponse(response: DataResponse<Any>)
    func networkFailureAction()
}

enum ApiRequestType {
    case isAccountInfoRequest, isAccountTreeRequest, isAlbumContentRequest, isAlbumContentPageRequest, isAlbumItemsCountRequest, isCreateAlbumRequest, isCreateFolderRequest, isUpdateFolderRequest, isUpdateAlbumRequest, isFolderContentRequest, isFbLoginRequest, isUploadItemRequest
}

class WebManager: NSObject {
    let delegate: WebManagerDelegate
    var apiRequestType = ApiRequestType.isAccountInfoRequest
    var sessionCount = 0
    var isLoginForNewSession = false
    var isReLoginForNewSession = false
    // variables added for making again requests if session expired
    var albumId = NSNumber()
    var albumName = ""
    var albumDescription = ""
    var page = 0
    var folderId = NSNumber()
    var folderName = ""
    var folderDescription = ""
    var uploadController = UploadViewController()
    var imageData = Data()
    var isVideo = false
    var image = UIImage()
    var isGif = false
    var startUploadingLabel = UILabel()
    
    // MARK: init methods
    init(d: WebManagerDelegate) {
        self.delegate = d
    }
    
    class func getInstance(delegate: WebManagerDelegate) -> WebManager? {
        return WebManager(d: delegate)
    }
    
    //MARK: user login/register/profile info methods
    func makeLogin(username: String, password: String) {
        isLoginForNewSession = true
        let url = "\(kbaseURL)\(knew_session)\(klogin)=\(username)&\(kpassword)=\(password)"
        makeRequest(requestUrl: url)
    }
    
    func makeLoginWithFacebook(accessToken: String, userName: String) {
        var url = ""
        isLoginForNewSession = true
        if userName == "" {
            url = "\(kbaseURL)\(kfacebook_new_session)\(kos)=ios&\(kaccess_token)=\(accessToken)"
        } else {
            url = "\(kbaseURL)\(kfacebook_new_session)\(kos)=ios&\(kaccess_token)=\(accessToken)&\(klogin)=\(userName)"
        }
        print(url)
        apiRequestType = .isFbLoginRequest
        makeRequest(requestUrl: url)
    }

    func makeLoginWithGmail(accessToken: String, userName: String) {
        var url = ""
        isLoginForNewSession = true
        if userName == "" {
            url = "\(kbaseURL)\(kgoogle_new_session)\(kos)=ios&\(kaccess_token)=\(accessToken)"
        } else {
            url = "\(kbaseURL)\(kgoogle_new_session)\(kos)=ios&\(kaccess_token)=\(accessToken)&\(klogin)=\(userName)"
        }
        print(url)
        makeRequest(requestUrl: url)
    }
    
    //MARK: get account tree/info
    func getAccountInfo() {
        apiRequestType = .isAccountInfoRequest
        let session = Session.getInstance()
        let url = "\(kbaseURL)\(kget_account_info)\(ksession_id)=\((session?.sessionId)!)"
        makeRequest(requestUrl: url)
    }
    
    func getAccountTree() {
        apiRequestType = .isAccountTreeRequest
        let session = Session.getInstance()
        let url = "\(kbaseURL)\(kget_account_tree)\(ksession_id)=\((session?.sessionId)!)"
        makeRequest(requestUrl: url)
    }
    
    //MARK: get data of album
    func getAlbumContent(albumId: NSNumber) {
        self.albumId = albumId
        apiRequestType = .isAlbumContentRequest
        let session = Session.getInstance()
        let album_id = String(describing: albumId as NSNumber)
        print("String = \(album_id)")
        let url = "\(kbaseURL)\(kget_album_content)\(ksession_id)=\((session?.sessionId)!)&\(kalbum_id_enc)=\(album_id)"
        makeRequest(requestUrl: url)
    }
    
    func getAlbumContentWithPage(albumId: NSNumber, page: Int) {
        self.albumId = albumId
        self.page = page
        apiRequestType = .isAlbumContentPageRequest
        let session = Session.getInstance()
        let album_id = String(describing: albumId as NSNumber)
        print("String = \(album_id)")
        print("page number is: \(page)")
        let url = "\(kbaseURL)\(kget_album_content)\(ksession_id)=\((session?.sessionId)!)&\(kalbum_id_enc)=\(album_id)&\(kcurrent_page)=\(page)"
        makeRequest(requestUrl: url)
    }
    
    func getAlbumItemsCount(albumId: NSNumber) {
        self.albumId = albumId
        apiRequestType = .isAlbumItemsCountRequest
        let session = Session.getInstance()
        let url = "\(kbaseURL)\(kget_album_items_count)\(ksession_id)=\((session?.sessionId)!)&\(kalbum_id_enc)=\(albumId)"
        print(url)
        makeRequest(requestUrl: url)
    }
    
    //MARK: update/create album/folder
    func createAlbum(folderId: NSNumber, albumname: String) {
        self.folderId = folderId
        self.albumName = albumname
        apiRequestType = .isCreateAlbumRequest
        let session = Session.getInstance()
        let albumName = (albumname.addingPercentEncodingForURLQueryValue())!
        let url = "\(kbaseURL)\(kcreate_album)\(ksession_id)=\((session?.sessionId)!)&\(kfolder_id_enc)=\(folderId)&\(kname)=\(albumName)"
        makeRequest(requestUrl: url)
    }
    
    func createFolder(folderId: NSNumber, foldername: String) {
        self.folderId = folderId
        self.folderName = foldername
        apiRequestType = .isCreateFolderRequest
        let session = Session.getInstance()
        let folderName = (foldername.addingPercentEncodingForURLQueryValue())!
        let url = "\(kbaseURL)\(kcreate_folder)\(ksession_id)=\((session?.sessionId)!)&\(kfolder_id_enc)=\(folderId)&\(kfolder_name)=\(folderName)"
        makeRequest(requestUrl: url)
    }
    
    func updateFolder(folderId: NSNumber, foldername: String , desc: String) {
        self.folderId = folderId
        self.folderName = foldername
        self.folderDescription = desc
        apiRequestType = .isUpdateFolderRequest
        let session = Session.getInstance()
        let folderName = (foldername.addingPercentEncodingForURLQueryValue())!
        let folderDesc = (desc.addingPercentEncodingForURLQueryValue())!
        let url = "\(kbaseURL)\(kupdate_folder)\(ksession_id)=\((session?.sessionId)!)&\(kfolder_id_enc)=\(folderId)&\(kname)=\(folderName)&\(kdescr)=\(folderDesc)"
        print(url)
        makeRequest(requestUrl: url)
    }
    
    func updateAlbum(albumId: NSNumber, albumname: String, desc: String) {
        self.albumId = albumId
        self.albumName = albumname
        self.albumDescription = desc
        apiRequestType = .isUpdateAlbumRequest
        let session = Session.getInstance()
        let albumName = (albumname.addingPercentEncodingForURLQueryValue())!
        let albumDesc = (desc.addingPercentEncodingForURLQueryValue())!
        let url = "\(kbaseURL)\(kupdate_album)\(ksession_id)=\((session?.sessionId)!)&\(kalbum_id_enc)=\(albumId)&\(kname)=\(albumName)&\(kdescription)=\(albumDesc)"
        makeRequest(requestUrl: url)
    }
    
    func getFolderContent(folderId: NSNumber) {
        self.folderId = folderId
        apiRequestType = .isFolderContentRequest
        let session = Session.getInstance()
        let folder_id = String(describing: folderId as NSNumber)
        print("String = \(folder_id)")
        let url = "\(kbaseURL)\(kget_folder_content)\(ksession_id)=\((session?.sessionId)!)&\(kfolder_id_enc)=\(folder_id)"
        makeRequest(requestUrl: url)
    }
    
    //MARK: helper method
    func makeRequest(requestUrl: String) {
        if Utility.isInternetConnected() {
            Alamofire.request(requestUrl).responseJSON { (response: DataResponse<Any>) in
                switch(response.result) {
                case .success(_):
                    // if session is expired, we need to relogin and get the account info
    //                if self.isGetAccountTreeRequest || self.isAccountInfoRequest {
                        if self.isLoginForNewSession {
                            self.isLoginForNewSession = false
                            // store login session
                            let result = response.result.value
                            let JSON = result as! NSDictionary
                            let checkResult = JSON[kok] as! NSNumber
                            if checkResult == 1 {
                                let data = JSON[kdata]  as! NSDictionary
                                if let logins = data[klogins] {
                                    print(logins)
                                    if self.apiRequestType == .isFbLoginRequest {
                                        self.delegate.successFbLoginResponse(response: response)
                                    } else {
                                        self.delegate.successResponse(response: response)
                                    }
                                    break
                                }
                                if data[ksession_id] != nil {
                                    //user info is saved in our instance
                                    let session = Session.getInstance()
                                    session?.sessionId = data[ksession_id] as! String
                                    session?.user.isLogin = true
                                    session?.saveSession()
                                    if self.isReLoginForNewSession {
                                        self.isReLoginForNewSession = false
                                        switch self.apiRequestType {
                                        case .isAccountInfoRequest:
                                            self.getAccountInfo()
                                            break
                                        case .isAccountTreeRequest:
                                            self.getAccountTree()
                                            break
                                        case .isAlbumContentRequest:
                                            self.getAlbumContent(albumId: self.albumId)
                                            break
                                        case .isAlbumContentPageRequest:
                                            self.getAlbumContentWithPage(albumId: self.albumId, page: self.page)
                                            break
                                        case .isAlbumItemsCountRequest:
                                            self.getAlbumItemsCount(albumId: self.albumId)
                                            break
                                        case .isCreateAlbumRequest:
                                            self.createAlbum(folderId: self.folderId, albumname: self.albumName)
                                            break
                                        case .isCreateFolderRequest:
                                            self.createFolder(folderId: self.folderId, foldername: self.folderName)
                                            break
                                        case .isUpdateFolderRequest:
                                            self.updateFolder(folderId: self.folderId, foldername: self.folderName, desc: self.folderDescription)
                                            break
                                        case .isUpdateAlbumRequest:
                                            self.updateAlbum(albumId: self.albumId, albumname: self.albumName, desc: self.albumDescription)
                                            break
                                        case .isFolderContentRequest:
                                            self.getFolderContent(folderId: self.folderId)
                                            break
                                        case .isUploadItemRequest:
                                            DispatchQueue.main.async {
                                            self.uploadItemWithAlamofire(controller: self.uploadController, data: self.imageData, isVideo: self.isVideo, image: self.image, isGif: self.isGif, startUpload: self.startUploadingLabel)
                                            }
                                            break
                                        default:
                                            break
                                        }
                                    } else {
                                        UserDefaults.standard.removeObject(forKey: kemail)
                                        UserDefaults.standard.removeObject(forKey: kaccess_token)
                                        UserDefaults.standard.synchronize()
                                        if self.apiRequestType == .isFbLoginRequest {
                                            self.delegate.successFbLoginResponse(response: response)
                                        } else {
                                            self.delegate.successResponse(response: response)
                                        }
                                    }
                                } else {
                                    print ("suspended")
                                    self.delegate.failureResponse(response: response)
                                }
                            } else {

                                if self.apiRequestType == .isFbLoginRequest {
                                    self.delegate.successFbLoginResponse(response: response)
                                } else {
                                    self.delegate.successResponse(response: response)
                                }
                            }
                        } else {
                            if let result = response.result.value {
                                print(result)
                                let JSON = result as! NSDictionary
                                let ok = JSON[kok] as! NSNumber
                                if ok == 1 {
                                    self.delegate.successResponse(response: response)
                                } else {
                                    let message = JSON[kmessage] as! String
                                    if message == kWrong_session_id {
                                        let session = Session.getInstance()
                                        if (session?.user.isGmailLogin)! {
                                            session?.user.isGmailLogin = false
                                            session?.sessionId = ""
                                            session?.user.isLogin = false
                                            session?.saveSession()
                                            NotificationCenter.default.post(name: NSNotification.Name(kGmailLogout), object: nil, userInfo: nil)
                                        } else if (session?.user.isFacebookLogin)! {
                                            session?.user.isFacebookLogin = false
                                            session?.sessionId = ""
                                            session?.user.isLogin = false
                                            session?.saveSession()
                                            NotificationCenter.default.post(name: NSNotification.Name(kFacebookLogout), object: nil, userInfo: nil)
                                        } else {
                                            self.isReLoginForNewSession = false
                                            self.isLoginForNewSession = false
                                            let session = Session.getInstance()
                                            session?.sessionId = ""
                                            session?.user.isLogin = false
                                            session?.saveSession()
                                             NotificationCenter.default.post(name: NSNotification.Name(kSessionExpired), object: nil, userInfo: nil)
                                        }
                                    }
                                   }
                            }
                        }
                    break
                case .failure(_):
                    self.isLoginForNewSession = false
                    self.delegate.failureResponse(response: response)
                    break
                }
            }
        } else {
            self.delegate.networkFailureAction()
        }
    }
    
    //MARK: Download images
    class func loadImage(imageUrl: String, imageView: UIImageView) {
        Alamofire.request(imageUrl).responseImage { response in
            if let image = response.result.value {
                imageView.image = image
            }
        }
    }
    
    //MARK: Items(image/video) uploaded method
    func uploadItemWithAlamofire(controller: UploadViewController, data: Data, isVideo: Bool, image: UIImage , isGif: Bool, startUpload: UILabel) {
        if Utility.isInternetConnected() {
            self.uploadController = controller
            self.imageData = data
            self.isVideo = isVideo
            self.isGif = isGif
            self.image = image
            DispatchQueue.main.async {
            self.startUploadingLabel = startUpload
            }
            apiRequestType = .isUploadItemRequest
            controller.singleFileProgressLabel.text = kZeroPercent
            controller.singleFileProgressView.progress = 0
            controller.imageView.image = image
            let session = Session.getInstance()
            let numberFormatter = NumberFormatter()
            let sessionId = (session?.sessionId)!.data(using: String.Encoding.utf8)
            let sendAlbumId = numberFormatter.string(from: controller.albumId)?.data(using: String.Encoding.utf8)
            let URL = try! URLRequest(url: "\(kbaseURL)\(kupload)", method: .post)
            startUpload.text = kUploading
            Alamofire.upload(multipartFormData: { multipartFormData in
                if isVideo {
                    multipartFormData.append(data, withName: kphoto, fileName: ("\(self.currentTimeInMilliSeconds())"), mimeType: kVideoMp4)
                } else if isGif {
                    multipartFormData.append(data, withName: kphoto, fileName: ("\(self.currentTimeInMilliSeconds())"), mimeType: kgif)
                } else {
                    multipartFormData.append(data, withName: kphoto, fileName: ("\(self.currentTimeInMilliSeconds())"), mimeType: kimagePng)
                }
                multipartFormData.append(sessionId!, withName: ksession_id as String)
                multipartFormData.append(sendAlbumId!, withName: kalbum_id_enc as String)
            }, with: URL, encodingCompletion: { result in
                switch result {
                    case .success(let upload, _, _):
                        upload.uploadProgress(closure: { Progress in
                            controller.singleFileProgressView.progress = Float(Progress.fractionCompleted)
                            print("\(kUploadProgress): \(Progress.fractionCompleted * 100)")
                            let converted = String(format: "%.0f%%", (Float(Progress.fractionCompleted) * 100))
                            controller.singleFileProgressLabel.text = converted
                        })
                        upload.responseJSON { response in
                            self.delegate.successResponse(response: response)
                        }
                    case .failure(let response):
                        print(response)
                        self.delegate.failureResponse(response: response as! DataResponse<Any>)
                }
            })
        } else {
            self.delegate.networkFailureAction()
        }
    }
    
    func currentTimeInMilliSeconds() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}

extension String {
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}
