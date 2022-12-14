//
//  HArray.swift
//
//
//  Created by Hristo Doichev on 10/16/21.
//

import Foundation

enum HArrayErrors: Error {
    case AllocationFailed
}

/// Array intended for usage where fast insertion and removal of items in the middle of the array is of importance.
///
///
public final class HArray<DataAllocator: StorableAllocator>: Codable, MutableCollection
where DataAllocator.Storage: Storable,
        DataAllocator.Storage.Element: Codable,
        DataAllocator.Storage.Index == Int,
        DataAllocator.Storage.StorageAllocator == DataAllocator {
    public final var startIndex: Int { return 0 }
    
    public final var endIndex: Int { return _count }
    
    public typealias Element = DataAllocator.Storage.Element
    public typealias Index = Int
    public final func index(after i: Int) -> Int { return i + 1 }
    
    public typealias Node = HNode<DataAllocator>
    public enum TraverseStyle {
        case InOrder
        case PreOrder
        case PostOrder
    }
    final var _root: Node?
    final let _maxElementsPerNode: Int
    final var _count: Int = 0
    final var _allocator: DataAllocator?
    
    enum CodingKeys: String, CodingKey {
        case root
        case maxElementsPerNode
        case count
    }
    ///  The _allocator would not be restored from the decoded data and this must be explicitly
    ///  set after this init return.
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _root = try? values.decode(Node.self, forKey: .root)
        _maxElementsPerNode = try values.decode(Int.self, forKey: .maxElementsPerNode)
        _count = try values.decode(Int.self, forKey: .count)
        _allocator = nil
    }
    public final func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_root, forKey: .root)
        try container.encode(_maxElementsPerNode, forKey: .maxElementsPerNode)
        try container.encode(_count, forKey: .count)
    }
    ///
    public final var count: Int { _count }
    public final var allocator: DataAllocator? {
        get { _allocator }
        set { _allocator = newValue
            traverse(style: .InOrder) { hnode, startIndex, depth in
                hnode._data.allocator = _allocator
            }
        }
    }
    ///
    public init(maxElementsPerNode: Int = 32, allocator: DataAllocator) {
        _allocator = allocator
        _root = nil
        _maxElementsPerNode = maxElementsPerNode
    }
    ///
    final func _visitNodes(for position: Int, current curNode: Node, parent parentNode: Node, runningSum: Int,
                     visitor:(Node/*current*/, Node/*parent*/, Bool/*found*/)->Void) {
        let curRange = curNode.getFindRange(runningSum)
        if position > curRange {
            guard let rightNode = curNode.right else { return }
            _visitNodes(for: position, current: rightNode, parent: curNode, runningSum: curRange.endIndex, visitor: visitor)
            visitor(curNode, parentNode, false)
            return
        } else if position < curRange {
            guard let leftNode = curNode.left else { return }
            _visitNodes(for: position, current: leftNode, parent: curNode, runningSum: curRange.startIndex, visitor: visitor)
            visitor(curNode, parentNode, false)
            return
        } else {
            visitor(curNode, parentNode, true)
        }
    }
    ///
    final func _findNode(for position: Int, starting node: Node, runningSum: Int) -> (Node?, Bool, HRange) {
        let findRange = node.getFindRange(runningSum)
        if position > findRange {
            guard let rightNode = node.right else { return (node, false, findRange) }
            return _findNode(for: position, starting: rightNode, runningSum: findRange.endIndex)
        } else if position < findRange {
            guard let leftNode = node.left else { return (node, false, findRange) }
            return _findNode(for: position, starting: leftNode, runningSum: findRange.startIndex /*- node._key*/)
        } else {
            return (node, true, findRange)
        }
    }
    ///
    public final func findNode(for position: Int) -> Node? {
        guard let root = _root else { return nil }
        return _findNode(for: position, starting: root, runningSum: 0).0
    }
    ///
    final func allocate() throws -> DataAllocator.Storage {
        guard let allocator = _allocator else { fatalError("Allocator is nil") }
        guard let store = allocator.createStore(capacity: _maxElementsPerNode) else { throw HArrayErrors.AllocationFailed}
        return store
    }
    ///
    private final func addNode(for position: Int, starting node: Node?, element: DataAllocator.Storage.Element, runningSum: Int) -> Node? {
        guard let node = node else {
            guard var storage = try? allocate() else { return nil }
            storage.append(element)
            return Node(key: 0, 
                        height: 1,
                        data: storage,
                        left: nil,
                        right: nil)
        }
        let curInsertRange = node.getFindRange(runningSum)
        
        if position > curInsertRange.endIndex {
            node.rightUpdateAdd = addNode(for: position, starting: node.right, element:element, runningSum: curInsertRange.endIndex )
        } else if position < curInsertRange.startIndex {
            node.leftUpdateAdd = addNode(for: position, starting: node.left, element:element, runningSum: curInsertRange.startIndex)
        } else {
            // Update the current node.
            // If the current node can store more data then add the data to the Node and update the position offsets.
            // Otherwise add a new node and update the chain of nodes/
            // The new node becomes the left of the current, and if the current had a prior left then
            // that one become the left of the new node.
            if node.insert(data: element, at: position - curInsertRange.startIndex) == false {
                if position == curInsertRange.startIndex {
                    node.leftUpdateAdd = addNode(for: position, starting: node.left, element:element, runningSum: curInsertRange.startIndex)
                } else if position == curInsertRange.endIndex {
                    node.rightUpdateAdd = addNode(for: position, starting: node.right, element:element, runningSum: curInsertRange.endIndex)
                } else {
                    guard var storage = try? allocate() else { return nil /** TODO: Is this the best way to go??? */}
                    storage.append(Array(node._data[(node._data.count/2..<node._data.count)]))
                    // split the current node
                    let splitRight = Node(key: 0,
                                          height: (node.right != nil) ? node.right!._height+1: 1,
                                          data: storage,
                                          left: nil,
                                          right: node.right)
                    node.right = splitRight
                    node._data.replace(with: Array(node._data[0..<node._data.count/2]))
                    // The current node was split into two, but the data was not yet added.
                    // Recurse using the current node, the data will find its position since there is enough space.
                    if let n = addNode(for: position, starting: node, element:element, runningSum: runningSum) {
                        return balanceNode(n, position, curInsertRange)
                    }
                    return nil // fatalError ???
                }
            }
            return balanceNode(node, position, curInsertRange)
        }
        
        return balanceNode(node, position, curInsertRange)
    }
    ///
    final func removeElement(at position: Int, starting node: Node?, runningSum: Int) -> (Element,Node?) {
        guard let node = node else { fatalError("Invalid object") }
        let findRange = node.getFindRange(runningSum)
        var element: Element
        if position > findRange {
            (element, node.rightUpdateRemove) = removeElement(at: position, starting: node.right, runningSum: findRange.endIndex)
            if node.right?._data.count == 0 {
                node.right = node.right!.combineChildren(as: .AsRight)
            }
        } else if position < findRange {
            (element, node.leftUpdateRemove) = removeElement(at: position, starting: node.left, runningSum: findRange.startIndex)
            if node.left?._data.count == 0 {
                node.left = node.left!.combineChildren(as: .AsLeft)
            }
        } else {
            let e = node.remove(at: position - findRange.startIndex) //else { fatalError("Unable to remove data at: \(position)") }
            guard node._data.count == 0 else { return (e, node) }
            if node === _root {
                return (e, node.combineChildren(as: .AsRight))
            }
            return (e, node)
        }
        return (element, balanceNode(node, position, findRange))
    }
    ///
    final func _traverseInOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        if let left = node.left { _traverseInOrder(left, findRange.startIndex, depth + 1, block) }
        block(node, findRange.startIndex, depth)
        if let right = node.right { _traverseInOrder(right, findRange.endIndex, depth + 1, block) }
    }
    final func _traversePreOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        block(node, findRange.startIndex, depth)
        if let left = node.left { _traversePreOrder(left, findRange.startIndex, depth + 1, block) }
        if let right = node.right { _traversePreOrder(right, findRange.endIndex, depth + 1, block) }
    }
    final func _traversePostOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        if let left = node.left { _traversePostOrder(left, findRange.startIndex, depth + 1, block) }
        if let right = node.right { _traversePostOrder(right, findRange.endIndex, depth + 1, block) }
        block(node, findRange.startIndex, depth)
    }
    public final func traverse(style: TraverseStyle, _ block:(Node,Int,Int)->Void) {
        guard let root = _root else { return }
        switch style {
        case .InOrder: _traverseInOrder(root, 0, 0, block)
        case .PreOrder: _traversePreOrder(root, 0, 0, block)
        case .PostOrder: _traversePostOrder(root, 0, 0, block)
        }
    }
    public final var height: Int { //}(Int,Int) {
        guard let root = _root else { return 0 }
        return root.height
    }
}

