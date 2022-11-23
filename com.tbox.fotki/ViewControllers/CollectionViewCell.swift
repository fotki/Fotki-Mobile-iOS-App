//
//  CollectionViewCell.swift
//  com.tbox.fotki
//
//  Created by Apple on 1/4/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet var playImage: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var smallActivityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playImage.alpha = 0
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if UIDevice.current.orientation == UIDeviceOrientation.portrait {
                self.frame.size = CGSize(width: 105, height: 105)
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                self.frame.size = CGSize(width: 140, height: 140)
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                self.frame.size = CGSize(width: 140, height: 140)
            } else {
                self.frame.size = CGSize(width: 105, height: 105)
            }
        } else {
            if UIDevice.current.orientation == UIDeviceOrientation.portrait {
                self.frame.size = CGSize(width: 77, height: 77)
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                self.frame.size = CGSize(width: 85, height: 85)
            } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                self.frame.size = CGSize(width: 85, height: 85)
            } else {
                self.frame.size = CGSize(width: 77, height: 77)
            }
        }
    }
}
