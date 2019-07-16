//
//  ViewController.swift
//  Workout Tracker
//
//  Created by macOS on 7/14/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import HealthKit
import HealthKitUI

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var activityRingView: RingView!
    
    var datasource = [HKQuantitySample]()
    
    var heartRateQuery: HKQuery?
    
    let healthKitManager = HealthKitManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        healthKitManager.authorizeHealthKit { (success, _ ) in
            print("Was healthKit authorization successful? \(success)")
            self.retrieveHeartRateData()
            self.retrieveActivitySummaryData()
        }
    }
    
    func retrieveHeartRateData() {
        
        if let query = healthKitManager.createHeartRateStreamingQuery(Date()) {
            self.heartRateQuery = query
            self.healthKitManager.heartRateDelegate = self
            self.healthKitManager.healthStore.execute(query)
        }
    }
    
    func retrieveActivitySummaryData() {
        if let query = healthKitManager.createActivitySummaryQuery() {
            self.healthKitManager.activitySummaryDelegate = self
            self.healthKitManager.healthStore.execute(query)
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "heartRateCell", for: indexPath)
        cell.textLabel?.text = "\(datasource[indexPath.row].quantity)"
        return cell
    }
}

extension ViewController: HeartRateDelegate {
    
    func heartRateUpdated(heartRateSamples: [HKSample]) {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else { return }
        DispatchQueue.main.async {
            self.datasource.append(contentsOf: heartRateSamples)
            self.tableView.reloadData()
        }
    }
}

extension ViewController: ActivitySummaryDelegate {
    
    func activitySummariesUpdated(activitySummaries: [HKActivitySummary]) {
        
        guard let summary = activitySummaries.first else { return }
        
        DispatchQueue.main.async {
            if let activityView = self.activityRingView {
                activityView.activitySmmry = summary
            }
        }
    }
}
