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
    var maxIndex: Int // position directly after the maximum element index
    // add offset to the range
    static func +(_ lhs: HRange, _ offset: Int) -> HRange {
        return HRange(startIndex: lhs.startIndex + offset, endIndex: lhs.endIndex + offset, maxIndex: lhs.maxIndex)
    }
    //
    // If the endIndex < maxIndex then an item can be inserted with range (startIndex - 1...endIndex)
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
///
struct HInsertRange: Codable {
    var hr: HRange
    var hasFreeSpace: Bool { hr.endIndex < hr.maxIndex }
    var startIndex: Int { hr.startIndex }
    var endIndex: Int { hr.endIndex }
    //
    init(_ hr: HRange) {
        self.hr = hr
    }
    // add offset to the range
    static func +(_ lhs: HInsertRange, _ offset: Int) -> HInsertRange {
        return HInsertRange(HRange(startIndex: lhs.hr.startIndex + offset,
                                   endIndex: lhs.hr.endIndex + offset,
                                   maxIndex: lhs.hr.maxIndex))
    }
    static func <(_ lhs: HInsertRange, _ position: Int) -> Bool {
        if lhs.hr.endIndex != lhs.hr.maxIndex {
            return lhs.hr.endIndex < position
        }
        return lhs.hr.endIndex <= position
    }
    static func >(_ lhs: HInsertRange, _ position: Int) -> Bool {
        return (position < lhs)
    }
    static func <(_ position: Int, _ rhs: HInsertRange) -> Bool {
        return position < rhs.startIndex
    }
    static func>(_ position: Int, _ rhs: HInsertRange) -> Bool{
        return (rhs < position)
    }
}
