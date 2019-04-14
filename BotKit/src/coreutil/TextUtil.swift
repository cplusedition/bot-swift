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

public struct TextUtil {
    
    public static let LINESEP = "\n"
    public static let LINESEP_CHAR: Character = "\n"
    public static let LINESEP_UTF8 = LINESEP.data(using: .utf8)!
    public static let EN_US = Locale(identifier: "en_US")

    public static func classname(_ any: AnyObject?) -> String {
        return any == nil ? "nil" : NSStringFromClass(type(of: any!))
    }
}

/// FIlepath manipulation methods
extension TextUtil {

    public static func removeLeading(_ sep: String, from: String) -> String {
        guard from.hasPrefix(sep) else {
            return from
        }
        var s = Substring(from)
        let len = sep.count
        repeat {
            s = s[s.index(s.startIndex, offsetBy: len)...]
        } while(s.hasPrefix(sep))
        return String(s)
    }

    public static func removeTrailing(_ sep: String, from: String) -> String {
        guard from.hasSuffix(sep) else {
            return from
        }
        var s = Substring(from)
        let len = sep.count
        repeat {
            s = s[..<s.index(s.endIndex, offsetBy: -len)]
        } while s.hasSuffix(sep)
        return String(s)
    }

    public static func ensureLeading(_ sep: String, for path: String) -> String {
        return path.hasPrefix(sep) ? path : sep + path
    }

    public static func ensureTrailing(_ sep: String, for path: String) -> String {
        return path.hasSuffix(sep) ? path : path + sep
    }

    /**
     * Remove duplicated /, /./ and /../
     */
    public static func cleanupFilepath(_ string: String) -> String {
        let sep = File.SEPCHAR
        let dot = Character.ASCII.DOT
        var last: Character? = nil;
        let chars = Array(string)
        let end = chars.count
        var i = 0
        var ret = [Character]()
        var modified = false
        while i < end {
            let next = i + 1
            let c = chars[i]
            if ((sep == last || ret.isEmpty) && c == dot
                && (((next < end) && chars[next] == sep))) {
                // We have ^\./ or /./
                // s~^\./+~~, s~/\./+~/~
                i = i + 2
                while i < end && chars[i] == sep {
                    i += 1
                }
                modified = true
                continue;
            }
            if ((sep == last || ret.isEmpty) && c == dot && next == end) {
                // We have ^/\.$ or /\.$
                // Remove the trailing ..
                i = next
                modified = true
                break
            }
            if (last == sep && c == sep) {
                // s~//~/~
                i = next
                modified = true
                continue;
            }
            let nextnext = (next < end ? next + 1 : end)
            if (last == sep
                && c == "."
                && next < end
                && chars[next] == "."
                && (nextnext >= end || chars[nextnext] == sep)) {
                // Replace /xxx/../ with /
                if let index = lastlastsep(ret, sep: sep) {
                    if !dotdotslash(ret, index) {
                        ret.removeLast(ret.count - index)
                        i = (nextnext < end  ? nextnext + 1: end)
                        modified = true
                        continue;
                    }
                }
            }
            ret.append(c)
            last = c
            i = next;
        }
        return modified ? String(ret) : string
    }

    /// Look for /xyz/ or ^xyz/ at end of the given string and return index for x.
    private static func lastlastsep(_ chars: [Character], sep: Character) -> Int? {
        let count = chars.count
        guard count > 1 else { return nil }
        let start = 0
        var end = count - 1
        while end > start {
            let prev = end - 1
            let c = chars[prev]
            if c == sep {
                return end
            }
            end = prev
        }
        return start
    }

    private static func dotdotslash(_ chars: [Character], _ index: Int) -> Bool {
        return index + 2 < chars.count
            && chars[index] == Character.ASCII.DOT
            && chars[index + 1] == Character.ASCII.DOT
            && chars[index + 2] == Character.ASCII.SLASH
    }
}

extension TextUtil {
    public static let UNITS = ["", "k", "m", "g", "t"]

    /**
     * @return Values with 4 or less digits.
     */
    public static func sizeUnit4(_ size: Int64) -> (Int64, String) {
        return valueUnit4(UNITS, 1000, size)
    }

    public static  func sizeUnit4String(_ size: Int64) -> String {
        let sizeunit = valueUnit4(UNITS, 1000, size)
        return "\(sizeunit.0) \(sizeunit.1)"
    }

