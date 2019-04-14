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

//////////////////////////////////////////////////////////////////////

public protocol ICoreLogger : ILog {

    var debugging: Bool { get }
    var prefix: String { get }

    /**
     * @return The system time in ms when the logger is created.
     */
    var startTime: Int64 { get }

    /**
     * @return The error Count.
     * Note that this method is synchronous.
     */
    var errorCount: Int { get }

    /**
     * Reset the error count.
     * @return The error count before reset.
     */
    @discardableResult
    func resetErrorCount() -> Int

    /**
     * Wait for all previous log task to complete and flush output.
     * Note that this method is synchronous.
     */
    func flush()

    /**
     * Suppress logging while executing the given code.
     */
    func quiet(_ code: Fun00)

    /**
     * Save log to a file.
     */
    func saveLog(_ file: File) throws

    /**
     * Get a copy of the log.
     * Note that this method is synchronous.
     */
    func getLog() -> Array<String>

    /** Log an error, ie. increment errorCount, without any log message. */
    func e()

    func d(_ msgs: String...)
    func i(_ msgs: String...)
    func w(_ msgs: String...)
    func e(_ msgs: String...)

    func d<T>(_ msgs: T) where T: Sequence
    func i<T>(_ msgs: T) where T: Sequence
    func w<T>(_ msgs: T) where T: Sequence
    func e<T>(_ msgs: T) where T: Sequence

    func dfmt(_ format: String, _ args: CVarArg...)
    func ifmt(_ format: String, _ args: CVarArg...)
    func wfmt(_ format: String, _ args: CVarArg...)
    func efmt(_ format: String, _ args: CVarArg...)

    /**
     * Debug message with timestamp.
     */
    func dd(_ msg: String)

    /**
     * Info message with timestamp.
     */
    func ii(_ msg: String)

    /**
     * Warning message with timestamp.
     */
    func ww(_ msg: String)
    
    /**
     * Error message with timestamp.
     */
    func ee(_ msg: String)
    
    /**
     * Enter a new scope.
     * It debug mode, it log a message with timestamp.
     */
    func enter(_ name: String?, _ msg: String?)

    /**
     * Enter a new scope, execute the code and leave the scope.
     * It debug mode, it log a message on enter and leave with timestamp.
     * The delta time in the leave message is the time elapsed since start of the scope.
     */
    func enter(_ name: String?, _ msg: String?, _ code: Fun00)

    /**
     * Enter a new scope, execute the code, leave the scope and return the result.
     * It debug mode, it log a message on enter and leave with timestamp.
     * The delta time in the leave message is the time elapsed since start of the scope.
     */
    func enter<T>(_ name: String?, _ msg: String?, _ code: Fun01<T>) -> T

    /**
     * Like enter(name, msg, code), but invoke leaveX() instead of leave() on leave.
     */
    func enterX(_ name: String?, _ msg: String?, _ code: Fun00x) throws

    /**
     * Like enter(name, msg, code), but invoke leaveX() instead of leave() on leave.
     * @throws IllegalStateException
     */
    func enterX<T>(_ name: String?, _ msg: String?, _ code: Fun01x<T>) throws -> T

    /**
     * Leave a scope.
     * In debug mode, it log a message with delta and timestamp.
     * The delta time is time elapsed since start of the scope.
     */
    func leave(_ msg: String?)

    /**
     * Like leave(msg), but throw an exception if there are errors logged.
     * Note that this method is synchronous.
     * @throws IllegalStateException
     */
    func leaveX(_ msg: String?) throws
}

// Shortcuts.
public extension ICoreLogger {

    func enter(_ name: String? = nil) {
        enter(name, nil)
    }
    
    func enter(_ name: String? = nil, _ code: Fun00) {
        enter(name, nil, code)
    }
    
    func enter<T>(_ name: String? = nil, _ code: Fun01<T>) -> T {
        return enter(name, nil, code)
    }
    
    func enter(_ c: AnyClass, _ msg: String? = nil) {
        enter("\(c)", msg)
    }
    
    func enter(_ c: AnyClass, _ msg: String? = nil, _ code: Fun00) {
        enter("\(c)", msg, code)
    }
    
    func enter<T>(_ c: AnyClass, _ msg: String? = nil, _ code: Fun01<T>) -> T {
        return enter("\(c)", msg, code)
    }
    
    func enterX(_ name: String? = nil, _ code: Fun00x) throws {
        try enterX(name, nil, code)
    }
    
    func enterX<T>(_ name: String? = nil, _ code: Fun01x<T>) throws -> T? {
        return try enterX(name, nil, code)
    }
    
