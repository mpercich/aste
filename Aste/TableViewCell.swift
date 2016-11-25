//
//  TableViewCell.swift
//  Aste
//
//  Created by Michele on 24/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var key: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var property: UILabel!
    @IBOutlet weak var sale: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var attachment: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
