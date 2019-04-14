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


public func < (lhs: GA, rhs: GA) -> Bool {
    return lhs.groupId < rhs.groupId || lhs.groupId == rhs.groupId && lhs.artifactId < rhs.artifactId
}

public func ==(lhs: GA, rhs: GA) -> Bool {
    return lhs === rhs || lhs.groupId == rhs.groupId && lhs.artifactId == rhs.artifactId
}

open class GA: Comparable, Hashable {
    
    public let groupId: String
    public let artifactId: String
    
    public init(_ groupid: String, _ artifactid: String) {
        self.groupId = groupid
        self.artifactId = artifactid
    }
    
    public var groupPath: String { return groupId.replacingOccurrences(of: ".", with: "/") }
    public var ga: String { return "\(groupId):\(artifactId)" }
    public var path: String { return "\(groupPath)/\(artifactId)" }
    
    public var hashValue: Int {
        var result = groupId.hashValue
        result = result << 5 ^ artifactId.hashValue
        return result
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(groupId)
        hasher.combine(artifactId)
    }
    
    /**
     * Create GA from path in forms:
     * group/artifact
     */
    public static func fromPath(_ rpath: String) -> GA? {
        let a = rpath.components(separatedBy: File.SEP)
        if a.count < 2 || a.any { $0.isEmpty } {
            return nil
        }
        let artifact = String(a.last!)
        let group = a.prefix(a.count - 1).joined(separator: ".")
        return GA(group, artifact)
    }
    
    /**
     * Create GA from gav in forms:
     * group:artifact
     */
    public static func fromGA(_ gav: String) -> GA? {
        let a = gav.components(separatedBy: ":")
        if a.count != 2 || a.any { $0.isEmpty } {
            return nil
        }
        return GA(String(a[0].replacingOccurrences(of: "/", with: ".")), String(a[1]))
    }
    
    /**
     * Create GA from either path or ga forms.
     */
    public static func from(_ s: String) -> GA? {
        if s.contains(":") {
            return fromGA(s)
        }
        return fromPath(s)
    }
    
    /**
     * Create GA from either path or ga forms.
     * Like GA.from() but fail on error instead of returning nil.
     */
    public static func of(_ s: String) -> GA {
        if s.contains(":") {
            guard let ret = fromGA(s) else { BU.fail(s) }
            return ret
        }
        guard let ret = fromPath(s)  else { BU.fail(s) }
        return ret
    }
    
    /// Read GAs from the given file.
    public static func read(_ ret: inout [GA], _ file: File, _ onerror: Fun10<String>? = nil) throws {
        try Without.comments(file) { line in
            if let ga = from(line) {
                ret.append(ga)
            } else {
                onerror?(line)
            }
        }
    }
    
    public static func write<T>(_ file: File, _ gas: T) throws where T:Collection, T.Element==GA {
        try With.outputStream(file) { out in
            for ga in gas {
                try out.writeFully(ga.ga.data(using: .utf8)!)
                try out.writeFully(TextUtil.LINESEP_UTF8)
            }
        }
    }
}

public func < (lhs: GAV, rhs: GAV) -> Bool {
    return lhs.ga < rhs.ga || lhs.ga == rhs.ga && lhs.version < rhs.version
}

public func == (lhs: GAV, rhs:GAV) -> Bool {
    return lhs.ga == rhs.ga && lhs.version == rhs.version
}

open class GAV: Comparable, Hashable {
    
    public let ga: GA
    public let version: ArtifactVersion
    public var groupId: String { return ga.groupId }
    public var artifactId: String { return ga.artifactId }
    
    public init(_ ga: GA, _ version: ArtifactVersion) {
        self.ga = ga
        self.version = version
    }
    
    public convenience init(_ group: String, _ artifact: String, _ version: String) {
        self.init(GA(group, artifact), ArtifactVersion.parse(version))
    }
    
    /** @return GAV in form: groupId:artifactId:version. */
    public var gav: String { return "\(groupId):\(artifactId):\(version)" }
    
    /** @return GAV in path form: groupId/artifactId/version. */
    public var path: String { return "\(ga.path)/\(version)" }
    
    /** @return Artifact path in form: groupId/artifactId/version/artifactId-version. */
    public var artifactPath: String { return "\(ga.path)/\(version)/\(artifactId)-\(version)" }
    
    public func artifactPath(_ suffix: String) -> String {
        return "\(artifactPath)\(suffix)"
    }
    
