//
//  HArrayTest.swift
//
//
//  Created by Hristo Doichev on 10/16/21.
//

import XCTest
@testable import HArray

///
//struct TestData: Equatable {
//    var v: Int
//}
typealias TestData = Int
typealias HTestArray = HArray<Array<TestData>>
typealias T = HTestArray.Node

fileprivate func insertAndVerify(data: TestData, at position: Int, in tree: HTestArray){
    tree.insert(data, at: position)
    if let result = tree.getData(at: position) {
        XCTAssertEqual(data, result, "Looking for \(position):\(data) found \(result)")
    } else {
        XCTFail("Looking for \(position): \(data)")
    }
}
/// Ensure the ordering and values for elements is correct.
fileprivate func verifyTreeOrder(_ tree: HTestArray, printTree: Bool = false) {
    let height = tree.height
    var runningCount = Int.min
    if printTree {
        print("Tree.count:", tree.count)
        print("Height:", height)
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, "(\($0.height))"*/)} }
        print("----------")
    }
    tree.traverse(style: .InOrder) {
        $2
        if !($0._data.isEmpty)  {
            if runningCount == Int.min {
                runningCount = $1
                XCTAssertEqual(0, $1, "Order mismatch")
            } else {
                XCTAssertEqual(runningCount, $1, "Order mismatch")
            }
            //            print("(\($1))", String(repeating: "  ", count: height - $0._height), $0._key, $0._data, $0._height)
            runningCount += $0._data.count
        } else {
            XCTFail("Data should not be nil")
        }
    }
}
///
fileprivate func createNode(forRange: Range<Int>, position: Int, with capacity: Int, isRight: Bool) -> (T?,Int/*height*/,Int/*key*/) {
    guard forRange.count > 0 else { return (nil, 0, 0) }
    var leftRange = (0..<0)
    var rightRange = (forRange.count..<forRange.count)
    if forRange.count >= capacity {
        let lrange = (forRange.count - capacity) / 2
        let rrange = forRange.count - capacity - lrange
        leftRange = (forRange.startIndex..<forRange.startIndex+lrange)// forRange.prefix((forRange.count - capacity) / 2)
        rightRange = (forRange.endIndex-rrange..<forRange.endIndex)// forRange.suffix(forRange.count - capacity - leftRange.count)
    }
    let itemsCount = (rightRange.startIndex - leftRange.endIndex)
    let startPosition = position - ((1 + itemsCount) / 2)
    let left = createNode(forRange: leftRange, position: (leftRange.startIndex + (1 + leftRange.count) / 2) , with: capacity, isRight: false)
    let right = createNode(forRange: rightRange, position: (rightRange.startIndex + (1 + rightRange.count) / 2), with: capacity, isRight: true)
    let height: Int = Swift.max(left.1, right.1)
    //    let data = [Int](leftRange.endIndex..<rightRange.startIndex)
    let data = [Int](startPosition..<startPosition + itemsCount)
    let key = isRight ? (left.0?.rightKey ?? 0) : (right.0?.leftKey ?? 0) - data.count //-(right.2 + data.count)
    let node = T(key: key, height: height, data: data, maxCount: capacity, left: left.0, right: right.0)
    node._height = node.height
    return (node, height, key)
}
fileprivate func constructTree(elements count: Int, capacityPerNode: Int) -> HTestArray {
    let tree = HTestArray(maxElementsPerNode: capacityPerNode, allocator: Array<Int>())
    let r = createNode(forRange: (0..<count), position: (count + 1) / 2, with: capacityPerNode, isRight: true)
    tree._root = r.0
    tree._count = count
    return tree
}

