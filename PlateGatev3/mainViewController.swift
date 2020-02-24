//
//  mainViewController.swift
//  PlateGatev3
//
//  Created by Kishan Patel on 2/23/20.
//  Copyright © 2020 Kishan Patel. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

var token = ""

class mainViewController: UIViewController {
    
    
    public func getToken() -> String {
        return token
    }
    
    override func viewDidLoad() {
    super.viewDidLoad()
        
        
    view.backgroundColor = .white
    

//      button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
    
        let button = UIButton(frame: CGRect(x: 135, y: 210, width: 100, height: 50))
        button.backgroundColor = UIColor(red:0.53, green:0.75, blue:0.60, alpha:1.0)
        button.setTitle("Sign In", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
      self.view.addSubview(button)
      
      setTextFeilds()
        
    }

    var Username = ""
    var Password = ""
    
    
    
    
    @objc func usernameChange(_ textField: UITextField) {
        Username = textField.text!
    }
    @objc func passwordChange(_ textField: UITextField) {
        Password = textField.text!
    }
    
    
    func setTextFeilds(){
            let sampleTextField =  UITextField(frame: CGRect(x: 35, y: 100, width: 300, height: 40))
            sampleTextField.placeholder = "Enter Username"
            sampleTextField.font = UIFont.systemFont(ofSize: 15)
            sampleTextField.borderStyle = UITextField.BorderStyle.roundedRect
            sampleTextField.autocorrectionType = UITextAutocorrectionType.no
            //sampleTextField.keyboardType = UIKeyboardType.default
            //sampleTextField.returnKeyType = UIReturnKeyType.done
            sampleTextField.clearButtonMode = UITextField.ViewMode.whileEditing
            sampleTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
            //sampleTextField.delegate = self
            self.view.addSubview(sampleTextField)
            sampleTextField.addTarget(self, action: #selector(mainViewController.usernameChange(_:)), for: UIControl.Event.editingChanged)

//    self.Username = sampleTextField.text!
        
            
            let sampleTextField1 =  UITextField(frame: CGRect(x: 35, y: 150, width: 300, height: 40))
            sampleTextField1.placeholder = "Enter Password"
            sampleTextField1.font = UIFont.systemFont(ofSize: 15)
            sampleTextField1.borderStyle = UITextField.BorderStyle.roundedRect
            sampleTextField1.autocorrectionType = UITextAutocorrectionType.no
          //  sampleTextField1.keyboardType = UIKeyboardType.default
           // sampleTextField1.returnKeyType = UIReturnKeyType.done
            sampleTextField1.clearButtonMode = UITextField.ViewMode.whileEditing
            sampleTextField1.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
            sampleTextField1.addTarget(self, action: #selector(mainViewController.passwordChange(_:)), for: UIControl.Event.editingChanged)
            //sampleTextField.delegate = self
            self.view.addSubview(sampleTextField1)
//        self.Password = sampleTextField.text!
            
        
        
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let url = URL(string: "http://plategate.tech/api.php?user=\(Username)&pass=\(Password)")

        guard let requestUrl = url else{ fatalError() }
        var request = URLRequest(url: requestUrl)
        
        
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                token = dataString
                print(dataString)
            }
            
        }
        task.resume()
        
        dismiss(animated: true)
        sender.setTitle("", for: .normal)
    }

    
    
    
}
