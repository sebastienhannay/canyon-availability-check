//
//  URLComponents+Utils.swift
//  URLComponents+Utils
//
//  Created by Sébastien Hannay on 06/08/2021.
//

import Foundation

extension URLComponents {
    
    var fileName : String? {
        get {
            var fileName = pathComponents?.last?.split(separator: ".")
            fileName?.removeLast()
            return fileName?.joined(separator: ".")
        }
    }
    
    var pathComponents : [String]? {
        get {
            path.split(separator: "/").compactMap( { String($0) } )
        }
    }
    
}