final class HTreeTests: XCTestCase {
    ///
    ///   1             1
    ///    \    --->     \
    ///     2  (here)    20 (*)
    ///                    \
    ///                     2
    ///
    func testAddBeforeLast() {
        let tree = HTestArray(maxElementsPerNode: 1, allocator: Array<Int>())
        tree._root = T(key: 0, height: 2, data: [1],
                      right: T(key: 0, height: 1, data: [2]))
        
        verifyTreeOrder(tree)
//        tree.traverse(style: .InOrder) { if !($0._data.isEmpty)  {print("(\($1))", String(repeating: "  ", count: 5 - $0._height), $0._key, $0._data/*, $0.height*/)} }
        //        print("----------")
        insertAndVerify(data: 20, at: 2, in: tree)
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    ///
    ///   1                      1
    ///    \                      \
    ///     2 (here)     --->      20 (*)
    ///      \                      \
    ///       3                      2
    ///                               \
    ///                                3
    ///
    func testAddBeforeBeforeLast() {
        let tree = HTestArray(maxElementsPerNode: 1, allocator: Array<Int>())
        tree._root = T(key: 0, height: 3, data: [1],
                      right: T(key: 0, height: 2, data: [2],
                               right: T(key: 0, height: 1, data: [3])))
        
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 2, in: tree)
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        //        if let jd = try? JSONEncoder().encode(tree) {
        //            print("HTree: ", String(data: jd, encoding: .utf8))
        //        }
    }
    ///
    ///   [1,2]                     [1,2]
    ///    \                         \
    ///     [3,4] (here)     --->     [3, 20] (*)
    ///      \                         \
    ///       [5,6]                     [4]
    ///                                  \
    ///                                   [5,6]
    ///
    func testAddBeforeBeforeLast_Multi() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 0, height: 3, data: [1,2],
                      right: T(key: 0, height: 2, data: [3,4],
                               right: T(key: 0, height: 1, data: [5,6])))
        
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 3, in: tree)
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        //        //        encoder.outputFormatting = .prettyPrinted
        //        if let jd = try? JSONEncoder().encode(tree) {
        //            print("HTree: ", String(data: jd, encoding: .utf8))
        //        }
    }
    ///
    ///   [1] (here)              [1, 20] (*)
    ///    \                       \
    ///     [2] (here)     --->     [30, 2] (*)
    ///      \                       \
    ///       [3]                     [3]
    func testInsertData() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 1, height: 3, data: [1], maxCount: 2,
                      right: T(key: 0, height: 2, data: [2], maxCount: 2,
                               right: T(key: 0, height: 1, data: [3], maxCount: 2)))
        
        let height = tree.height + 1
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 2, in: tree)
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 30, at: 3, in: tree)
        tree.traverse(style: .InOrder) { if !($0._data.isEmpty) {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        //        //        encoder.outputFormatting = .prettyPrinted
        //        if let jd = try? JSONEncoder().encode(tree) {
        //            print("HTree: ", String(data: jd, encoding: .utf8))
        //        }
    }
    func testAddFirst() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 1, height: 2, data: [1], maxCount: 2,
                      left: T(key: -1, height: 1, data: [0], maxCount: 2))
        
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 0, in: tree)
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    func testAddBeforeFirst() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 2, height: 3, data: [2],
                      left: T(key: -1, height: 2, data: [1], maxCount: 2,
                              left: T(key: -1, height: 1, data: [0], maxCount: 2)))
        
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 1, in: tree)
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    ///
    ///     2                      3
    ///    /                      /
    ///   0             --->     0
    ///    \                      \
    ///     1 (here)               20 (*)
    ///                           /
    ///                          1
    ///
    func testAddInnerBeforeBeforeLast_Left() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 2, height: 3, data: [2], maxCount: 2,
                      left: T(key: -2, height: 2, data: [0], maxCount: 2,
                              right: T(key: 0, height: 1, data: [1], maxCount: 2)))
        
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 1, in: tree)
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    ///
    ///     0                      0
    ///      \                      \
    ///       2          --->        2
    ///      /                      /
    ///     1 (here)               [20,1] (*)
    ///
    func testAddInnerBeforeBeforeLast_Right() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 0, height: 3, data: [0], maxCount: 2,
                      right: T(key: 1, height: 2, data: [2], maxCount: 2,
                               left: T(key: -1, height: 1, data: [1], maxCount: 2)))
        var h = tree.height
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 2, in: tree)
        h = tree.height
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    ///
    ///
    ///
    func testAdd_Left() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 0, height: 2, data: [4,5], maxCount: 2,
                      right: T(key: 0, height: 1, data: [6,7], maxCount: 2))
        var h = tree.height
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
        insertAndVerify(data: 20, at: 0, in: tree)
        insertAndVerify(data: 30, at: 1, in: tree)
        insertAndVerify(data: 22, at: 2, in: tree)
        //        insertAndVerify(data: 33, at: 3, in: tree)
        h = tree.height
        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: $2), $0._key, $0._data/*, $0.height*/)} }
        print("----------")
    }
    
    ///
    ///
    ///
    ///
    func testAddAtRandomPositions() {
        let tree = HTestArray(maxElementsPerNode: 5, allocator: Array<Int>())
        for i in 0..<777 { tree.insert(i, at: i)}
        //        print("Height: ", tree.height)
        //        print("InOrder:")
        verifyTreeOrder(tree)
        //        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: 5 - $0._height), $0._key, $0._data/*, $0.height*/)} }
        //        print("----------")
        //        insertAndVerify(data: 10, at: 4, in: tree)
        //        //        tree.traverse(style: .InOrder) { if $0.data != nil {print("(\($1))", String(repeating: "  ", count: 5 - $0.height), $0.key, $0.data!/*, $0.height*/)} }
        //
        //        //        print("----------")
        //        insertAndVerify(data: 20, at: 5, in: tree)
        //        //        tree.traverse(style: .InOrder) { if $0.data != nil {print("(\($1))", String(repeating: "  ", count: 5 - $0.height), $0.key, $0.data!/*, $0.height*/)} }
        //        //
        //        insertAndVerify(data: 20, at: 3, in: tree)
        //        for i in 0..<105 {
        //            insertAndVerify(data: 100 + i, at: i, in: tree)
        //        }
        ////        for i in (0..<34).reversed() {
        ////            insertAndVerify(data: 100 + i, at: Int.random(in: 0..<100), in: tree)
        ////        }
        //        let h = tree.height
        //        print("Height: ", h)
        //        verifyTreeOrder(tree)
        //        tree.traverse(style: .InOrder) { if $0._data != nil {print("(\($1))", String(repeating: "  ", count: (h + 5) - $0._height), $0._key, $0._data/*, $0.height*/)} }
        ///
        //    for i in 0..<1_000_000 {
        //        insertAndVerify(data: i, at: Int.random(in: 0..<100_000), in: tree)
        //    }
        //    print("Height: ", tree.height)
        //    print("Tree.count: ", tree.count)
        //        print("----------")
    }
    func testAddAtRandomPositions_Rverse() {
        let tree = HTestArray(maxElementsPerNode: 5, allocator: Array<Int>())
        for i in (0..<777).reversed() { tree.insert(i, at: i)}
        verifyTreeOrder(tree)
    }
    func testBalanceRotateRight() {
        let tree = HTestArray(maxElementsPerNode: 1, allocator: Array<Int>())
        tree._root = T(key: 4, height: 5, data: [4],
                      left: T(key: -1, height: 4, data: [3],
                              left: T(key: -1, height: 3, data: [2],
                                      left: T(key: -1, height: 2, data: [1],
                                              left: T(key: -1, height: 1, data: [0])))))
        insertAndVerify(data: 5, at: 5, in: tree)
        verifyTreeOrder(tree)
    }
    func testBalanceRotateRight_2() {
        let tree = HTestArray(maxElementsPerNode: 2, allocator: Array<Int>())
        tree._root = T(key: 8, height: 5, data: [8,9], maxCount: 2,
                      left: T(key: -2, height: 4, data: [6,7], maxCount: 2,
                              left: T(key: -2, height: 3, data: [4,5], maxCount: 2,
                                      left: T(key: -2, height: 2, data: [2,3], maxCount: 2,
                                              left: T(key: -2, height: 1, data: [0,1],  maxCount: 2)))))
        insertAndVerify(data: 10, at: 10, in: tree)
        verifyTreeOrder(tree)
    }
    func testAdd_Insertions_Performance() {
        let tree = HTestArray(maxElementsPerNode: 20, allocator: Array<Int>())
        for i in 0..<10 {
            tree.insert(i, at: i)
        }
        measure{
            for m in 0..<2 {
                for i in 0..<10 { insertAndVerify(data: i, at: (2 + m) * i, in: tree) }
            }
        }
        verifyTreeOrder(tree)
    }
    func testAdd_Performance_5() {
        measure {
            let tree = HTestArray(maxElementsPerNode: 5, allocator: Array<Int>())
            for i in 0..<100_000 { insertAndVerify(data: i, at: i, in: tree) }
        }
        //        verifyTreeOrder(tree)
    }
    ///
    func testRemove_1() {
        let tree = HTestArray(allocator: Array<Int>())
        tree._root = T(key: 1, height: 2, data: [0],
                      left: T(key: -1, height: 1, data: [0]))
        
        tree.remove(at: 1)
        verifyTreeOrder(tree)
    }
    func testRemove_2() {
        let tree = constructTree(elements: 7, capacityPerNode: 1)
        
        print("Root.rightKey: ", tree._root?.rightKey)
        print("Root.leftKey: ", tree._root?.leftKey)
        print("Root.left.rightKey: ", tree._root?.left?.rightKey)
        print("Root.right.leftKey: ", tree._root?.right?.leftKey)
        
        tree.remove(at: 3)
        verifyTreeOrder(tree)
        
        tree.remove(at: 1)
        verifyTreeOrder(tree)
    }
    func testRemove_3() {
        let tree = constructTree(elements: 7, capacityPerNode: 1)
        tree.remove(at: 1)
        verifyTreeOrder(tree)
        tree.remove(at: 3)
        verifyTreeOrder(tree)
        tree.remove(at: 4)
        verifyTreeOrder(tree)
    }
    func testRemove_64_1() {
        let tree = constructTree(elements: 64, capacityPerNode: 1)
        for i in 20..<40 { tree.remove(at: i); verifyTreeOrder(tree) }
        for i in (1..<44).reversed() { tree.remove(at: i); verifyTreeOrder(tree) }
    }
    func testRemove_64_2() {
        let tree = constructTree(elements: 64, capacityPerNode: 2)
        for i in 20..<40 { tree.remove(at: i); verifyTreeOrder(tree) }
        for i in (1..<44).reversed() { tree.remove(at: i); verifyTreeOrder(tree) }
    }
    func testRemove_64_3() {
        let tree = constructTree(elements: 64, capacityPerNode: 3)
        for i in 20..<40 { tree.remove(at: i) }
        verifyTreeOrder(tree)
        for i in (1..<44).reversed() { tree.remove(at: i) }
        verifyTreeOrder(tree)
    }
    func testRemove_64_4() {
        let tree = constructTree(elements: 64, capacityPerNode: 4)
        for i in 20..<40 { tree.remove(at: i) }
        verifyTreeOrder(tree)
        for i in (1..<44).reversed() { tree.remove(at: i) }
        verifyTreeOrder(tree)
    }
    func testRemove_257_5() {
        let tree = constructTree(elements: 257, capacityPerNode: 5)
        for i in 20..<40 { tree.remove(at: i) }
        verifyTreeOrder(tree, printTree: true)
        for i in (1..<44).reversed() { tree.remove(at: i) }
        verifyTreeOrder(tree)
    }
    func testRemove_100000_32() {
        let tree = constructTree(elements: 100_000, capacityPerNode: 32)
        while tree.count > 1 {
            tree.remove(at: Int.random(in: 0..<tree.count))
        }
        verifyTreeOrder(tree)
    }
    ///
    func testRemove_Performance() {
        let tree = constructTree(elements: 1_000_000, capacityPerNode: 3)
        measure {
            let half = tree.count/2
            for i in half-500..<half+500 {
                tree.remove(at: i)
            }
        }
        verifyTreeOrder(tree)
    }
    ///
    func testStoreToJSON() {
        let tree = HTestArray(maxElementsPerNode: 1024, allocator: Array<Int>())
        for i in 0..<1_000_000 {
            // insertAndVerify(data: i, at: i, in: tree) }
            tree.insert(i, at: i)
        }
//        verifyTreeOrder(tree, printTree: true)
        print("Height: ", tree.height)
        let encoder = JSONEncoder()
        if let json = try? encoder.encode(tree) {
            print("JSON.count:        ", json.count)
            print("JSON.count(lz4):   ", try? (json as NSData).compressed(using: .lz4).count )
            print("JSON.count(lzfse): ", try? (json as NSData).compressed(using: .lzfse).count )
            print("JSON.count(zlib):  ", try? (json as NSData).compressed(using: .zlib).count )
//            print("JSON: ", String(data: json, encoding: .utf8))
        }
    }
}
