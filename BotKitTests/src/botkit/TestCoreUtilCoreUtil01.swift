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

class TestCoreUtilCoreUtil01: TestBase {
    
    override var DEBUGGING: Bool {
        return false
    }
    
    func testWith01() throws {
        try subtest("TImeout") {
            XCTAssertEqual(1234, try With.timeout(seconds: 1.0) { done in
                done(1234)
                })
            let error = With.error {
                _ = try With.timeout(seconds: 0.1) { (done: (Int)->Void) in
                    usleep(1000 * 1000)
                    done(1234)
                }}
            self.log.d("# \(String(describing: error))")
            XCTAssertTrue(error is TimeoutException)
        }
        try subtest("errorOrThrow") {
            XCTAssertTrue(With.error {
                try With.errorOrThrow {
                }} is IllegalStateException)
            try With.errorOrThrow { throw IOException() }
        }
        try subtest("nullOrThrow") {
            try With.nullOrThrow { return nil as Int? }
            XCTAssertTrue(With.error {
                try With.nullOrThrow {
                    return 123
                }
            } is IllegalStateException)
        }
        subtest("nullable") {
            let input1:Int? = 123
            let input2: Int? = nil
            XCTAssertEqual(123, With.nullable(input1) { input in return input })
            XCTAssertEqual(nil, With.nullable(input2) { input in return input })
        }
    }
    
    func testWith02() throws {
        let htmldir = testResDir.file("html")
        let htmlfile = htmldir.file("manual.html")
        try subtest("inputStream") {
            try With.inputStream(htmlfile) { input in
                let data = try input.asData()
                XCTAssertEqual(19072, data.count)
            }
        }
        try subtest("inputStream") {
            let data = try With.inputStream(htmlfile) { input in
                return try input.asData()
            }
            XCTAssertEqual(19072, data.count)
        }
        try subtest("bufferedInputStream") {
            try With.bufferedInputStream(htmlfile) { input in
                var count = 0
                while true {
                    guard let line = try input.readline() else { break }
                    count += line.count
                }
                XCTAssertEqual(18861, count)
            }
        }
        try subtest("bufferedInputStream") {
            let count: Int = try With.bufferedInputStream(htmlfile) { input in
                var count = 0
                while true {
                    guard let line = try input.readline() else { break }
                    count += line.count
                }
                return count
            }
            XCTAssertEqual(18861, count)
        }
        try subtest("OutputStream") {
            let outfile = self.tmpFile()
            let data = RandUtil.getData(Int(bitPattern: UInt(RandUtil.getUInt32(1000*1000, 2000*1000))))
            try With.outputStream(outfile) { output in
                try output.writeFully(data)
            }
            XCTAssertEqual(data, try outfile.readData())
        }
        try subtest("OutputStream") {
            let outfile = self.tmpFile()
            let data = RandUtil.getData(Int(bitPattern: UInt(RandUtil.getUInt32(1000*1000, 2000*1000))))
            let callback: Fun11x<IOutputStream, String> = { output in
                try output.writeFully(data)
                return "OK"
            }
            let ret = try With.outputStream(outfile, callback)
            XCTAssertEqual("OK", ret)
            XCTAssertEqual(data, try outfile.readData())
        }
        try subtest("lines") {
            var count = 0
            try With.lines(htmlfile) { line in
                count += line.count
            }
            XCTAssertEqual(18861, count)
        }
        try subtest("rewriteText") {
            let outfile = self.tmpFile()
            try FileUtil.copy(tofile: outfile, fromfile: htmlfile)
            XCTAssertFalse(try With.rewriteText(outfile) { text in
                return text
            })
            XCTAssertEqual(19072, outfile.length)
            XCTAssertTrue(try With.rewriteText(outfile) { text in
                return text + "abcd"
            })
            XCTAssertEqual(19076, outfile.length)
        }
        try subtest("rewriteLines") {
            let outfile = self.tmpFile()
            try FileUtil.copy(tofile: outfile, fromfile: htmlfile)
            XCTAssertFalse(try With.rewriteLines(outfile) { line in
                return line
                })
            XCTAssertEqual(19072, outfile.length)
            var lines: Int64 = 0
            XCTAssertTrue(try With.rewriteLines(outfile) { line in
                lines += 1
                return line + "a"
                })
            XCTAssertEqual(19072, htmlfile.length)
            // Original file does not has terminating line break.
            XCTAssertEqual(19072 + lines + 1, outfile.length)
        }
    }
    
    func testWithTmp01() throws {
        try subtest("tmpdir") {
            var dir1: File? = nil
            try With.tmpdir { dir in
                dir1 = dir
                XCTAssertTrue(dir.exists)
            }
            XCTAssertNotNil(dir1)
            XCTAssertFalse(dir1!.exists)
        }
        try subtest("tmpdir") {
            let dir1: File = try With.tmpdir { dir in
                XCTAssertTrue(dir.exists)
                return dir
            }
            XCTAssertFalse(dir1.exists)
        }
        try subtest("tmpfile") {
            let file: File = try With.tmpfile { file in
                XCTAssertFalse(file.exists)
                try file.writeText("testing")
                XCTAssertTrue(file.exists)
                return file
            }
            XCTAssertFalse(file.exists)
        }
    }
}
