//
//  UserCollectionViewCell.swift
//  com.tbox.fotki
//
//  Created by apple on 9/6/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit

class UserCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var creationDate: UILabel!
    @IBOutlet weak var space: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