    public func artifactPaths() -> [String] {
        var ret = Array<String>()
        artifactPaths(&ret)
        return ret 
    }
    
    public func artifactPaths<T>(_ ret: inout T) where T:RangeReplaceableCollection, T.Element==String {
        artifactPaths(&ret, ".pom")
        artifactPaths(&ret, ".jar")
        artifactPaths(&ret, "-source.jar")
    }
    
    public func artifactPaths<T>(_ ret: inout T, _ suffix: String) where T: RangeReplaceableCollection, T.Element==String {
        artifactPath(&ret, suffix)
        artifactPath(&ret, suffix + ".sha1")
        artifactPath(&ret, suffix + ".asc")
    }
    
    public func artifactPath<T>(_ ret: inout T, _ suffix: String) where T:RangeReplaceableCollection, T.Element==String {
        ret.append("\(artifactPath)\(suffix)")
    }
    
    public var hashValue: Int {
        var result = groupId.hashValue
        result = result << 5 ^ artifactId.hashValue
        result = result << 5 ^ version.hashValue
        return result
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(groupId)
        hasher.combine(artifactId)
        hasher.combine(version)
    }
    
    /**
     * Create GAV from path in forms:
     * group/artifact/version
     * group/artifact/version/xxx.pom
     */
    public static func fromPath(_ rpath: String) -> GAV? {
        let a = rpath.components(separatedBy: File.SEP)
        if a.count < 3 || a.any { $0.isEmpty } {
            return nil
        }
        var version = a.last!
        var index = a.count - 2
        if (version.hasSuffix(".pom")) {
            if a.count < 4 {
                return nil
            }
            version = a[index]
            index -= 1
        }
        let artifact = a[index]
        let group = a[0..<index].joined(separator: ".")
        return GAV(group, artifact, version)
    }
    
    /**
     * Create GAV from gav in forms:
     * group:artifact:version
     * group:artifact:version:packaging
     */
    public static  func fromGAV(_ gav: String) -> GAV? {
        let a = gav.components(separatedBy: ":")
        if a.any({ $0.isEmpty }) { return nil }
        switch a.count {
        case 3, 4: return GAV(a[0].replacingOccurrences(of: "/", with: "."), a[1], a[2])
        default: return nil
        }
    }
    
    /**
     * Create GAV from either path or gav forms.
     */
    public static func from(_ s: String) -> GAV? {
        if s.contains(":") {
            return fromGAV(s)
        }
        return fromPath(s)
    }
    
    /**
     * Create GAV from either path or gav forms.
     * Like GAV.from() but fail on error instead of returning nil.
     */
    public static func of(_ s: String) -> GAV {
        if s.contains(":") {
            guard let ret = fromGAV(s) else { BU.fail(s) }
            return ret
        }
        guard let ret = fromPath(s) else { BU.fail(s) }
        return ret
    }
    
    public static func read<T>(_ ret: inout T, _ file: File, _ onerror: Fun10<String>? = nil) throws where T: RangeReplaceableCollection, T.Element==GAV {
        try Without.comments(file) { line in
            if let gav = from(line) {
                ret.append(gav)
            } else {
                onerror?(line)
            }
        }
    }
    
    public static func write<T>(_ file: File, _ gavs: T) throws where T:Collection, T.Element==GAV {
        try With.outputStream(file) { out in
            for gav in gavs {
                try out.writeFully(gav.gav.data(using: .utf8)!)
                try out.writeFully(TextUtil.LINESEP_UTF8)
            }
        }
    }
}

/**
 * Parse maven version numbers.
 */
open class ArtifactVersion: Comparable, Hashable {
    public let unparsed: String
    public let majorVersion: Int
    public let minorVersion: Int
    public let incrementalVersion: Int
    public let extraVersion: Int
    public let buildNumber: Int
    public let qualifier: String?
    
    public init(_ unparsed: String,
         _ majorVersion: Int,
         _ minorVersion: Int,
         _ incrementalVersion: Int,
         _ extraVersion: Int,
         _ buildNumber: Int,
         _ qualifier: String?
        ) {
        self.unparsed = unparsed
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.incrementalVersion = incrementalVersion
        self.extraVersion = extraVersion
        self.buildNumber = buildNumber
        self.qualifier = qualifier
    }
    
