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

class TestCoreUtilRandUtil01: TestBase {
    
    override var DEBUGGING: Bool {
        return false
    }
    
    func testRandUtil01() {
        subtest("Bool") {
            var count0 = 0
            var count1 = 1
            let ITER = 1000
            for _ in 0..<ITER {
                if RandUtil.getBool() { count1 += 1 } else { count0 += 1 }
            }
            self.log.d("# \(count0) \(count1)")
            XCTAssertTrue(count0 > ITER / 3)
            XCTAssertTrue(count1 > ITER / 3)
        }
        subtest("Int32") {
            var set = Set<Int32>();
            var dups = 0
            for _ in 1...100*1000 {
                if !set.insert(RandUtil.getInt32()).inserted {
                    dups += 1
                }
            }
            self.log.d("# dups = \(dups)")
            XCTAssertTrue(dups < 5)
        }
        subtest("Data") {
            var set : Set<Data> = Set();
            for iter in 1...100*1000 {
                var data = Data(count: 8);
                RandUtil.get(to: &data);
                let ret = set.insert(data)
                XCTAssert(ret.inserted, "\(iter)")
            }
        }
        subtest("String") {
            var set : Set<String> = Set();
            //# This takes ~2 sec in emulator
            for iter in 1...100*1000 {
                let s = RandUtil.getWord(length: 16);
                let ret = set.insert(s)
                XCTAssert(ret.inserted, "\(iter)")
            }
        }
    }
}
