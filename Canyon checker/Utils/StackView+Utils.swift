//
//  File.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import Foundation
import UIKit

extension UIStackView {
    
    func clear() {
        for view in self.arrangedSubviews {
            view.removeFromSuperview()
        }
    }
}
