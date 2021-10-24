//
//  Extensions.swift
//  
//
//  Created by Hristo Doichev on 10/23/21.
//

import Foundation
///
extension Array: StorableAllocator where Array.Element: Codable {
    public typealias Storage = Array
    public func createStore(capacity: Int) -> Array<Element> {
        return Array()
    }
}
///
extension Array: Storable where Array.Element: Codable {
    public mutating func replace(with elements: [Element]) {
        self = elements
    }
    public mutating func append(_ elements: [Element]) {
        self += elements
    }
}
