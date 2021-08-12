//
//  CanyonBike.swift
//  CanyonBike
//
//  Created by Sébastien Hannay on 06/08/2021.
//


// To read values from URLs:
//
//   let task = URLSession.shared.canyonBikeTask(with: url) { canyonBike, response, error in
//     if let canyonBike = canyonBike {
//       ...
//     }
//   }
//   task.resume()

import Foundation
import UIKit

// MARK: - CanyonBike
class CanyonBike: Codable {
    let productData: ProductData
    let gtmModel: GtmModel
    
    var id : String {
        get {
            return productData.id
        }
    }
    
    var url : String? {
        get {
            selectedColorInfo?.configurationUrl
        }
    }
    
    var imageUrl : URL? {
        get {
            if let fullUrl = selectedColorInfo?.images?.bikeTile.first?.urls.sm {
                let detailUrl = fullUrl.replacingOccurrences(of: "full/full_(\\d{3})\\d_/(\\d{4})/full", with: "detail/detail_$1/$2/detail", options: .regularExpression)
                    .replacingOccurrences(of: "_/full", with: "detail")
                if let url = URL(string: detailUrl), var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    urlComponents.queryItems = [
                        URLQueryItem(name: "sw", value: String(100 * UIScreen.main.scale)),
                        URLQueryItem(name: "sh", value: String(100 * UIScreen.main.scale)),
                        URLQueryItem(name: "sm", value: "cut"),
                        URLQueryItem(name: "sfrm", value: "png")
                    ]
                    return urlComponents.url
                }
            }
            return nil
        }
    }
    
    var name : String? {
        get {
            productData.productName
        }
    }
    
    var selectedColorInfo : Value? {
        get {
            productData.variationAttributes.first(where: { $0.id == "pv_rahmenfarbe" })?.values.first(where:  { $0.selected == true })
        }
    }
    
    private var selectedColor : String? {
        selectedColorInfo?.id
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
    
    var sizes : [Value]? {
        get {
            productData.variationAttributes.first(where: { $0.id == "pv_rahmengroesse" })?.values
        }
    }
    
    var sizeIds : [String]? {
        get {
            productData.variationAttributes.first(where: { $0.id == "pv_rahmengroesse" })?.values.compactMap( { $0.displayValue })
        }
    }
    
    func availabities(for sizes : [String]) -> [BikeAvailability] {
        return self.sizes?.compactMap( { BikeAvailability(size: $0.displayValue, available: $0.availability?.available ?? false) } ).filter( { sizes.contains($0.size) } ) ?? [BikeAvailability]()
    }
    
}


// MARK: - GtmModel
struct GtmModel: Codable {
    let ecommerce: Ecommerce
}


// MARK: - Ecommerce
struct Ecommerce: Codable {
    let detail: Detail
    let currencyCode: String
}


// MARK: - Detail
struct Detail: Codable {
    let products: [Product]
}


// MARK: - Product
struct Product: Codable {
    let name, category, dimension50, dimension51: String
    let dimension52, metric4: String
}


// MARK: - ProductData
struct ProductData: Codable {
    let id: String
    let variationAttributes: [VariationAttribute]
    let productName: String
    let selectedProductUrl: String
}

// MARK: - VariationAttribute
struct VariationAttribute: Codable {
    let id, displayName: String
    let values: [Value]
}


// MARK: - Value
struct Value: Codable {
    let id, displayValue: String
    let selected: Bool
    let configurationUrl: String?
    let swatchColors: [String]?
    let images: Images?
    let availability: Availability?
}

// MARK: - Availability
struct Availability: Codable {
    let messages: [String]
    let inStockDate: String?
    let available: Bool
}

// MARK: - Images
struct Images: Codable {
    let bikeTile: [BikeTile]
}

// MARK: - BikeTile
struct BikeTile: Codable {
    let urls: Urls
}

// MARK: - Urls
struct Urls: Codable {
    let sm: String
}


// MARK: - URLSession response handlers

extension URLSession {
    
    func canyonBikeTask(with url: URL, completionHandler: @escaping (CanyonBike?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
    
}

