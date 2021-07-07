//
//  EventViewController.swift
//  MyCalendar
//
//  Created by Jatuh on 12/3/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//

import UIKit
import Firebase

class EventViewController: UIViewController {
    
    @IBOutlet weak var TimerView: UIView!
    @IBOutlet weak var EventTitle: UILabel!
    @IBOutlet weak var EventDate: UILabel!
    @IBOutlet weak var EventSubject: UILabel!
    @IBOutlet weak var HrInput: UITextField!
    @IBOutlet weak var MinInput: UITextField!
    @IBOutlet weak var SecInput: UITextField!
    @IBOutlet weak var CountDownTimer: UILabel!
    @IBOutlet weak var StartButton: UIButton!
    @IBOutlet weak var StopButton: UIButton!
    
    
    var oneevent:event?
    var timeForTask = 0
    var seconds = 60
    var timer = Timer ()
    var isTimerRunning = false
    var resumeTapped = false
    var chosenTimeInterval: Int = 0
    var tapGesture = UITapGestureRecognizer()
    var token:String? = nil
    var email:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TimerView.layer.shadowOffset = CGSize(width: 3, height: 3)
        TimerView.layer.shadowOpacity = 0.25
        TimerView.layer.cornerRadius = 20
        TimerView.layer.shadowColor = UIColor.red.cgColor
        TimerView.layer.masksToBounds = false
        TimerView.layer.shadowRadius = 10
        TimerView.layer.shadowOffset = CGSize(width:4,height:10)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        EventTitle.text = oneevent?.title
        EventDate.text = oneevent?.date
        EventSubject.text = oneevent?.subject
        let hr:Int = Int(HrInput.text ?? "0") ?? 0
        let min:Int = Int(MinInput.text ?? "0") ?? 0
        let sec:Int = Int(SecInput.text ?? "0") ?? 0
        chosenTimeInterval = sec + 60 * min + 3600 * hr
        seconds = chosenTimeInterval
        CountDownTimer.text = timeString(time: Double(chosenTimeInterval))
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func runTimer() {
        if self.resumeTapped == false {
            seconds = chosenTimeInterval
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(EventViewController.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
            self.StopButton.isEnabled = true
        } else {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(EventViewController.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
            self.StopButton.isEnabled = true
        }
    }
    
    @objc func updateTimer(){
        if seconds < 1 {
            timer.invalidate()
            isTimerRunning = false
        } else {
            seconds -= 1
            CountDownTimer.text = timeString(time: TimeInterval(seconds))
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let Hours = Int(time) / 3600
        let Minutes = Int(time) / 60 % 60
        let Seconds = Int(time) % 60
        return String(format: "%02i:%02i:%02i", Hours, Minutes, Seconds)
    }
    
    @IBAction func StartButtonTapped(_ sender: Any) {
        if isTimerRunning == false {
            let hr:Int = Int(HrInput.text ?? "0") ?? 0
            let min:Int = Int(MinInput.text ?? "0") ?? 0
            let sec:Int = Int(SecInput.text ?? "0") ?? 0
            print(hr)
            print(sec)
            chosenTimeInterval = sec + 60 * min + 3600 * hr
            seconds = chosenTimeInterval
            runTimer()
            CountDownTimer.text = timeString(time: Double(chosenTimeInterval))
            print("here")
        }else{            
        }
    }
    
    @IBAction func StopButtonTapped(_ sender: UIButton) {
        if self.resumeTapped == false {
            timer.invalidate()
            self.resumeTapped = true
        } else {
            runTimer()
            self.resumeTapped = false
        }
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToEvent"{
            let vc = segue.destination as! CalendarViewController
            vc.email = email ?? ""
        }
    }
}
