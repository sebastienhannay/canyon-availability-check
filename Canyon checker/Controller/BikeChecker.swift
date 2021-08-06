//
//  BikeChecker.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import Foundation
import SwiftSoup
import UserNotifications
import UIKit
import BackgroundTasks

extension Notification.Name {
    static let bikeRefresh = Notification.Name("bikeRefresh")
}

private let bikeFileURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("registered_bikes.json")

class BikeChecker {
    
    private let detailRegex = "<section class=\"productDetailHeader__row productDetailHeader__row--mainContent\">.+?js-productDefectsNewCondition.+?section>"
    private let availabilityRegex = "<ul class=\"productConfiguration__options \">.+?ul>"
    
    static let shared = BikeChecker()
    
    var registeredBikes = [Bike]() {
        didSet {
            serialize()
            NotificationCenter.default.post(name: .bikeRefresh, object: nil)
        }
    }

    private init() {
        registeredBikes = (try? JSONDecoder().decode([Bike].self, from: Data(contentsOf: bikeFileURL))) ?? [Bike]()
    }
    
    func serialize() {
        try? JSONEncoder().encode(registeredBikes).write(to: bikeFileURL, options: .atomic)
    }
    
    func bike(from url: URL, completion : @escaping(CanyonBike?) -> Void) {
        
        // build URL
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = urlComponents?.queryItems
        queryItems?.append(URLQueryItem(name: "pid", value: urlComponents?.fileName))
        urlComponents?.queryItems = queryItems
        let queryParams = urlComponents?.percentEncodedQuery ?? ""
        let locale = Locale(identifier: urlComponents?.pathComponents?.first ?? "de-de")
        let apiURL = URL(string: "https://www.canyon.com/on/demandware.store/Sites-RoW-Site/\(locale.languageCode ?? "en")_\(locale.regionCode ?? "US")/Product-Variation?\(queryParams)")!
        let datatask = URLSession.shared.canyonBikeTask(with: apiURL) { (canyonBike, _, _) in
            completion(canyonBike)
        }
        datatask.resume()
    }
    
    func checkStatus(for bike: Bike, completion : @escaping([BikeAvailability]) -> Void){
        if let url = bike.canyonBikeUrl {
            let datatask = URLSession.shared.canyonBikeTask(with: url) { (canyonBike, _, _) in
                bike.canyonBike = canyonBike ?? bike.canyonBike
                completion(bike.availabilities)
            }
            datatask.resume()
        } else {
            completion(bike.availabilities)
        }
    }
    
    func checkAllAndNotify(completion: (() -> Void)?) {
        var iterator = self.registeredBikes.makeIterator()
        var bike : Bike? = iterator.next()
        if bike != nil {
            var checkNext : ([BikeAvailability]) -> Void = { _ in }
            checkNext = { bikeAvailabilities in
                print("Checking for bike \(bike!.name ?? "bike") \(bike!.colorName ?? "no color")")
                let availableSizes = bikeAvailabilities.filter( { $0.available == true } ).compactMap { $0.size }
                if availableSizes.count > 0 {
                    let content = UNMutableNotificationContent()
                    content.title = "New bike available"
                    content.body = "\(bike!.name!) \(bike!.colorName ?? "") is available in \(availableSizes.joined(separator: " and "))"
                    content.sound = UNNotificationSound.default
                    content.badge = NSNumber(value: 1)

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }
                bike = iterator.next()
                if bike != nil {
                    self.checkStatus(for: bike!, completion: checkNext)
                } else {
                    completion?()
                }
            }
            checkStatus(for: bike!, completion: checkNext)
        }
    }
    
    static func registerBackgroundTask() {
        let bikeCheckerTask = BGAppRefreshTaskRequest(identifier: "canyonChecker.checkAll")
        bikeCheckerTask.earliestBeginDate = Date(timeIntervalSinceNow: 60*15)
        do {
          try BGTaskScheduler.shared.submit(bikeCheckerTask)
        } catch {
          print("Unable to submit task: \(error.localizedDescription)")
        }
    }
}
