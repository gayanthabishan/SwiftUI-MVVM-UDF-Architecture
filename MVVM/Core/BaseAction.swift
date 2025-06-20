//
//  ActionIdType.swift
//  MVVM
//
//  Created by Bishanm on 2025-06-08.
//

import Foundation

struct AnalyticsEventsInfo {
    let name: String
    let timeStamp: String
}

protocol AnalyticsIdentifiable {
    var analyticsEventInfo: AnalyticsEventsInfo { get }
}

extension AnalyticsIdentifiable {
    var analyticsEventInfo: AnalyticsEventsInfo {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timeStamp = formatter.string(from: Date())
        return AnalyticsEventsInfo(name: String(describing: self), timeStamp: timeStamp)
    }
}

protocol ActionIdType: Hashable, AnalyticsIdentifiable {}
protocol UIActionType: Hashable, AnalyticsIdentifiable {}
