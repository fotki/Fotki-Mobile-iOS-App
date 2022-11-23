//
//  Item.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/18/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import Foundation

class Item: NSObject {
    var albumIdEnc: NSNumber
    var thumbnailUrl: String
    var created: String
    var viewUrl: String
    var originalUrl: String
    var title: String
    var isVideo: Bool
    var isOriginal: Bool
    var isDeleted: Bool
    var id: NSNumber
    var imageHeight: Int
    var imageWidth: Int
    var imageSize: NSNumber
    var resizedImageHeight: Int
    var resizedImageWidth: Int
    var resizedImageSize: NSNumber

    //MARK: Default Constructor
    override init() {
        albumIdEnc = 0
        id = 0
        title = ""
        originalUrl = ""
        thumbnailUrl = ""
        viewUrl = ""
        created = ""
        isOriginal = false
        isDeleted = false
        isVideo = false
        self.imageHeight = 0
        self.imageWidth = 0
        self.imageSize = 0
        self.resizedImageHeight = 0
        self.resizedImageWidth = 0
        self.resizedImageSize = 0
    }
}
