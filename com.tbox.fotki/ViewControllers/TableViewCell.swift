
import UIKit

class TableViewCell: UITableViewCell {
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileImage: UIImageView!
    @IBOutlet weak var noOfFiles: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
