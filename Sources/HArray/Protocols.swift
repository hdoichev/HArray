//
//  Protocols.swift
//  
//
//  Created by Hristo Doichev on 10/23/21.
//

import Foundation

///
public protocol StorableAllocator {
    associatedtype Storage
    func createStore(capacity: Int) -> Storage?
}
///
public protocol Storable: MutableCollection, Codable  {
    associatedtype StorageAllocator
    var capacity: Int { get }
    var allocator: StorageAllocator? { get set }
    mutating func replace(with elements: [Element])
    mutating func append(_ elements: [Element])
    mutating func append(_ element: Element)
    mutating func insert(_ element: Element, at position: Int)
    mutating func remove(at: Int) -> Element
}
