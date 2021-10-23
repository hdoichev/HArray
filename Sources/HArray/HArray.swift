//
//  HArray.swift
//
//
//  Created by Hristo Doichev on 10/16/21.
//

import Foundation

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
///
///
///
public class HArray<DataType: Codable>: Codable{
    public typealias Node = HNode<DataType>
    public enum TraverseStyle {
        case InOrder
        case PreOrder
        case PostOrder
    }
    var root: Node?
    let _maxElementsPerNode: Int
    var _count: Int = 0
    
    public var count: Int { _count }
    ///
    public init(maxElementsPerNode: Int = 32) {
        root = nil
        _maxElementsPerNode = maxElementsPerNode
    }
    ///
    func _visitNodes(for position: Int, current curNode: Node, parent parentNode: Node, runningSum: Int, visitor:(Node/*current*/, Node/*parent*/, Bool/*found*/)->Void) {
        let curRange = curNode.getFindRange(runningSum)
        if position > curRange {
            if curNode.right == nil { return }
            _visitNodes(for: position, current: curNode.right!, parent: curNode, runningSum: curRange.endIndex, visitor: visitor)
            visitor(curNode, parentNode, false)
            return
        } else if position < curRange {
            if curNode.left == nil { return }
            _visitNodes(for: position, current: curNode.left!, parent: curNode, runningSum: curRange.startIndex, visitor: visitor)
            visitor(curNode, parentNode, false)
            return
        } else {
            visitor(curNode, parentNode, true)
        }
    }
    ///
    func _findNode(for position: Int, starting node: Node, runningSum: Int) -> (Node?, Bool, HRange) {
        let findRange = node.getFindRange(runningSum)
        if position > findRange {
            if node.right == nil { return (node, false, findRange) }
            return _findNode(for: position, starting: node.right!, runningSum: findRange.endIndex)
        } else if position < findRange {
            if node.left == nil { return (node, false, findRange) }
            return _findNode(for: position, starting: node.left!, runningSum: findRange.startIndex /*- node._key*/)
        } else {
            return (node, true, findRange)
        }
    }
    ///
    ///
    ///
    public func getData(at position: Int) -> DataType? {
        guard let root = root else { return nil }
        let r = _findNode(for: position, starting: root, runningSum: 0)
        guard r.1 else { return nil }
        guard (r.2.startIndex..<r.2.endIndex).contains(position) else { return nil /*TODO: This should throw...dohhhh */}
        guard let node = r.0 else { return nil }
        return node._data[position - r.2.startIndex]
    }
    ///
    ///
    ///
    public func findNode(for position: Int) -> Node? {
        guard let root = root else { return nil }
        return _findNode(for: position, starting: root, runningSum: 0).0
    }
    ///
    ///        6 (6)                   3 (3)
    ///     /     \                 /     \
    ///  3 (-3)    8 (2) --->              6 (3)
    ///     \                            /   \
    ///     4 (1)                    4 (-2)   8 (2)
    ///
    private func rotateRight(_ node: Node) -> Node? {
        guard let left = node.left else { return node }
        let lright = left.right
        let left_key = node._key + left._key
        let node_key = (-left._key) - left._data.count // this should be positive - always
        if let lr = lright {
            lr._key = -(node_key - lr._key)
            if lr._key >= 0 {
                // TODO: Throw or fatalError
                fatalError("Tree key is corrupted")
            }
        }
        left._key = left_key
        node._key = node_key// + node._data.count
        if node._key < 0 {
            // TODO: Throw or fatalError
            fatalError("Tree key is corrupted")
        }
        
        node.left = lright
        left.right = node
        return left
    }
    ///
    ///        6 (6)                   11 (11)
    ///     /     \                 /     \
    ///  3 (-3)   11 (5) --->     6 (-5)
    ///           /              /  \
    ///          8 (-3)      3 (-3)  8 (2)
    ///
    private func rotateLeft(_ node: Node) -> Node? {
        guard let right = node.right else {  return node }
        let rleft = right.left
        let right_key = node._key + right._key + node._data.count
        let node_key = node._key - right_key
        if let rl = rleft {
            rl._key = (right._key + rl._key)
            if rl._key < 0 {
                // TODO: Throw or fatalError
                fatalError("Tree key is corrupted")
            }
        }
        right._key = right_key
        node._key = node_key
        if node._key >= 0 {
            // TODO: Throw or fatalError
            fatalError("Tree key is corrupted")
        }
        
        node.right = rleft
        right.left = node
        return right
    }
    ///
    ///
    ///
    private func addNode(for position: Int, starting node: Node?, data: DataType, runningSum: Int) -> Node? {
        guard let node = node else {
            return Node(key: 0, //position - runningSum,
                        height: 1,
                        data: [data],
                        maxCount: _maxElementsPerNode,
                        left: nil,
                        right: nil)
        }
        let curInsertRange = node.getInsertRange(runningSum)
        
        if position > curInsertRange {
            node.rightUpdateAdd = addNode(for: position, starting: node.right, data:data, runningSum: curInsertRange.endIndex )
        } else if position < curInsertRange {
            node.leftUpdateAdd = addNode(for: position, starting: node.left, data:data, runningSum: curInsertRange.startIndex)
        } else {
            // Update the current node.
            // If the current node can store more data then add the data to the Node and update the position offsets.
            // Otherwise add a new node and update the chain of nodes/
            // The new node becomes the left of the current, and if the current had a prior left then
            // that one become the left of the new node.
            if node.insert(data: data, at: position - curInsertRange.startIndex) == false {
                if position == curInsertRange.startIndex {
                    node.leftUpdateAdd = addNode(for: position, starting: node.left, data:data, runningSum: curInsertRange.startIndex)
                } else if position == curInsertRange.endIndex {
                    node.rightUpdateAdd = addNode(for: position, starting: node.right, data:data, runningSum: curInsertRange.endIndex)
                } else {
                    // split the current node
                    let splitRight = Node(key: 0,
                                          height: (node.right != nil) ? node.right!._height+1: 1,
                                          data: Array(node._data[(node._data.count/2..<node._data.count)]),
                                          maxCount: _maxElementsPerNode,
                                          left: nil,
                                          right: node.right)
                    node.right = splitRight
                    node._data = Array(node._data[0..<node._data.count/2])
                    // The current node was split into two, but the data was not yet added.
                    // Recurse using the current node, the data will find its position since there is enough space.
                    if let n = addNode(for: position, starting: node, data:data, runningSum: runningSum) {
                        return balanceNode(n, position, curInsertRange.hr)
                    }
                    return nil // fatalError ???
                }
            }
            return node
        }
        
        return balanceNode(node, position, curInsertRange.hr)
    }
    ///
    ///
    func balanceNode(_ node: Node,_ position: Int, _ insertRange: HRange) -> Node? {
        let balance = node.balance
        
        // Left Left Case
        if let left = node.left {
            if balance > 1 && position < left.getFindRange(insertRange.startIndex) {
                return rotateRight(node);
            }
        }
        // Right Right Case
        if let right = node.right {
            if balance < -1 && position > right.getFindRange(insertRange.startIndex) {
                return rotateLeft(node)
            }
        }
        
        // Left Right Case
        if let left = node.left {
            if balance > 1 && position > left.getFindRange(insertRange.startIndex) {
                node.left = rotateLeft(left);
                return rotateRight(node);
            }
        }
        
        // Right Left Case
        if let right = node.right {
            if (balance < -1 && position < right.getFindRange(insertRange.endIndex)) {
                node.right = rotateRight(right);
                return rotateLeft(node);
            }
        }
        
        return node
    }
    ///
    public func add(data: DataType, at position: Int) {
        root = addNode(for: position, starting: root, data: data, runningSum: 0)
        _count += 1
    }
    ///
    func removeElement(at position: Int, starting node: Node?, runningSum: Int) -> Node? {
        guard let node = node else { return nil }
        let findRange = node.getFindRange(runningSum)
        
        if position > findRange {
            node.rightUpdateRemove = removeElement(at: position, starting: node.right, runningSum: findRange.endIndex)
            if node.right?._data.count == 0 {
                node.right = node.right!.combineChildren(as: .AsRight)
            }
        } else if position < findRange {
            node.leftUpdateRemove = removeElement(at: position, starting: node.left, runningSum: findRange.startIndex)
            if node.left?._data.count == 0 {
                node.left = node.left!.combineChildren(as: .AsLeft)
            }
        } else {
            guard node.remove(at: position - findRange.startIndex) else { fatalError("Unable to remove data at: \(position)") }
            guard node._data.count == 0 else { return node }
            if node === root {
                return node.combineChildren(as: .AsRight)
            }
            return node
        }
        return balanceNode(node, position, findRange)
    }
    ///
    func remove(at position: Int) {
        root = removeElement(at: position, starting: root, runningSum: 0)
        _count -= 1
    }
    ///
    func _traverseInOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        if let left = node.left { _traverseInOrder(left, findRange.startIndex, depth + 1, block) }
        block(node, findRange.startIndex, depth)
        if let right = node.right { _traverseInOrder(right, findRange.endIndex, depth + 1, block) }
    }
    func _traversePreOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        block(node, findRange.startIndex, depth)
        if let left = node.left { _traversePreOrder(left, findRange.startIndex, depth + 1, block) }
        if let right = node.right { _traversePreOrder(right, findRange.endIndex, depth + 1, block) }
    }
    func _traversePostOrder(_ node: Node, _ runningSum: Int, _ depth: Int, _ block:(Node,Int,Int)->Void) {
        let findRange = node.getFindRange(runningSum)
        if let left = node.left { _traversePostOrder(left, findRange.startIndex, depth + 1, block) }
        if let right = node.right { _traversePostOrder(right, findRange.endIndex, depth + 1, block) }
        block(node, findRange.startIndex, depth)
    }
    public func traverse(style: TraverseStyle,_ block:(Node,Int,Int)->Void) {
        guard let root = root else { return }
        switch style {
        case .InOrder: _traverseInOrder(root, 0, 0, block)
        case .PreOrder: _traversePreOrder(root, 0, 0, block)
        case .PostOrder: _traversePostOrder(root, 0, 0, block)
        }
    }
    public var height: Int { //}(Int,Int) {
        guard let root = root else { return 0 }
        return root.height
    }
}

