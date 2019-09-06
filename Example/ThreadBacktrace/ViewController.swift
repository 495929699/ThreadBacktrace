//
//  ViewController.swift
//  ThreadBacktrace
//
//  Created by 495929699g@gmail.com on 09/05/2019.
//  Copyright (c) 2019 495929699g@gmail.com. All rights reserved.
//

import UIKit
import ThreadBacktrace

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backtraceOfMainThread().log()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

