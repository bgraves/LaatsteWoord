//
//  ViewController.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 12-01-15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import AVFoundation
import CoreLocation
import MapKit
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, AVAudioPlayerDelegate {
	
	@IBOutlet var label: UILabel!
	@IBOutlet var mapView: MKMapView!
	@IBOutlet var infoView: UIView!
	@IBOutlet var actView: UIActivityIndicatorView!
	@IBOutlet var button: UIButton!
	
	var locationManager: CLLocationManager!
	var walk: Walk = Walk()
	
	var firstAudioPlayer: AVAudioPlayer!
	var lastAudioPlayer: AVAudioPlayer!
	var outOfBoundsAudioPlayer: AVAudioPlayer!
	
	var completedIntro = false
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
						++soundsLoaded
						self.updateLoadMessage(sounds2Load, soundsLoaded: soundsLoaded)
					})
				}
				
				++sounds2Load
				self.walk.firstSound.load({
					var error: NSError?
					self.firstAudioPlayer = AVAudioPlayer(data: self.walk.firstSound.data, error: &error)
					self.firstAudioPlayer.numberOfLoops = 0
					self.firstAudioPlayer.volume = 1
					self.firstAudioPlayer.delegate = self
					soundsLoaded++
					self.updateLoadMessage(sounds2Load, soundsLoaded: soundsLoaded)
				})
				
				++sounds2Load
				self.walk.lastSound.load({
					var error: NSError?
					self.lastAudioPlayer = AVAudioPlayer(data: self.walk.lastSound.data, error: &error)
					self.lastAudioPlayer.numberOfLoops = 0
					self.lastAudioPlayer.volume = 1
					self.lastAudioPlayer.delegate = self
					soundsLoaded++
					self.updateLoadMessage(sounds2Load, soundsLoaded: soundsLoaded)
				})
				
				++sounds2Load
				self.walk.outOfBoundsSound.load({
					var error: NSError?
					self.outOfBoundsAudioPlayer = AVAudioPlayer(data: self.walk.outOfBoundsSound.data, error: &error)
					self.outOfBoundsAudioPlayer.numberOfLoops = -1
					self.outOfBoundsAudioPlayer.volume = 1
					self.outOfBoundsAudioPlayer.delegate = self
					soundsLoaded++
					self.updateLoadMessage(sounds2Load, soundsLoaded: soundsLoaded)
				})
				
				
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
			area.polygon = MKPolygon(points: &points, count: points.count)
			dispatch_async(dispatch_get_main_queue(), {
				self.mapView.addOverlay(area.polygon)
				
				// While we're at it just re-center/zoom the map - JBG
				var region = self.mapView.region
				var span = MKCoordinateSpanMake(0.01, 0.01)
				region.span = span
				region.center = self.walk.location()
				self.mapView.region = region
			})
		}
	}
	
	func areaContains(area: Area, location: CLLocation) -> Bool {
		let mapPoint = MKMapPointForCoordinate(location.coordinate)
		let polygonRenderer = MKPolygonRenderer(polygon: area.polygon)
		let point = polygonRenderer.pointForMapPoint(mapPoint)
		return CGPathContainsPoint(polygonRenderer.path, nil, point, false);
	}
	
	func updateLoadMessage(sounds2Load: Int, soundsLoaded: Int) {
		let message = "\(soundsLoaded) of \(sounds2Load) sounds loaded..."
		println(message)
		dispatch_async(dispatch_get_main_queue(), {
			self.label.text = message
			
			if soundsLoaded == sounds2Load {
				self.infoView.hidden = true
				self.actView.stopAnimating()
			}
		})
	}
	
	// CLLocationManagerDelegate - JBG
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		println("didFailWithError")
	}

	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		let location = locations[0] as CLLocation
		println("didUpdateLocations \(location.coordinate.latitude), \(location.coordinate.longitude)")
		
		if !running {
			return
		}
		
		if !completedIntro {
			if self.firstAudioPlayer != nil && !self.firstAudioPlayer.playing {
				self.firstAudioPlayer.play()
			}
			return
		}
		
		var complete = true
		var inBounds = false
		for area in walk.areas {
			let areaContainsPoint = self.areaContains(area, location: location)
			if areaContainsPoint {
				area.checkLocation(locations[0] as CLLocation)
			}
			let areaComplete = area.isCompleted()
			complete = complete && areaComplete
			inBounds = inBounds || areaContainsPoint
		}
		
		if complete {
			self.lastAudioPlayer.play()
		}
		
		if !inBounds {
			println("User is out of bounds.")
			if !self.outOfBoundsAudioPlayer.playing {
				self.outOfBoundsAudioPlayer.play()
			}
		} else {
			if self.outOfBoundsAudioPlayer.playing {
				self.outOfBoundsAudioPlayer.stop()
			}
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
	
	// AVAudioPlayerDelegate - JBG
	func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
		if player == self.firstAudioPlayer {
			self.completedIntro = true
		}
	}
}

