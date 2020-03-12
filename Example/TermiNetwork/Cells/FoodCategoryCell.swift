//
//  FoodCategoryCellTableViewCell.swift
//  SimpleNetworking_Example
//
//  Created by Vasilis Panagiotopoulos on 15/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class FoodCategoryCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: CustomImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
