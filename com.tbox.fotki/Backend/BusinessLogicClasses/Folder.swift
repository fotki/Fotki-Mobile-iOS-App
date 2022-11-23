//
//  Folder.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/10/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import Foundation

class Folder {
    var folderIdEnc: NSNumber
    var folderName: String
    var description: String
    var albums = NSMutableArray()
    var folders = NSMutableArray()
    var noOfSubAlbums: Int
    var noOfSubFolders: Int
    var url: String
    //Default Constructor
    init() {
        folderIdEnc = 0
        folderName = ""
        description = ""
        noOfSubFolders = 0
        noOfSubAlbums = 0
        url = ""
    }
    
    func setData(folderIdEnc: NSNumber, folderName: String, description: String, albums: NSMutableArray, folders: NSMutableArray, subFoldersCount: Int, subAlbumsCount: Int, url: String) {
        self.folderIdEnc = folderIdEnc
        self.folderName = folderName
        self.description = description
        self.albums = albums
        self.folders = folders
        self.noOfSubFolders = subFoldersCount
        self.noOfSubAlbums = subAlbumsCount
        self.url = url
    }
}
