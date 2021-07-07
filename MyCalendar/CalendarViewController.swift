//
//  CalendarViewController.swift
//  MyCalendar
//
//  Created by Yan Yubing on 11/20/19.
//  Copyright © 2019 Yan Yubing. All rights reserved.
//
import UIKit
import Firebase
import FirebaseFirestore
var vSpinner : UIView?

extension UIViewController {
    //Show activity indicator when loading
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    //dismiss the activity indicator once succeessfully loaded
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

//Used for auto deleting events based on date (3-day auto expire)
extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    static var checkdate: Date { return ((Date().dayBefore).dayBefore).dayBefore}
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
}


class CalendarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MyProtocol{
    //passing user data from other navigated screen to the original and reload list
    func senduserdataToPreviousVC(newuser: User, completionHandler: @escaping (String?, String?) -> Void) {
        self.user = newuser
        self.email = newuser.id ?? ""
        self.needsinitialized = false
        self.tableview.reloadData()
        DispatchQueue.main.async{
            completionHandler("response", nil)
        }
    }
    
    
    
    let db = Firestore.firestore()
    private let refreshControl = UIRefreshControl()
    var canvasdataapi = Api.init()
    var user = User()
    var ref: DocumentReference? = nil
    var jsondata:[[String:Any]] = [["":""]]
    var email:String = ""
    var id:Int = 0
    var name:String = ""
    var token:String = ""
    var isfromcanvas: Bool = false
    var activities = [(key: Date, value: [event])] ()
    var selectdateindex:Int = 0
    var selecteventindex:Int = 0
    let dateFormatter = DateFormatter()
    var isfromCanvas:Bool = true
    var needsinitialized:Bool = true
    var canvasdatastrings:[String] = []
    var currentdate:String? = nil
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var AddButton: UIButton!
    
