//
//  ringView.swift
//  Workout Tracker
//
//  Created by macOS on 7/16/19.
//  Copyright © 2019 macOS. All rights reserved.
//

import UIKit
import HealthKitUI

class RingView: HKActivityRingView {
    
    var activitySmmry: HKActivitySummary? {
        didSet{
            setActivitySummary(activitySmmry, animated: true)
        }
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
