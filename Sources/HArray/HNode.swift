//
//  HNode.swift
//  
//
//  Created by Hristo Doichev on 10/22/21.
//

import Foundation

///
public class HNode<DataAllocator: StorableAllocator>: Codable where DataAllocator.Storage: Storable {
    /// This is main piece of information that is required to travers (find, add, remove) elements.
    /// It value is handled automatically and is not intended for external usage.
    ///
    ///     _key in terms of an array
    ///     [0, 1, 2, 3, 4, 5, 6, 7]
    ///      ^     ^
    ///      |     Root node: _key = 2
    ///      Left node: _key: -2
    ///
    ///      left._key = distance between the first element of the parent node and the first element of the left node. Always <0
    ///      right.key = distance between the last element of the parent node and the first element in the right node. Always >= 0
    ///
    ///  Meaning of _key values (format is "N:<_key>"):
    ///
    ///             A:2
    ///           /    \
    ///        B:-2     C:0
    ///           \
    ///             C:0
    ///  "A:2" means that there are 2 elements before A - that is the chain of element starting with A.left
    ///  "B:-2" means that there are 2 elements after the B. In this case the count is with respect to the last element contained within B
    ///  "C:0" means that there are no elements on the left handside of C. "D:0" is the same as C:0, but with respect to node "D".
    ///
    ///             A:5                         [5]
    ///           /    \                      /     \
    ///        B:-5     C:0             [0,1,2]      [6]
    ///           \            ===>           \
    ///             C:1                       [4]
    ///           /                           /
    ///         E:-1                        [3]
    ///
    ///   _key is the distance between the Node and its predecessor.
    ///     _key < 0 when going left: parent.startIndex - node.startIndex
    ///     _key >= 0 when going right: node.startIndex - parent.endIndex
    ///
    var _key: Int = 0
    var _left: HNode?
    var _right: HNode?
    var _height: Int = 1
    var _data: DataAllocator.Storage
    
    enum CombineOutput {
        case AsLeft, AsRight
    }
    enum CodingKeys: String, CodingKey {
        case k, l, r, h, d
    }
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _key = try values.decode(Int.self, forKey: .k)
        _left = try? values.decode(HNode.self, forKey: .l)
        _right = try? values.decode(HNode.self, forKey: .r)
        _height = try values.decode(Int.self, forKey: .h)
        _data = try values.decode(DataAllocator.Storage.self, forKey: .d)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_key, forKey: .k)
        try container.encode(_left, forKey: .l)
        try container.encode(_right, forKey: .r)
        try container.encode(_height, forKey: .h)
        try container.encode(_data, forKey: .d)
    }

    public init(key: Int, height: Int, data: DataAllocator.Storage, left: HNode? = nil, right: HNode? = nil) {
        self._key = key
        self._left = left
        self._right = right
        self._height = height
        self._data = data
    }
}
/// Memeber variables
extension HNode {
    public var key: Int { _key }
    public var data: DataAllocator.Storage { _data }
    public var height: Int { 1 + Swift.max((left?._height) ?? 0, (right?._height) ?? 0) }
    var isLeaf: Bool { right == nil && left == nil }
    var balance: Int { (left?._height ?? 0) - (right?._height ?? 0) }
    ///
    var left: HNode? {
        set {
            _left = newValue
            _height = height
        }
        get { _left }
    }
    var right: HNode? {
        set {
            _right = newValue
            _height = height
        }
        get { _right }
    }
    /// Update the left node and keep track of how many elements are on that path.
    var leftUpdateAdd: HNode? {
        set {
            left = newValue
            if left != nil {
                if _key >= 0 {
                    _key += 1
                }
                if left!._key == 0 { left!._key -= left!._data.count }
            }
        }
        get {
            return left
        }
    }
    /// Update the left node and keep track of how many elements are on that path.
    var rightUpdateAdd: HNode? {
        set {
            right = newValue
            if right != nil {
                if _key < 0 {
                    _key -= 1
                }
//                if right!._key == 0 { right!._key = 1 }
            }
        }
        get {
            return right
        }
    }
    var leftUpdateRemove: HNode? {
        set {
            if left != nil && _key > 0 { _key -= 1 }
            left = newValue
        }
        get { left }
    }
    var rightUpdateRemove: HNode? {
        set {
            if right != nil && _key < 0 { _key += 1}
            right = newValue
        }
        get { right }
    }
}

extension HNode {
    func canInsertData(at position: Int) -> Bool {
        guard position >= 0 && position <= _data.count && _data.count < _data.capacity else { return false}
        return true
    }
    func insert(data: DataAllocator.Storage.Element, at position: Int) -> Bool {
        guard canInsertData(at: position) else { return false }
        _data.insert(data, at: position)
        // Inserting data item into the current node, has the same semantics as adding a right node.
        // If the current node is with _key < 0 then it must be handled properly.
        if _key < 0 {
            _key -= 1
        }
        return true
    }
    func remove(at position: Int) -> DataAllocator.Storage.Element  {
        guard (0..<_data.count).contains(position) else { fatalError("Invalid Position") }
        if _key < 0 { _key += 1}
        return _data.remove(at: position)
    }
    func getFindRange(_ position: Int) -> HRange {
        return HRange(startIndex: position + _key,
                      endIndex: position + _key + _data.count)
    }
    ///
    var leftKey: Int {
        return -(_key + _data.count) + (right?.leftKey ?? 0)
    }
    var rightKey: Int {
        return (left?.rightKey ?? 0) - _key
    }
}
/// 
extension HNode {
    ///
    func appendLeft(_ node: HNode? ) {
        guard let node = node else { return }
        if self.left != nil {
            self.left!.appendLeft(node)
            self._height = self.height
        } else {
            self.left = node
        }
    }
    func appendRight(_ node: HNode? ) {
        guard let node = node else { return }
        if self.right != nil {
            self.right!.appendRight(node)
            self._height = self.height
        } else {
            self.right = node
        }
    }
    ///
    func combineChildren(as outputDirection: CombineOutput) -> HNode? {
        // Time to remove this node.right
        if let right = right {
            right.appendLeft(left)
            
            switch outputDirection {
            case .AsLeft:
                if _key > 0 {
                    right._key = right.leftKey
                } else {
                    // shortcut to get the key
                    right._key = _key + _data.count + right._key
                    //                    right._key = right.leftKey + right._key
                }
            case .AsRight:
                if _key < 0 {
                    // shortcut to get the key
                    right._key -= _data.count
                } else {
                    right._key = right._left?.rightKey ?? 0
                }
            }
            return right
        } else if let left = left {
            switch outputDirection {
            case .AsLeft:
                if _key > 0 {
                    // shortcut to get the key
                    left._key = -left._data.count + (left.right?.leftKey ?? 0)
                } else {
                    // Since there is no 'right' node in the parent
                    // the left stays the same
                    // left._key = _key - _data.count // - left._data.count
                }
            case .AsRight:
                if _key > 0 {
                    // shortcut to get the key
                    left._key += _key
                } else {
                    left._key = left.left?.rightKey ?? 0
                }
            }
            return left
        }
        return nil
    }
}
