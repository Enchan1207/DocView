//
//  AddBMViewController.swift
//  DocView
//
//  Created by EnchantCode on 2019/03/29.
//  Copyright © 2019年 EnchantCode. All rights reserved.
//

import UIKit

class AddBMViewController: UIViewController {
    
    //--components
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var typeSwitch: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    @IBAction func Back(_ sender: Any) {
        //--画面遷移した方が楽か…
        let next=self.storyboard?.instantiateViewController(withIdentifier: "MainScreen") as! ViewController;
        
        //--遷移
        show(next, sender: nil);
        
    }
    
    @IBAction func Add(_ sender: Any) {
    }
    

}