    public static func <(lhs: ArtifactVersion, rhs: ArtifactVersion) -> Bool {
        func weight(_ qualifier: String?) -> Int {
            guard var q = qualifier else { return 0 }
            if (q.hasPrefix("-")) {
                q = q.substring(from: 1)
            }
            q = q.lowercased()
            if ("ga" == q || "final" == q || "fcs" == q) {
                return 1
            }
            if (q.hasPrefix("sp") && q.count > 2) {
                guard let v = Int(q.substring(from: 2)) else { return -1 }
                return v + 1
            }
            return -1
        }
        
        var result = lhs.majorVersion - rhs.majorVersion
        if (result == 0) {
            result = lhs.minorVersion - rhs.minorVersion
            if (result == 0) {
                result = lhs.incrementalVersion - rhs.incrementalVersion
                if (result == 0) {
                    result = lhs.extraVersion - rhs.extraVersion
                    if (result == 0) {
                        let w = weight(lhs.qualifier)
                        let ow = weight(rhs.qualifier)
                        if (w != ow) {
                            return w < ow
                        }
                        if (w != 0 && ow != 0) {
                            result = U.compareQualifier(lhs.qualifier, rhs.qualifier)
                        }
                        if (result == 0) {
                            result = lhs.buildNumber - rhs.buildNumber
                        }
                    }
                }
            }
        }
        return result < 0
    }
    
    public static func == (lhs: ArtifactVersion, rhs: ArtifactVersion) -> Bool {
        return lhs === rhs
            || lhs.majorVersion == rhs.majorVersion
            && lhs.minorVersion == rhs.minorVersion
            && lhs.incrementalVersion == rhs.incrementalVersion
            && lhs.extraVersion == rhs.extraVersion
            && lhs.buildNumber == rhs.buildNumber
            && lhs.qualifier == rhs.qualifier
    }
    
