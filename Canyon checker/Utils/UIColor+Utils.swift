//
//  UIColor+Utils.swift
//  UIColor+Utils
//
//  Created by Sébastien Hannay on 03/08/2021.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex:String) {
        let hex = hex.lowercased().replacingOccurrences(of: "#", with: "0x")
        var colorInt: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&colorInt)
        self.init(red: CGFloat((colorInt & 0xFF0000) >> 16) / 255.0, green: CGFloat((colorInt & 0xFF00) >> 8) / 255.0, blue: CGFloat(colorInt & 0xFF) / 255.0, alpha: 1.0)
    }
}
