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

//	////////////////////////////////////////////////////////////////////

public protocol ILog {
    func d(_ msg: String)
    func i(_ msg: String)
    func w(_ msg: String)
    func e(_ msg: String)
    func d(_ msg: String, _ e: Error?)
    func i(_ msg: String, _ e: Error?)
    func w(_ msg: String, _ e: Error?)
    func e(_ msg: String, _ e: Error?)
}

//	////////////////////////////////////////////////////////////////////

open class With {
    
    /**
     * Run the given code with a done(result: T?) callback.
     * @return The result.
     * @throws Errors.Timeout if timeout occurs.
     */
    public static func timeout<T>(seconds: Double,  _ code: @escaping ((T?)->Void) -> Void) throws -> T? {
        let done = DispatchSemaphore(value: 0)
        var result: T? = nil
        DispatchQueue.global().async {
            code { ret in
                result = ret
                done.signal()
            }
        }
        if done.wait(seconds: seconds) == .timedOut {
            throw TimeoutException()
        }
        return result
    }
    
    /** @return the throwable thrown by the code or null. */
    @discardableResult
    public static func error(_ code: Fun00x) -> Error? {
        do {
            try code()
            return nil
        } catch let e {
            return e
        }
    }
    
    /**
     * If code throws a Throwable, ignores it.
     * If code does not throw a Throwable, throw an IllegalStateException.
     */
    public static func errorOrThrow(_ code: Fun00x) throws {
        do {
            try code()
        } catch {
            // Expected throwable
            return
        }
        throw IllegalStateException()
    }
    
    /**
     *  If code() does not return null then throw an IllegalStateException.
     */
    public static func nullOrThrow<T>(_ code: Fun01<T?>) throws {
        if let error = code() {
            throw IllegalStateException("\(error)")
        }
    }
    
    /** @return nil if input is nil, otherwise return code(input) */
    public static func nullable<T, R>(_ input: T?, _ code: Fun11<T, R>) -> R? {
        guard let input = input else { return nil }
        return code(input)
    }
    
    public static func inputStream<T>(_ file: File, _ code: Fun11x<IInputStream, T>) throws -> T {
        let input = try FileUtil.openInputStream(file)
        defer { input.close() }
        return try code(input)
    }
    
    public static func bufferedInputStream<T>(_ file: File, _ code: Fun11x<IBufferedInputStream, T>) throws -> T {
        return try With.inputStream(file) { input in
            let buffered = BufferedInputStream(input)
            defer { buffered.close() }
            return try code(buffered)
        }
    }
    
    public static func outputStream<T>(_ file: File, _ code: Fun11x<IOutputStream, T>) throws -> T {
        let output = try FileUtil.openOutputStream(file)
        defer { output.close() }
        return try code(output)
    }
    
    /** Process file content by lines, with line separators stripped. */
    public static func lines(_ file: File, _ encoding: String.Encoding = .utf8, _ code: Fun10x<String>) throws {
        try With.bufferedInputStream(file) { input in
            while let line = try input.readline(encoding) {
                try code(line)
            }
        }
    }
    
    /**
     * Rewrite a file with a text content transform.
     *
     * @param code(String): String?.
     */
    public static func rewriteText(_ file: File, _ encoding: String.Encoding = .utf8, _ code: Fun11<String, String>) throws -> Bool {
        let input = try file.readText(encoding)
        let output = code(input)
        let modified = (output != input)
        if (modified) {
            try file.writeText(output, encoding)
        }
        return modified
    }
    
    /**
     * Rewrite a file with a line by line transform through a tmp file.
     * If there are no changes, input file stay intact and tmp file is deleted.
     * If there are changes, tmp file is copied over to the input file, then get deleted.
     *
     * @param code(String): String?.
     * @return true if file is modified.
     */
    public static func rewriteLines(_ file: File, _ encoding: String.Encoding = .utf8, _ code: Fun11<String, String?>) throws -> Bool {
        var modified = false
        try With.tmpfile { tmpfile in
            try With.bufferedInputStream(file) { reader in
                try With.outputStream(tmpfile) { out in
                    guard let linebreak = TextUtil.LINESEP.data(using: encoding) else {
                        throw CharacterEncodingException()
                    }
                    while let line = try reader.readline(encoding) {
                        if let output = code(line) {
                            if output != line { modified = true }
                            guard let data = output.data(using: encoding) else {
                                throw CharacterEncodingException()
                            }
                            try out.writeFully(data)
                            try out.writeFully(linebreak)
                        }
                    }
                }
            }
            if modified {
                try FileUtil.copy(tofile: file, fromfile: tmpfile)
            }
        }
        return modified
    }
    
    /**
     * @param code(tmpdir): T
     * @throws Exception If operation fail.
     */
    public static func tmpdir<T>(_ dir: File? = nil, _ code: Fun11<File, T>) throws -> T {
        let tmpdir = FileUtil.createTempDir(dir: dir)
        defer { _ = tmpdir.deleteTree() }
        return code(tmpdir)
    }
    
    /**
     * @param code(tmpfile): T
     * @throws Exception If operation fail.
     */
    public static func tmpfile<T>(_ suffix: String = ".tmp", _ dir: File? = nil, _ code: Fun11x<File, T>) throws -> T {
        let tmpfile = FileUtil.tempFile(suffix: suffix, dir: dir)
        defer { _ = tmpfile.delete() }
        return try code(tmpfile)
    }
}

open class Without {
    
    public static func comments(_ file: File, _ prefix: String = "#", _ code: Fun10x<String>) throws {
        try With.lines(file) { it in
            let s = it.trimmed()
            if !s.isEmpty && !s.hasPrefix(prefix) {
                try code(s)
            }
        }
    }
}

////////////////////////////////////////////////////////////////////

