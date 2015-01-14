//
//  ViewController.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 12-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
	
	@IBOutlet var label: UILabel!
	@IBOutlet var mapView: MKMapView!
	@IBOutlet var infoView: UIView!
	@IBOutlet var actView: UIActivityIndicatorView!
	@IBOutlet var button: UIButton!
	
	var locationManager: CLLocationManager!
	var walk: Walk = Walk()
	
	var running = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Init location manager - JBG
		self.locationManager = CLLocationManager()
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		walk.load({(success: Bool) -> Void in
			if success {
				var sounds2Load = 0
				var soundsLoaded = 0
				for area in self.walk.areas {
					sounds2Load += area.sounds.count
					
					dispatch_async(dispatch_get_main_queue(), {
						let message = "\(soundsLoaded) of \(sounds2Load) sounds loaded..."
						self.label.text = message
					})
					
					area.load({ (sound: Sound) -> Void in
						soundsLoaded += 1
						let message = "\(soundsLoaded) of \(sounds2Load) sounds loaded..."
						println(message)
						dispatch_async(dispatch_get_main_queue(), {
							self.label.text = message
							
							if soundsLoaded == sounds2Load {
								self.infoView.hidden = true
								self.actView.stopAnimating()
							}
						})
					})
				}
				
				self.addOverlays()
			} else {
				// TODO : alert the user - JBG
				println("Something went wrong")
			}
		})
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func startStop(sender: UIButton) {
		self.running = !self.running
		
		for area in walk.areas {
			for trigger in area.triggers {
				trigger.startStop(self.running)
			}
		}
		
		if self.running {
			self.button.setTitle("Stop", forState: UIControlState.Normal)
		} else {
			self.button.setTitle("Start", forState: UIControlState.Normal)
		}
	}
	
	func addOverlays() {
		for area in walk.areas {
			var points = [MKMapPoint]()
			for var i = 0; i < area.coordinates.count; i+=2 {
				let c = CLLocationCoordinate2DMake(area.coordinates[i], area.coordinates[i+1])
				points.append(MKMapPointForCoordinate(c))
			}
			let polygon = MKPolygon(points: &points, count: points.count)
			dispatch_async(dispatch_get_main_queue(), {
				self.mapView.addOverlay(polygon)
				
				// While we're at it just re-center/zoom the map - JBG
				var region = self.mapView.region
				var span = MKCoordinateSpanMake(0.01, 0.01)
				region.span = span
				region.center = self.walk.location()
				self.mapView.region = region
				
			})
		}
	}
	
	// CLLocationManagerDelegate - JBG
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		println("didFailWithError")
	}

	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		let location = locations[0] as CLLocation
		println("didUpdateLocations \(location.coordinate.latitude), \(location.coordinate.longitude)")
		
		for area in walk.areas {
			area.checkLocation(locations[0] as CLLocation)
		}
	}
	
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == CLAuthorizationStatus.Authorized {
			self.locationManager.startUpdatingLocation()
		}
	}
	
	// MKMapViewDelegate - JBG
	func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
		let polygon = overlay as MKPolygon
		let renderer = MKPolygonRenderer(polygon: polygon)
		renderer.fillColor = UIColor(red: 253.0/255.0, green: 232.0/255.0, blue: 17.0/255.0, alpha: 0.33)
		renderer.strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.9)
		renderer.lineWidth = 3
		return renderer
	}
}