    func enterX(_ c: AnyClass, _ msg: String? = nil, _ code: Fun00x) throws {
        try enterX("\(c)", msg, code)
    }

    func enterX<T>(_ c: AnyClass, _ msg: String? = nil, _ code: Fun01x<T>) throws -> T? {
        return try enterX("\(c)", msg, code)
    }

    func leave() {
        leave(nil)
    }
    
    func leaveX() throws {
        try leaveX(nil)
    }
    
    /**
     * Check that at least one error occurs in code().
     * If so, clear the error status, otherwise log an error.
     */
    func expectError(_ msg: String, _ code: @escaping Fun00) {
        enter(nil, nil) {
            code()
            if (resetErrorCount() == 0) {
                e(msg)
            }
        }
    }
    
    static func fmt(_ value: Double) -> String {
        return (value >= 1000) ? String(format: "%6d", Int(value)) : String(format: "%6.2f", value)
    }
}

//////////////////////////////////////////////////////////////////////

public protocol ICoreLoggerLifecycleListener {
    func onStart(_ msg: String, _ starttime: Int64, _ logger: Fun10<String>)
    func onDone(_ msg: String, _ endtime: Int64, _ errors: Int, _ logger: Fun10<String>)
}

////////////////////////////////////////////////////////////////////////

/**
 * A thread safe logger.
 * Note that unless otherwise specified, all calls are asynchronous.
 * In general, methods that retreive status, eg. errorCount, are synchronous.
 */
open class CoreLogger: ICoreLogger {

    public let debugging: Bool
    public let startTime: Int64
    public let prefix: String
    private let delegate: Delegate

    public init(debugging: Bool, startTime: Int64 = DateUtil.ms, prefix: String = "####") {
        self.debugging = debugging
        self.startTime = startTime
        self.prefix = prefix
        self.delegate = Delegate(debugging, startTime, prefix)
    }

    ////////////////////////////////////////////////////////////////////////

    private class Delegate{

        private let debugging: Bool
        private var startTime: Int64
        private let prefix: String

        private let prefixEnter: String
        private let prefixTimestamp: String
        private let callStack = Stack<Info>()
        private let quietStack = Stack<Bool>()
        private var logs = Array<String>()
        private var listeners = Array<ICoreLoggerLifecycleListener>()
        private var quiet = false
        private var errorCount = 0
        private let k = Double(1000)
        private let executor = DispatchQueue(label: "L")

        init(_ debugging: Bool, _ startTime: Int64, _ prefix: String) {
            self.debugging = debugging
            self.startTime = startTime
            self.prefix = prefix
            self.prefixEnter = "\(prefix) +++++++"
            self.prefixTimestamp = "\(prefix)        "
        }
        
        private struct Info {
            let name: String?
            let errorCount: Int
            let startTime: Int64
        }

        func getErrorCount() -> Int {
            return executor.sync {
                return errorCount
            }
        }

        @discardableResult
        func resetErrorCount() -> Int {
            return executor.sync {
                let ret = errorCount
                errorCount = 0
                return ret
            }
        }

        func flush() {
            executor.sync {
                flushall()
            }
        }

        func log(_ msg: String, _ e: Error? = nil, _ timestamp: Bool, _ error: Bool = false) {
            let time = (timestamp) ? DateUtil.ms : nil
            executor.async {
                if (error) {
                    self.errorCount += 1
                    self.flushall()
                    self.log1(msg, e, time, nil)
                } else {
                    self.flushall()
                    self.log1(msg, e, time, nil)
                }
            }
        }

        func e() {
            executor.async {
                self.errorCount += 1
            }
        }

        func enter(_ name: String?, _ msg: String?) {
            let time = DateUtil.ms
            executor.async {
                self.enter1(name, msg, time)
            }
        }

        func leave(_ msg: String?) {
            let time = DateUtil.ms
            executor.async {
                self.leave1(msg, time)
            }
        }

        /// @throws IllegalStateException
        func leaveX(_ msg: String?) throws {
            let time = DateUtil.ms
            try executor.sync {
                if (errorCount > 0) {
                    let m = U.join(callStack.peek()!.name, msg)
                    leave1(msg, time)
                    throw IllegalStateException(m)
                } else {
                    leave1(msg, time)
                }
            }
        }

        /// @throws IllegalStateException
        func leaveXX(_ msg: String?, _ e: Error) -> Error {
            let time = DateUtil.ms
            return executor.sync {
                self.errorCount += 1
                self.flushall()
                let m = U.join(callStack.peek()!.name, msg)
                self.log1(m, e, time, nil)
                leave1(msg, time)
                return IllegalStateException(m)
            }
        }
        
