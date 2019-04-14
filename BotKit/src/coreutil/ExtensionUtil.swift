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

public extension Int {
    var isOdd: Bool {
        return (self & 0x01) != 0
    }
}

public extension Date {
    init(ms: Int64) {
        self.init(timeIntervalSince1970: Double(ms) / 1000)
    }
    var ms: Int64 {
        return Int64((timeIntervalSince1970 * 1000).rounded())
    }
}

public extension Data {
    var makeString: String? {
        return String(data: self, encoding: .utf8)
    }
    
    mutating func withUnsafeMutableBytePointer<R>(_ code: Fun11x<UnsafeMutablePointer<UInt8>, R>) rethrows -> R {
        return try withUnsafeMutableBytes { (buf: UnsafeMutableRawBufferPointer) throws -> R in
            return try code(UnsafeMutablePointer(OpaquePointer(buf.baseAddress!)))
        }
    }

    func withUnsafeBytePointer<R>(_ code: Fun11x<UnsafePointer<UInt8>, R>) rethrows -> R {
        return try withUnsafeBytes { (buf: UnsafeRawBufferPointer) throws -> R in
            return try code(UnsafePointer(OpaquePointer(buf.baseAddress!)))
        }
    }
}

public extension DispatchTime {
    /**
     Create a dispatch time for a given seconds from now.
     */
    init(seconds: Double) {
        let nanos = UInt64((seconds * Double(1_000_000_000)).rounded())
        let uptime = DispatchTime.now().uptimeNanoseconds + nanos
        self.init(uptimeNanoseconds: uptime)
    }
    init(ms: Int) {
        let uptime = DispatchTime.now().uptimeNanoseconds + (UInt64(ms) * 1000 * 1000)
        self.init(uptimeNanoseconds: uptime)
    }
}

public extension DispatchSemaphore {
    func wait(seconds: Double) -> DispatchTimeoutResult {
        let time = DispatchTime(seconds: seconds)
        return self.wait(timeout: time)
    }
    func wait(ms: Int) -> DispatchTimeoutResult {
        let time = DispatchTime(ms: ms)
        return self.wait(timeout: time)
    }
}

public extension DispatchGroup {
    func wait(seconds: Double) -> DispatchTimeoutResult {
        let time = DispatchTime(seconds: seconds)
        return self.wait(timeout: time)
    }
    func wait(ms: Int) -> DispatchTimeoutResult {
        let time = DispatchTime(ms: ms)
        return self.wait(timeout: time)
    }
}

public extension String {
    
    private static let WHITESPACES = CharacterSet(charactersIn: " \t\n\r")
    
    func substring(to offset: Int) -> String {
        return String(self[self.startIndex..<self.index(self.startIndex, offsetBy: offset)])
    }
    
    func substring(from offset: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: offset)..<self.endIndex])
    }
    
    func substring(from start: Int, to end: Int) -> String {
        let s = self.index(startIndex, offsetBy: start)
        let e = (end >= 0 ? self.index(startIndex, offsetBy: end) : self.index(endIndex, offsetBy: end))
        return String(self[s..<e])
    }
    
    func trimmed() -> String {
        return self.trimmingCharacters(in: String.WHITESPACES)
    }
    
    var lines: Array<String> {
        return self.components(separatedBy: TextUtil.LINESEP) // Keeping empty segments.
        //#BEGIN NOTE This get weird when input contains \r\n, it does not consider \n in \r\n as a separator.
        //        return self.split(separator: TextUtil.LINESEP.first!, omittingEmptySubsequences: false).map { String($0) }
        //#END NOTE
    }
    
    var data: Data {
        return Data(self.utf8)
    }
    
    var bytes: Bytes {
        return Array(utf8)
    }
}

public extension Sequence {
    func none(_ code: IPredicate1<Element>) -> Bool {
        for e in self {
            if code(e) { return false }
        }
        return true
    }
    func all(_ code: IPredicate1<Element>) -> Bool {
        for e in self {
            if !code(e) { return false }
        }
        return true
    }
    func any(_ code: IPredicate1<Element>) -> Bool {
        for e in self {
            if code(e) { return true }
        }
        return false
    }
}

public extension Array {
    // Create an empty array, but reserve the specified capacity.
    init(reserve: Int) {
        self.init()
        self.reserveCapacity(reserve)
    }
    init(_ s: Array, _ start: Int, _ end: Int) {
        self.init()
        append(s, start, end)
    }
    mutating func append(_ a: Array, _ start: Int, _ end: Int) {
        append(contentsOf: a[start..<end])
    }
    mutating func append(_ a: Array) {
        append(a, 0, a.count)
    }
    mutating func setLength(_ length: Int) {
        removeSubrange(length..<self.count)
    }
}

