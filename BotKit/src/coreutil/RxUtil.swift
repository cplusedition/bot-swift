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

/// NSRegularExpression wrapper.
/// Note that NSRegularExpression works on NSString which use utf16 representation.
public class Regex {
    
    private let regex: NSRegularExpression
    
    public init(_ string: String, _ options: NSRegularExpression.Options = []) throws {
        self.regex = try NSRegularExpression(pattern: string, options: options)
    }
    
    private enum FindState {
        case START
        case MATCHING
        case END
    }
    
    public class Matcher {
        private let input: String
        private let regex: NSRegularExpression
        private var range: NSRange
        private var findState = FindState.START
        private var result: NSTextCheckingResult?
        fileprivate init(_ input: String, _ regex: NSRegularExpression, _ range: NSRange? = nil) {
            self.input = input
            self.regex = regex
            self.range = range ?? NSRange(location: 0, length: input.utf16.count)
        }
       
        /// Anchored match.
        /// Note that unlike in Java, this only anchor at start, not at the end.
        /// @return true if match found.
        public func matches() -> Bool {
            findState = .START
            if let match = regex.firstMatch(in: input, options: [.anchored], range: range) {
                self.result = match
                return true
            }
            self.result = nil
            return false
        }
       
        public func matching() -> Matcher? {
            return matches() ? self : nil
        }
       
        public func find() -> Bool {
            switch findState {
            case .START:
                return find1(range)
            case .MATCHING:
                let e = end()!
                let r = NSRange(location: e, length: (range.location + range.length - e))
                return find1(r)
            case .END:
                return false
            }
        }
        
        public func finding() -> Matcher? {
            switch findState {
            case .START:
                return find1(range) ? self : nil
            case .MATCHING:
                let e = end()!
                let r = NSRange(location: e, length: (range.location + range.length - e))
                return find1(r) ? self : nil
            case .END:
                return nil
            }
        }
        
        /** Find and replace all matches. */
        public func replaceAll(_ replacement: String) -> String {
            return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: replacement)
        }

        private func find1(_ range: NSRange) -> Bool {
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                self.result = match
                findState = .MATCHING
                return true
            } else {
                self.result = nil
                findState = .END
                return false
            }
        }
        
        public func group(_ n: Int) -> String? {
            guard validrange(n) else { return nil }
            let range = result!.range(at: n)
            let start = input.index(input.startIndex, offsetBy: range.location)
            let end = input.index(start, offsetBy: range.length)
            // return input.substring(with: start..<end)
            return String(input[start..<end])
        }
       
        public func start(_ n: Int = 0) -> Int? {
            guard validrange(n) else { return nil }
            return result!.range(at: n).location
        }
       
        public func end(_ n: Int = 0) -> Int? {
            guard validrange(n) else { return nil }
            let range = result!.range(at: n)
            return range.location + range.length
        }
        
        private func validrange(_ n: Int) -> Bool {
            return result != nil && n >= 0 && n < result!.numberOfRanges
        }
    }
    
   public func matcher(_ string: String, _ range: NSRange? = nil) -> Matcher {
        return Matcher(string, regex, range)
    }

   public func matching(_ string: String, _ range: NSRange? = nil) -> Matcher? {
        return Matcher(string, regex, range).matching()
    }

    public func matches(_ string: String, _ range: NSRange? = nil) -> Bool {
        return Matcher(string, regex, range).matches()
    }

    public func finding(_ string: String, _ range: NSRange? = nil) -> Matcher? {
        return Matcher(string, regex, range).finding()
    }

    public func find(_ string: String, _ range: NSRange? = nil) -> Bool {
        return Matcher(string, regex, range).find()
    }
}

public class MatchUtil {
    
    public static func compile(_ regexs: String...) throws -> Array<Regex> {
        return try Array(regexs.map { s in try Regex(s) })
    }
    
    public static func compile<T>(_ regexs: T) throws -> Array<Regex> where T: Sequence, T.Element == String {
        return try Array(regexs.map { s in try Regex(s) })
    }
    
    /**
     * Match input using Regex.matches().
     * @return true if entire input matches include and not matches exclude.
     * If the regex is nil, it always match.
     */
    public static func matches(_ input: String, _ include: Regex?, _ exclude: Regex? = nil) -> Bool {
        if let include = include, !include.matches(input) { return false }
        if let exclude = exclude, exclude.matches(input) { return false }
        return true
    }
    
    /**
     * Match input using Regex.matches().
     * @return true if input matches one of the includes and none of the excludes.
     * If the regex is nil, it always match.
     */
    public static func matches(_ input: String, _ includes: [Regex]?, _ excludes: [Regex]? = nil) -> Bool {
        if let includes = includes, includes.none({ $0.matches(input) }) { return false }
        if let excludes = excludes, excludes.any({ $0.matches(input) }) { return false }
        return true
    }
    
    /**
     * Match input using Regex.find().
     * @return true if include is found in input and not found exclude.
     * If the regex is nil, it always match.
     */
    public static func find(_ input: String, _ include: Regex?, _ exclude: Regex? = nil) -> Bool {
        if let include = include, !include.find(input) { return false }
        if let exclude = exclude, exclude.find(input) { return false }
        return true
    }
    
    /**
     * Match input using Regex.find().
     * @return true if one of the includes is found in input and none of the excludes found.
     * If the regex is nil, it always match.
     */
    public static func find(_ input: String, _ includes: [Regex]?, _ excludes: [Regex]? = nil) -> Bool {
        if let includes = includes, includes.none({ $0.find(input) }) { return false }
        if let excludes = excludes, excludes.any({ $0.find(input) }) { return false }
        return true
    }
}
