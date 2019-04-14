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

class TestCoreUtilExtensionUtil01: TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    func test01() {
        subtest("isOdd") {
            XCTAssertTrue((-3).isOdd)
            XCTAssertFalse((-2).isOdd)
            XCTAssertTrue((-1).isOdd)
            XCTAssertFalse(0.isOdd)
            XCTAssertTrue(1.isOdd)
            XCTAssertFalse(2.isOdd)
            XCTAssertTrue(3.isOdd)
        }
        subtest("Date") {
            for _ in 0..<100 {
                let date = Date()
                let d = Date(ms: date.ms)
                XCTAssertEqual(Int64((date.timeIntervalSince1970 * 1000).rounded()), d.ms)
                usleep(10 * 1000)
            }
        }
        subtest("Data") {
            XCTAssertEqual("123", Data([0x31, 0x32, 0x33]).makeString)
        }
        subtest("DispatchSemaphore") {
            self.subtest {
                let done = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    usleep(1000 * 1000)
                    done.signal()
                }
                XCTAssertTrue(done.wait(ms: 50) == .timedOut)
            }
            self.subtest {
                let done = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    usleep(50 * 1000)
                    done.signal()
                }
                XCTAssertFalse(done.wait(seconds: 0.2) == .timedOut)
            }
        }
        subtest("DispatchGroup") {
            self.subtest {
                let group = DispatchGroup()
                group.enter()
                group.enter()
                DispatchQueue.global().async {
                    usleep(10*1000)
                    group.leave()
                }
                DispatchQueue.global().async {
                    usleep(100*1000)
                    group.leave()
                }
                XCTAssertTrue(group.wait(ms: 50) == .timedOut)
            }
            self.subtest {
                let group = DispatchGroup()
                group.enter()
                group.enter()
                DispatchQueue.global().async {
                    usleep(100*1000)
                    group.leave()
                }
                DispatchQueue.global().async {
                    usleep(100*1000)
                    group.leave()
                }
                XCTAssertTrue(group.wait(seconds: 0.15) != .timedOut)
            }
        }
    }
    
    func testString01() {
        subtest("substring") {
            XCTAssertEqual("123abc456", "123abc456".substring(from: 0))
            XCTAssertEqual("", "123abc456".substring(from: 9))
            XCTAssertEqual("abc456", "123abc456".substring(from: 3))
            XCTAssertEqual("123abc", "123abc456".substring(to: 6))
            XCTAssertEqual("", "123abc456".substring(to: 0))
            XCTAssertEqual("123abc456", "123abc456".substring(to: 9))
            XCTAssertEqual("abc", "123abc456".substring(from: 3, to: 6))
            XCTAssertEqual("", "123abc456".substring(from: 0, to: 0))
            XCTAssertEqual("", "123abc456".substring(from: 9, to: 9))
            XCTAssertEqual("1", "123abc456".substring(from: 0, to: 1))
            XCTAssertEqual("6", "123abc456".substring(from: 8, to: 9))
            XCTAssertEqual("", "123abc456".substring(from: 8, to: -1))
            XCTAssertEqual("abc45", "123abc456".substring(from: 3, to: -1))
            XCTAssertEqual("abc", "123abc456".substring(from: 3, to: -3))
        }
        subtest("trimmed") {
            XCTAssertEqual("", "".trimmed())
            XCTAssertEqual("", " ".trimmed())
            XCTAssertEqual("", " \t\r\n".trimmed())
            XCTAssertEqual("abc", " abc".trimmed())
            XCTAssertEqual("abc", " abc \t\n\r".trimmed())
            XCTAssertEqual("abc", "abc \t\n\r".trimmed())
        }
        subtest("lines") {
            func check(_ expected: Int, _ s: String) {
                let lines = s.lines
                self.log.d("\(lines)")
                XCTAssertEqual(expected, lines.count, "\(lines)")
            }
            check(1, "")
            check(1, " abc ")
            check(2, "\n")
            check(2, "\r\n")
            check(3, "\n\n")
            check(3, "\n\r\n")
            check(3, "\nabc\r\n")
            check(3, "123\nabc\r\n")
            check(3, "123\nabc\r\n123")
        }
        subtest("data") {
            XCTAssertTrue(Data() == "".data)
            XCTAssertTrue(Data([0x31, 0x32, 0x33]) == "123".data)
        }
        subtest("data") {
            XCTAssertTrue([UInt8]() == "".bytes)
            XCTAssertTrue([UInt8](arrayLiteral: 0x31, 0x32, 0x33) == "123".bytes)
        }
    }
    
    func testSequence01() {
        subtest {
            XCTAssertTrue([1, 2, 3].all { $0 > 0 })
            XCTAssertFalse([1, 2, 3].all { $0 > 1 })
            XCTAssertTrue([1, 2, 3].any { $0 > 0 })
            XCTAssertFalse([1, 2, 3].any { $0 > 10 })
            XCTAssertTrue([1, 2, 3].none { $0 > 10 })
            XCTAssertFalse([1, 2, 3].none { $0 > 2 })
        }
    }
    
    func testArray01() {
        subtest {
            var a = Array<Int>(reserve: 100)
            a.append([1, 10, 20, 100])
            a.append([100, 200, 300], 1, 3)
            XCTAssertTrue([1, 10, 20, 100, 200, 300] == a)
            a.setLength(3)
            XCTAssertTrue([1, 10, 20] == a)
        }
        subtest {
            let a = Array<Int>([1, 2, 3, 4], 1, 3)
            XCTAssertTrue([2, 3] == a)
            let set = a.toSet()
            XCTAssertEqual(2, set.count)
            XCTAssertTrue(set.contains(3))
        }
        subtest {
            let a = ["a", "b", "", "c", ""]
            XCTAssertEqual("a\nb\n\nc\n", a.joinln())
            XCTAssertEqual("a/b//c/", a.joinPath())
        }
    }
    
    func testDict01() {
        subtest {
            var map = ["1": 1, "2": 2, "3": 3].map { k, v in
                return v != 2 ? v : nil
            }
            map.add(["a": 10, "1": 20])
            XCTAssertEqual(3, map.count)
            XCTAssertEqual(20, map["1"])
            XCTAssertNil(map["2"])
        }
    }
}
