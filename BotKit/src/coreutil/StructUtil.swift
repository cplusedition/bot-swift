/*
 *  Copyright (c) 2018, Cplusedition Limited.  All rights reserved.
 *
 *  This file is licensed to you under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

open class Stack<T> {
    private var a = Array<T>()
    public init() {}
    public var count: Int { return a.count }
    public var isEmpty: Bool { return a.isEmpty }
    public func peek() -> T? {
        return a.last
    }
    public func pop() -> T? {
        if let ret = a.last {
            a.removeLast()
            return ret
        }
        return nil
    }
    public func push(_ e: T) {
        a.append(e)
    }
}

/// A thin wrapper around array for now, in case it may implement generator later.
public struct MySeq<T> {
    private var array = Array<T>()
    public var count: Int { return array.count }
    public var isEmpty: Bool { return array.isEmpty }
    public init() {}
    public init(_ a: T...) {
        array.append(contentsOf: a)
    }
    public mutating func append(_ elm: T) {
        array.append(elm)
    }
    public mutating func append(_ s: T...) {
        array.append(contentsOf: s)
    }
    public mutating func append<S>(_ s: S) where S: Sequence, S.Element == T {
        array.append(contentsOf: s)
    }
}

public extension MySeq where T: Equatable {
    func toArray() -> Array<T> {
        return array
    }
}

public extension MySeq where T: Hashable {
    func toSet() -> Set<T> {
        return Set(self)
    }
}

extension MySeq: Sequence {
    public typealias Element = T
    public struct Iterator: IteratorProtocol {
        public typealias Element = T
        private var index = 0
        private var array: Array<Element>
        fileprivate init(_ array: Array<Element>) {
            self.array = array
        }
        public mutating func next() -> Element? {
            guard index < array.count else { return nil }
            let ret = array[index]
            index += 1
            return ret
        }
    }
    public func makeIterator() -> MySeq<T>.Iterator {
        return Iterator(array)
    }
}

open class StringPrintWriter : TextOutputStream {
    
    private var buffer = String()
    public var count: Int {
        return buffer.count
    }
    
    public init() {
    }
    
    public init(reserve: Int) {
        buffer.reserveCapacity(reserve)
    }
    
    public func write(_ string: String) {
        buffer.append(string)
    }
    
    public func print(_ msg: String) {
        write(msg)
    }
    
    public func print(_ msgs: String...) {
        write(msgs.joined(separator: ""))
    }
    
    public func print<T>(_ msgs: T) where T: Sequence, T.Element == String {
        write(msgs.joined(separator: ""))
    }
    
    public func print<T>(_ msgs: inout T) where T: IteratorProtocol, T.Element == String {
        while let msg = msgs.next() {
            write(msg)
        }
    }
    
    public func println(_ msg: String) {
        write(msg)
        write(TextUtil.LINESEP)
    }
    
    public func println(_ msgs: String...) {
        write(msgs.joined(separator: TextUtil.LINESEP))
        write(TextUtil.LINESEP)
    }
    
    public func println<T>(_ msgs: T) where T: Sequence, T.Element == String {
        write(msgs.joined(separator: TextUtil.LINESEP))
        write(TextUtil.LINESEP)
    }
    
    public func println<T>(_ msgs: inout T) where T: IteratorProtocol, T.Element == String {
        while let msg = msgs.next() {
            write(msg)
            write(TextUtil.LINESEP)
        }
    }
    
    public func toString() -> String {
        return buffer
    }
}

open class DiffStat<T> where T: Hashable {
    public var aonly = Set<T>()
    public var bonly = Set<T>()
    public var diffs = Set<T>()
    public var sames = Set<T>()
    
    public init() {}
    
    public func hasDiff() -> Bool {
        return aonly.count > 0 || bonly.count > 0 || diffs.count > 0
    }
    
    public func toString() -> String {
        return toString("A", "B")
    }
    
    public func toString(
        _ msg1: String,
        _ msg2: String,
        printsames: Bool = false,
        printaonly: Bool = true,
        printbonly: Bool = true,
        printdiffs: Bool = true
        ) -> String {
        let w = StringPrintWriter()
        if (printsames) {
            w.println("### Same: \(sames.count)")
            sames.forEach { w.println("\($0)") }
        }
        if (printaonly) {
            w.println("### \(msg1) only: \(aonly.count)")
            aonly.forEach { w.println("\($0)") }
        }
        if (printbonly) {
            w.println("### \(msg2) only: \(bonly.count)")
            bonly.forEach { w.println("\($0)") }
        }
        if (printdiffs) {
            w.println("### Diff: \(diffs.count)")
            diffs.forEach { w.println("\($0)") }
        }
        return w.toString()
    }
}
