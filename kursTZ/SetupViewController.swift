//
//  SetupViewController.swift
//  kursTZ
//
//  Created by Petr Gusakov on 02.06.2021.
//

import UIKit

protocol SetupReferenceValueDelegate {
    func didSetup(referenceValue: Double, isLess: Bool, isSelect: Bool)
}

class SetupViewController: UIViewController {

    @IBOutlet var valueTextField: UITextField!
    @IBOutlet var conditionSegmentedControl: UISegmentedControl!
    @IBOutlet var showSegmentedControl: UISegmentedControl!
    
    var delegate: SetupReferenceValueDelegate? = nil
    var isLess = false
    var isSelect = false

    var referenceValue = Double.zero

    override func viewDidLoad() {
        super.viewDidLoad()

        valueTextField.text = String(format: "%.4f", referenceValue)
        isLess = UserDefaults.standard.bool(forKey: "isLess")
        isSelect = UserDefaults.standard.bool(forKey: "isSelect")

        if isLess { conditionSegmentedControl.selectedSegmentIndex = 1 }
        if isSelect { showSegmentedControl.selectedSegmentIndex = 1 }
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func setupValue(_ sender: Any) {
        if conditionSegmentedControl.selectedSegmentIndex == 0 {
            isLess = false
        } else {
            isLess = true
        }
        if showSegmentedControl.selectedSegmentIndex == 0 {
            isSelect = false
        } else {
            isSelect = true
        }
        
        
        let valueStr = valueTextField.text
        referenceValue = (valueStr! as NSString).doubleValue
//        referenceValue = NumberFormatter().number(from: valueStr!)!.doubleValue
        
        delegate?.didSetup(referenceValue: referenceValue, isLess: isLess, isSelect: isSelect)
        UserDefaults.standard.set(isLess, forKey: "isLess")
        UserDefaults.standard.set(isSelect, forKey: "isSelect")

        self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
