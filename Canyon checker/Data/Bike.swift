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
    
    var image : UIImage?
    var sizesToCheck = [String]()
    var selectedColor : String?
    var canyonBike : CanyonBike? {
        didSet {
            if BikeChecker.shared.registeredBikes.contains(where: { $0.url == self.url }) {
                BikeChecker.shared.serialize()
            }
        }
    }
    
    var url : URL? {
        get {
            if let canyonBike = canyonBike, let url = URL(string: canyonBike.productData.selectedProductUrl) {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.host = "www.canyon.com"
                components?.scheme = "https"
                components?.queryItems = [URLQueryItem(name: "dwvar_\(canyonBike.id)_pv_rahmenfarbe", value: selectedColor)]
                return components?.url
            }
            return nil
        }
    }
    
    var canyonBikeUrl : URL? {
        get {
            if let url = url {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                var queryItems = urlComponents?.queryItems
                queryItems?.append(URLQueryItem(name: "pid", value: urlComponents?.fileName))
                urlComponents?.queryItems = queryItems
                let queryParams = urlComponents?.percentEncodedQuery ?? ""
                let locale = Locale(identifier: urlComponents?.pathComponents?.first ?? "de-de")
                return URL(string: "https://www.canyon.com/on/demandware.store/Sites-RoW-Site/\(locale.languageCode ?? "en")_\(locale.regionCode ?? "US")/Product-Variation?\(queryParams)")!
            }
            return nil
        }
    }
    
    var name : String? {
        get {
            canyonBike?.name
        }
    }
    
    var selectedColorInfo : Value? {
        get {
            canyonBike?.productData.variationAttributes.first(where: { $0.id == "pv_rahmenfarbe" })?.values.first(where:  { $0.id == selectedColor })
        }
    }
    
    var colorName : String? {
        get {
            selectedColorInfo?.displayValue
        }
    }
    
    var colors : [String]? {
        get {
            selectedColorInfo?.swatchColors
        }
    }
    
    var availabilities : [BikeAvailability] {
        get {
            canyonBike?.sizes?.compactMap( { BikeAvailability(size: $0.displayValue, available: $0.availability?.available ?? false) } ).filter( { sizesToCheck.contains($0.size) } ) ?? [BikeAvailability]()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case image
        case sizesToCheck
        case selectedColor
        case canyonBike
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
    
        image = try UIImage(data: values.decode(Data.self, forKey: .image))
        sizesToCheck = try values.decodeIfPresent([String].self, forKey: .sizesToCheck) ?? [String]()
        selectedColor = try values.decodeIfPresent(String.self, forKey: .selectedColor)
        canyonBike = try values.decodeIfPresent(CanyonBike.self, forKey: .canyonBike)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image?.pngData(), forKey: .image)
        try container.encode(sizesToCheck, forKey: .sizesToCheck)
        try container.encode(selectedColor, forKey: .selectedColor)
        try container.encode(canyonBike, forKey: .canyonBike)
    }
}
