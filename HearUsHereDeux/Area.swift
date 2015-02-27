//
//  Area.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 12-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit

class Area {
	var triggers: [GPSTrigger]!
	var sounds: [Sound]!
	var coordinates: [Double]
	var polygon: MKPolygon!
	
	init() {
		self.triggers = []
		self.sounds = []
		self.coordinates = []
	}
	
	convenience init(dict: NSDictionary) {
		self.init()
		var triggerDicts: NSArray = dict["triggers"] as NSArray
		for triggerDict in triggerDicts {
			var trigger: GPSTrigger = GPSTrigger(dict: triggerDict as NSDictionary)
			self.triggers.append(trigger)
		}
		
		var soundDicts: NSArray = dict["sounds"] as NSArray
		for soundDict in soundDicts {
			var sound: Sound = Sound(dict: soundDict as NSDictionary)
			self.sounds.append(sound)
		}
		
		var coordinates: NSArray = dict["coords"] as NSArray
		for coordinate in coordinates {
			self.coordinates.append(coordinate as Double)
		}
	}
	
	func load(completionHander: (Sound) -> Void) {
		for sound in sounds {
			sound.load({
				completionHander(sound)
			})
		}
	}
	
	func checkLocation(location: CLLocation) {
		//If sounds are still loading return - JBG
		if !allSoundsLoaded() {
			return
		}
		
		for trigger in triggers {
			let distance = location.distanceFromLocation(trigger.location)
			println("Distance from trigger: \(distance)")
			if distance <= Double(trigger.radius) {
				if trigger.sound == nil && sounds.count > 0 {
					trigger.sound = sounds.removeAtIndex(0)
				} else {
					let volume = (log(distance/Double(trigger.radius)) * -1) / 4
					trigger.audioPlayer?.volume = Float(volume)
				}
			}
		}
	}
	
	func bounds() -> [CLLocationCoordinate2D] {
		var minLat: CLLocationDegrees = DBL_MAX
		var minLng: CLLocationDegrees = DBL_MAX
		var maxLat: CLLocationDegrees = 0
		var maxLng: CLLocationDegrees = 0
		
		for trigger in triggers {
			if trigger.location.coordinate.latitude < minLat {
				minLat = trigger.location.coordinate.latitude
			}
			if trigger.location.coordinate.latitude > maxLat {
				maxLat = trigger.location.coordinate.latitude
			}
			if trigger.location.coordinate.longitude < minLng {
				minLng = trigger.location.coordinate.longitude
			}
			if trigger.location.coordinate.longitude > maxLng {
				maxLng = trigger.location.coordinate.longitude
			}
		}
		return [ CLLocationCoordinate2DMake(minLat, minLng), CLLocationCoordinate2DMake(maxLat, maxLng) ]
	}
	
	func allSoundsLoaded() -> Bool {
		var allLoaded = true
		for sound in sounds {
			allLoaded = allLoaded && sound.loaded
		}
		return allLoaded
	}
	
	func isCompleted() -> Bool {
		if sounds.count != 0 {
			return false
		}
		var playing = false
		for trigger in triggers {
			if let player = trigger.audioPlayer {
				playing = playing && player.playing
			}
		}
		return !playing
	}
}
