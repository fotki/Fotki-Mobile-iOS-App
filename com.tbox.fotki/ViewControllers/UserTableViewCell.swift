//
//  UserTableViewCell.swift
//  com.tbox.fotki
//
//  Created by Apple on 3/22/17.
//  Copyright © 2020 Fotki. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var creationDate: UILabel!
    @IBOutlet weak var space: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
