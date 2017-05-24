//
//  CMTimeExtension.swift
//  Odd-iOS
//
//  Created by Matthew Barth on 11/18/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import Foundation
import CoreMedia

extension CMTime {
  
  func formattedTime(_ needsConverting: Bool) -> Int {
    var timeValue = needsConverting ? Double(self.value) / 1000000 : Double(self.value)
    let roundedValue = timeValue.roundTimeForMetrics()
    return roundedValue
  }
  
}
