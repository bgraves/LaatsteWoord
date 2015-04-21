//
//  Walk.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 13-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit

class Walk {
	
	let requestURL = "http://hearushere.nl/triggers.json"
	var areas: [Area]!
	
	var coordinates: [Double]
	var polygon: MKPolygon!
	
	var firstSound: Sound!
	var lastSound: Sound!
	var outOfBoundsSound: Sound!
	
	init() {
		areas = []
		coordinates = []
	}
	
	func load(completionHandler:(Bool) -> Void) {
		var request : NSMutableURLRequest = NSMutableURLRequest()
		request.URL = NSURL(string: self.requestURL)
		request.HTTPMethod = "GET"
		request.cachePolicy = .ReloadIgnoringLocalCacheData
		
		NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(),
			completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
				if nil == error {
					let responseStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
					println("RESPONSE: " + (responseStr! as String))
					
					var error: NSError?
					var walkDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
					var areaDicts = walkDict["areas"] as! NSArray
					for areaDict in areaDicts {
						var area: Area = Area(dict: areaDict as! NSDictionary)
						self.areas.append(area)
					}
					self.firstSound = Sound(dict: walkDict["firstSound"] as! NSDictionary)
					self.lastSound = Sound(dict: walkDict["lastSound"] as! NSDictionary)
					self.outOfBoundsSound = Sound(dict: walkDict["outOfBoundsSound"] as! NSDictionary)
					
					var coordinates: NSArray = walkDict["displayCoords"] as! NSArray
					for coordinate in coordinates {
						self.coordinates.append(coordinate as! Double)
					}
					
					var points = [MKMapPoint]()
					for var i = 0; i < self.coordinates.count; i+=2 {
						let c = CLLocationCoordinate2DMake(self.coordinates[i], self.coordinates[i+1])
						points.append(MKMapPointForCoordinate(c))
					}
					self.polygon = MKPolygon(points: &points, count: points.count)
					
					completionHandler(true)
				} else {
					completionHandler(false)
				}
		})
	}
	
	func location() -> CLLocationCoordinate2D {
		
		var minLat: CLLocationDegrees = DBL_MAX
		var minLng: CLLocationDegrees = DBL_MAX
		var maxLat: CLLocationDegrees = 0
		var maxLng: CLLocationDegrees = 0
		
		for area in self.areas {
			let bounds = area.bounds()
			if bounds[0].latitude < minLat {
				minLat = bounds[0].latitude
			}
			
			if bounds[0].longitude < minLng {
				minLng = bounds[0].longitude
			}
			
			if bounds[1].latitude > maxLat {
				maxLat = bounds[1].latitude
			}
			
			if bounds[1].longitude > maxLng {
				maxLng = bounds[1].longitude
			}
		}
		
		let avgLat = (maxLat + minLat) / 2
		let avgLng = (maxLng + minLng) / 2
		
		return CLLocationCoordinate2DMake(avgLat, avgLng)
	}
}