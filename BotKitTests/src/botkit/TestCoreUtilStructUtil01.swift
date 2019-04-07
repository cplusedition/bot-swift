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

class TestCoreUtilStructUtil01: TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    func testStack01() {
        subtest {
            let s = Stack<String>()
            XCTAssertTrue(s.isEmpty)
            XCTAssertEqual(0, s.count)
        }
        subtest {
            let s = Stack<Int>()
            s.push(1)
            s.push(10)
            s.push(100)
            XCTAssertEqual(3, s.count)
            XCTAssertEqual(100, s.peek())
            XCTAssertEqual(100, s.pop())
            XCTAssertEqual(10, s.pop())
            XCTAssertEqual(1, s.pop())
            XCTAssertTrue(s.isEmpty)
            XCTAssertNil(s.peek())
            XCTAssertNil(s.pop())
        }
    }
    
    func testMySeq01() {
        subtest {
            let a = MySeq<String>()
            XCTAssertTrue(a.isEmpty)
            XCTAssertEqual(0, a.count)
        }
        subtest {
            var a = MySeq<Int>(1, 2, 3)
            a.append(10)
            a.append(20, 21, 22)
            a.append([30, 31])
            XCTAssertEqual(9, a.count)
            let s = a.map { $0 + 100 }
            var set = a.toSet()
            var array = a.toArray()
            XCTAssertEqual(a.count, s.count)
            XCTAssertEqual(101, s[0])
            XCTAssertEqual(110, s[3])
            XCTAssertTrue(s.contains(101))
            XCTAssertTrue(s.contains(131))
            XCTAssertEqual(a.count, set.count)
            XCTAssertEqual(a.count, array.count)
            XCTAssertTrue(set.contains(1))
            XCTAssertTrue(set.contains(31))
            XCTAssertEqual(1, array[0])
            XCTAssertEqual(10, array[3])
            set.insert(123)
            array.append(123)
            XCTAssertEqual(a.count + 1, set.count)
            XCTAssertEqual(a.count + 1, array.count)
        }
    }
    
    func testDiffstat01() {
        let diff = DiffStat<Int>()
        XCTAssertFalse(diff.hasDiff())
        diff.sames.insert(123)
        XCTAssertFalse(diff.hasDiff())
        diff.diffs.insert(1)
        XCTAssertTrue(diff.hasDiff())
        diff.diffs.remove(1)
        XCTAssertFalse(diff.hasDiff())
        diff.aonly.insert(1)
        XCTAssertTrue(diff.hasDiff())
        diff.aonly.remove(1)
        XCTAssertFalse(diff.hasDiff())
        diff.bonly.insert(2)
        XCTAssertTrue(diff.hasDiff())
        diff.bonly.remove(2)
        diff.diffs.insert(111)
        diff.aonly.insert(333)
        diff.bonly.insert(444)
        subtest {
            let output = diff.toString()
            self.log.d("# output = \(output)")
            XCTAssertTrue(output.contains("111"))
            XCTAssertTrue(output.contains("333"))
            XCTAssertTrue(output.contains("444"))
            XCTAssertFalse(output.contains("123"))
            XCTAssertFalse(output.contains("### Same"))
            XCTAssertTrue(output.contains("### A"))
            XCTAssertTrue(output.contains("### B"))
            XCTAssertTrue(output.contains("### A only"))
            XCTAssertTrue(output.contains("### B only"))
            XCTAssertTrue(output.contains("### Diff"))
        }
        subtest {
            let output = diff.toString("AAA", "BBB", printsames: true, printaonly: false, printbonly: false, printdiffs: false)
            self.log.d("# output = \(output)")
            XCTAssertTrue(output.contains("123"))
            XCTAssertTrue(output.contains("### Same"))
            XCTAssertFalse(output.contains("### AAA"))
            XCTAssertFalse(output.contains("### BBB"))
            XCTAssertFalse(output.contains("### AAA only"))
            XCTAssertFalse(output.contains("### BBB only"))
            XCTAssertFalse(output.contains("### Diff"))
        }
    }
}
