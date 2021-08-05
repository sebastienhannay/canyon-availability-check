//
//  NSRegularExpression+Utils.swift
//  NSRegularExpression+Utils
//
//  Created by Sébastien Hannay on 05/08/2021.
//

import Foundation

extension String {
    
    func firstMatch(for regex: String) -> String? {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            if let results = regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)) {
                return String(self[Range(results.range, in: self)!])
            }
            return nil
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return nil
        }
    }
    
}
