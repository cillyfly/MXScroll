//
//  ChildViewController.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/17.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import UIKit
import MXScroll
class ChildViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

 
    }
     
}

extension ChildViewController:UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = "\(indexPath.section) \(indexPath.row)"
        return cell
    }
}

extension ChildViewController:MXViewControllerViewSource{
    func viewForMixToObserveContentOffsetChange() -> UIView {
        return self.tableView
    }
}