    public var hashValue: Int {
        return unparsed.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unparsed)
    }
    
    public class InvalidVersionException : Exception {
    }
    
    public static let EMPTY = ArtifactVersion("", 0, 0, 0, 0, 0, "")
    
    public static func parse(_ version: String) -> ArtifactVersion {
        return U.parse1(version)
    }
    
    public static func sort<T>(_ versions: T) -> Array<String> where T:Sequence, T.Element==String {
        var set = Set<ArtifactVersion>()
        for version in versions {
            set.insert(ArtifactVersion.parse(version))
        }
        return set.sorted().map { ver in return ver.unparsed }
    }
    
    fileprivate struct K {
        static let ZERO = Int.ASCII.ZERO
        static let NINE = Int.ASCII.NINE
        static let A = Int.ASCII.A
        static let Z = Int.ASCII.Z
        static let a = Int.ASCII.a
        static let z = Int.ASCII.z
        static let TILE = Int.ASCII.TILDE
    }
    
    fileprivate struct U {

        static func isdigit(_ c: Int) -> Bool {
            return c >= K.ZERO && c <= K.NINE
        }
        
        static func compareQualifier<T: StringProtocol>(_ ver1: T?, _ ver2: T?) -> Int {
            guard let v1 = ver1 else { return (ver2 == nil) ? 0 : -1 }
            guard let v2 = ver2 else { return 1 }
            return compareQualifier1(v1, v2)
        }
        
        static func compareQualifier1<T: StringProtocol>(_ ver1: T, _ ver2: T) -> Int {
            func weight(_ c: Int) -> Int {
                if (c == K.TILE) { return -2 }
                if (c == -1
                    || c >= K.ZERO && c <= K.NINE
                    || c >= K.A && c <= K.Z
                    || c >= K.a && c <= K.z
                    ) { return c }
                return c + 256
            }
            
            let v1 = StringScanner(ver1)
            let v2 = StringScanner(ver2)
            while (true) {
                var c1 = v1.get()
                var c2 = v2.get()
                if (isdigit(c1) && isdigit(c2)) {
                    // Skip leading 0
                    while (c1 == K.ZERO) {
                        c1 = v1.get()
                    }
                    // Skip leading 0
                    while (c2 == K.ZERO) {
                        c2 = v2.get()
                    }
                    var r = 0
                    while (isdigit(c1) && isdigit(c2)) {
                        if (r == K.ZERO) {
                            r = c1 - c2
                        }
                        c1 = v1.get()
                        c2 = v2.get()
                    }
                    if (isdigit(c1)) {
                        // v1 is numeric and v2 is not, v1 is larger
                        return 1
                    }
                    if (isdigit(c2)) {
                        // v2 is numeric and v1 is not, v2 is larger
                        return -1
                    }
                    if (r != 0) {
                        return r
                    }
                }
                c1 = weight(c1)
                c2 = weight(c2)
                let r = c1 - c2
                if (r != 0) {
                    return r
                }
                // If we reach end of either string, it is a tie.
                if (c1 == -1 || c2 == -1) {
                    return 0
                }
            }
        }
        
        static func parse1(_ version: String) -> ArtifactVersion {
            var majorVersion = 0
            var minorVersion = 0
            var incrementalVersion = 0
            var extraVersion = 0
            var buildNumber = 0
            var qualifier: String? = nil
            let part1: String
            var part2: String? = nil
            if let index = version.lastIndex(where: { $0 == "-" }) { // Check for build number, eg. 1.0-aplha-9
                part1 = String(version[version.startIndex..<index])
                part2 = String(version[version.index(after: index)...])
            } else {
                part1 = version
            }
            let dot = Int.ASCII.DOT
            let s = VersionScanner(part1)
            while (true) {
                var n = s.nextInt()
                if (n < 0) {
                    break
                }
                majorVersion = n
                if (s.remaining() == 0) {
                    break
                }
                if (s.get() != dot) {
                    s.unget()
                    break
                }
                n = s.nextInt()
                if (n < 0) {
                    break
                }
                minorVersion = n
                if (s.remaining() == 0) {
                    break
                }
                if (s.get() != dot) {
                    s.unget()
                    break
                }
                n = s.nextInt()
                if (n < 0) {
                    break
                }
                incrementalVersion = n
                if (s.remaining() == 0) {
                    break
                }
                if (s.get() != dot) {
                    s.unget()
                    break
                }
                n = s.nextInt()
                if (n < 0) {
                    break
                }
                extraVersion = n
                if (s.remaining() == 0) {
                    break
                }
                if (s.get() != dot) {
                    s.unget()
                }
                break
            }
            if let p2 = part2 {
                let ss = VersionScanner(p2)
                let n = ss.nextInt()
                if (ss.remaining() == 0) {
                    buildNumber = n
                    part2 = nil
                }
            }
            if (s.remaining() > 0 || part2 != nil) {
                qualifier = (s.remaining() > 0 ? s.remain() : "") + (part2 == nil ? "" : "-\(part2!)")
            }
            return ArtifactVersion(
                version,
                majorVersion,
                minorVersion,
                incrementalVersion,
                extraVersion,
                buildNumber,
                qualifier
            )
        }
        
        private class StringScanner<T: StringProtocol> {
            private let source: Array<UInt16>
            private let length: Int
            private var index = 0
            init(_ source: T) {
                self.source = Array(source.utf16)
                self.length =  source.count
            }
            
            /**
             * @return The next char as integer value, -1 if end of string.
             */
            func get() -> Int {
                guard index < length else { return -1 }
                defer { index += 1 }
                return Int(source[index])
            }
            
            func unget() {
                precondition(index>0)
                index -= 1
            }
            
            func position() -> Int {
                return index
            }
            
            func remaining() -> Int {
                return length - index
            }
            
            func remain() -> String {
                let a = Array(source[index...])
                return String(utf16CodeUnits: UnsafePointer(a), count: a.count)
            }
        }
        
        private class VersionScanner<T: StringProtocol> {
            private let scanner: StringScanner<T>
            init(_ source: T) {
                self.scanner = StringScanner(source)
            }
            func nextInt() -> Int {
                var ret = -1
                while (scanner.remaining() > 0) {
                    let c = scanner.get()
                    if !U.isdigit(c) {
                        scanner.unget()
                        break
                    }
                    ret = (ret > 0 ? ret * 10 : 0) + (c - K.ZERO)
                }
                return ret
            }
            
            func get() -> Int {
                return scanner.get()
            }
            
            func unget() {
                scanner.unget()
            }
            
            func remaining() -> Int {
                return scanner.remaining()
            }
            
            func remain() -> String {
                return scanner.remain()
            }
        }
    }
}

extension GA: CustomStringConvertible {
    public var description: String {
        return ga
    }
}

extension GAV: CustomStringConvertible {
    public var description: String {
        return gav
    }
}

extension ArtifactVersion: CustomStringConvertible {
    public var description: String {
        return unparsed
    }
}

extension ArtifactVersion: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "[\(majorVersion), \(minorVersion), \(incrementalVersion), \(extraVersion), \(qualifier ?? "null"), \(buildNumber)]"
    }
}


