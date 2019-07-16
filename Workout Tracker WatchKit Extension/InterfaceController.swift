//
//  InterfaceController.swift
//  Workout Tracker WatchKit Extension
//
//  Created by macOS on 7/14/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var workoutButton: WKInterfaceButton!
    
    let healthKitManager = HealthKitManager.sharedInstance
    var workoutSession: HKWorkoutSession?
    var isWorkoutInProgress = false
    var workoutStartDate: Date?
    var heartRateQuery: HKQuery?
    var heartRateSamples = [HKQuantitySample]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        workoutButton.setEnabled(false)
        healthKitManager.authorizeHealthKit { (success, _) in
            print("Was healthkit authorization successful? \(success)")
            self.workoutButton.setEnabled(true)
            self.createWorkoutSession()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startOrStopWorkout() {
        
        if isWorkoutInProgress {
            endWorkoutSession()
            workoutSession = nil
        } else {
            startWorkoutSession()
        }
        isWorkoutInProgress = !isWorkoutInProgress
        workoutButton.setTitle(isWorkoutInProgress ? "End Workout" : "Start Workout")
    }
    
    func createWorkoutSession() {
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
            workoutSession?.delegate = self
        } catch {
            print("Exception thrown")
        }
    }
    
    func startWorkoutSession() {
        
        if nil == workoutSession {
            createWorkoutSession()
        }
        guard let session = workoutSession else { return }
        healthKitManager.healthStore.start(session)
        self.workoutStartDate = Date()
    }
    
    func endWorkoutSession() {
        guard let session = workoutSession else { return }
        healthKitManager.healthStore.end(session)
        saveWorkout()
    }
    
    func saveWorkout() {
        
        guard let startDate = workoutStartDate else { return }
        let workout = HKWorkout(activityType: .other, start: startDate, end: Date())
        healthKitManager.healthStore.save(workout) { [weak self] (success, _) in
            print("Was saving successful? \(success)")
            guard let samples = self?.heartRateSamples else { return }
            self?.healthKitManager.healthStore.add(samples, to: workout, completion: { (success, _) in
                if success {
                    print("Successfully saved heart rate samples.")
                }
            })
        }
    }
}

extension InterfaceController: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            guard let workoutStartDate = workoutStartDate else { return }
            if let query = self.healthKitManager.createHeartRateStreamingQuery(workoutStartDate) {
                self.heartRateQuery = query
                self.healthKitManager.heartRateDelegate = self
                self.healthKitManager.healthStore.execute(query)
            }
        case .ended:
            if let query = self.heartRateQuery {
                self.healthKitManager.healthStore.stop(query)
            }
        default: break
            
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout failed with error: \(error)")
    }
}

extension InterfaceController: HeartRateDelegate {
    func heartRateUpdated(heartRateSamples: [HKSample]) {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else { return }
        DispatchQueue.main.async {
            self.heartRateSamples = heartRateSamples
            guard let sample = heartRateSamples.first else { return }
            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            let heartRateString = String(format: "%.00f", value)
            self.heartRateLabel.setText(heartRateString)
        }
    }
}
