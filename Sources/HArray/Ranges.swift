//
//  Ranges.swift
//  
//
//  Created by Hristo Doichev on 10/24/21.
//

import Foundation
///
struct HRange: Codable {
    var startIndex: Int // position for the first element
    var endIndex: Int // position directly after the last available element
    // add offset to the range
    static func +(_ lhs: HRange, _ offset: Int) -> HRange {
        return HRange(startIndex: lhs.startIndex + offset, endIndex: lhs.endIndex + offset)
    }
    //
    static func <(_ lhs: HRange, _ position: Int) -> Bool {
        return lhs.endIndex <= position
    }
    static func >(_ lhs: HRange, _ position: Int) -> Bool {
        return (position < lhs)
    }
    static func <(_ position: Int, _ rhs: HRange) -> Bool {
        return position < rhs.startIndex
    }
    static func >(_ position: Int, _ rhs: HRange) -> Bool {
        return (rhs < position)
    }
}
