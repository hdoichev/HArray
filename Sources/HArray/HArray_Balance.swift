//
//  HArray_Balance.swift
//  
//
//  Created by Hristo Doichev on 10/24/21.
//

import Foundation

extension HArray {
    ///
    ///        6 (6)                   3 (3)
    ///     /     \                 /     \
    ///  3 (-3)    8 (2) --->              6 (3)
    ///     \                            /   \
    ///     4 (1)                    4 (-2)   8 (2)
    ///
    private final func rotateRight(_ node: Node) -> Node? {
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
    private final func rotateLeft(_ node: Node) -> Node? {
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
    final func balanceNode(_ node: Node,_ position: Int, _ insertRange: HRange) -> Node? {
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

}
