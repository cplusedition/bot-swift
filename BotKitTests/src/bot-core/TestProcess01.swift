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

import XCTest
import BotKit

class TestProcess01: TestBase {

    open override var DEBUGGING: Bool {
        return false
    }
    
    func testProcess01() throws {
        let done = expectation(description: "done")
        _ = ProcessUtil.Builder("/bin/ls", "/").backtick { rc, out, err in
            self.log.d("# callback: \(rc)")
            self.log.d("# stdout:\n\(out)")
            self.log.d("# stderr:\n\(err)")
            XCTAssertEqual(0, rc)
            XCTAssertTrue(out.contains("Users"))
            XCTAssertTrue(err.isEmpty)
            done.fulfill()
            return out
        }
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testProcessFail01() throws {
        let done = expectation(description: "done")
        _ = ProcessUtil.Builder("/bin/notexists", "/").backtick { rc, out, err in
            self.log.d("# callback: \(rc)")
            self.log.d("# stdout:\n\(out)")
            self.log.d("# stderr:\n\(err)")
            XCTAssertEqual(-1, rc)
            XCTAssertTrue(out.isEmpty)
            XCTAssertTrue(err.contains("notexists"))
            done.fulfill()
            return out
        }
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testProcessFail02() throws {
        let done = expectation(description: "done")
        let msg = "Expected exception"
        do {
            _ = try ProcessUtil.Builder("/bin/ls").arguments("/").backtick { rc, out, err in
                self.log.d("# callback: \(rc)")
                self.log.d("# stdout:\n\(out)")
                self.log.d("# stderr:\n\(err)")
                XCTAssertEqual(0, rc)
                XCTAssertTrue(out.contains("Users"))
                XCTAssertTrue(err.isEmpty)
                throw IOException(msg)
                }.wait()
        } catch let e {
            log.d("# e=\(e)")
            XCTAssertTrue(e is ExecutionException)
            XCTAssertTrue("\(e)".contains(msg))
            done.fulfill()
        }
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testProcessTimeout01() throws {
        let done = expectation(description: "done")
        _ = try ProcessUtil.Builder("/bin/sleep", ["2"])
            .workdir(File.pwd)
            .env([:])
            .env([:])
            .timeout(100)
            .backtick { rc, out, err in
                self.log.d("# callback: \(rc)")
                self.log.d("# stdout:\n\(out)")
                self.log.d("# stderr:\n\(err)")
                XCTAssertEqual(15, rc) // Killed
                done.fulfill()
                return out
            }.wait()
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testProcessStdin01() throws {
        let filesdir = testResDir.file("files")
        let zipfile = tmpFile(suffix: ".zip")
        log.d("# zipfile = \(zipfile.path)")
        let input = Pipe()
        let out = input.fileHandleForWriting
        Fileset(filesdir).walk { file, rpath in
            out.write(rpath.data)
            out.write(TextUtil.LINESEP_UTF8)
        }
        out.closeFile()
        _ = try ProcessUtil.Builder("/usr/bin/zip").arguments("-ry", zipfile.path, "-@")
            .workdir(filesdir)
            .input(input)
            .backtick().wait()
        log.d("# zipfile: \(BU.filesizeString(zipfile))")  // 2520
        XCTAssertTrue(zipfile.exists)
        XCTAssertTrue(zipfile.length > 1000)
    }

    func testProcessStdin02() throws {
        let filesdir = testResDir.file("files")
        let zipfile = tmpFile(suffix: ".zip")
        log.d("# zipfile = \(zipfile.path)")
        _ = try ProcessUtil.Builder("/usr/bin/zip").arguments(["-ry", zipfile.path, "-@"])
            .workdir(filesdir)
            .input { out in
                Fileset(filesdir).walk { file, rpath in
                    out.write(rpath.data)
                    out.write(TextUtil.LINESEP_UTF8)
                }
            }
            .backtick().wait()
        XCTAssertTrue(zipfile.exists)
        XCTAssertTrue(zipfile.length > 1000)
    }

    func testProcessStdout01() throws {
        let outmon = ProcessUtil.OutputMonitor()
        let errmon = ProcessUtil.OutputMonitor()
        _ = try ProcessUtil.Builder("/bin/ls", "/")
            .out(outmon)
            .err(errmon)
            .async { process, error in
                XCTAssertTrue(String(data: outmon.buf, encoding: .utf8)?.contains("Users") ?? false)
                XCTAssertTrue(String(data: errmon.buf, encoding: .utf8)?.isEmpty ?? false)
            }.wait()
    }
}
