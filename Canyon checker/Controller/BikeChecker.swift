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
    
    func bike(from url: URL, completion : @escaping(Bike?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                if let source = (try? String(data: Data(contentsOf: url), encoding: .utf8))?.replacingOccurrences(of: "[\r\n]", with: "", options: .regularExpression).firstMatch(for: self.detailRegex)  {
                    let document = try SwiftSoup.parse(source)
                    
                    guard let summaryArea = try? document.select(".productDescription__productSummary").first() else {
                        completion(nil)
                        return
                    }
                    let bike = Bike()
                    if let picturePath = try? document.select(".productDetailHeader__imageColContent .productHero__pictureWrapper .productHero__picture source").first()?.attr("data-srcset"), let pictureURL = URL(string: picturePath) {
                        bike.image = try UIImage(data: Data(contentsOf:pictureURL))?.resized(with: CGSize(width: 100, height: 100))
                    }
                    
                    bike.name = try summaryArea.select(".productDescription__productName").first()?.text().trimmingCharacters(in: .whitespaces)
                    bike.type = try summaryArea.select(".productDescription__breadcrumb .breadcrumb__item").first()?.text().trimmingCharacters(in: .whitespaces)
                    bike.url = url
                    
                    let colorArea = try summaryArea.select("button.colorSwatch--selected").first()
                    bike.colorName = try colorArea?.attr("aria-label")
                    bike.colors = try colorArea?.select(".colorSwatch__color").compactMap ( { try $0.attr("style").replacingOccurrences(of: "color:", with: "").replacingOccurrences(of: ";", with: "") })
                    
                    bike.availabilities = try summaryArea.select("div.productConfiguration__sizeType").compactMap({ BikeAvailability(size: try $0.text().trimmingCharacters(in: .whitespaces), available: (try? $0.parent()?.attr("type") == "button") ?? false) })
                    bike.sizesToCheck = bike.availabilities?.compactMap( { $0.size } )
                    
                    completion(bike)
                    return
                }
                completion(nil)
            } catch {
                completion(nil)
            }
        }
    }
    
    func checkStatus(for bike: Bike, completion : @escaping([BikeAvailability]) -> Void){
        DispatchQueue.global(qos: .utility).async {
            self.checkStatusSync(for: bike, completion: completion)
        }
    }
    
    private func checkStatusSync(for bike: Bike, completion : @escaping([BikeAvailability]) -> Void){
        if let html = try? String(data: Data(contentsOf: bike.url!), encoding: .utf8)?.replacingOccurrences(of: "\n", with: "").firstMatch(for: availabilityRegex)  {
            do {
                let document = try SwiftSoup.parse(html)
                let availability = try document.select("div.productConfiguration__sizeType").compactMap({ BikeAvailability(size: try $0.text().trimmingCharacters(in: .whitespaces), available: (try? $0.parent()?.attr("type") == "button") ?? false) }).filter( { bike.sizesToCheck?.contains($0.size) ?? false } )
                completion(availability)
            } catch {
                print("Error parsing data for bike : \("bike")")
            }
        }
    }
    
    func checkAllAndNotify() {
        for bike in self.registeredBikes {
            checkStatusSync(for: bike) { bikeAvailabilities in
                bike.availabilities = bikeAvailabilities
                let availableSizes = bikeAvailabilities.filter( { $0.available == true } ).compactMap { $0.size }
                if availableSizes.count > 0 {
                    let content = UNMutableNotificationContent()
                    content.title = "New bike available"
                    content.body = "\(bike.name!) \(bike.colorName ?? "") is available in \(availableSizes.joined(separator: " and "))"
                    content.sound = UNNotificationSound.default
                    content.badge = NSNumber(value: 1)

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }
            }
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