    //handle refresh event list
    @objc private func refreshcalender(_ sender: Any){
        getData(){response, error in
            if response != nil{
                
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
                self.tableview.reloadData()
            }
        }
        
    }
    //check whether Canvas has updated assignments
    func checkCanvasUpdates(completionHandler: @escaping (_ Response: String?, _ Error: String?) -> Void) {
        let userref = self.db.collection("users").document(email)
        userref.getDocument{(document, error) in
            if let document = document, document.exists{
                let temptoken = (document.data()?["token"] as? String) ?? ""
                self.token = temptoken
                self.canvasdataapi.ApiCall(token:temptoken){
                    response, error in
                    if(response != nil){
                        self.jsondata = self.canvasdataapi.upcomingeventsdata
                        var newcanvas:[String] = []
                        var datestrings:[String] = []
                        for dic in self.jsondata{
                            //print(dic)
                            guard let date = dic["all_day_date"] as? String else { return }
                            guard let title = dic["title"] as? String else { return }
                            guard let assignment = dic["assignment"] as? [String:Any] else{return }
                            guard let courseid = assignment["course_id"] as? Int else{return}
                            newcanvas.append(date+title+String(courseid))
                            datestrings.append(date)
                        }
                        let userref = self.db.collection("users").document(self.user.id ?? "")
                        var oldcanvas: [String] = []
                        var olddate: [String] = []
                        userref.getDocument{(document, error) in
                            if let document = document, document.exists{
                                //print(document.documentID)
                                let temp = (document.data()?["Canvasdata"] as? NSArray) as Array?
                                guard let canvas = temp else{
                                    return
                                }
                                for i in canvas{
                                    let canvasstring = String(_cocoaString: i)
                                    oldcanvas.append(canvasstring)
                                }
                                let storedate = (document.data()?["dates"] as? NSArray) as Array?
                                guard let date = storedate else{
                                    return
                                }
                                for i in date{
                                    let datestring = String(_cocoaString: i)
                                    olddate.append(datestring)
                                }
                                
                            }
                            if newcanvas == oldcanvas{
                                DispatchQueue.main.async {
                                    completionHandler("complete", nil)
                                }
                                return
                            }
                            for i in newcanvas {
                                var check:Bool = false
                                for j in oldcanvas {
                                    if i == j{
                                        check = true
                                    }
                                }
                                
                                if !check{
                                    self.initializeCanvasevents(){
                                        response, error in
                                        if response != nil{
                                            for k in newcanvas{
                                                var check:Bool = false
                                                for m in oldcanvas{
                                                    if k == m{
                                                        check = true
                                                    }
                                                }
                                                if !check{
                                                    oldcanvas.append(k)
                                                }
                                            }
                                            for k in datestrings{
                                                var check:Bool = false
                                                for m in olddate{
                                                    if k == m{
                                                        check = true
                                                    }
                                                }
                                                if !check{
                                                    olddate.append(k)
                                                }
                                            }
                                            var allstring:[String] = []
                                            for i in self.activities{
                                                let tempdatestring = self.dateFormatter.string(from: i.key)
                                                allstring.append(tempdatestring)
                                                for j in i.value{
                                                    self.db.collection("users").document(self.email).collection(tempdatestring).document(j.title).setData(["isCanvas":j.isCanvasevent, "Subject":j.subject]){
                                                        err in
                                                        if err != nil{
                                                            print("there is some error")
                                                        }else{
                                                            print("successfully written")
                                                        }
                                                    }
                                                }
                                                self.db.collection("users").document(self.email).setData(["dates":olddate, "token":self.token, "isCanvasUser":true,"Canvasdata":oldcanvas]){
                                                    err in
                                                    if err != nil{
                                                        print("there is some error")
                                                    }else{
                                                        print("successfully written")
                                                    }
                                                }
                                                DispatchQueue.main.async {
                                                    completionHandler("complete", nil)
                                                }
                                                break;
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //initialze canvas fecthed event format
    func initializeCanvasevents(completionHandler: @escaping (_ Response: String?, _ Error: String?)->Void) {
        var temp = [Date:[event]] ()
        var check:Bool = false
        let dispatchGroup = DispatchGroup.init()
        let dispatchQueue = DispatchQueue(label: "taskQueue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        dispatchQueue.async{
            for dic in self.jsondata{
                //print(dic)
                dispatchGroup.enter()
                check = false
                var temptitles:[event] = []
                guard let date = dic["all_day_date"] as? String else { return }
                guard let title = dic["title"] as? String else { return }
                guard let assignment = dic["assignment"] as? [String:Any] else{
                    return }
                guard let courseid = assignment["course_id"] as? Int else{
                    return
                }
                self.canvasdatastrings.append(date+title+String(courseid))
                let courseidstring = String(courseid)
                self.canvasdataapi.getCourse(token: self.token, courseid: courseidstring){
                    response, error in
                    if response != nil{
                        //print(self.canvasdataapi.subject)
                        let tempevent = event.init(title, date, true, self.canvasdataapi.subject)
                        guard let formatdate = self.dateFormatter.date(from: date) else {return}
                        for i in temp{
                            if i.key == formatdate{
                                temptitles = i.value
                                tempevent.isCanvasevent = true
                                temptitles.append(tempevent)
                                temp.updateValue(temptitles, forKey: formatdate)
                                check = true
                            }
                        }
                        if !check{
                            tempevent.isCanvasevent = true
                            temptitles.append(tempevent)
                            temp.updateValue(temptitles, forKey: formatdate)
                        }
                        self.activities = temp.sorted{$0.key < $1.key}
                        self.user.user = self.activities
                        dispatchSemaphore.signal()
                        dispatchGroup.leave()
                    }
                    if error != nil{
                        print("there is some error!")
                        DispatchQueue.main.async {
                            completionHandler(nil, "error")
                        }
                    }
                }
                dispatchSemaphore.wait()
            }
        }
        dispatchGroup.notify(queue: dispatchQueue){
            DispatchQueue.main.async {
                completionHandler("complete", nil)
            }
            
        }
        
        
    }
    
    //fetch date from firestore
    //load both Canvas data and user customized event
    //check if there is a Canvas update: if so, compare the assignment with the stored canvas event
    //if matched, skip, otherwise store the new event
    func getData(completionHandler: @escaping (_ Response: String?, _ Error: String?)->Void){
        let dname = user.id ?? email
        let userref = self.db.collection("users").document(dname)
        userref.getDocument{(document, error) in
            if let document = document, document.exists{
                let isCanvas = (document.data()?["isCanvasUser"] as? Bool) ?? false
                if(isCanvas){
                    self.checkCanvasUpdates(){
                        response, error in
                        if response != nil{
                            let temp = (document.data()?["dates"] as? NSArray) as Array?
                            guard let dates = temp else{
                                return
                            }
                            self.user.token = (document.data()?["token"] as? String ?? "")
                            self.token = self.user.token ?? ""
                            self.user.getdata(db: self.db, dates: dates){
                                response, error in
                                if response != nil{
                                    DispatchQueue.main.async {
                                        completionHandler("complete", nil)
                                    }
                                }
                            }
                        }
                    }
                }else{
                    let temp = (document.data()?["dates"] as? NSArray) as Array?
                    guard let dates = temp else{
                        return
                    }
                    self.user.getdata(db: self.db, dates: dates){
                        response, error in
                        if response != nil{
                            DispatchQueue.main.async {
                                completionHandler("complete", nil)
                            }
                        }
                    }
                }
                
                //print(document.documentID)
                
            }else{
                let iscanvas = self.user.isfromCanvas ?? false
                if(iscanvas){
                    self.canvasdataapi.ApiCall(token:self.token){
                        response, error in
                        if(response != nil){
                            self.jsondata = self.canvasdataapi.upcomingeventsdata
                            self.initializeCanvasevents(){
                                response, error in
                                if response != nil{
                                    //self.tableview.reloadData()
                                    var allstring:[String] = []
                                    for i in self.activities{
                                        let tempdatestring = self.dateFormatter.string(from: i.key)
                                        allstring.append(tempdatestring)
                                        for j in i.value{
                                            self.db.collection("users").document(dname).collection(tempdatestring).document(j.title).setData(["isCanvas":j.isCanvasevent, "Subject":j.subject]){
                                                err in
                                                if err != nil{
                                                    print("there is some error")
                                                }else{
                                                    print("successfully written")
                                                }
                                            }
                                        }
                                        self.db.collection("users").document(dname).setData(["dates":allstring, "token":self.token, "isCanvasUser":true, "Canvasdata":self.canvasdatastrings]){
                                            err in
                                            if err != nil{
                                                print("there is some error")
                                            }else{
                                                print("successfully written")
                                            }
                                        }
                                        DispatchQueue.main.async {
                                            completionHandler("complete", nil)
                                        }
                                        
                                    }
                                }
                            }
                            
                        }
                    }
                    
                }else{
                    self.db.collection("users").document(dname).setData(["dates":[], "token":self.token, "isCanvasUser":false, "CanvasData": []]){
                        err in
                        if err != nil{
                            print("there is some error")
                        }else{
                            print("successfully written")
                            DispatchQueue.main.async {
                                completionHandler("complete", nil)
                            }
                        }
                    }
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        //        dateFormatter.timeStyle = .none
        self.tableview.delegate = self
        self.tableview.dataSource = self
        refreshControl.addTarget(self, action: #selector(refreshcalender(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Getting calender data...")
        self.tableview.refreshControl = refreshControl
        self.showSpinner(onView: self.view)
        if(needsinitialized){
            user.getid(isCanvas: isfromCanvas, email: email, token: token, canvasapi: canvasdataapi){
                response, error in
                if(response != nil){
                    self.getData(){
                        getdataresponse, error in
                        if getdataresponse != nil{
                            self.removeSpinner()
                            self.tableview.reloadData()
                        }
                        if error != nil{
                            self.removeSpinner()
                            //someerrormessage
                        }
                    }
                }
            }
        }
        AddButton.SetAddButtonUI()
        // Do any additional setup after loading the view.
    }
    
    
    //Tableview for displaying events. including swipe to delete, select to segue
    //separated by sections of event date sorted by time
    //each section contains the events
    func numberOfSections(in tableView: UITableView) -> Int {
        self.activities = user.user.sorted{$0.key < $1.key}
        //print(activities)
        return self.activities.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.activities = user.user.sorted{$0.key < $1.key}
        let title = self.activities[section].key
        let titlestring = dateFormatter.string(from:title)
        return "\(titlestring)"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        self.activities = user.user.sorted{$0.key < $1.key}
        //        print(self.activities[section].value.count)
        return self.activities[section].value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.activities = user.user.sorted{$0.key < $1.key}
        //        print(activities)
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventTableViewCell
        
        let title = self.activities[indexPath.section].value[indexPath.row].title
        cell.setCell(title:title)
        //        cell.textLabel?.text = "\(title)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.activities[indexPath.section].value[indexPath.row].isCanvasevent{
            return false
        }else{
            return true
        }
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete"){(contextualAction, view, actionPerformed: @escaping (Bool) -> Void) in
            //delete here
            let alert = UIAlertController(title: "Delete Event", message: "Are you sure you want to delete this event", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(alertAction) in
                actionPerformed(false)
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(alertAction) in
                let date = self.dateFormatter.string(from: self.activities[indexPath.section].key)
                let userref = self.db.collection("users").document(self.user.id ?? "").collection(date).document(self.activities[indexPath.section].value[indexPath.row].title)
                userref.delete(){
                    error in
                    if error != nil{
                        print (error as Any)
                    }
                }
                var temp = self.activities[indexPath.section].value
                temp.remove(at: indexPath.row)
                if temp.count != 0{
                    self.activities[indexPath.section].value = temp
                    self.user.user = self.activities
                    self.tableview.deleteRows(at: [indexPath], with: .fade)
                }else{
                    let userref = self.db.collection("users").document(self.user.id ?? "")
                    var datestrings:[String] = []
                    userref.getDocument{(document, error) in
                        if let document = document, document.exists{
                            print(document.documentID)
                            let temp = (document.data()?["dates"] as? NSArray) as Array?
                            guard let dates = temp else{
                                return
                            }
                            for i in dates{
                                let checkdate = String(_cocoaString: i)
                                if checkdate != date{
                                    datestrings.append(checkdate)
                                }
                                
                            }
                            self.db.collection("users").document(self.user.id ?? "").updateData(["dates":datestrings]){
                                err in
                                if err != nil{
                                    print("there is some error")
                                }else{
                                    print("successfully written")
                                }
                            }
                        }
                        self.activities.remove(at: indexPath.section)
                        self.user.getdata(db: self.db, dates: datestrings as Array<AnyObject>){
                            response, error in
                            if response != nil{
                                self.tableview.deleteSections([indexPath.section], with: .fade)
                            }
                        }
                        //self.user.user = self.activities
                        //self.tableview.deleteSections([indexPath.section], with: .fade)
                        
                        //self.tableview.reloadData()
                    }
                }
                
                // self.tableview.reloadData()
                actionPerformed(true)
            }))
            
            self.present(alert, animated: true)
            
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // self.index = indexPath.row
        self.selectdateindex = indexPath.section
        self.selecteventindex = indexPath.row
        self.performSegue(withIdentifier: "toEvent", sender: self)
        
        
    }
    /* func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     //for further instructions
     }*/
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addEventSegue"{
            let vc = segue.destination as! PopupAddEventViewController
            vc.mDelegate = self
            vc.activities = activities
            vc.db = self.db
            vc.user = self.user
            vc.doneSaving = { [weak self] in
                DispatchQueue.main.async{
                    self?.tableview.reloadData()
                }
            }
        }else if segue.identifier == "toEvent"{
            let VC = segue.destination as! EventViewController
            VC.oneevent = activities[selectdateindex].value[selecteventindex]
            VC.email = user.id
        }
    }
    @IBAction func backTOHome(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(identifier: "LoginViewController") as! ViewController
        self.present(loginVC, animated: true, completion: nil)
    }
}
