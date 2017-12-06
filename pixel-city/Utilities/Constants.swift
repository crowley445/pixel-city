//
//  Constents.swift
//  pixel-city
//
//  Created by Brian  Crowley on 30/11/2017.
//  Copyright © 2017 Brian Crowley. All rights reserved.
//

import Foundation

typealias CompletionHandler = (_ SUCCESS: Bool) -> ()

let API_KEY = "d89452179754b46d9c21f14ed1e5a558"
let BASE_URL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key="

var RADIUS = 2
var RADIUS_UNITS = "km"

func flickrURL (withAnnotaion annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    return "\(BASE_URL)\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=\(RADIUS)&radius_units=\(RADIUS_UNITS)&per_page=\(number)&format=json&nojsoncallback=1"
}
