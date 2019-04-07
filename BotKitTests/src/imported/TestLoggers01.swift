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

class TestLoggers01 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testSystemLogger01() throws {
        func check(_ logger: ILog) {
            logger.d("debug")
            logger.i("info")
            logger.w("warn")
            logger.e("error")
            logger.d("debug", Exception("throwable_d"))
            logger.i("info", Exception("throwable_i"))
            logger.w("warn", Exception("throwable_w"))
            logger.e("error", Exception("throwable_e"))
        }
        try log.enterX {
            subtest {
                let logger = StringLogger()
                check(logger)
                let output = logger.toString()
                XCTAssertTrue(output.contains("debug"))
                XCTAssertTrue(output.contains("info"))
                XCTAssertTrue(output.contains("warn"))
                XCTAssertTrue(output.contains("error"))
                XCTAssertTrue(output.contains("throwable_d"))
                XCTAssertTrue(output.contains("throwable_i"))
                XCTAssertTrue(output.contains("throwable_w"))
                XCTAssertTrue(output.contains("throwable_e"))
            }
            subtest {
                let logger = StringLogger(true)
                check(logger)
                let output = logger.toString()
                XCTAssertTrue(output.contains("debug"))
                XCTAssertTrue(output.contains("info"))
                XCTAssertTrue(output.contains("warn"))
                XCTAssertTrue(output.contains("error"))
                XCTAssertTrue(output.contains("throwable_d"))
                XCTAssertTrue(output.contains("throwable_i"))
                XCTAssertTrue(output.contains("throwable_w"))
                XCTAssertTrue(output.contains("throwable_e"))
            }
            subtest {
                let logger = StringLogger(false)
                check(logger)
                let output = logger.toString()
                XCTAssertFalse(output.contains("debug"))
                XCTAssertTrue(output.contains("info"))
                XCTAssertTrue(output.contains("warn"))
                XCTAssertTrue(output.contains("error"))
                XCTAssertFalse(output.contains("throwable_d"))
                XCTAssertFalse(output.contains("throwable_i"))
                XCTAssertFalse(output.contains("throwable_w"))
                XCTAssertTrue(output.contains("throwable_e"))
            }
        }
    }
    
    func testStringPrintWriter01() {
        let out = StringPrintWriter(reserve: 128)
        XCTAssertEqual(0, out.count)
        out.print("string")
        out.print(["a", "b", "c"])
        var it1 = ["1", "2", "3"].makeIterator()
        out.print(&it1)
        out.print("string1", "string2", "string3")
        out.println("string")
        out.println(["a", "b", "c"])
        var it2 = ["1", "2", "3"].makeIterator()
        out.println(&it2)
        out.println("string1", "string2", "string3")
        let result = out.toString()
        log.d("# result:\n\(result)")
        XCTAssertEqual("stringabc123string1string2string3string\na\nb\nc\n1\n2\n3\nstring1\nstring2\nstring3\n", result)
    }
}