    public static func sizeUnit4String(_ file: File) -> String {
        return sizeUnit4String(file.length)
    }

    public static func valueUnit4(_ units: Array<String>, _ max: Int64, _ size: Int64) -> (Int64, String) {
        var value = size
        var unit = 0
        let len = units.count
        let maxmax = max * 10
        while (unit < len - 1) {
            if (value < maxmax) {
                break
            }
            value = (value + 500) / 1000
            unit += 1
        }
        return (value, units[unit])
    }

    /**
     * Split at the first occurence of the sep.
     * @return (s, nil) if sep not found.
     */
    public static func split2(_ s: String, sep: String) -> (String, String?) {
        guard let index = s.range(of: sep) else { return (s, nil) }
        return (String(s[..<index.lowerBound]), String(s[index.upperBound...]))
    }
}

public struct Hex {
    public static let LOWER = "0123456789abcdef".bytes
    public static let UPPER = "0123456789ABCDEF".bytes

    public static func decode(_ string: String) throws -> Bytes {
        let hex = string.bytes
        let count = hex.count
        if count.isOdd { throw Exception(string) }
        var i = 0
        var ret = Bytes(reserve: count / 2)
        while (i  < count) {
            ret.append(try UInt8((decode(hex[i]) << 4) + decode(hex[i + 1])))
            i += 2
        }
        return ret
    }

    public static func encode(_ bytes: Bytes, _ uppercase: Bool = false) -> String {
        var ret = Bytes(reserve: bytes.count * 2)
        let hex = (uppercase ? UPPER : LOWER)
        for b in bytes {
            let n = Int(b) & 0xff
            ret.append(hex[n >> 4])
            ret.append(hex[n & 0x0f])
        }
        return String(bytes: ret, encoding: .ascii)!
    }

    public static func decode(_ c: Byte) throws -> Int {
        let n = Int(c) & 0xff
        if (n >= 0x61 && n <= 0x66) { return 10 + n - 0x61 }
        else if (n >= 0x41 && n <= 0x46) { return 10 + n - 0x41 }
        else if (n >= 0x30 && n <= 0x39) { return n - 0x30 }
        else { throw Exception("\(n)") }
    }
}

public func == (lhs: Basepath, rhs: Basepath) -> Bool {
    return lhs.dir == rhs.dir && lhs.name == rhs.name
}

public struct Basepath: Hashable {

    private var _dir: String?
    private var _name: String
    private var _base: String
    private var _suffix: String

    public var path : String {
        return sibling(_name)
    }

    public var dir : String? {
        return _dir
    }

    public var name : String {
        return _name
    }

    public var base : String {
        return _base
    }

    public var suffix : String {
        return _suffix
    }

    public var lcSuffix: String {
        return _suffix.lowercased()
    }

    public var ext: String? {
        return _suffix.count > 0 ? _suffix.substring(from: 1) : nil
    }

    public var lcExt: String? {
        if let s = self.ext {
            return s.lowercased()
        }
        return nil
    }

    public init(_ path: String) {
        (self._dir, self._name) = Basepath.splitDirName(path)
        (self._base, self._suffix) = Basepath.splitBaseSuffix(self._name)
    }

    public func sibling(_ newname: String) -> String {
        return _dir != nil ? _dir! + "/" + newname : newname
    }

    public func changeBase(_ newbase: String) -> String {
        return sibling(newbase + suffix)
    }

    public func changeSuffix(_ newsuffix: String) -> String {
        return sibling(base + newsuffix)
    }

    public var hashValue: Int {
        return path.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    /// Split path into directory and filename components.
    public static func splitDirName(_ path: String) -> (dir: String?, name: String) {
        // Remove trailing / to be compatible with File() constructor.
        let path1 = TextUtil.removeTrailing(File.SEP, from: path)
        if let index  = path1.range(of : "/", options: .backwards) {
            return (String(path1[..<index.lowerBound]), String(path1[index.upperBound...]))
        }
        return (nil, path1)
    }

    public static func splitBaseSuffix(_ name: String) -> (base: String, suffix: String) {
        if name.hasPrefix(".") && isDotOnly(name) { return (name, "") }
        if let index = name.range(of : ".", options: .backwards),
            index.lowerBound > name.startIndex {
            return (String(name[..<index.lowerBound]), String(name[index.lowerBound...]))
        }
        return (name, "")
    }

    private static func isDotOnly(_ name: String) -> Bool {
        return Array(name).all { $0 == "." }
    }
}
