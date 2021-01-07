//
//  ViewController.swift
//  SampleAws
//
//  Created by Akansha Dixit on 06/01/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let object = ServiceHandling()
        object.downloadFile()
    }


}

