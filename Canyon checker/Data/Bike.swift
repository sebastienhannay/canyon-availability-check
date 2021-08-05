//
//  Bike.swift
//  Bike
//
//  Created by Sébastien Hannay on 03/08/2021.
//

import UIKit

struct BikeAvailability : Codable {
    var size : String
    var available : Bool
    
    init(size : String, available : Bool) {
        self.size = size
        self.available = available
    }
}

class Bike: Codable {
    var name : String?
    var colorName : String?
    var url : URL?
    var image : UIImage?
    var colors : [String]?
    var sizesToCheck : [String]? {
        didSet {
            availabilities = availabilities?.filter( { sizesToCheck?.contains($0.size) ?? false })
        }
    }
    var type : String?
    var availabilities : [BikeAvailability]? {
        didSet {
            if BikeChecker.shared.registeredBikes.contains(where: { $0.url == self.url }) {
                BikeChecker.shared.serialize()
            }
        }
    }
    var otherColor : (colorName : String, colors : [String], url: URL)?
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case image
        case colors
        case sizesToCheck
        case availabilities
        case type
        case colorName
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        url = try values.decodeIfPresent(URL.self, forKey: .url)
        image = try UIImage(data: values.decode(Data.self, forKey: .image))
        colors = try values.decodeIfPresent([String].self, forKey: .colors)
        sizesToCheck = try values.decodeIfPresent([String].self, forKey: .sizesToCheck)
        availabilities = try values.decodeIfPresent([BikeAvailability].self, forKey: .availabilities)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        colorName = try values.decodeIfPresent(String.self, forKey: .colorName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(image?.pngData(), forKey: .image)
        try container.encode(colors, forKey: .colors)
        try container.encode(sizesToCheck, forKey: .sizesToCheck)
        try container.encode(availabilities, forKey: .availabilities)
        try container.encode(colorName, forKey: .colorName)
    }
}
