//
//  Sound.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 12-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import Foundation

class Sound {
	var data: NSMutableData
	var resourceURL: String
	
	var loaded = false
	
	init(resourceURL: String) {
		self.resourceURL = resourceURL
		self.data = NSMutableData()
	}
	
	convenience init(dict: NSDictionary) {
		let url = dict["url"] as! String
		self.init(resourceURL: url)
	}
	
	func load(completionHandler:() -> Void) {
		let pathStr = getCachePath(resourceURL)
		if let cachedData = getCachedSound(pathStr) {
			println("In cache: \(pathStr)")
			self.data.appendData(cachedData)
			self.loaded = true
			completionHandler()
		} else {
			var request : NSMutableURLRequest = NSMutableURLRequest()
			request.URL = NSURL(string: self.resourceURL)
			request.HTTPMethod = "GET"
			
			NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(),
				completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
					if data != nil {
						self.data.appendData(data)
						var error: NSError?
						if data.writeToFile(pathStr, options: .DataWritingAtomic, error: &error) {
							self.loaded = true
							println("Sound fetched from \(self.resourceURL)")
							completionHandler()
						} else {
							println("Failed file write \(error?.localizedDescription)")
						}
					} else {
						println("Download failed for \(self.resourceURL)")
						if let error = error {
							println(error.localizedDescription)
							// Try again? - JBG
							self.load(completionHandler)
						}
					}
			})
		}
	}
	
	func getCachePath(resourceURL: String) -> String {
		let fileComponents = resourceURL.componentsSeparatedByString("/")
		let fileStr = fileComponents[fileComponents.count - 1]
		let pathStr = NSTemporaryDirectory() + fileStr
		return pathStr

	}
	
	func getCachedSound(pathStr: String) -> NSData? {
		if NSFileManager().fileExistsAtPath(pathStr) {
			return (NSData.dataWithContentsOfMappedFile(pathStr) as! NSData)
		} else {
			return nil
		}
	}
}