public extension Array where Element: Hashable {
    func toSet() -> Set<Element> {
        return Set(self)
    }
}

public extension Array where Element==String {
    /// @return A new string with elements joined by linebreaks.
    func joinln() -> String {
        return joined(separator: TextUtil.LINESEP)
    }
    
    func joinPath() -> String {
        return joined(separator: File.SEP)
    }
}

public extension Dictionary {

    /// Add entries from the other dictionary.
    /// Use new value on duplicated key.
    @discardableResult
    mutating func add(_ other: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        merge(other, uniquingKeysWith: { a, b in return b })
        return self
    }
    
    /// Create a new dictionary with mapped value.
    /// @param transform(key, value) -> newvalue? If newvalue is not nil, added (key: newvalue) to the result.
    func map(_ transform: Fun21<Key, Value, Value?>) -> Dictionary<Key, Value> {
        var ret = Dictionary<Key,Value>()
        for (k, v) in self {
            if let value = transform(k, v) {
                ret[k] = value
            }
        }
        return ret
    }
}

extension OutputStream: IOutputStream {
}

extension InputStream: IInputStream {
}

public extension Int {
    struct ASCII {
        public static let NULL = 0
        public static let SOH = 1
        public static let STX = 2
        public static let ETX = 3
        public static let EOT = 4
        public static let ENQ = 5
        public static let ACK = 6
        public static let BEL = 7
        public static let BS = 8
        public static let HT = 9
        public static let LF = 10
        public static let VT = 11
        public static let FF = 12
        public static let CR = 13
        public static let SO = 14
        public static let SI = 15
        public static let DLE = 16
        public static let DC1 = 17
        public static let DC2 = 18
        public static let DC3 = 19
        public static let DC4 = 20
        public static let NAK = 21
        public static let SYN = 22
        public static let ETB = 23
        public static let CAN = 24
        public static let EM = 25
        public static let SUB = 26
        public static let ESC = 27
        public static let FS = 28
        public static let GS = 29
        public static let RS = 30
        public static let US = 31
        public static let SPACE = 32
        public static let EXCLAMATION = 33
        public static let QUOTE = 34
        public static let HASH = 35
        public static let DOLLAR = 36
        public static let PERCENT = 37
        public static let AMPERSAND = 38
        public static let APOS = 39
        public static let LPAREN = 40
        public static let RPAREN = 41
        public static let STAR = 42
        public static let PLUS = 43
        public static let COMMA = 44
        public static let MINUS = 45
        public static let DOT = 46
        public static let SLASH = 47
        public static let ZERO = 48
        public static let ONE = 49
        public static let TWO = 50
        public static let THREE = 51
        public static let FOUR = 52
        public static let FIVE = 53
        public static let SIX = 54
        public static let SEVEN = 55
        public static let EIGHT = 56
        public static let NINE = 57
        public static let COLON = 58
        public static let SEMICOLON = 59
        public static let LT = 60
        public static let EQUAL = 61
        public static let GT = 62
        public static let QUESTION = 63
        public static let AT = 64
        public static let A = 65
        public static let B = 66
        public static let C = 67
        public static let D = 68
        public static let E = 69
        public static let F = 70
        public static let G = 71
        public static let H = 72
        public static let I = 73
        public static let J = 74
        public static let K = 75
        public static let L = 76
        public static let M = 77
        public static let N = 78
        public static let O = 79
        public static let P = 80
        public static let Q = 81
        public static let R = 82
        public static let S = 83
        public static let T = 84
        public static let U = 85
        public static let V = 86
        public static let W = 87
        public static let X = 88
        public static let Y = 89
        public static let Z = 90
        public static let LBRACKET = 91
        public static let BACKSLASH = 92
        public static let RBRACKET = 93
        public static let CARET = 94
        public static let UNDERSCORE = 95
        public static let BACKQUOTE = 96
        public static let a = 97
        public static let b = 98
        public static let c = 99
        public static let d = 100
        public static let e = 101
        public static let f = 102
        public static let g = 103
        public static let h = 104
        public static let i = 105
        public static let j = 106
        public static let k = 107
        public static let l = 108
        public static let m = 109
        public static let n = 110
        public static let o = 111
        public static let p = 112
        public static let q = 113
        public static let r = 114
        public static let s = 115
        public static let t = 116
        public static let u = 117
        public static let v = 118
        public static let w = 119
        public static let x = 120
        public static let y = 121
        public static let z = 122
        public static let LBRACE = 123
        public static let VBAR = 124
        public static let RBRACE = 125
        public static let TILDE = 126
        public static let BACKSPACE = 127
    }
}

public extension Character {
    struct ASCII {
        public static let SLASH: Character = "/"
        public static let DOT: Character = "."
    }
}

