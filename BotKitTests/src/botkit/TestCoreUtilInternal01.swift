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
@testable import BotKit

class TestCoreUtilInternal01: TestBase {

    func testCleanPathSegments01() {
        XCTAssertEqual("", FileUtil.cleanPathSegments("").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("/").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("//").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("/////").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("/.").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("/./").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments(".").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("./").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("./.").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("/././/").joinPath())
        XCTAssertEqual("", FileUtil.cleanPathSegments("//a/../").joinPath())
        XCTAssertEqual("a/b/c", FileUtil.cleanPathSegments("/a/b/./c").joinPath())
        XCTAssertEqual("a/b/c", FileUtil.cleanPathSegments("/a/b/./c/").joinPath())
        XCTAssertEqual("a/c", FileUtil.cleanPathSegments("/a/b/../c/").joinPath())
        XCTAssertEqual("a/c", FileUtil.cleanPathSegments("/a/b/../c").joinPath())
        XCTAssertEqual("a", FileUtil.cleanPathSegments("/a/b/..//.//c/..").joinPath())
        XCTAssertEqual("a", FileUtil.cleanPathSegments("/a/b/..//.//c/../").joinPath())
        XCTAssertEqual("..", FileUtil.cleanPathSegments("..").joinPath())
        XCTAssertEqual("../a", FileUtil.cleanPathSegments("../a").joinPath())
        XCTAssertEqual("../a", FileUtil.cleanPathSegments("../a/.").joinPath())
        XCTAssertEqual("../a", FileUtil.cleanPathSegments("../a/./").joinPath())
        XCTAssertEqual("../..", FileUtil.cleanPathSegments("../../.").joinPath())
        XCTAssertEqual("../..", FileUtil.cleanPathSegments("../a/b/../../..").joinPath())
        XCTAssertEqual("../..", FileUtil.cleanPathSegments("../a/b/../../..///").joinPath())
        XCTAssertEqual("..", FileUtil.cleanPathSegments("a/b/../../..").joinPath())
        XCTAssertEqual("../c", FileUtil.cleanPathSegments("a/b/../../../c").joinPath())
        XCTAssertEqual("a/b", FileUtil.cleanPathSegments("////a////b").joinPath())
        XCTAssertEqual("a/b", FileUtil.cleanPathSegments("////a////b///").joinPath())
        XCTAssertEqual("a/b/c/d", FileUtil.cleanPathSegments("a/b/c/d").joinPath())
        XCTAssertEqual("aaa/bb/cc/dd", FileUtil.cleanPathSegments("/aaa/bb/cc/dd/").joinPath())
    }
}
