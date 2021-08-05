//
//  UIImage+Utils.swift
//  UIImage+Utils
//
//  Created by Sébastien Hannay on 03/08/2021.
//

import Foundation
import UIKit

extension UIImage {
    
    func resized(with newSize: CGSize) -> UIImage {
        let aspectRatio = size.width/size.height
        var newSize = newSize
        newSize.height = newSize.width / aspectRatio
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(renderingMode)
    }
    
}