        func quiet(_ code: Fun00) {
            executor.async {
                self.quietStack.push(self.quiet)
                self.quiet = true
            }
            defer {
                executor.async {
                    self.quiet = self.quietStack.pop()!
                }
            }
            code()
        }

        func saveLog(_ file: File) throws {
            try executor.sync {
                guard file.mkparent() != nil else { throw IOException() }
                try file.writeText(logs.joined())
            }
        }

        func getLog() -> Array<String> {
            return executor.sync {
                return Array(logs)
            }
        }

        func addLifecycleListener(_ listener: ICoreLoggerLifecycleListener) {
            executor.async {
                self.listeners.append(listener)
            }
        }

        ////////////////////////////////////////////////////////////////////////

        private func flushall() {
        }

        private func log1(_ msg: String, _ e: Error? = nil, _ start: Int64?, _ end: Int64?) {
            if (quiet) {
                return
            }
            let s: String
            if let start = start, let end = end {
                s = "\(prefix) \(fmt(Double(end - start) / k))/\(fmt(Double(end - startTime) / k)) s: \(msg)"
            } else if let start = start {
                s = "\(prefixTimestamp)\(fmt(Double(start - startTime) / k)) s: \(msg)"
            } else if let end = end {
                s = "\(prefixEnter)\(fmt(Double(end - startTime) / k)) s: \(msg)"
            } else {
                s = msg
            }
            if (e == nil) {
                smartlog(s)
            } else {
                let w = StringPrintWriter()
                if (s.hasSuffix(TextUtil.LINESEP)) {
                    w.print(s)
                } else if !s.isEmpty {
                    w.println(s)
                }
                w.println("\(e!)")
                let str = w.toString()
                print(str)
                self.logs.append(str)
            }
        }

        private func smartlog(_ msg: String) {
            if msg.hasSuffix(TextUtil.LINESEP) {
                print(msg, separator: "")
                self.logs.append(msg)
            } else if !msg.isEmpty {
                print(msg)
                self.logs.append(msg)
                self.logs.append(TextUtil.LINESEP)
            }
        }

        private func enter1(_ name: String?, _ msg: String?, _ time: Int64) {
            callStack.push(Info(name: name, errorCount: errorCount, startTime: time))
            if debugging && callStack.count == 1 {
                listeners.forEach {
                    $0.onStart(name ?? "", startTime) { s in
                        log1(s, nil, nil, time)
                    }
                }
            }
            errorCount = 0
            if debugging && name != nil {
                var b = String()
                for _ in 0..<callStack.count {
                    b.append("+")
                }
                if !b.isEmpty { b.append(" ") }
                b.append(name!)
                if let m = msg { b.append(": \(m)") }
                log1(b, nil, nil, time)
            }
        }

