//
//  EventTableViewCell.swift
//  MyCalendar
//
//  Created by Yan Yubing on 12/3/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCell: UIView!
    @IBOutlet weak var EventTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        eventCell.backgroundColor = UIColor(red: 26/255, green: 173/255, blue: 136/255, alpha: 1)
        eventCell.layer.shadowOffset = CGSize(width: 3, height: 3)
        eventCell.layer.shadowOpacity = 0.25
        eventCell.layer.cornerRadius = 10
        eventCell.layer.shadowColor = UIColor.green.cgColor
        eventCell.layer.masksToBounds = false
        eventCell.layer.shadowRadius = 10
        eventCell.layer.shadowOffset = CGSize(width:4,height:10)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCell(title:String){
        EventTitle.text = title
    }
}
