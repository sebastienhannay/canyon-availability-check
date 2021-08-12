//
//  CanyonCheckerTableViewController.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import UIKit

class CanyonCheckerTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        NotificationCenter.default.addObserver(forName: .bikeRefresh, object: nil, queue: nil) { notification in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        refreshJob()
    }
    
    private func refreshJob() {
        refresh()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 120) {
            self.refreshJob()
        }
    }
    
    @objc private func refresh() {
        for bike in BikeChecker.shared.registeredBikes.enumerated() {
            let indexPath = IndexPath(row: bike.offset, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as? BikeCell
            cell?.loading = true
            BikeChecker.shared.checkStatus(for: bike.element) { canyonBike in
                bike.element.canyonBike = canyonBike
                DispatchQueue.main.async {
                    cell?.loading = false
                    cell?.bike = bike.element
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
        self.tableView.refreshControl?.endRefreshing()
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BikeChecker.shared.registeredBikes.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Action to remove cell on bike list"), handler: {(action, view, completionHandler) in
            // Update data source when user taps action
            BikeChecker.shared.remove(at: indexPath.row)
            completionHandler(true)
          })

          let configuration = UISwipeActionsConfiguration(actions: [action])
          return configuration
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bike = BikeChecker.shared.registeredBikes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BikeCell", for: indexPath) as! BikeCell
        cell.bike = bike
        cell.loading = false
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bike = BikeChecker.shared.registeredBikes[indexPath.row]
        if let url = bike.url {
            UIApplication.shared.open(url)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
}
