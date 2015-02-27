//
//  Trigger.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 12-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import AVFoundation
import CoreLocation
import Foundation

class Trigger {
	var running = false
	var audioPlayer: AVAudioPlayer?
	var sound: Sound? {
		didSet {
			var error: NSError?
			self.audioPlayer = AVAudioPlayer(data: self.sound?.data, error: &error)
			self.audioPlayer?.numberOfLoops = -1
			self.audioPlayer?.volume = 0
			if self.running {
				self.audioPlayer?.play()
			}
		}
	}
	
	init() {
		self.sound = nil
	}
}

class GPSTrigger: Trigger {
	var location: CLLocation
	var radius: Int
	var url: String?
	
	init(location: CLLocation, radius: Int) {
		self.location = location
		self.radius = radius
		super.init()
	}
	
	init(dict: NSDictionary) {
		var coords: [Double] = dict["location"] as [Double]
		self.location = CLLocation(latitude: coords[0], longitude: coords[1])
		self.radius = dict["radius"] as Int
		self.url = dict["url"] as? String
		
		super.init()
	}
	
	func startStop(start: Bool) {
		self.running = start
		if self.running {
			self.audioPlayer?.play()
		} else {
			self.audioPlayer?.volume = 0
			self.audioPlayer?.stop()
		}
	}
}