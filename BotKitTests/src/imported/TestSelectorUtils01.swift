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

class TestSelectorUtils01 : TestBase {

    open override var DEBUGGING: Bool {
        return false
    }
    
    func testSelectorUtils01() {
        subtest {
            XCTAssertTrue(SelectorUtils.matchPath("", ""))
            XCTAssertTrue(SelectorUtils.matchPath("a", "a"))
            XCTAssertTrue(SelectorUtils.matchPath("a", "a/"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "/a"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "/a/"))
            XCTAssertTrue(SelectorUtils.matchPath("a/", "a"))
            XCTAssertFalse(SelectorUtils.matchPath("/a", "a"))
            XCTAssertFalse(SelectorUtils.matchPath("/a/", "a"))
            XCTAssertTrue(SelectorUtils.matchPath("a.txt", "a.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("", "a"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "A"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "aA"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "a.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("a", "a/a"))
            //
            XCTAssertFalse(SelectorUtils.matchPath("*", ""))
            XCTAssertTrue(SelectorUtils.matchPath("*", "a.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("*", "a.txt/"))
            XCTAssertFalse(SelectorUtils.matchPath("*", "/a.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("*", "a/a.txt"))
            //
            XCTAssertTrue(SelectorUtils.matchPath("**", ""))
            XCTAssertTrue(SelectorUtils.matchPath("**", "a.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**", "a.txt/"))
            XCTAssertTrue(SelectorUtils.matchPath("**", "/a.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**", "/a.txt/"))
            XCTAssertTrue(SelectorUtils.matchPath("**", "a/a.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**", "/a/b/a.txt"))
            //
            XCTAssertTrue(SelectorUtils.matchPath("**/file.txt", "file.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/file.txt", "a/file.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/file.txt", "a/b/file.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/file.txt", "/a/file.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/file.txt", "/a/b/file.txt"))
            //
            XCTAssertFalse(SelectorUtils.matchPath("*/file.txt", "file.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("*/file.txt", "a/file.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("*/file.txt", "a/b/file.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("*/file.txt", "/a/file.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("*/file.txt", "/a/b/file.txt"))
            //
            XCTAssertFalse(SelectorUtils.matchPath("file.txt", "File.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("*/file.txt", "a/File.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("a/*.txt", "a/File.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("a/*.txt", "a/b/File.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("a/**/*.txt", "a/b/File.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/*.txt", "a/b/File.txt"))
            XCTAssertTrue(SelectorUtils.matchPath("**/b/*.txt", "a/b/File.txt"))
            XCTAssertFalse(SelectorUtils.matchPath("**/b/*.txt", "a/b/c/File.txt"))
        }
    }
}
