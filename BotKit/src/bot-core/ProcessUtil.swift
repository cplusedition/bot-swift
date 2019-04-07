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

open class ExecutionException: Exception {
}

public protocol IOutputMonitor {
    var pipe: Pipe { get }
    /// Buffered output data.
    var buf: Data { get }
    /// Start monitoring pipe.fileHandleForReading in an async thread.
    func start()
    /// Wait for pipe.fileHandleForReading to close.
    func wait()
}

open class Future<T> {
    fileprivate let done = DispatchSemaphore(value: 0)
    fileprivate var result: T? = nil
    fileprivate var error: Error? = nil
    public init() {
    }
    /// Complete without error.
    public func fulfill(result: T) {
        self.result = result
        done.signal()
    }
    /// Complete with error.
    public func fulfill(error: Error) {
        self.error = error
        done.signal()
    }
    /// Wait for result/error indefinitely. Target should implement any
    /// timeout and throw an exception if neccessary.
    /// @throws ExecutionException on error.
    public func wait() throws -> T {
        done.wait()
        if let error = error {
            throw ExecutionException("\(error)")
        }
        return result!
    }
}

open class ProcessUtil {
    
    public class Builder {
        private let _cmd: String
        private var _arguments = Array<String>()
        private var _workdir = File.pwd
        private var _env: [String: String]? = nil
        private var _timeout: Int = Int(DateUtil.DAY)
        private var _input: Pipe? = nil
        private var _out:  IOutputMonitor? = nil
        private var _err: IOutputMonitor? = nil
        public init(_ cmd: String, _ args: String...) {
            self._cmd = cmd
            self._arguments.append(args)
        }
        public init<S>(_ cmd: String, _ args: S) where S: Sequence, S.Element == String {
            self._cmd = cmd
            self._arguments.append(contentsOf: args)
        }
        public func arguments(_ args: String...) -> Builder {
            self._arguments.append(args)
            return self
        }
        public func arguments<S>(_ args: S) -> Builder where S: Sequence, S.Element == String {
            self._arguments.append(contentsOf: args)
            return self
        }
        public func env(_ envs: [String: String]) -> Builder {
            var e: [String: String]
            if _env == nil {
                e = [String: String]()
                _env = e
            } else {
                e = _env!
            }
            e.add(envs)
            return self
        }
        public func workdir(_ dir: File) -> Builder {
            self._workdir = dir
            return self
        }
        public func timeout(_ ms: Int) -> Builder {
            self._timeout = ms
            return self
        }
        public func input(_ pipe: Pipe) -> Builder {
            self._input = pipe
            return self
        }
        /// Pipe data to stdin.
        public func input(_ code: @escaping Fun10<FileHandle>) -> Builder {
            let pipe = Pipe()
            self._input = pipe
            DispatchQueue.global().async {
                let out = pipe.fileHandleForWriting
                defer { out.closeFile() }
                code(out)
            }
            return self
        }
        /// Pipe stdout to the given IOutputMonitor. If not set, output goes to stdout.
        public func out(_ out: IOutputMonitor) -> Builder {
            self._out = out
            return self
        }
        /// Pipe stderr to the given IOutputMonitor. If not set, output goes to stderr.
        public func err(_ err: IOutputMonitor) -> Builder {
            self._err = err
            return self
        }
        /**
         * @param callback(process) Invoke when process is completed with or without error.
         */
        public func async<T>(_ callback: @escaping Fun21x<Process?, Error?, T>) -> Future<T> {
            let process = Process()
            let future = Future<T>()
            DispatchQueue.global().async {
                process.currentDirectoryURL = URL(fileURLWithPath: self._workdir.path)
                process.executableURL = URL(fileURLWithPath: self._cmd)
                process.arguments = self._arguments
                if let env = self._env {
                    process.environment = env
                }
                if let input = self._input {
                    process.standardInput = input
                }
                if let out = self._out {
                    process.standardOutput = out.pipe
                }
                if let err = self._err {
                    process.standardError = err.pipe
                }
                let done = DispatchSemaphore(value: 0)
                func result(_ process: Process?, _ error: Error?) {
                    if process != nil {
                        if let out = self._out { out.wait() }
                        if let err = self._err { err.wait() }
                    }
                    do {
                        let ret = try callback(process, error)
                        done.signal()
                        future.fulfill(result: ret)
                    } catch let e {
                        done.signal()
                        future.fulfill(error: e)
                    }
                }
                process.terminationHandler = { process in
                    result(process, nil)
                }
                do {
                    try process.run()
                    if let out = self._out { out.start() }
                    if let err = self._err { err.start() }
                } catch let e {
                    // Apparently, terminationHandler is not called on exception.
                    // The task is not launched in case such as command not found.
                    result(nil, e)
                }
                if done.wait(ms: self._timeout) == .timedOut {
                    if process.isRunning {
                        process.terminate()
                    }
                }
                process.waitUntilExit()
            }
            return future

        }
        public func backtick(_ callback: @escaping Fun31x<Int32, String, String, String> = defaultBacktickCallback) -> Future<String> {
            let out = OutputMonitor()
            let err = OutputMonitor()
            return self.out(out).err(err).async { process, error in
                guard let process = process else {
                    return try callback(-1, "", "\(String(describing: error))")
                }
                let rc = process.terminationStatus
                return try callback(
                    rc,
                    String(data: out.buf, encoding: .utf8)!,
                    String(data: err.buf, encoding: .utf8)!)
            }
        }
    }
    
    public static func defaultBacktickCallback(_ rc: Int32, _ out: String, _ err: String) throws -> String {
        guard rc == 0 else {
            throw ExecutionException("# rc=\(rc):\n# Err:\n\(err)\n# Out:\n\(out)")
        }
        return out
    }
    
    open class OutputMonitor: IOutputMonitor {
        public var buf = Data()
        public let pipe = Pipe()
        private let done = DispatchSemaphore(value: 0)
        public init()  {
        }
        public func start() {
            DispatchQueue.global().async {
                let input = self.pipe.fileHandleForReading
                defer { input.closeFile() }
                while(true) {
                    let data = input.availableData
                    if data.isEmpty { break }  // EOF
                    self.buf.append(data)
                }
                self.done.signal()
            }
        }
        public func wait() {
            done.wait()
        }
    }
}
