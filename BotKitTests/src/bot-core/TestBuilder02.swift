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

class TestBuilder02 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testExpectError01() {
        subtest("Expect.error()") {
            self.log.expectError("Expected error not occurred") {
                self.log.e("# ERROR: Expected error")
            }
            XCTAssertEqual(0, self.log.resetErrorCount())
            self.log.expectError("Expected error not occurred") {
            }
            XCTAssertEqual(1, self.log.resetErrorCount())
        }
        subtest {
            class Builder: BasicBuilder {
                init() {
                    super.init(BasicBuilderConf(debugging: true))
                }
                func test() {
                    log.expectError("Expected error not occurred") {
                        self.log.e("# ERROR: Expected error")
                    }
                    XCTAssertEqual(0, log.resetErrorCount())
                    log.expectError("Expected error not occurred") {
                    }
                    XCTAssertEqual(1, log.resetErrorCount())
                }
            }
            Builder().test()
        }
    }
    
    func testTestBase01() throws {
        let dir = tmpDir()
        let file1 = tmpFile(suffix: ".html", dir: dir)
        let file2 = tmpFile(suffix: ".html")
        let res = try testResData("html/manual.html")
        XCTAssertTrue(file1.name.hasSuffix(".html"))
        XCTAssertEqual(dir, file1.parent)
        XCTAssertTrue(file2.name.hasSuffix(".html"))
        XCTAssertEqual(tmpdir, file2.parent)
        XCTAssertEqual(19072, res.count)
        XCTAssertTrue(With.error {
            _ = try testResData("html/notexists.html")
            } is IOException)
    }
    
    func testProject01() {
        subtest("KotlinProject") {
            let project = KotlinProject(GAV("group", "artifact", "1.0"), self.testResDir.file("workspace/kotlinProject01"))
            XCTAssertTrue(project.srcDir.exists)
            XCTAssertTrue(project.buildDir.exists)
            XCTAssertTrue(project.outDir.exists)
            XCTAssertEqual(2, project.mainSrcs.count)
            XCTAssertEqual(2, project.testSrcs.count)
            XCTAssertTrue(project.outDir.exists)
            XCTAssertTrue(project.mainRes.exists)
            XCTAssertTrue(project.testRes.exists)
        }
        subtest("SwiftProject") {
            let project = SwiftProject(GAV("group", "artifact", "1.0"), self.testResDir.file("workspace/swiftProject01"))
            XCTAssertTrue(project.srcDir.exists)
            XCTAssertTrue(project.resDir.exists)
        }
    }
}
