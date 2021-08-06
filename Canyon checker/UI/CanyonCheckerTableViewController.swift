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
        self.refreshControl?.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        NotificationCenter.default.addObserver(forName: .bikeRefresh, object: nil, queue: nil) { notification in
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func reloadData() {
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
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
            BikeChecker.shared.registeredBikes.remove(at: indexPath.row)
            completionHandler(true)
          })

          let configuration = UISwipeActionsConfiguration(actions: [action])
          return configuration
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bike = BikeChecker.shared.registeredBikes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BikeCell", for: indexPath) as! BikeCell
        cell.bike = bike
        
        if let _ = bike.url {
            cell.loading = true
            BikeChecker.shared.checkStatus(for: bike) { availability in
                DispatchQueue.main.async {
                    cell.loading = false
                    cell.bike = bike
                }
            }
        }

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
