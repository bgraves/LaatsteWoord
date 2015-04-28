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
		var triggerDicts: NSArray = dict["triggers"] as! NSArray
		for triggerDict in triggerDicts {
			var trigger: GPSTrigger = GPSTrigger(dict: triggerDict as! NSDictionary)
			self.triggers.append(trigger)
		}
		
		var soundDicts: NSArray = dict["sounds"] as! NSArray
		for soundDict in soundDicts {
			var sound: Sound = Sound(dict: soundDict as! NSDictionary)
			self.sounds.append(sound)
		}
		
		var coordinates: NSArray = dict["coords"] as! NSArray
		for coordinate in coordinates {
			self.coordinates.append(coordinate as! Double)
		}
		
		// We need the polygon to check if the user is in a area - JBG
		var points = [MKMapPoint]()
		for var i = 0; i < coordinates.count; i+=2 {
			let c = CLLocationCoordinate2DMake(coordinates[i] as! CLLocationDegrees, coordinates[i+1] as! CLLocationDegrees)
			points.append(MKMapPointForCoordinate(c))
		}
		polygon = MKPolygon(points: &points, count: points.count)
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
			if !trigger.checkArea || contains(location) {
				let distance = location.distanceFromLocation(trigger.location)
				println("Distance from trigger: \(distance)")
				if distance <= Double(trigger.radius) {
					if trigger.sound == nil && sounds.count > 0 {
						trigger.sound = sounds.removeAtIndex(0)
						trigger.audioPlayer?.numberOfLoops = 0
						trigger.checkArea = true
					} else {
						var volume = -(1/pow(Double(trigger.radius), 2)) * pow(distance, 2) + 1
						volume = min(volume, 1)
						volume = max(volume, 0)
						//let volume = (log(distance/Double(trigger.radius)) * -1) / 4
						trigger.audioPlayer?.volume = Float(volume)
					}
				} else {
					trigger.audioPlayer?.volume = 0
				}
			} else {
				trigger.audioPlayer?.volume = 0
			}
		}
	}
	
	func contains(location: CLLocation) -> Bool {
		let mapPoint = MKMapPointForCoordinate(location.coordinate)
		let polygonRenderer = MKPolygonRenderer(polygon: polygon)
		let point = polygonRenderer.pointForMapPoint(mapPoint)
		return CGPathContainsPoint(polygonRenderer.path, nil, point, false);
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
			if let player = trigger.audioPlayer where trigger.checkArea {
				playing = playing || player.playing
			}
		}
		return !playing
	}
}