extension HArray {
    public final subscript(position: Int) -> DataAllocator.Storage.Element {
        get {
            return getData(at: position)!
        }
        set(newValue) {
            guard let root = _root else { fatalError("Invalid position") }
            let r = _findNode(for: position, starting: root, runningSum: 0)
            guard r.1 else { fatalError("Invalid position") }
//            guard (r.2.startIndex..<r.2.endIndex).contains(position) else { fatalError("Invalid position") /*TODO: This should throw...dohhhh */}
            guard let node = r.0 else { fatalError("Invalid position") }
            node._data[position - r.2.startIndex] = newValue
        }
    }
    public final func append(_ element: DataAllocator.Storage.Element) {
        _insert(data: element, at: count)
    }
    public final func insert(_ element: DataAllocator.Storage.Element, at position: Int) {
        _insert(data: element, at: position)
    }
    ///
    final func getData(at position: Int) -> DataAllocator.Storage.Element? {
        guard let root = _root else { return nil }
        let r = _findNode(for: position, starting: root, runningSum: 0)
        guard r.1 else { return nil }
//        guard (r.2.startIndex..<r.2.endIndex).contains(position) else { return nil /*TODO: This should throw...dohhhh */}
        guard let node = r.0 else { return nil }
        return node._data[position - r.2.startIndex]
    }
    ///
    public final func remove(at position: Int) -> Element {
        let e: Element
        (e, _root) = removeElement(at: position, starting: _root, runningSum: 0)
        _count -= 1
        return e
    }
    ///
    final func _insert(data: DataAllocator.Storage.Element, at position: Int) {
        _root = addNode(for: position, starting: _root, element: data, runningSum: 0)
        _count += 1
    }
}
