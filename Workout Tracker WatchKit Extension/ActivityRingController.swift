//
//  ActivityRingController.swift
//  Workout Tracker WatchKit Extension
//
//  Created by macOS on 7/14/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import WatchKit
import HealthKit

class ActivityRingController: WKInterfaceController {

    @IBOutlet weak var activityRing: WKInterfaceActivityRing!
    
    let healthKitManager = HealthKitManager.sharedInstance
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let query = healthKitManager.createActivitySummaryQuery() {
            self.healthKitManager.activitySummaryDelegate = self
            healthKitManager.healthStore.execute(query)
        }
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}

extension ActivityRingController: ActivitySummaryDelegate {
    
    func activitySummariesUpdated(activitySummaries: [HKActivitySummary]) {
        guard let summary = activitySummaries.first else { return }
        
        DispatchQueue.main.async {
            if let activityView = self.activityRing {
                activityView.setActivitySummary(summary, animated: true)
            }
        }
    }
}
