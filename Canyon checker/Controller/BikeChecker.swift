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
    
    private(set) var registeredBikes = [Bike]() {
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
    
    func append(_ bike: Bike) {
        if let existingBike = registeredBikes.first(where: { $0.name == bike.name && $0.selectedColor == bike.selectedColor }) {
            existingBike.sizesToCheck = Array(Set(existingBike.sizesToCheck).union(Set(bike.sizesToCheck)))
        } else {
            registeredBikes.append(bike)
        }
    }
    
    func remove(at index : Int) {
        registeredBikes.remove(at: index)
    }
    
    func bike(from url: URL, completion : @escaping(CanyonBike?) -> Void) {
        
        // build URL
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = urlComponents?.queryItems
        queryItems?.append(URLQueryItem(name: "pid", value: urlComponents?.fileName))
        urlComponents?.queryItems = queryItems
        let queryParams = urlComponents?.percentEncodedQuery ?? "pid=\(urlComponents?.fileName ?? "")"
        let locale = Locale(identifier: urlComponents?.pathComponents?.first ?? "de-de")
        let apiURL = URL(string: "https://www.canyon.com/on/demandware.store/Sites-RoW-Site/\(locale.languageCode ?? "en")_\(locale.regionCode ?? "US")/Product-Variation?\(queryParams)&quantity=1&imageupdate=color")!
        let datatask = URLSession.shared.canyonBikeTask(with: apiURL) { (canyonBike, _, _) in
            completion(canyonBike)
        }
        datatask.resume()
    }
    
    func checkStatus(for bike: Bike, completion : @escaping(CanyonBike?) -> Void){
        if let url = bike.canyonBikeUrl {
            let datatask = URLSession.shared.canyonBikeTask(with: url) { (canyonBike, _, _) in
                completion(canyonBike)
            }
            datatask.resume()
        } else {
            completion(nil)
        }
    }
    
    func checkAllAndNotify(completion: (() -> Void)?) {
        var iterator = self.registeredBikes.makeIterator()
        var bike : Bike? = iterator.next()
        if bike != nil {
            var checkNext : (CanyonBike?) -> Void = { _ in }
            checkNext = { canyonBike in
                print("Checking for bike \(bike!.name ?? "bike") \(bike!.colorName ?? "no color")")
                let newAvailabilities = canyonBike?.availabities(for: bike?.sizesToCheck ?? [String]()) ?? [BikeAvailability]()
                let oldAvailabilities = bike?.availabilities ?? [BikeAvailability]()
                if (newAvailabilities != oldAvailabilities) {
                    var availableSize = newAvailabilities.filter( { $0.available} ).compactMap( { $0.size })
                    let content = UNMutableNotificationContent()
                    content.title = "\(bike!.name!) \(bike!.colorName!) availability changed"
                    if (availableSize.count > 0) {
                        let last = availableSize.popLast()!
                        if (availableSize.count > 0) {
                            content.body = "Now available in \(availableSize.joined(separator: ", ")) and \(last)"
                        } else {
                            content.body = "Now available in \(last)"
                        }
                    } else {
                        content.body = "Not available anymore"
                    }
                    content.sound = UNNotificationSound.default
                    content.badge = NSNumber(value: self.availableBikeCount)

                    let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: timeTrigger)
                    UNUserNotificationCenter.current().add(request)
                }
                bike?.canyonBike = canyonBike
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
    
    var availableBikeCount : Int {
        get {
            self.registeredBikes.filter( { $0.availabilities.contains(where: { $0.available == true }) } ).count
        }
    }
    
    static func registerBackgroundTask() {
        let bikeCheckerTask = BGAppRefreshTaskRequest(identifier: "canyonChecker.checkAll")
        bikeCheckerTask.earliestBeginDate = Date(timeIntervalSinceNow: 60*30)
        do {
          try BGTaskScheduler.shared.submit(bikeCheckerTask)
        } catch {
          print("Unable to submit task: \(error.localizedDescription)")
        }
    }
}
