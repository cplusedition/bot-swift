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

extension MySeq where Element == (File, String) {
    func toPathSet() -> Set<String> {
        return Set(map { $0.1 })
    }
    
    func toPathList() ->Array<String> {
        return map { $0.1 }
    }
}

class TestDatatype01 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testFileset01() throws {
        let filesdir = testResDir.file("files")
        subtest("**") {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt"
                ),
                Fileset(filesdir, "dir2/**/*.txt").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt"
                ),
                Fileset(filesdir, "dir2/*.txt").collect().toPathSet()
            )
        }
        subtest("Multi") {
            // Not supporting multiple patterns in a single pattern string.
            XCTAssertEqual(
                Set<String>(),
                Fileset(filesdir).includes("dir1/dir** dir2/dir**").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt"
                ),
                Fileset(filesdir).includes("dir1/dir**", "dir2/dir**").collect().toPathSet()
            )
        }
        try subtest("Space separated") {
            let tmpdir = self.tmpDir()
            try tmpdir.file("a b/a b c.t x t").mkparentOrFail().writeText("testing123")
            try tmpdir.file("a b/a c/t.txt").mkparentOrFail().writeText("testing123")
            XCTAssertEqual(
                Set(arrayLiteral:
                    "a b",
                    "a b/a b c.t x t",
                    "a b/a c",
                    "a b/a c/t.txt"
                ), Fileset(tmpdir, "a b/**").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "a b/a b c.t x t",
                    "a b/a c"
                ), Fileset(tmpdir, "a b/*").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "a b/a b c.t x t",
                    "a b/a c/t.txt"
                ), Fileset(tmpdir, "**").files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "a b",
                    "a b/a c"
                ), Fileset(tmpdir, "**/*").dirs().toPathSet()
            )
        }
    }

    func testFilesetCollect01() {
        let filesdir = testResDir.file("files")
        subtest("collect(preorder)") {
            XCTAssertEqual(16, Fileset(filesdir).collect().count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a"
                ),
                Fileset(filesdir, "**/*a*", "**/file1*").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt",
                    "dir1",
                    "empty.dir",
                    "empty.txt"
                ), Fileset(filesdir, nil, "**/file*").collect().toPathSet()
            )
            let list = Fileset(filesdir).includes("**/*1*", "**/*2*").collect().toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "dir1",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt"
                ),
                Set(list)
            )
            // Scan is same as preOrder.
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! < list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
        }
        subtest("collect(bottomUp)") {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt",
                    "dir1",
                    "empty.dir",
                    "empty.txt"
                ),
                Fileset(filesdir, nil, "**/file*").collect(true).toPathSet()
            )
            let list = Fileset(filesdir).includes("**/*1*", "**/*2*").collect(true).toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "dir1",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt"
                ),
                Set(list)
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! > list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
    }

    
    func testFilesetWalk01() {
        let filesdir = testResDir.file("files")
        func walk(_ fileset: Fileset, _ bottomup: Bool = false) -> Array<String> {
            var ret = Array<String>()
            fileset.walk(bottomup) { _, rpath in ret.append(rpath) }
            return ret
        }
        subtest("collect(preorder)") {
            XCTAssertEqual(16, walk(Fileset(filesdir)).count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a"),
                walk(Fileset(filesdir, "**/*a*", "**/file1*")).toSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt",
                    "dir1",
                    "empty.dir",
                    "empty.txt"
                ), walk(Fileset(filesdir, nil, "**/file*")).toSet()
            )
            let list = walk(Fileset(filesdir).includes("**/*1*", "**/*2*"))
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "dir1",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt"
                ),
                list.toSet()
            )
            // Scan is same as preOrder.
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! < list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
        }
        subtest("collect(bottomUp)") {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt",
                    "dir1",
                    "empty.dir",
                    "empty.txt"
                ),
                walk(Fileset(filesdir, nil, "**/file*"), true).toSet()
            )
            let list = walk(Fileset(filesdir).includes("**/*1*", "**/*2*"), true)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "dir1",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt"
                ),
                list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! > list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
    }

    
    func testFilesetFiles01() {
        let filesdir = testResDir.file("files")
        subtest("files") {
            XCTAssertEqual(11, Fileset(filesdir).files().count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir2a.txt"),
                Fileset(filesdir, "**/*a*", "**/file1*").files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/file1.txt",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt"
                ),
                Fileset(filesdir, "**/*1*").files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt",
                    "dir1/dir1only.txt",
                    "empty.txt"),
                Fileset(filesdir, nil, "**/file*").files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "prefix/dir2/dir1a.txt",
                    "prefix/dir2/dir2only.txt",
                    "prefix/dir1/dir2a.txt",
                    "prefix/dir1/dir1only.txt",
                    "prefix/empty.txt"
                ),
                Fileset(filesdir, nil, "**/file*").basepath("prefix").files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "prefix/dir2/dir1a.txt",
                    "prefix/dir2/dir2only.txt",
                    "prefix/dir1/dir2a.txt",
                    "prefix/dir1/dir1only.txt",
                    "prefix/empty.txt"
                ),
                Fileset(filesdir, nil, "**/file*").basepath("prefix").files(true).toPathSet()
            )
        }
    }

    
    func testFilesetDirs01() {
        let filesdir = testResDir.file("files")
        subtest("dirs") {
            XCTAssertEqual(5, Fileset(filesdir).dirs().count)
            XCTAssertEqual(
                Set(arrayLiteral: "dir2/dir2a", "dir1/dir1a"),
                Fileset(filesdir, "**/*a*", "**/file1*").dirs().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral: "dir1/dir1a", "dir1"),
                Fileset(filesdir, "**/*1*").dirs().toPathSet()
            )
        }
        subtest("dirs(predorder)") {
            let list = Fileset(filesdir, nil, "**/file*").dirs(false).toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir2a",
                    "dir2",
                    "dir1/dir1a",
                    "dir1",
                    "empty.dir"),
                list.toSet())
            XCTAssertTrue(list.firstIndex(of: "dir1")! < list.firstIndex(of: "dir1/dir1a")!)
        }
        subtest("dirs(bottomUp)") {
            let list = Fileset(filesdir, nil, "**/file*").dirs(true).toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir2a",
                    "dir2",
                    "dir1/dir1a",
                    "dir1",
                    "empty.dir"),
                list.toSet())
            XCTAssertTrue(list.firstIndex(of: "dir1")! > list.firstIndex(of: "dir1/dir1a")!)
        }
        subtest("dirs(basepath, predorder)") {
            let list = Fileset(filesdir, nil, "**/file*").basepath("prefix").dirs().toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "prefix/dir2/dir2a",
                    "prefix/dir2",
                    "prefix/dir1/dir1a",
                    "prefix/dir1",
                    "prefix/empty.dir"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "prefix/dir1")! < list.firstIndex(of: "prefix/dir1/dir1a")!)
        }
        subtest("dirs(basepath, bottomUp)") {
            let list = Fileset(filesdir, nil, "**/file*").basepath("prefix").dirs(true).toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "prefix/dir2/dir2a",
                    "prefix/dir2",
                    "prefix/dir1/dir1a",
                    "prefix/dir1",
                    "prefix/empty.dir"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "prefix/dir1")! > list.firstIndex(of: "prefix/dir1/dir1a")!)
        }
    }


    func testFilesetCollectorCollect01() {
        let filesdir = testResDir.file("files")
        subtest("collect(preorder)") {
            XCTAssertEqual(16, Fileset(filesdir).collector{ ($0, $1) }.collect().count)
            XCTAssertEqual(16, Fileset(filesdir).collector{ file , _ in file }.collect().count)
            XCTAssertEqual(16, Fileset(filesdir).collector{ $1 }.collect().count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir2/dir2a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a"),
                Fileset(filesdir, "**/*a*", "**/file1*").collector{ $1 }.collect().toSet()
            )
        }
    }


    func testFilesetCollectorFiles01() {
        let filesdir = testResDir.file("files")
        subtest("files") {
            XCTAssertEqual(11, Fileset(filesdir).collector{ ($0, $1) }.files().count)
            XCTAssertEqual(11, Fileset(filesdir).collector{ file, _ in file }.files().count)
            XCTAssertEqual(11, Fileset(filesdir).collector{ $1 }.files().count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir2a.txt"),
                Fileset(
                    filesdir,
                    "**/*a*",
                    "**/file1*"
                    ).collector{ $1 }.files().toSet()
            )
        }
    }


    func testFilesetCollectorDirs01() {
        let filesdir = testResDir.file("files")
        subtest("dirs") {
            XCTAssertEqual(5, Fileset(filesdir).collector{ ($0, $1) }.dirs().count)
            XCTAssertEqual(5, Fileset(filesdir).collector{ file, _ in file }.dirs().count)
            XCTAssertEqual(5, Fileset(filesdir).collector{ $1 }.dirs().count)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir2a",
                    "dir1/dir1a"),
                Fileset(filesdir, "**/*a*", "**/file1*").collector{ $1 }.dirs().toSet()
            )
        }
    }

    func testIgnoresDir01() {
        let filesdir = testResDir.file("files")
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt",
                    "empty.txt"
                ),
                Fileset(filesdir, "**/*.txt").ignoresDir("dir2").collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "empty.txt"),
                Fileset(filesdir, "**/*.txt").ignoresDir("dir1", "**/dir*a").collect().toPathSet()
            )
        }
    }

    func testRegexFilter01() {
        let filesdir = testResDir.file("files")
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt"
                ),
                /// Note that match is only anchored at start, so $ is required here.
                Fileset(filesdir, try! Regex(".*dir\\d+/dir\\d+[^/]*$")).collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt"
                ),
                Fileset(filesdir, try! Regex("^.*dir\\d+/dir\\d+[^/]*$"), try! Regex("^.*/dir1.*$")).collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt"
                ),
                Fileset(filesdir).includes(
                    try! Regex("^.*dir1/dir\\d+[^/]*$"),
                    try! Regex("^.*dir2/dir\\d+[^/]*$")
                ).collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2",
                    "dir2/dir2a/file2a.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "dir1",
                    "dir1/dir1a/file1a.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt"
                ),
                Fileset(filesdir).excludes(
                    try! Regex("^.*dir\\d+/dir\\d+[^/]*$"),
                    try! Regex("^empty.*$")
                ).collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt"
                ),
                Fileset(filesdir).includes(Fileset.RegexFilter.predicate(["^.*dir\\d+/dir\\d+[^/]*$"])).collect(true).toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir1/dir2a.txt",
                    "dir1/dir1a",
                    "dir1/dir1only.txt"
                ),
                Fileset(filesdir).includes(
                    Fileset.RegexFilter.predicate([
                        "^.*dir1/dir\\d+[^/]*$",
                        "^.*dir2/dir\\d+[^/]*$"
                        ])
                ).collect(true).toPathSet()
            )
        }
    }

    func testFilepathset01() {
        let filesdir = testResDir.file("files")
        subtest {
            let list = Filepathset(
                filesdir,
                "dir2/notexists",
                "dir2/dir1a.txt",
                "dir2/dir2a",
                "dir2/dir2only.txt",
                "dir2/dir2a/file2a.txt",
                "notexists.txt"
            ).includes(
                "dir1/dir1a",
                "dir1/dir2a.txt",
                "dir1/dir1a/file1a.txt",
                "notexists1"
            ).collect(true).toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir1a",
                    "dir2/dir2a",
                    "dir1/dir1a/file1a.txt",
                    "dir2/dir2only.txt"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! > list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
        subtest {
            let list = Filepathset(
                filesdir,
                "dir2/notexists",
                "dir2/dir1a.txt",
                "dir2/dir2a",
                "dir2/dir2only.txt",
                "dir2/dir2a/file2a.txt",
                "notexists.txt"
            ).includes(
                "dir1/dir1a",
                "dir1/dir2a.txt",
                "dir1/dir1a/file1a.txt",
                "notexists1"
            ).collect().toPathList()
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir1a",
                    "dir2/dir2a",
                    "dir1/dir1a/file1a.txt",
                    "dir2/dir2only.txt"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! < list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt"
                ),
                Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "notexists.txt"
                ).includes(
                    "dir1/dir2a.txt",
                    "notexists1"
                ).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt"
                ),
                Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "notexists.txt"
                ).includes(
                    "dir1/dir2a.txt",
                    "notexists1"
                ).files().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir2a"
                ),
                Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "notexists.txt"
                ).includes(
                    "dir1/dir2a.txt",
                    "notexists1"
                ).dirs().toPathSet()
            )
        }
    }


    func testFilepathsetWalk01() {
        let filesdir = testResDir.file("files")
        func walk(_ fileset: Filepathset, _ bottomup: Bool = false) -> Array<String> {
            var ret = Array<String>()
            fileset.walk(bottomup) { _, rpath in ret.append(rpath) }
            return ret
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt"
                ),
                walk(
                    Filepathset(
                        filesdir,
                        "dir2/notexists",
                        "dir2/dir1a.txt",
                        "dir2/dir2a",
                        "dir2/dir2only.txt",
                        "notexists.txt"
                    ).includes(
                        "dir1/dir2a.txt",
                        "notexists1"
                    )
                ).toSet()
            )
        }
        subtest {
            let list = walk(
                Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2/dir2a/file2a.txt",
                    "notexists.txt"
                ).includes(
                    "dir1/dir1a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "notexists1"
                ), true)
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir1a",
                    "dir2/dir2a",
                    "dir1/dir1a/file1a.txt",
                    "dir2/dir2only.txt"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! > list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
        subtest {
            let list = walk(
                Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2/dir2a/file2a.txt",
                    "notexists.txt"
                ).includes(
                    "dir1/dir1a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "notexists1"
                )
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a/file2a.txt",
                    "dir1/dir1a",
                    "dir2/dir2a",
                    "dir1/dir1a/file1a.txt",
                    "dir2/dir2only.txt"
                ), list.toSet()
            )
            XCTAssertTrue(list.firstIndex(of: "dir2/dir2a")! < list.firstIndex(of: "dir2/dir2a/file2a.txt")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
    }


    func testFilemap01() {
        let filesdir = testResDir.file("files")
        subtest {
            let tmpdir = self.tmpDir()
            let filemap = Filemap().add(filesdir.file(), tmpdir.file())
                .add(Fileset(filesdir, "dir1/**/file*.txt"), tmpdir)
                .add(Fileset(filesdir, "dir2/dir*/**"), { _, rpath in tmpdir.file("\(rpath)/test") })
            if (self.log.debugging) {
                for (k, v) in filemap.mapping {
                    let src = FileUtil.rpathOrNull(file: k, base: filesdir.parent!)!
                    let dst = FileUtil.rpathOrNull(file: v, base: tmpdir.parent!)!
                    self.log.d("\(src) -> \(dst)")
                }
            }
            XCTAssertEqual(8, filemap.mapping.count)
            XCTAssertEqual(3, filemap.mapping.keys.filter { $0.path.contains("files/dir1/") }.count)
            XCTAssertEqual(3, filemap.reversed().values.filter { $0.path.contains("files/dir1/") }.count)
            XCTAssertEqual(7, filemap.modified().count)
        }
        subtest {
            let srcdir = self.tmpDir()
            let dstdir = self.tmpDir()
            func debugprint(_ msg: String, _ map: Dictionary<File, File>) {
                if (self.log.debugging) {
                    self.log.d("\(msg): \(map.count)")
                    map.forEach { k, v in
                        let src = FileUtil.rpathOrNull(file: k, base: srcdir.parent!)
                        let dst = FileUtil.rpathOrNull(file: v, base: dstdir.parent!)
                        self.log.d("\(String(describing: src)) -> \(String(describing: dst))")
                    }
                }
            }
            self.task(Copy(srcdir, filesdir))
            self.task(Copy(dstdir, filesdir))
            self.task(Remove(dstdir, "dir1/dir1a/**"))
            let now = DateUtil.ms
            Fileset(srcdir, "dir2/file*.txt").collect(true)
                .forEach { pair in _ = pair.0.setLastModified(ms: now) }
            let filemap = Filemap().add(srcdir.file(), dstdir.file())
                .add(Fileset(srcdir, "**/file*.txt"), dstdir)
                .add(Fileset(srcdir, "dir2/**"), dstdir)
                .add(Fileset(srcdir, "dir2/dir2a/*"), { _, rpath in
                    dstdir.file("\(rpath)/test")
                }
            )
            debugprint("# mapping", filemap.mapping)
            let modified = filemap.modified()
            debugprint("# modified", modified)
            XCTAssertEqual(11, filemap.mapping.count)
            XCTAssertEqual(4, modified.count)
            let dstfile = filemap.mapping[srcdir.file("dir2/dir2a/file2a.txt")]
            XCTAssertTrue(dstfile != nil && dstfile!.path.hasSuffix("dir2/dir2a/file2a.txt/test"))
            for (src, dst) in modified {
                XCTAssertTrue(src.path.contains("/dir2/") || src.path.contains("/dir1/dir1a/"))
                XCTAssertTrue(dst.path.hasSuffix(".txt") || dst.path.hasSuffix("/test"))
            }
        }
    }
}
