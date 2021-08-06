//
//  URLSession+Utils.swift
//  URLSession+Utils
//
//  Created by Sébastien Hannay on 06/08/2021.
//

import Foundation

extension URLSession {
    func codableTask<T: Codable>(with url: URL, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, response, error)
                return
            }
            completionHandler(try? newJSONDecoder().decode(T.self, from: data), response, nil)
        }
    }
}
