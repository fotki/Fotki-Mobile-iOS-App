//
//  Album.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/10/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import Foundation

class Album {
    var albumIdEnc: NSNumber
    var description: String
    var name: String
    var coverUrl: String
    var items: [Item] = []
    var noOfVideos: Int
    var noOfPhotos: Int
    var url: String
    
    //Default Constructor
    init() {
        albumIdEnc = 0
        name = ""
        description = ""
        coverUrl = ""
        noOfPhotos = 0
        noOfVideos = 0
        url = ""
    }
    
    func setData(albumIdEnc: NSNumber, albumName: String, description: String, coverUrl: String, videoCount: Int, photoCount: Int, url: String) {
        self.albumIdEnc = albumIdEnc
        self.description = description
        self.name = albumName
        self.coverUrl = coverUrl
        self.noOfVideos = videoCount
        self.noOfPhotos = photoCount
        self.url = url
    }
}
