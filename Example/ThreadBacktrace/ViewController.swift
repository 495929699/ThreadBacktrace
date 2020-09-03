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
        
        funcBacktrace(5)
    }

    func funcBacktrace(_ level: Int) {
        if level == 0 {
            BacktraceOfMainThread().log()
            return
        }
        
        funcBacktrace(level - 1)
    }

}

