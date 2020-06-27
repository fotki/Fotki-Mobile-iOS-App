//
//  ActionsViewController.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/13/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit
import Alamofire

protocol ActionViewControllerDelegate {
    func recallApi()
}

class ActionsViewController: UIViewController {
    var actionDelegate: ActionViewControllerDelegate? = nil
    @IBOutlet var textArea: UITextView!
    @IBOutlet weak var retryView: UIView!
    @IBOutlet var desc: UILabel!
    var getAction = String()
//    var folderIdEnc = NSNumber()
//    var folderName = String()
//    var folderDescription = String()
    var album = Album()
    var folder = Folder()
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadNavBarItems()
        self.placeActionImage()
        activityIndicator.hidesWhenStopped = true
        self.hideKeyboardWhenTappedAround()
        self.setupLayout()
    }
    
    func setupLayout(){
        nameTextField.delegate = self
        nameTextField.becomeFirstResponder()
        nameTextField.layer.borderWidth = 1.0
        nameTextField.layer.borderColor = UIColor.gray.cgColor
        nameTextField.layer.cornerRadius = 5
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 2))
        nameTextField.leftView = paddingView;
        nameTextField.leftViewMode = UITextField.ViewMode.always
        textArea.layer.borderWidth = 1.0
        textArea.layer.borderColor = UIColor.gray.cgColor
        textArea.layer.cornerRadius = 5
        textArea.textContainerInset = UIEdgeInsets(top: 4, left: 2, bottom: 2, right: 2)
    }
    
    //MARK: load NavBar Items
    func loadNavBarItems() {
        let logo = UIImage(named: klogoImage)
        let logoImageView = UIImageView(image: logo)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        logoImageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.navigationItem.titleView = logoImageView
        if getAction == kCreate_Folder || getAction == kCreate_Album {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: kCreate, style: .plain, target: self, action: #selector(actionTapped))
        } else {
             navigationItem.rightBarButtonItem = UIBarButtonItem(title: kSave, style: .plain, target: self, action: #selector(actionTapped))
        }
        let backButton = UIBarButtonItem(title: kCancel, style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    
    //MARK: place action image and api calling according to action
    func placeActionImage() {
        switch getAction {
            case kCreate_Folder:
                nameLabel.text = kFolder_Name
                textArea.alpha = 0
                desc.alpha = 0
                break
            case kCreate_Album:
                nameLabel.text = kAlbum_Name
                textArea.alpha = 0
                desc.alpha = 0
                break
            case kUpdate_Folder:
                nameLabel.text = kFolder_Name
                textArea.text = folder.description
                nameTextField.text = folder.folderName
                break
            case kAlbum_Properties:
                nameLabel.text = kAlbum_Name
                textArea.text = album.description
                nameTextField.text = album.name
                break
            default: break
        }
    }
    
    @objc func actionTapped() {
        switch getAction {
            case kCreate_Folder:
                if nameTextField.text == "" {
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_folder_name_is_missing, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                } else {
                    activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
                    WebManager.getInstance(delegate: self)?.createFolder(folderId: folder.folderIdEnc, foldername: nameTextField.text!)
                }
                break
            case kCreate_Album:
                if nameTextField.text == "" {
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_album_name_is_missing, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
                }else {
                    activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
                    WebManager.getInstance(delegate: self)?.createAlbum(folderId: folder.folderIdEnc, albumname: nameTextField.text!)
                }
                break
            case kUpdate_Folder:
                if nameTextField.text == "" {
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_folder_name_is_missing, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
               
                } else {
                    activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
                    WebManager.getInstance(delegate: self)?.updateFolder(folderId: folder.folderIdEnc, foldername: nameTextField.text!, desc: textArea.text)
                }
                break
            case kAlbum_Properties:
                if nameTextField.text == "" {
                    Utility.showAlertWithSingleOption(controller: self, title: "", message: kThe_album_name_is_missing, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
               
                } else {
                    activityIndicator = Utility.startSpinner(view: self.view, activityIndicator: self.activityIndicator)
                    WebManager.getInstance(delegate: self)?.updateAlbum(albumId: album.albumIdEnc, albumname: nameTextField.text!, desc: textArea.text)
                }
                break
            default: break
        }
    }
    
    @IBAction func retryNetworkCall(_ sender: Any) {
        self.retryView.isHidden = true
        self.actionTapped()
    }
    //MARK: cancel/back Button
    @objc func cancelButtonTapped() {
        _ = navigationController?.popViewController(animated: true)
    }
}

extension ActionsViewController: UITextFieldDelegate {
    //MARK: textFieldDelegate functions
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}

extension ActionsViewController: WebManagerDelegate {
    //MARK: webManagerDelegate functions
    func successFbLoginResponse(response: DataResponse<Any>){
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if response.result.value != nil {
            print(response.result.value!)
            if getAction == kAlbum_Properties {
                album.name = nameTextField.text!
                album.description = textArea.text
            }
            _ = navigationController?.popViewController(animated: true)
            actionDelegate?.recallApi()
            NotificationCenter.default.post(name: NSNotification.Name(kReloadData), object: nil, userInfo: nil)
        }
    }

    func successResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        if response.result.value != nil {
            print(response.result.value!)
            if getAction == kAlbum_Properties {
                album.name = nameTextField.text!
                album.description = textArea.text
            } else if getAction == kUpdate_Folder {
                folder.folderName = nameTextField.text!
                folder.description = textArea.text
            }
            _ = navigationController?.popViewController(animated: true)
            actionDelegate?.recallApi()
            NotificationCenter.default.post(name: NSNotification.Name(kReloadData), object: nil, userInfo: nil)
        }
    }
    
    func networkFailureAction() {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        retryView.isHidden = false
    }
    
    func failureResponse(response: DataResponse<Any>) {
        Utility.stopSpinner(activityIndicator: activityIndicator)
        Utility.showAlertWithSingleOption(controller: self, title: "", message: kCannot_connect_right_now_Please_check_internet_connection, preferredStyle: .alert, buttonText: kOK, buttonHandler: nil)
    }
}
