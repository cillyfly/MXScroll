//
//  SecondViewController.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/17.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import UIKit

class SecondViewController: ChildViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("SecondViewController viewWillAppear")
    }
}

extension SecondViewController{
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 40
    } 
}
