//
//  CanvasViewController.swift
//  MyCalendar
//
//  Created by Arthur on 12/4/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//

import UIKit
import SafariServices

class CanvasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var TokenLabel: UITextField!
    
    let steps = ["step1","step2","step3","step4"]
    var canvasdataapi = Api.init()
    var jsondata:[[String:Any]] = [["":""]]
    var email:String = ""
    var password:String = ""
    var isfromcanvas:Bool =  false
    var token:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func CanvasURL(_ sender: Any) {
        showSafariVC(for: "https://canvas.ucdavis.edu/")
    }
    
    @IBAction func Login(_ sender: Any) {
        let token = "Bearer " + TokenLabel.text!
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let calendarVC = storyboard.instantiateViewController(identifier: "CalendarViewController") as! CalendarViewController
        calendarVC.token = token
        calendarVC.isfromCanvas = true
        calendarVC.email = email
        self.present(calendarVC, animated: true, completion: nil)
        
    }
    
    //redirect user to Canvas page
    func showSafariVC(for url: String){
        guard let url = URL(string: url)else{
            return
        }
        
        let safariVC =  SFSafariViewController(url: url)
        present(safariVC, animated: true)
        
    }
    
    //set up image instruction for getting token
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(steps.count)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CanvasTableViewCell
        cell.myImage.image = UIImage(named: (steps[indexPath.row] + ".jpg"))
        cell.myLabel.text = steps[indexPath.row]
        return (cell)
    }
}
