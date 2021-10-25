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
        var a = Array()
        a.reserveCapacity(capacity)
        return a
    }
}
///
extension Array: Storable where Array.Element: Codable {
    public typealias Allocator = Array<Element>
    
    public var allocator: Array<Element>? {
        get { Array<Element>() }
        set {}
    }
    
    public mutating func replace(with elements: [Element]) {
        var a = Array()
        a.reserveCapacity(self.capacity)
        a += elements
        self = a
//        print("self.capacity: ", self.capacity)
    }
    public mutating func append(_ elements: [Element]) {
        self += elements
    }
}
