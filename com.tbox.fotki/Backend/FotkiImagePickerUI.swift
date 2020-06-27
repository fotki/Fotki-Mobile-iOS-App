//
//  FotkiImagePickerUI.swift
//  com.tbox.fotki
//
//  Created by Apple on 3/6/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import Foundation
import DKImagePickerController

public class FotkiImagePickerUI : DKImagePickerControllerBaseUIDelegate {
    override public func createDoneButtonIfNeeded() -> UIButton {
        let button = super.createDoneButtonIfNeeded()
        return button
    }
    
    override public func updateDoneButtonTitle(_ button: UIButton) {
        if self.imagePickerController.selectedAssets.count > 0 {
            button.setTitle("Upload(\(self.imagePickerController.selectedAssets.count))", for: .normal)
        } else {
            print("hhhh")
            button.setTitle(DKImagePickerControllerResource.localizedStringWithKey("picker.select.done.title"), for: .normal)

//            button.setTitle("done", for: .normal)
        }
        button.sizeToFit()
    }
}
