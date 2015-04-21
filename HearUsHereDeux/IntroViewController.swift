//
//  IntroViewController.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 17/04/15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import Foundation
import UIKit

class IntroViewController: UIViewController {
	
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var imageView: UIImageView!
	
	
	override func viewDidLoad() {
		scrollView.contentSize = imageView.frame.size
	}
	
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	@IBAction func done(sender: UIBarButtonItem) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
}