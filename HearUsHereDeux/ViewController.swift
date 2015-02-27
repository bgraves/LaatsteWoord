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
	
	var firstAudioPlayer: AVAudioPlayer?
	var lastAudioPlayer: AVAudioPlayer?
	var outOfBoundsAudioPlayer: AVAudioPlayer?
	
	var completedIntro = false
	var running = false
	
	var sounds2Load = 0
	var soundsLoaded = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Init location manager - JBG
		self.locationManager = CLLocationManager()
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		walk.load({(success: Bool) -> Void in
			if success {
				for area in self.walk.areas {
					self.sounds2Load += area.sounds.count
					
					dispatch_async(dispatch_get_main_queue(), { [unowned self] in
						let message = "\(self.soundsLoaded) of \(self.sounds2Load) sounds loaded..."
						self.label.text = message
					})
					
					area.load({ (sound: Sound) -> Void in
						++self.soundsLoaded
						self.updateLoadMessage()
					})
					
					for trigger in area.triggers {
						if let url = trigger.url {
							++self.sounds2Load
							let sound = Sound(resourceURL: url)
							sound.load({
								trigger.sound = sound
								++self.soundsLoaded
							})
						}
					}
				}
				
				self.initializePlayerWithSound(self.walk.firstSound, callback: { (player: AVAudioPlayer) in self.firstAudioPlayer = player })
				self.initializePlayerWithSound(self.walk.lastSound, callback: { (player: AVAudioPlayer) in self.lastAudioPlayer = player })
				self.initializePlayerWithSound(self.walk.outOfBoundsSound, callback: { (player: AVAudioPlayer) in self.outOfBoundsAudioPlayer = player })
				
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
			if !self.completedIntro {
				if let player = self.firstAudioPlayer {
					if !player.playing { player.play() }
				}
			}
		} else {
			self.button.setTitle("Start", forState: UIControlState.Normal)
			if let player = self.firstAudioPlayer {
				player.stop()
			}
			if let player = self.lastAudioPlayer {
				player.stop()
			}
			if let player = self.outOfBoundsAudioPlayer {
				player.stop()
			}
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
	
	func initializePlayerWithSound(sound: Sound, callback: (player: AVAudioPlayer) -> Void) {
		self.sounds2Load++
		sound.load({ [unowned self] in
			var error: NSError?
			if let player = AVAudioPlayer(data: sound.data, error: &error) {
				if error == nil {
					player.numberOfLoops = 0
					player.volume = 1
					player.delegate = self
					self.soundsLoaded++
					self.updateLoadMessage()
					callback(player: player)
				} else {
					self.showAlert(error!.localizedDescription)
				}
			}
		})
	}
	
	func showAlert(message: String) {
		let alert = UIAlertView()
		alert.title = "Laaste Woord"
		alert.message = message
		alert.addButtonWithTitle("OK")
		alert.show()
	}
	
	func updateLoadMessage() {
		let message = "\(soundsLoaded) of \(sounds2Load) sounds loaded..."
		dispatch_async(dispatch_get_main_queue(), { [unowned self] in
			self.label.text = message
			if self.soundsLoaded == self.sounds2Load {
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
			if let player = self.firstAudioPlayer {
				if !player.playing { player.play() }
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
			if let player = self.lastAudioPlayer {
				if !player.playing { player.play() }
			}
		}
		
		if let player = self.outOfBoundsAudioPlayer {
			if !inBounds {
				println("User is out of bounds.")
				if !player.playing { player.play() }
			} else {
				player.stop()
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
			player.stop()
		}
	}
}

