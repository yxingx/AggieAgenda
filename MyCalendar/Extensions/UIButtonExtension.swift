//
//  UIButtonExtension.swift
//  MyCalendar
//
//  Created by Yan Yubing on 12/2/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//

import UIKit


extension UIButton {
    
    func SetAddButtonUI(){
        backgroundColor = UIColor(red: 145/255, green: 245/255, blue: 173/255, alpha: 1)
        layer.cornerRadius = frame.height / 2
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width:0,height:10)
        
    }

}