        private func leave1(_ msg: String?, _ time: Int64) {
            let info = callStack.pop()!
            errorCount += info.errorCount
            if (debugging && info.name != nil) {
                var b = String()
                for _ in 0...callStack.count {
                    b.append("-")
                }
                if !b.isEmpty { b.append(" ") }
                b.append(info.name!)
                if let m = msg { b.append(": \(m)") }
                log1(b, nil, info.startTime, time)
            }
            if (callStack.isEmpty) {
                listeners.forEach {
                    $0.onDone(info.name ?? "", time, errorCount) { s in
                        log1(s, nil, nil, time)
                    }
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////

    /** @return The errorCount. Note that this method is synchronous. */
    public var errorCount: Int {
        return delegate.getErrorCount()
    }

    ////////////////////////////////////////////////////////////////////////

    @discardableResult
    public func resetErrorCount() -> Int {
        return delegate.resetErrorCount()
    }

    public func flush() {
        delegate.flush()
    }

    public func quiet(_ code: Fun00) {
        delegate.quiet(code)
    }

    public func saveLog(_ file: File) throws {
        try delegate.saveLog(file)
    }

    /**
     * @ return The log entries.
     * Note that this method is synchronous.
     */

    public func getLog() -> Array<String> {
        return delegate.getLog()
    }

    public func addLifecycleListener(_ listener: ICoreLoggerLifecycleListener) {
        delegate.addLifecycleListener(listener)
    }

    ////////////////////////////////////////////////////////////////////////

    public func d(_ msg: String) {
        if (debugging) {
            delegate.log(msg, nil, false)
        }
    }
    
    public func i(_ msg: String) {
        delegate.log(msg, nil, false)
    }
    
    public func w(_ msg: String) {
        delegate.log(msg, nil, false)
    }
    
    public func e(_ msg: String) {
        delegate.log(msg, nil, false, true)
    }
    
    
    public func d(_ msg: String, _ e: Error?) {
        if (debugging) {
            delegate.log(msg, e, false)
        }
    }

    public func i(_ msg: String, _ e: Error?) {
        delegate.log(msg, (debugging ? e : nil), false)
    }

    public func w(_ msg: String, _ e: Error?) {
        delegate.log(msg, e, false)
    }

    public func e(_ msg: String, _ e: Error?) {
        delegate.log(msg, e, false, true)
    }

    public func e() {
        delegate.e()
    }

    public func dd(_ msg: String) {
        if (debugging) {
            delegate.log(msg, nil, true, false)
        }
    }

    public func ii(_ msg: String) {
        delegate.log(msg, nil, true, false)
    }

    public func ww(_ msg: String) {
        delegate.log(msg, nil, true, false)
    }
    
    public func ee(_ msg: String) {
        delegate.log(msg, nil, true, true)
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    public func d<T>(_ msgs: T) where T: Sequence {
        if (debugging) {
            delegate.log(msgs.map { "\($0)" }.joined(separator: TextUtil.LINESEP), nil, false)
        }
    }
    
    public func i<T>(_ msgs: T) where T: Sequence {
        delegate.log(msgs.map { "\($0)" }.joined(separator: TextUtil.LINESEP), nil, false)
    }
    
    public func w<T>(_ msgs: T) where T: Sequence {
        delegate.log(msgs.map { "\($0)" }.joined(separator: TextUtil.LINESEP), nil, false)
    }
    
    public func e<T>(_ msgs: T) where T: Sequence {
        delegate.log(msgs.map { "\($0)" }.joined(separator: TextUtil.LINESEP), nil, false, true)
    }

    ////////////////////////////////////////////////////////////////////////

    public func dfmt(_ format: String, _ args: CVarArg...) {
        if (debugging) {
            d(String(format: format, arguments: args))
        }
    }

    public func ifmt(_ format: String, _ args: CVarArg...) {
        i(String(format: format, arguments: args))
    }

    public func wfmt(_ format: String, _ args: CVarArg...) {
        w(String(format: format, arguments: args))
    }

    public func efmt(_ format: String, _ args: CVarArg...) {
        e(String(format: format, arguments: args))
    }

    /**
     * Print multi-line debug messages without timestamp
     */
    public func d(_ msgs: String...) {
        d(msgs)
    }

    /**
     * Print multi-line info messages without timestamp
     */
    public func i(_ msgs: String...) {
        i(msgs)
    }

    /**
     * Print multi-line warn messages without timestamp
     */
    public func w(_ msgs: String...) {
        w(msgs)
    }

    /**
     * Print multi-line error messages without timestamp
     */
    public func e(_ msgs: String...) {
        e(msgs)
    }

    ////////////////////////////////////////////////////////////////////////

    public func enter(_ name: String? = nil, _ msg: String? = nil) {
        delegate.enter(name, msg)
    }

    public func enter(_ name: String? = nil, _ msg: String? = nil, _ code: Fun00) {
        delegate.enter(name, msg)
        defer { delegate.leave(msg) }
        code()
    }

    public func enter<T>(_ name: String? = nil, _ msg: String? = nil, _ code: Fun01<T>) -> T {
        delegate.enter(name, msg)
        defer { delegate.leave(msg) }
        return code()
    }

    public func enterX(_ name: String? = nil, _ msg: String? = nil, _ code: Fun00x) throws {
        delegate.enter(name, msg)
        do {
            try code()
        } catch let e {
            self.e(U.join(name, msg), e)
        }
        try leaveX(msg)
    }

    public func enterX<T>(_ name: String? = nil, _ msg: String? = nil, _ code: Fun01x<T>) throws -> T {
        delegate.enter(name, msg)
        let ret: T
        do {
            ret = try code()
        } catch let e {
            throw delegate.leaveXX(msg, e)
        }
        try leaveX(msg)
        return ret
        
    }

    public func leave(_ msg: String? = nil) {
        delegate.leave(msg)
    }

    public func leaveX(_ msg: String? = nil) throws {
        try delegate.leaveX(msg)
    }
}

fileprivate struct U {
    static func join(_ name: String?, _ msg: String?) -> String {
        var ret = name ?? ""
        if let m = msg {
            ret.append(": ")
            ret.append(m)
        }
        return ret
    }
}

////////////////////////////////////////////////////////////////////////
