//
//  MapPin.swift
//  HearUsHereDeux
//
//  Created by James Bryan Graves on 17/04/15.
//  Copyright (c) 2015 HearUsHere. All rights reserved.
//

import Foundation
import MapKit

class MapPin: MKPlacemark, MKAnnotation {
	var trackTitle: String?
	
	override var title:String! {
		get {
			if let trackTitle = trackTitle {
				return trackTitle
			} else {
				return "Not yet assigned"
			}
		}
	}
}
