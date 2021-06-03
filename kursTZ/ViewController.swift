//
//  ViewController.swift
//  kursTZ
//
//  Created by Petr Gusakov on 02.06.2021.
//

import UIKit

class ViewController: UIViewController, XMLParserDelegate, UITableViewDataSource, UITableViewDelegate, SetupReferenceValueDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var referencaButtonItem: UIBarButtonItem!
    @IBOutlet var reminderButton: UIButton!
    @IBOutlet var datePicker: UIDatePicker!
    
    var recordList = [Record]()
    var dateStr = String()
    var nominal = Int.zero
    var value = Double.zero
    var elementName = String()
    
    var dateNotification: Date?
    let notificationIidentifier = "ru.pitermail.kursTZ"
    var isDateSetMode = false
    
    var tableList = [Record]()
    
    var dateStartStr: String!
    var dateEndStr: String!

    var referenceValue = Double.zero
    var isLess = false
    var isSelect = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        segmentedControl.isEnabled = false
        UserDefaults.standard.set(isLess, forKey: "isLess")
        UserDefaults.standard.set(isSelect, forKey: "isSelect")
        
        let lastDateNotification = UserDefaults.standard.object(forKey: "dateNotification") as? Date
        if lastDateNotification != nil {
            if lastDateNotification! < Date.init() {
                UserDefaults.standard.removeObject(forKey: "dateNotification")
            } else {
                dateNotification = lastDateNotification
                showDateNotification()
            }
        }
        
        datePicker.minimumDate = Date.init()
        datePicker.backgroundColor = UIColor.white

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) {
            (granted, error) in
            if !granted {
                print("UNUserNotificationCenter - NOT !!!")
            }
        }
    }
    
    func showDateNotification()  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        
        let dateStr = "Reminder set to: " + dateFormatter.string(from: dateNotification!) + " " + timeFormatter.string(from: dateNotification!)
        reminderButton.setTitle(dateStr, for: .normal)
    }
    
    // MARK: - Запрос данных с сервера ЦБР
    @IBAction func readDataFromServer(_ sender: Any) {
//        var path = "http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=02/03/2021&date_req2=21/03/2021&VAL_NM_RQ=R01235"
        
        let dateEnd = Date.init()
        let date = Calendar.current.date(byAdding: .day, value: -30, to: dateEnd)!

        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "dd/MM/yyyy"  // 14/03/2001
        
        dateStartStr = dateFormatter.string(from: date)
        dateEndStr = dateFormatter.string(from: dateEnd)

        let path = String(format: "http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=%@&date_req2=%@&VAL_NM_RQ=R01235",
                          dateStartStr, dateEndStr)

        print(path as Any)
        
        if let parser = XMLParser(contentsOf: URL(string: path)!) {
            parser.delegate = self
            parser.parse()
        }
    }
    
    // MARK: - Установка временного диапазана для показа в таблице
    @IBAction func rangeDays(_ sender: Any) {
        let segmentedControl = sender as! UISegmentedControl
        referencaButtonItem.isEnabled = true

        switch segmentedControl.selectedSegmentIndex {
        case 0:
            tableList = recordList
        case 1:
            tableList = recordList.suffix(10)
        case 2:
            tableList = recordList.suffix(1)
            referencaButtonItem.isEnabled = false
        default:
            break
        }
        
        referencaButtonItem.title = "reference Value"
        isLess = false
        isSelect = false
        referenceValue = .zero
        
        tableView.reloadData()
    }
    
    // MARK: - Установка напоминалки
    @IBAction func reminder(_ sender: Any) {
        if isDateSetMode {
            setTimeReminder()
            showDateNotification()
            self.datePicker.isHidden = true
            isDateSetMode = false
            return
        }
        
        let alertController = UIAlertController(title: nil, message: "Set a reminder", preferredStyle: .actionSheet)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (alertAction) in
            self.reminderButton.setTitle("Set a reminder", for: .normal)
            self.removeTimeReminder()
        }
        
        let newAction = UIAlertAction(title: "New", style: .default) { (alertAction) in
            print("New")
            self.datePicker.isHidden = false
            self.reminderButton.setTitle("Set", for: .normal)
            self.isDateSetMode = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        if dateNotification != nil {
            alertController.addAction(removeAction)
        }
        
        alertController.addAction(newAction)
        alertController.addAction(cancelAction)
            
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setTimeReminder() {
        dateNotification = datePicker.date
        UserDefaults.standard.setValue(dateNotification, forKey: "dateNotification")
        
        let content = UNMutableNotificationContent()
        content.title = "Dollar USA rate from Bank of Russia"
        content.subtitle = "non-public offer"
        content.body = "test"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "ChingSound.mp3"))

        let imageName = "us_dollar"
        guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") else { return }

        let attachment = try! UNNotificationAttachment(identifier: imageName, url: imageURL, options: .none)
        content.attachments = [attachment]
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dateNotification!)
        let triggerDate = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "notificationIidentifier", content: content, trigger: triggerDate)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func removeTimeReminder() {
        UserDefaults.standard.removeObject(forKey: "dateNotification")
        dateNotification = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIidentifier])
    }

    @IBAction func changeTimeReminder(_ sender: Any) {
        print((sender as! UIDatePicker).date)
    }
    
    // MARK: - SetupReferenceValueDelegate Установка контрольного числа
    func didSetup(referenceValue: Double, isLess: Bool, isSelect: Bool) {
        self.referenceValue = referenceValue
        self.isLess = isLess
        self.isSelect = isSelect
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            tableList = recordList
        case 1:
            tableList = recordList.suffix(10)
        default:
            break
        }

        var prefix = ">= "

        if !isSelect {
            if isLess {
                tableList = tableList.filter {$0.value <= referenceValue }
            } else {
                tableList = tableList.filter {$0.value >= referenceValue }
            }
        }
        
        if isLess { prefix = "<= " }
        referencaButtonItem.title = prefix + String(format: "%.4f", referenceValue)
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let record = tableList[indexPath.row]
        
        cell.textLabel?.text = record.dateStr
        cell.detailTextLabel?.text = String(format: "%f", record.value)
        cell.detailTextLabel?.textColor = UIColor.black

        if isSelect {
            if isLess && record.value <= referenceValue {
                cell.detailTextLabel?.textColor = UIColor.red
            }
            if !isLess && record.value >= referenceValue {
                cell.detailTextLabel?.textColor = UIColor.red
            }
        }

        return cell
    }
    
    // MARK: - Разбор ответа с ЦБР
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        if elementName == "Record" {
            dateStr = attributeDict["Date"]!
            nominal = Int.zero
            value = Double.zero
        }

        self.elementName = elementName
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" {
            let record = Record(dateStr: dateStr, nominal: nominal, value: value)
            recordList.append(record)
        }
        if elementName == "ValCurs" {
            //print(recordList)
            tableList = recordList

            segmentedControl.isEnabled = true
            tableView.reloadData()
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        var whiteStr = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if !whiteStr.isEmpty {
            if elementName == "Nominal" {
                nominal = Int(whiteStr)!
            }
            if self.elementName == "Value" {
                whiteStr = whiteStr.replacingOccurrences(of: ",", with: ".")
                value = Double(whiteStr)!
            }
            if self.elementName == "Date" {
                dateStr = whiteStr
            }
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Setup" {
            let setupViewController = segue.destination as! SetupViewController
            if referenceValue == .zero {
                referenceValue = tableList.reduce(.zero, { $0 + $1.value }) / Double(tableList.count)
            }
            setupViewController.referenceValue = referenceValue
            setupViewController.delegate = self
        }
    }

}

struct Record {
    var dateStr: String
    var nominal: Int
    var value: Double
}
