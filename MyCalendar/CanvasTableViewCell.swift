//
//  CanvasTableViewCell.swift
//  MyCalendar
//
//  Created by Arthur on 12/4/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.


import UIKit

class CanvasTableViewCell: UITableViewCell {
    
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myLabel: UILabel!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
