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

class TestCoreLogger01 : TestBase {

    open override var DEBUGGING: Bool {
        return false
    }
    
    func testEnterLeave01() {
        func setup(_ log: ICoreLogger, _ name: String) -> String {
            log.enter {
                log.enter(TestCoreLogger01.self) {
                    log.enter(name) {
                        log.enter("testing") {
                            log.d("# debug")
                            log.i("# info")
                            log.w("# warn")
                            log.e("# error")
                            log.resetErrorCount()
                        }
                    }
                }
            }
            return log.getLog().joined()
        }
        subtest {
            let log = CoreLogger(debugging: true)
            let output = setup(log, #function)
            XCTAssertTrue(output.contains("++ TestCoreLogger01"))
            XCTAssertTrue(output.contains("-- TestCoreLogger01"))
            XCTAssertTrue(output.contains("+++ testEnterLeave01"))
            XCTAssertTrue(output.contains("--- testEnterLeave01"))
            XCTAssertTrue(output.contains("++++ testing"))
            XCTAssertTrue(output.contains("---- testing"))
            XCTAssertTrue(output.contains("# debug"))
            XCTAssertTrue(output.contains("# info"))
            XCTAssertTrue(output.contains("# warn"))
            XCTAssertTrue(output.contains("# error"))
        }
        subtest {
            let log = CoreLogger(debugging: false)
            let output = setup(log, #function)
            XCTAssertFalse(output.contains("++ TestCoreLogger01"))
            XCTAssertFalse(output.contains("-- TestCoreLogger01"))
            XCTAssertFalse(output.contains("+++ testEnterLeave01"))
            XCTAssertFalse(output.contains("--- testEnterLeave01"))
            XCTAssertFalse(output.contains("++++ testing"))
            XCTAssertFalse(output.contains("---- testing"))
            XCTAssertFalse(output.contains("# debug"))
            XCTAssertTrue(output.contains("# info"))
            XCTAssertTrue(output.contains("# warn"))
            XCTAssertTrue(output.contains("# error"))
        }
    }

    func testEnterLeave02() throws {
        try subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            XCTAssertEqual("OK", log.enter {
                return "OK"
            })
            XCTAssertEqual("OK", log.enter("name", "msg") {
                return "OK"
            })
            XCTAssertEqual("OK", try log.enterX {
                return "OK"
            })
            XCTAssertEqual("OK", try log.enterX("name", "msg") {
                return "OK"
            })
            log.enter("error cleared")
            log.enter("fail on error")
            log.enter("continue on error")
            log.e()
            XCTAssertEqual(1, log.errorCount)
            log.leave()
            XCTAssertEqual(1, log.errorCount)
            XCTAssertTrue(With.error { try log.leaveX() } is IllegalStateException)
            log.resetErrorCount()
            try log.leaveX()
            XCTAssertEqual(0, log.errorCount)
        }
        try subtest {
            let log = CoreLogger(debugging: true)
            log.enter(#function)
            log.enter(#function, "msg")
            log.enter(TestCoreLogger01.self)
            log.enter(TestCoreLogger01.self, "msg")
            log.enter(#function)
            log.enter(#function, "msg")
            log.enter(TestCoreLogger01.self)
            log.enter(TestCoreLogger01.self, "msg")
            log.e("error")
            log.leave("msg")
            log.leave()
            log.leave("msg")
            log.leave()
            XCTAssertTrue(With.error { try log.leaveX("msg") } is IllegalStateException)
            log.resetErrorCount()
            try log.leaveX()
            try log.leaveX("msg")
            try log.leaveX()
            let output = log.getLog().joined()
            XCTAssertTrue(output.contains("+ testEnterLeave02"))
            XCTAssertTrue(output.contains("++ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("+++ TestCoreLogger01"))
            XCTAssertTrue(output.contains("++++ TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("+++++ testEnterLeave02()"))
            XCTAssertTrue(output.contains("++++++ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("+++++++ TestCoreLogger01"))
            XCTAssertTrue(output.contains("++++++++ TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("- testEnterLeave02()"))
            XCTAssertTrue(output.contains("-- testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("--- TestCoreLogger01"))
            XCTAssertTrue(output.contains("---- TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("----- testEnterLeave02()"))
            XCTAssertTrue(output.contains("------ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("------- TestCoreLogger01"))
            XCTAssertTrue(output.contains("-------- TestCoreLogger01: msg"))
        }
        try subtest {
            let log = CoreLogger(debugging: true)
            try log.enterX(#function) {
                try log.enterX(#function, "msg") {
                    try log.enterX(TestCoreLogger01.self) {
                        XCTAssertTrue(With.error {
                            try log.enterX(TestCoreLogger01.self, "msg") {
                                log.enter(#function) {
                                    log.enter(#function, "msg") {
                                        log.enter(TestCoreLogger01.self) {
                                            log.enter(TestCoreLogger01.self, "msg") {
                                                log.e("error")
                                            }
                                        }
                                    }
                                }
                            }
                        } is IllegalStateException)
                        XCTAssertEqual(1, log.errorCount)
                        log.resetErrorCount()
                    }
                    XCTAssertEqual(0, log.errorCount)
                }
            }
            let output = log.getLog().joined()
            XCTAssertTrue(output.contains("+ testEnterLeave02()"))
            XCTAssertTrue(output.contains("++ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("+++ TestCoreLogger01"))
            XCTAssertTrue(output.contains("++++ TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("+++++ testEnterLeave02()"))
            XCTAssertTrue(output.contains("++++++ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("+++++++ TestCoreLogger01"))
            XCTAssertTrue(output.contains("++++++++ TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("- testEnterLeave02()"))
            XCTAssertTrue(output.contains("-- testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("--- TestCoreLogger01"))
            XCTAssertTrue(output.contains("---- TestCoreLogger01: msg"))
            XCTAssertTrue(output.contains("----- testEnterLeave02()"))
            XCTAssertTrue(output.contains("------ testEnterLeave02(): msg"))
            XCTAssertTrue(output.contains("------- TestCoreLogger01"))
            XCTAssertTrue(output.contains("-------- TestCoreLogger01: msg"))
        }
        try subtest {
            func check(_ output: String) {
                XCTAssertTrue(output.contains("+ testEnterLeave02()"))
                XCTAssertTrue(output.contains("++ testEnterLeave02(): msg"))
                XCTAssertTrue(output.contains("+++ TestCoreLogger01"))
                XCTAssertTrue(output.contains("++++ TestCoreLogger01: msg"))
                XCTAssertTrue(output.contains("+++++ testEnterLeave02()"))
                XCTAssertTrue(output.contains("++++++ testEnterLeave02(): msg"))
                XCTAssertTrue(output.contains("+++++++ TestCoreLogger01"))
                XCTAssertTrue(output.contains("++++++++ TestCoreLogger01: msg"))
                XCTAssertTrue(output.contains("- testEnterLeave02()"))
                XCTAssertTrue(output.contains("-- testEnterLeave02(): msg"))
                XCTAssertTrue(output.contains("--- TestCoreLogger01"))
                XCTAssertTrue(output.contains("---- TestCoreLogger01: msg"))
                XCTAssertTrue(output.contains("----- testEnterLeave02()"))
                XCTAssertTrue(output.contains("------ testEnterLeave02(): msg"))
                XCTAssertTrue(output.contains("------- TestCoreLogger01"))
                XCTAssertTrue(output.contains("-------- TestCoreLogger01: msg"))
            }

            let log = CoreLogger(debugging: true)
            XCTAssertEqual(
                "OK",
                try log.enterX(#function) {
                    try log.enterX(#function, "msg") {
                        try log.enterX(TestCoreLogger01.self) {
                            try log.enterX(TestCoreLogger01.self, "msg") {
                                log.enter(#function) {
                                    log.enter(#function, "msg") {
                                        log.enter(TestCoreLogger01.self) {
                                            log.enter(TestCoreLogger01.self, "msg") {
                                                return "OK"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }!)
            let file = FileUtil.tempFile()
            try log.saveLog(file)
            /// Note that this is a sync call and thus make sure savelog() is completed.
            check(log.getLog().joined())
            let text = try file.readText()
            log.d("# savelog:\n\(text)")
            check(text)
        }
    }

    func testLog01() throws {
        subtest {
            let log = CoreLogger(debugging: false)
            log.enter {
                log.dd("step1")
                log.ii("stepii1")
                usleep(100*1000)
                log.dd("step2")
                log.ii("stepii2")
            }
            let output = log.getLog().joined()
            XCTAssertFalse(try! Regex("[\\d.]+ s: step1").find(output))
            XCTAssertFalse(try! Regex("[\\d.]+ s: step2").find(output))
            XCTAssertTrue(try! Regex("[\\d.]+ s: stepii1").find(output))
            XCTAssertTrue(try! Regex("[\\d.]+ s: stepii2").find(output))
        }
        subtest {
            let log = CoreLogger(debugging: true)
            usleep(100*1000)
            log.enter {
                log.dd("step1")
                log.ii("stepii1")
                usleep(100*1000)
                log.dd("step2")
                log.ii("stepii2")
                usleep(100*1000)
                log.ww("ww3")
                log.ee("ee3")
            }
            let output = log.getLog().joined()
            XCTAssertEqual(1, log.errorCount)
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: step1").find(output))
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: step2").find(output))
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: stepii1").find(output))
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: stepii2").find(output))
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: ww3").find(output))
            XCTAssertTrue(try! Regex(".*[\\d.]+ s: ee3").find(output))
            let match = try! Regex("([\\d.]+) s: stepii2").matcher(output).finding()
            XCTAssertNotNil(match)
            if let match = match,
                let group1 = match.group(1) {
                /// Check that time relative to start of logger instead of start of scope.
                XCTAssertTrue(Double(group1)! >= 0.19, group1)
            }
        }
        subtest {
            let log = CoreLogger(debugging: true)
            log.enter {
                log.e("msg1")
                log.e("msg2", IOException("Expected IOException"))
                XCTAssertEqual(2, log.errorCount)
                log.resetErrorCount()
            }
        }
        subtest {
            let log = CoreLogger(debugging: true)
            XCTAssertTrue(
                With.error {
                    try log.enterX {
                        throw IOException("Expected IOException")
                    }
                } is IllegalStateException)
            XCTAssertEqual(1, log.errorCount)
            XCTAssertTrue(
                With.error {
                    try log.enterX {
                        throw IOException("Expected IOException")
                    }
                } is IllegalStateException)
            XCTAssertEqual(2, log.errorCount)
            log.resetErrorCount()
        }
    }

    func testLogMulti01() {
        subtest {
            let log = CoreLogger(debugging: true)
            let a = ["a", "b", "c"]
            let b = ["A", "B", "C"]
            log.d("1", "2", "3")
            log.d(a)
            log.d(b.makeIterator())
            log.i("1", "2", "3")
            log.i(a)
            log.i(b.makeIterator())
            log.w("1", "2", "3")
            log.w(a)
            log.w(b.makeIterator())
            log.e("1", "2", "3")
            log.e(a)
            log.e(b.makeIterator())
            log.resetErrorCount()
            var set = Set<String>()
            for s in log.getLog().joined().lines {
                set.insert(String(s))
            }
            XCTAssertEqual(10, set.count)
            XCTAssertTrue(set.contains("1"))
            XCTAssertTrue(set.contains("2"))
            XCTAssertTrue(set.contains("3"))
            XCTAssertTrue(set.contains("a"))
            XCTAssertTrue(set.contains("b"))
            XCTAssertTrue(set.contains("c"))
            XCTAssertTrue(set.contains("A"))
            XCTAssertTrue(set.contains("B"))
            XCTAssertTrue(set.contains("C"))
        }
        subtest {
            let log = CoreLogger(debugging: true)
            log.enter {
                log.dfmt("%@", "debug formatted")
                log.ifmt("%@", "info formatted")
                log.wfmt("%@", "warn formatted")
                log.efmt("%@", "error formatted")
                XCTAssertEqual(1, log.errorCount)
                log.resetErrorCount()
            }
            let output = log.getLog()
            XCTAssertTrue(output.contains("debug formatted"))
            XCTAssertTrue(output.contains("info formatted"))
            XCTAssertTrue(output.contains("warn formatted"))
            XCTAssertTrue(output.contains("error formatted"))
        }
    }

    func testQuiet01() {
        let log = CoreLogger(debugging: true)
        log.enter("normal") {
            log.quiet {
                log.enter("quiet") {
                    log.d("quiet d")
                    log.i("quiet i")
                    usleep(100*1000)
                    log.w("quiet w")
                    log.e("quiet e")
                    log.resetErrorCount()
                }
            }
        }
        let output = log.getLog().joined()
        let lines = output.trimmed().lines
        XCTAssertEqual(2, lines.count)
        XCTAssertTrue(output.contains("+ normal"))
        XCTAssertTrue(output.contains("- normal"))
        XCTAssertFalse(output.contains("quiet"))
        XCTAssertFalse(output.contains("quiet"))
    }

    func testLifecycleListener01() {
        let log = CoreLogger(debugging: true)
        class Listener: ICoreLoggerLifecycleListener {
            var count = 0
            public func onDone(_ msg: String, _ endtime: Int64, _ errors: Int, _ logger: Fun10<String>) {
                logger("# done")
                count += 1
            }
            public func onStart(_ msg: String, _ starttime: Int64, _ logger: Fun10<String>) {
                logger("# start")
                count += 1
            }
        }
        let listener = Listener()
        log.addLifecycleListener(listener)
        log.enter {
        }
        /// getLog() is sync
        XCTAssertEqual(2, log.getLog().joined().trimmed().lines.count)
        XCTAssertEqual(2, listener.count)
        // log.removeLifecycleListener(listener)
        log.enter("testing") {
            log.enter("testing again") {
                log.i("info")
            }
        }
        /// getLog() is sync
        XCTAssertEqual(9, log.getLog().joined().trimmed().lines.count)
        XCTAssertEqual(4, listener.count)
    }

    func testSmart01() {
        let log = CoreLogger(debugging: true)
        log.d("")
        log.i("")
        log.w("")
        log.e("")
        XCTAssertEqual("", log.getLog().joined())
        log.d("\n")
        log.i("\n")
        log.w("\n")
        log.e("\n")
        XCTAssertEqual("\n\n\n\n", log.getLog().joined())
        log.d("d")
        log.i("i")
        log.w("w")
        log.e("e")
        XCTAssertEqual("\n\n\n\nd\ni\nw\ne\n", log.getLog().joined())
        log.d("d\n")
        log.i("i\n")
        log.w("w\n")
        log.e("e\n")
        XCTAssertEqual("\n\n\n\nd\ni\nw\ne\nd\ni\nw\ne\n", log.getLog().joined())
    }
    
    func testLogWithError01() throws {
        subtest {
            let log = CoreLogger(debugging: false)
            log.d("", IOException("D"))
            log.i("", IOException("I"))
            log.w("", IOException("W"))
            log.e("", IOException("E"))
            XCTAssertEqual("W\nE\n", log.getLog().joined())
            log.d("d\n", IOException("D"))
            log.i("i\n", IOException("I"))
            log.w("w\n", IOException("W"))
            log.e("e\n", IOException("E"))
            XCTAssertEqual("W\nE\ni\nw\nW\ne\nE\n", log.getLog().joined())
        }
        subtest {
            let log = CoreLogger(debugging: true)
            log.d("", IOException("D"))
            log.i("", IOException("I"))
            log.w("", IOException("W"))
            log.e("", IOException("E"))
            XCTAssertEqual("D\nI\nW\nE\n", log.getLog().joined())
            log.d("d\n", IOException("D"))
            log.i("i\n", IOException("I"))
            log.w("w\n", IOException("W"))
            log.e("e\n", IOException("E"))
            XCTAssertEqual("D\nI\nW\nE\nd\nD\ni\nI\nw\nW\ne\nE\n", log.getLog().joined())
        }
    }
    
    func testCoverage01() throws {
        try subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            log.enter()
            log.i("test1")
            try log.leaveX()
            let lines = log.getLog().joined().lines
            XCTAssertEqual(2, lines.count)
            XCTAssertTrue(
                With.error {
                    try log.saveLog(File("/notexists/t.log"))
                    } is IOException
            )
        }
        try subtest {
            let log: ICoreLogger = BuilderLogger(true, "\(TestCoreLogger01.self)")
            log.enter("BuilderLogger")
            log.i("test1")
            try log.leaveX()
            let lines = log.getLog().joined().lines
            XCTAssertEqual(6, lines.count)
        }
        subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            log.expectError("Expected error not occurred") {
                log.e("!!!Error!!!")
            }
            XCTAssertEqual(0, log.errorCount)
            log.expectError("Expected error not occurred") {
                log.d("no errors")
            }
            XCTAssertEqual(1, log.errorCount)
            log.flush()
            let output = log.getLog().joined()
            XCTAssertTrue(output.contains("!!!Error!!!"))
            XCTAssertTrue(output.contains("no errors"))
            var count = 0
            for line in output.lines {
                if line.hasPrefix("Expected error not occurred") { count += 1}
            }
            XCTAssertEqual(1, count)
        }
        try subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            XCTAssertEqual("", log.getLog().joined())
            log.i("")
            XCTAssertEqual("", log.getLog().joined())
            let tmpfile = FileUtil.tempFile()
            defer { _ = tmpfile.delete() }
            try log.saveLog(tmpfile)
            XCTAssertEqual("", try tmpfile.readText())
            log.i("123")
            XCTAssertEqual("123\n", log.getLog().joined())
        }
        subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            class Test: CustomStringConvertible {
                var description: String = "abc"
            }
            let a = Test()
            log.d("\(a)")
            XCTAssertEqual("abc\n", log.getLog().joined())
        }
        subtest {
            let log: ICoreLogger = CoreLogger(debugging: true)
            func test01() throws -> String {
                throw IOException()
            }
            XCTAssertTrue(
                With.error {
                    let _ = try log.enterX {
                        return try test01()
                    }
                    } is IllegalStateException)
            XCTAssertTrue(
                With.error {
                    let _ = try log.enterX("test2") {
                        return try test01()
                    }
                    } is IllegalStateException)
        }
    }
}
