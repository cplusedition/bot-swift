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

class TestBuilderUt01 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testBuilderUtil01() {
        subtest {
            let file = self.testResDir.file("html/manual.html")
            XCTAssertEqual(19072, file.length)
            XCTAssertEqual("19 kB", BU.filesizeString(file))
            XCTAssertEqual("19 kB", BU.filesizeString(file.length))
        }
    }
    
    func testBuilderAncestorTree01() throws {
        class Builder : IBasicBuilder {
            public lazy var conf: IBuilderConf = BasicBuilderConf(
                project: BasicProject(GAV("group", "project", "0"), File(TestBase.resourcesBundlePath("files/dir1/dir1a"))),
                builder: BasicProject(GAV("group", "builder", "0"), File(TestBase.resourcesBundlePath("files/dir2/dir2a"))),
                debugging: true
            )
            public lazy var log: ICoreLogger = TestLogger(true)
            public init() {}
            func test() {
                let dir = conf.project.dir
                XCTAssertTrue(BU.ancestorTree("files", dir)?.exists ?? false)
                XCTAssertTrue(BU.ancestorTree("files/dir1", dir)?.exists ?? false)
                XCTAssertTrue(BU.ancestorTree("resources.bundle/html/manual.html", dir)?.exists ?? false)
                XCTAssertNil(BU.ancestorTree("", dir))
                XCTAssertNil(BU.ancestorTree("notexists.html"))
                XCTAssertNil(BU.ancestorTree("files/notexists", dir))
                XCTAssertNil(BU.ancestorTree("files/dir1/notexists"))
                XCTAssertNil(BU.ancestorTree("dir2", dir))
                XCTAssertTrue(BU.ancestorSiblingTree("files/dir1", dir)?.exists ?? false)
                XCTAssertTrue(BU.ancestorSiblingTree("resources.bundle/html/manual.html", dir)?.exists ?? false)
                XCTAssertTrue(BU.ancestorSiblingTree("dir2", dir)?.exists ?? false)
                XCTAssertTrue(BU.ancestorSiblingTree("html/manual.html", dir)?.exists ?? false)
                XCTAssertNil(BU.ancestorSiblingTree("", dir))
                XCTAssertNil(BU.ancestorSiblingTree("notexists", dir))
                XCTAssertNil(BU.ancestorSiblingTree("html/notexists", dir))
                XCTAssertNil(BU.ancestorSiblingTree("dir1/notexists", dir))
                XCTAssertNil(BU.ancestorSiblingTree("dir2"))
                XCTAssertNil(BU.ancestorSiblingTree("notexists/notexists"))
            }
        }
        Builder().test()
    }
}
