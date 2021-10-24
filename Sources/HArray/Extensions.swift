//
//  Extensions.swift
//  
//
//  Created by Hristo Doichev on 10/23/21.
//

import Foundation

extension Array: Storable, StorableAllocator where Array.Element: Codable {
    
    public func createStore(capacity: Int) -> Array<Element> {
        return Array()
    }
    
    public typealias Storage = Array
    public mutating func replace(with elements: [Element]) {
        self = elements
    }
    public mutating func append(_ elements: [Element]) {
        self += elements
    }
    public mutating func split(at position: Int) -> Array<Element> {
        let r = Array(self[position..<self.count])
        self = Array(self[0..<position])
        return r
    }
}
