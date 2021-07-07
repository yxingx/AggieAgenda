//
//  ViewController.swift zuixinban
//  MyCalendar
//
//  Created by Yan Yubing on 11/20/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var SignSelector: UISegmentedControl!
    @IBOutlet weak var EmailEntered: UITextField!
    @IBOutlet weak var PasswordEntered: UITextField!
    @IBOutlet weak var SignButton: UIButton!
    @IBOutlet weak var Success: UILabel!
    
    var isSignIn:Bool = true
    var tapGesture = UITapGestureRecognizer()
    var isfromcanvas: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        EmailEntered.layer.shadowOffset = CGSize(width: 3, height: 3)
        EmailEntered.layer.shadowOpacity = 0.25
        EmailEntered.layer.shadowColor = UIColor.yellow.cgColor
        EmailEntered.layer.masksToBounds = false
        EmailEntered.layer.shadowRadius = 10
        
        PasswordEntered.layer.shadowOffset = CGSize(width: 3, height: 3)
        PasswordEntered.layer.shadowOpacity = 0.25
        PasswordEntered.layer.shadowColor = UIColor.yellow.cgColor
        PasswordEntered.layer.masksToBounds = false
        PasswordEntered.layer.shadowRadius = 10
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //to check if user need to register or sign in
    @IBAction func SignSelect(_ sender: Any) {
        isSignIn = !isSignIn
        
        if isSignIn {
            SignButton.setTitle("Sign In", for: .normal)
        }else{
            SignButton.setTitle("Register", for: .normal)
        }
    }
    
    //api call for user login and sign in, to navigate to different controller depending on the email
    @IBAction func ButtonPress(_ sender: Any) {
        if let email = EmailEntered.text, let password = PasswordEntered.text{
            if isSignIn {
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error == nil{
                        self.Success.text = ""
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let calendarVC = storyboard.instantiateViewController(identifier: "CalendarViewController") as! CalendarViewController
                        calendarVC.email = email
                        calendarVC.isfromCanvas = false
                        self.present(calendarVC, animated: true, completion: nil)
                    }else{
                        self.Success.text = "Unmatched email & password"
                        self.EmailEntered.layer.borderColor = UIColor.red.cgColor
                        self.PasswordEntered.layer.borderColor = UIColor.red.cgColor
                        self.EmailEntered.layer.borderWidth = 1.0
                        self.PasswordEntered.layer.borderWidth = 1.0
                        
                    }
                })
            }else{
                
                Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                    if user != nil{
                        print("here")
                    }else{
                        print("now here")
                        if let i = email.firstIndex(of: "@"){
                            if  email[i ..< email.endIndex] == "@ucdavis.edu"{
                                print("here1")
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let canvasVC = storyboard.instantiateViewController(identifier: "Canvas") as! CanvasViewController
                                canvasVC.email = email
                                canvasVC.isfromcanvas = true
                                self.present(canvasVC, animated: true, completion: nil)
                            }else{
                                print("here2")
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let calendarVC = storyboard.instantiateViewController(identifier: "CalendarViewController") as! CalendarViewController
                                calendarVC.email = email
                                calendarVC.isfromcanvas = false
                                self.isfromcanvas = false
                                
                                self.present(calendarVC, animated: true, completion: nil)
                            }
                        }
                    }
                })
            }
        }else{
            self.Success.text = "Enter your Email and Password"
            EmailEntered.layer.borderColor = UIColor.red.cgColor
            PasswordEntered.layer.borderColor = UIColor.red.cgColor
            EmailEntered.layer.borderWidth = 1.0
            PasswordEntered.layer.borderWidth = 1.0
        }
    }
}

