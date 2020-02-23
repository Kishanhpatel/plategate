//
//  mainViewController.swift
//  PlateGatev3
//
//  Created by Kishan Patel on 2/23/20.
//  Copyright © 2020 Kishan Patel. All rights reserved.
//

import Foundation
import UIKit

class mainViewController: UIViewController {
    
    override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .white
    let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
      button.backgroundColor = .green
      button.setTitle("Test Button", for: .normal)
      button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)

      self.view.addSubview(button)
    }

    @objc func buttonAction(sender: UIButton!) {
        print("Button tapped")
        self.present(ViewController , animated: true, completion: nil)
    }
    
   
    

    
    
    
    
}
