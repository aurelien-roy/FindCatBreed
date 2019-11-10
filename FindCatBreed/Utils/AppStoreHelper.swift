//
//  AppStoreHelper.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 10/11/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import StoreKit

class AppStoreHelper {
    
    let Defaults = UserDefaults.standard
    let APP_WORKFLOW_ENDED_COUNT = "APP_WORKFLOW_ENDED_COUNT"
    
    static let shared = AppStoreHelper()
    
    private func considerRequestingReview() {
        let count = get(key: APP_WORKFLOW_ENDED_COUNT)
        
        if count == 5 || count == 10 || (count > 0 && count % 20 == 0) {
            requestReview()
        }
    }
    
    private func requestReview() {
        SKStoreReviewController.requestReview()
    }
    
    private func get(key: String) -> Int {
        guard let counter = Defaults.value(forKey: key) as? Int else {
            Defaults.set(0, forKey: key)
            return 0
        }
        
        return counter
    }
    
    private func increment(key: String) {
        let counter = get(key: key) + 1
        Defaults.set(counter, forKey: key)
    }
    
    public func countWorkflowEnd() {
        increment(key: APP_WORKFLOW_ENDED_COUNT)
        considerRequestingReview()
    }
    
}
