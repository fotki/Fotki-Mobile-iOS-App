//
//  FotkiSKPhoto.swift
//  com.tbox.fotki
//
//  Created by Dilawer Hussain on 2/15/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import Foundation
import SKPhotoBrowser

class FotkiSKPhoto: SKPhoto {
    open var videoUrl: String!
    open var isVideo: Bool = false
    open var isOriginal: Bool = false
    open var isDeleted: Bool = false
    open var imageSize: NSNumber!
    open var resizedImageSize: NSNumber!
    open var originalImageDimensions: CGSize!
    open var resizedImageDimensions: CGSize!
    open var originalPhotoUrl: String!
    open var resizedPhotoUrl: String!

    
    override init() {
        super.init()
    }
    
    func setIsVideo(isVideo: Bool) {
        self.isVideo = isVideo
    }
        
    func setIsOriginal(isOriginal: Bool) {
        self.isOriginal = isOriginal
    }
    
    func setOriginalPhotoUrl(originalPhotoUrl: String) {
        self.originalPhotoUrl = originalPhotoUrl
    }
    
    func setResizedPhotoUrl(resizedPhotoUrl: String) {
        self.resizedPhotoUrl = resizedPhotoUrl
    }
    
    func setIsDeleted(isDeleted: Bool) {
        self.isDeleted = isDeleted
    }
    
    func setPhotoUrl(photoUrl: String) {
        photoURL = photoUrl
    }

    func setImageSize(imageSize: NSNumber) {
        self.imageSize = imageSize
    }
    
    func setResizedImageSize(resizedImageSize: NSNumber) {
        self.resizedImageSize = resizedImageSize
    }
    
    func setOriginalImageDimensions(originalImageDimensions: CGSize) {
        self.originalImageDimensions = originalImageDimensions
    }
    
    func setResizedImageDimensions(resizedImageDimensions: CGSize) {
        self.resizedImageDimensions = resizedImageDimensions
    }
}
