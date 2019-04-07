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

class TestCoreUtilDateUtil01: TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    func testRFC01() {
        subtest {
            let date = Date()
            let string = date.rfc1123
            self.log.d("# rfc1123 = \(string)")
            XCTAssertEqual(date.ms / 1000 * 1000, Date(rfc1123: string)?.ms)
            XCTAssertNil(Date(rfc1123: "invalid"))
        }
        subtest {
            let date = Date()
            let string = date.rfc822
            self.log.d("# rf822 = \(string)")
            XCTAssertEqual(date.ms / 1000 * 1000, Date(rfc822: string)?.ms)
            XCTAssertNil(Date(rfc822: "invalid"))
        }
        subtest {
            let date = Date()
            let string = date.iso8601
            self.log.d("# iso8601 = \(string)")
            XCTAssertEqual(date.ms / 1000 * 1000, Date(iso8601: string)?.ms)
            XCTAssertNil(Date(iso8601: "invalid"))
        }
        subtest {
            let date = Date()
            let string = date.enUS
            self.log.d("# enUS = \(string)")
            XCTAssertEqual(date.ms / 1000 * 1000, Date(enUS: string)?.ms)
            XCTAssertNil(Date(enUS: "invalid"))
        }
    }
    
    func testDateComponents01() {
        subtest {
            let expected = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            for d in 1...8 {
                let s = DateUtil.shortWeekdaySymbol(d)
                self.log.d("# \(String(describing: s))")
                if d < 8 {
                    XCTAssertEqual(expected[d-1], s)
                } else {
                    XCTAssertNil(s)
                }
            }
        }
        subtest {
            XCTAssertEqual(0, DateUtil.duration())
            XCTAssertEqual(
                DateUtil.DAY * 2
                + DateUtil.HOUR
                + DateUtil.MIN
                + DateUtil.SEC * 10
                + 100,
                DateUtil.duration(days: 2, hours: 1, minutes: 1, seconds: 10, ms: 100))
        }
        subtest {
            let date = DateUtil.date(1999, 12, 25, 20, 30, 55, 123)
            let c = DateUtil.components(date)
            XCTAssertEqual(1999, c.year)
            XCTAssertEqual(12, c.month)
            XCTAssertEqual(25, c.day)
            XCTAssertEqual(20, c.hour)
            XCTAssertEqual(30, c.minute)
            XCTAssertEqual(55, c.second)
            XCTAssertEqual(Double(123) * 1000 * 1000, Double(c.nanosecond!), accuracy: 1.0)
            let cc = DateUtil.components(Set(arrayLiteral: .year, .minute), date)
            XCTAssertEqual(1999, cc.year)
            XCTAssertEqual(nil, cc.month)
            XCTAssertEqual(nil, cc.day)
            XCTAssertEqual(nil, cc.hour)
            XCTAssertEqual(30, cc.minute)
            XCTAssertEqual(nil, cc.second)
            XCTAssertEqual(nil, cc.nanosecond)
        }
    }
    
    func testDateString01() {
        let date = DateUtil.date(1999, 12, 25, 20, 30, 55, 123)
        subtest {
            XCTAssertEqual(DateUtil.today, DateUtil.simpleDateString(DateUtil.now))
            XCTAssertEqual("19991225", DateUtil.simpleDateString(date))
            XCTAssertEqual("19991225", DateUtil.simpleDateString(date.ms))
            XCTAssertEqual("203055", DateUtil.simpleTimeString(date))
            XCTAssertEqual("203055", DateUtil.simpleTimeString(date.ms))
            XCTAssertEqual("19991225-203055", DateUtil.simpleDateTimeString(date))
            XCTAssertEqual("19991225-203055", DateUtil.simpleDateTimeString(date.ms))
            XCTAssertEqual("19991225-203055123", DateUtil.simpleDateTimeMsString(date))
            XCTAssertEqual("19991225-203055123", DateUtil.simpleDateTimeMsString(date.ms))
            XCTAssertEqual("12/25/1999 20:30:55", DateUtil.toString(ms: date.ms))
            XCTAssertEqual(DateUtil.toString(ms: DateUtil.ms), DateUtil.toString())
            XCTAssertEqual("1999-12-25T20:30:55+00:00", DateUtil.toString(format: "yyyy-MM-dd'T'HH:mm:ss'+00:00'", date: date))
        }
    }
}
