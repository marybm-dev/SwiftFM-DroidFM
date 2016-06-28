//
//  PersonCell.swift
//  SwiftFM
//
//  Created by Mary Martinez on 1/9/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation
import UIKit

class PersonCell : UITableViewCell {
    
    @IBOutlet var name : UILabel!
    @IBOutlet var email : UILabel!
    @IBOutlet var photo : UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

