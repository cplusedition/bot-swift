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

class TestCoreUtilRxUtil01: TestBase {

    func testRxUtil01() {
        subtest {
            XCTAssertNotNil(try! Regex("a"))
            XCTAssertNil(try? Regex("a("))
        }
        subtest {
            XCTAssertTrue(try! Regex("a").matches("abcabc"))
            XCTAssertFalse(try! Regex("A").matches("abcabc"))
            XCTAssertTrue(try! Regex("a").matcher("abcabc").matches())
            XCTAssertFalse(try! Regex("A").matcher("abcabc").matches())
        }
        subtest {
            XCTAssertNil(try! Regex("^\\s+$").matching("abc"))
            XCTAssertNotNil(try! Regex("^\\s+$").matching(" "))
            XCTAssertNil(try! Regex("a").finding("bcbc"))
            XCTAssertNotNil(try! Regex("a").finding("abcabc"))
        }
        subtest {
            XCTAssertNotNil(try! Regex("a").finding("abcabc"))
            XCTAssertNotNil(try! Regex("a").finding("abcabc")?.finding())
            XCTAssertNil(try! Regex("a").finding("abcabc")?.finding()?.finding())
            XCTAssertNil(try! Regex("a").finding("abcabc")?.finding()?.finding()?.finding())
        }
        subtest {
            XCTAssertTrue(try! Regex("a").find("abcabc"))
            XCTAssertTrue(try! Regex("a").finding("abcabc")?.find() ?? false)
            XCTAssertFalse(try! Regex("a").finding("abcabc")?.finding()?.find() ?? false)
            XCTAssertFalse(try! Regex("a").finding("abcabc")?.finding()?.finding()?.find() ?? false)
        }
        subtest {
            XCTAssertEqual("xbcxbc", try! Regex("a").matcher("abcabc").replaceAll("x"))
        }
        subtest {
            XCTAssertEqual("bc", try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.group(1))
            XCTAssertEqual("bc", try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.group(2))
            XCTAssertEqual(nil, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.group(3))
            XCTAssertEqual(1, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.start(1))
            XCTAssertEqual(3, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.end(1))
            XCTAssertEqual(4, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.start(2))
            XCTAssertEqual(6, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.end(2))
            XCTAssertEqual(nil, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.start(3))
            XCTAssertEqual(nil, try! Regex("a(\\w+)a(\\w+)").matcher("abcabc").matching()?.end(3))
        }
    }
    
    func testMatchUtil01() {
        subtest {
            let includes = try! MatchUtil.compile("^dir1/.*$", "^dir2/.*$")
            let excludes = try! MatchUtil.compile(["^dir1/dir1a(/.*)?$", "^dir2/dir2a(/.*)?$"])
            XCTAssertFalse(MatchUtil.matches("dir3/dir1.txt", includes[0], excludes[0]))
            XCTAssertTrue(MatchUtil.matches("dir1/dir1.txt", includes[0], excludes[0]))
            XCTAssertFalse(MatchUtil.matches("dir1/dir1a", includes[0], excludes[0]))
            //
            XCTAssertFalse(MatchUtil.matches("dir3/dir1.txt", includes, excludes))
            XCTAssertTrue(MatchUtil.matches("dir1/dir1.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.matches("dir1/dir1a", includes, excludes))
            XCTAssertTrue(MatchUtil.matches("dir1/dir1a.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.matches("dir1/dir1a/file.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.matches("dir2/dir2a", includes, excludes))
            XCTAssertTrue(MatchUtil.matches("dir2/dir2a.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.matches("dir2/dir2a/file.txt", includes, excludes))
        }
        subtest {
            let includes = try! MatchUtil.compile("dir1a", "dir2a")
            let excludes = try! MatchUtil.compile(["empty", "a\\.txt"])
            XCTAssertFalse(MatchUtil.find("dir3/dir1.txt", includes[0], excludes[0]))
            XCTAssertFalse(MatchUtil.find("dir1a/empty1.txt", includes[0], excludes[0]))
            XCTAssertTrue(MatchUtil.find("dir1a/dir1.txt", includes[0], excludes[0]))
            XCTAssertTrue(MatchUtil.find("dir1/dir1a", includes[0], excludes[0]))
            //
            XCTAssertFalse(MatchUtil.find("dir3/dir1.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.find("dir1a/dir1a.txt", includes, excludes))
            XCTAssertTrue(MatchUtil.find("dir1/dir1a", includes, excludes))
            XCTAssertFalse(MatchUtil.find("dir2a/dir1a.txt", includes, excludes))
            XCTAssertFalse(MatchUtil.find("dir1/dir1a/empty.txt", includes, excludes))
            XCTAssertTrue(MatchUtil.find("dir2/dir2a", includes, excludes))
            XCTAssertTrue(MatchUtil.find("dir2/dir2a.dir", includes, excludes))
            XCTAssertFalse(MatchUtil.find("dir2/dir2a/empty.txt", includes, excludes))
        }
    }
}
