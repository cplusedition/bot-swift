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

class TestRxUtil02: TestBase {
    
    override var DEBUGGING: Bool {
        return false
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testReplaceAll01() throws {
        let data1 = try Array(Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\r\n\r\r\n\n").replaceAll("").utf8)
        let data2 = try Array(Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\r\n\r\r\n\nx").replaceAll("").utf8)
        log.d("# s1=\(data1)")
        log.d("# s2=\(data2)")
        try subtest {
            XCTAssertEqual("abcdefg", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\n\r").replaceAll(""))
            XCTAssertEqual("abcdefg", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\n").replaceAll(""))
            XCTAssertEqual("abcdefg", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\n\n").replaceAll(""))
            XCTAssertEqual("abcdefg", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\r\n\r\r\n\n").replaceAll(""))
            XCTAssertEqual("abcdefgx", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\r\n\r\r\n\nx").replaceAll(""))
            XCTAssertEqual("abcdefgx", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\n\nx").replaceAll(""))
            XCTAssertEqual("abcdefg", try Regex("\\s+").matcher("\ta b   c\t\nd\r\ne \t fg\n\n\n\n").replaceAll(""))
            XCTAssertEqual("abcdefg", try Regex("[\\s\\r]+").matcher("\ta b   c\t\nd\r\ne \t fg\n\r").replaceAll(""))
            XCTAssertEqual("", try Regex("\\n+").matcher("\n\n\n\n").replaceAll(""))
            XCTAssertEqual("", try Regex("[\\n\\t ]+").matcher("\n \t \n \n\t\n\n").replaceAll(""))
            XCTAssertEqual("", try Regex("[\\n\\r\\t ]+").matcher("\n \t \n \r\r \n\t\n\n").replaceAll(""))
            XCTAssertEqual("", try Regex("[\\n\\r\\t ]+").matcher("\n \t \n \r\n\r\n\r\n \n\t\n\n").replaceAll(""))
        }
    }

    /// Basic tests for Regex.matcher().matches()
    func testRegex01() throws {
        let ccby40 = testResDir.file("assets/licenses/cc/cc-by-nc-4.0.html.txt")
        let input = try ccby40.readText()
        let matcher = try Regex("(?s).*?href=\\\"(.*?)\\\".*").matcher(input)
        XCTAssertEqual(true, matcher.matches())
        log.d("# start=\(String(describing: matcher.start()))")
        log.d("# end=\(String(describing: matcher.end()))")
        log.d("# start(1)=\(String(describing: matcher.start(1)))")
        log.d("# end(1)=\(String(describing: matcher.end(1)))")
        log.d("# group(1)=\(String(describing: matcher.group(1)))")
        XCTAssertEqual(258, matcher.start(1))
        XCTAssertEqual("CC BY-NC 4.0", try Regex("(?s).*?<title>.*(CC BY.*?)</.*").matching(input)?.group(1))
        XCTAssertEqual("CC BY-NC 4.0", try Regex("(?s).*?<title>.*(cc .*?)</.*", [.caseInsensitive]).matching(input)?.group(1))
        var hrefs = [String]()
        let finder = try Regex("href=\\\"(.*?)\\\"").matcher(input)
        while finder.find() {
            log.d("# \(hrefs.count): \(String(describing: finder.group(1)))")
            hrefs.append(finder.group(1)!)
        }
        XCTAssertEqual(35, hrefs.count, "count")
        XCTAssertTrue(hrefs[0].hasSuffix("/deed3.css"))
        XCTAssertTrue(hrefs[34].hasSuffix("/by-nc/4.0/"))
        // Check that not found works
        XCTAssertFalse(try! Regex("xxxxxxx").matcher(input).matches())
        XCTAssertFalse(try! Regex("xxxxxxx").matcher(input).find())
    }
    
    func testRegexWithRange01() throws {
        let ccby40 = testResDir.file("assets/licenses/cc/cc-by-nc-4.0.html.txt")
        let input = try ccby40.readText()
        let matcher = try Regex("(?s).*?href=\\\"(.*?)\\\".*").matcher(input, NSRange(location: 258, length: 1000))
        XCTAssertEqual(true, matcher.matches())
        log.d("# start=\(String(describing: matcher.start()))")
        log.d("# end=\(String(describing: matcher.end()))")
        log.d("# start(1)=\(String(describing: matcher.start(1)))")
        log.d("# end(1)=\(String(describing: matcher.end(1)))")
        log.d("# group(1)=\(String(describing: matcher.group(1)))")
        XCTAssertEqual(448, matcher.start(1))
        XCTAssertTrue(matcher.group(1)!.hasSuffix("-print.css"))
        var hrefs = [String]()
        let finder = try Regex("href=\\\"(.*?)\\\"").matcher(input, NSRange(location: 258, length: 1000))
        while finder.find() {
            log.d("# \(hrefs.count): \(String(describing: finder.group(1)))")
            hrefs.append(finder.group(1)!)
        }
        XCTAssertEqual(3, hrefs.count, "count")
        XCTAssertTrue(hrefs[0].hasSuffix("/deed3-print.css"))
        XCTAssertTrue(hrefs[2].hasSuffix("/creativecommons.org/"))
        // Check that not found works
        XCTAssertFalse(try! Regex("xxxxxxx").matcher(input, NSRange(location: 258, length: 1000)).matches())
        XCTAssertFalse(try! Regex("xxxxxxx").matcher(input, NSRange(location: 258, length: 1000)).find())
    }
    
}
