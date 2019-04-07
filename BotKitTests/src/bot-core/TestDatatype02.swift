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

class TestDatatype02: TestBase {

    open override var DEBUGGING: Bool {
        return false
    }
    
    public func test01() {
        let filesdir = testResDir.file("files")
        subtest {
            XCTAssertEqual(5, Fileset(filesdir, "dir1/**/*.txt").collect().count)
        }
        subtest {
            var total = 0
            var files = 0
            var dirs = 0
            Fileset(filesdir).walk { file, rpath in
                total += 1
                if file.isFile { files += 1 } else { dirs += 1 }
            }
            XCTAssertEqual(16, total)
            XCTAssertEqual(11, files)
            XCTAssertEqual(5, dirs)
        }
    }

    func testFileset02() {
        let filesdir = testResDir.file("files")
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes(
                        "dir2/file*.txt",
                        "dir2/**/file2a.txt")
                    .excludes(
                        "dir2/file1.txt",
                        "dir2/notexists.txt")
                    .collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes(
                        try! Regex("^dir2/file\\d+.txt$"),
                        try! Regex("^dir2/(.*/)?file2a.txt$"))
                    .excludes(
                        try! Regex("^dir2/file1.txt$"),
                        try! Regex("^dir2/notexists.txt$"))
                    .collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes([
                        "dir2/file*.txt",
                        "dir2/**/file2a.txt"])
                    .excludes([
                        "dir2/file1.txt",
                        "dir2/notexists.txt"])
                    .collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes([
                        try! Regex("^dir2/file\\d+.txt$"),
                        try! Regex("^dir2/(.*/)?file2a.txt$")])
                    .excludes([
                        try! Regex("^dir2/file1.txt$"),
                        try! Regex("^dir2/notexists.txt$")])
                    .collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes(
                        { file, rpath in rpath.hasSuffix("dir2/file1.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/file2.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/dir2a/file2a.txt") })
                    .excludes(
                        { file, rpath in rpath.hasSuffix("dir2/file1.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/notexists.txt") })
                    .collect().toPathSet()
            )
        }
        subtest {
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/file2.txt",
                    "dir2/dir2a/file2a.txt"
                ),
                Fileset(filesdir)
                    .includes([
                        { file, rpath in rpath.hasSuffix("dir2/file1.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/file2.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/dir2a/file2a.txt") }])
                    .excludes([
                        { file, rpath in rpath.hasSuffix("dir2/file1.txt") },
                        { file, rpath in rpath.hasSuffix("dir2/notexists.txt") }])
                    .collect().toPathSet()
            )
        }
    }

    func testIgnoresDir02() {
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
                Fileset(filesdir, "**/*.txt").ignoresDir(["dir2", "notexists"]).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "empty.txt"),
                Fileset(filesdir, "**/*.txt").ignoresDir(["dir1", "**/dir*a"]).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt",
                    "empty.txt"
                ),
                Fileset(filesdir, "**/*.txt").ignoresDir(
                    try! Regex("^dir2$"),
                    try! Regex("^notexists/.*$")
                    ).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "empty.txt"),
                Fileset(filesdir, "**/*.txt").ignoresDir(
                    try! Regex("^dir1$"),
                    try! Regex("^.*/dir.*a$")).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "dir1/dir1only.txt",
                    "dir1/file1.txt",
                    "dir1/file2.txt",
                    "empty.txt"
                ),
                Fileset(filesdir, "**/*.txt").ignoresDir([
                    try! Regex("^dir2$"),
                    try! Regex("^notexists/.*$")
                    ]).collect().toPathSet()
            )
            XCTAssertEqual(
                Set(arrayLiteral:
                    "dir2/dir1a.txt",
                    "dir2/dir2only.txt",
                    "dir2/file1.txt",
                    "dir2/file2.txt",
                    "empty.txt"),
                Fileset(filesdir, "**/*.txt").ignoresDir([
                    try! Regex("^dir1$"),
                    try! Regex("^.*/dir.*a$")
                    ]).collect().toPathSet()
            )
        }
    }
    
    func testFilesetWalkX01() {
        let filesdir = testResDir.file("files")
        subtest {
            do {
                try Fileset(filesdir).walk { file, rpath in
                    throw IOException("Expected exception")
                }
                XCTFail()
            } catch let e {
                XCTAssertTrue(e is IOException)
            }
        }
        subtest {
            var count = 0
            do {
                try Fileset(filesdir).walk { file, rpath in
                    if rpath == "dir2/dir2only.txt" {
                        throw IOException("Expected exception")
                    }
                    count += 1
                }
                XCTFail()
            } catch let e {
                self.log.d("# count=\(count)")
                XCTAssertTrue(count > 0)
                XCTAssertTrue(e is IOException)
            }
        }
        subtest {
            var count = 0
            do {
                try Fileset(filesdir).walk(true) { file, rpath in
                    if rpath == "dir2/dir2only.txt" {
                        throw IOException("Expected exception")
                    }
                    count += 1
                }
                XCTFail()
            } catch let e {
                self.log.d("# count=\(count)")
                XCTAssertTrue(count > 0)
                XCTAssertTrue(e is IOException)
            }
        }
    }
    
    func testSelector01() {
        let filesdir = testResDir.file("files")
        subtest {
            let rpath = "dir2/dir2only.txt"
            let file = filesdir.file(rpath)
            XCTAssertFalse(Fileset.SelectorFilter("dir2/file1.txt").invoke(file, rpath))
            XCTAssertTrue(Fileset.SelectorFilter("dir2/file1.txt", "dir2/**").invoke(file, rpath))
            XCTAssertFalse(Fileset.SelectorFilter(["dir2/file1.txt"]).invoke(file, rpath))
            XCTAssertTrue(Fileset.SelectorFilter(["dir2/file1.txt", "dir2/**"]).invoke(file, rpath))
            XCTAssertTrue(Fileset.SelectorFilter(false, "dir2/file1.txt", "Dir2/**").invoke(file, rpath))
            XCTAssertTrue(Fileset.SelectorFilter(false, "dir2/file1.txt", "Dir2/**").invoke(file, rpath))
            XCTAssertFalse(Fileset.SelectorFilter(true, "dir2/file1.txt", "Dir2/**").invoke(file, rpath))
            XCTAssertFalse(Fileset.SelectorFilter(true, "dir2/file1.txt", "Dir2/**").invoke(file, rpath))
        }
        subtest {
            let rpath = "dir2/dir2only.txt"
            let file = filesdir.file(rpath)
            XCTAssertFalse(Fileset.RegexFilter("^dir2/file.*$").invoke(file, rpath))
            XCTAssertTrue(Fileset.RegexFilter("^dir2/file.*$", "^dir2/.*$").invoke(file, rpath))
            XCTAssertFalse(Fileset.RegexFilter(["^dir2/file.*$"]).invoke(file, rpath))
            XCTAssertTrue(Fileset.RegexFilter(["^dir2/file.*$", "^dir2/.*$"]).invoke(file, rpath))
            XCTAssertFalse(Fileset.RegexFilter(
                try! Regex("^dir2/file.*$")).invoke(file, rpath))
            XCTAssertTrue(Fileset.RegexFilter(
                try! Regex("^dir2/file.*$"),
                try! Regex("^dir2/.*$")).invoke(file, rpath))
            XCTAssertFalse(Fileset.RegexFilter([
                try! Regex("^dir2/file.*$")]).invoke(file, rpath))
            XCTAssertTrue(Fileset.RegexFilter([
                try! Regex("^dir2/file.*$"),
                try! Regex("^dir2/.*$")]).invoke(file, rpath))
        }
    }
    
    func testFilepathSet02() {
        let filesdir = testResDir.file("files")
        subtest("init(Sequence)") {
            let list = Filepathset(
                filesdir,
                "dir2/notexists",
                "dir2/dir1a.txt",
                "dir2/dir2a",
                "dir2/dir2only.txt",
                "dir2/dir2a/file2a.txt",
                "notexists.txt"
                ).includes([
                    "dir1/dir1a",
                    "dir1/dir2a.txt",
                    "dir1/dir1a/file1a.txt",
                    "notexists1"
                ]).collect(true).toPathList()
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
        subtest("Walk(IFilePathCallbackX") {
            let list = Filepathset(
                filesdir,
                "dir2/notexists",
                "dir2/dir1a.txt",
                "dir2/dir2a",
                "dir2/dir2only.txt",
                "dir2/dir2a/file2a.txt",
                "notexists.txt")
                .includes([
                    "dir1/dir1a",
                    "dir1/dir1a/file1a.txt",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "notexists1"])
                .collect().toPathList()
            self.log.d(list)
            XCTAssertEqual(6, list.count)
            var count = 0
            let e = With.error {
                try Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2/dir2a/file2a.txt",
                    "notexists.txt")
                    .includes([
                        "dir1/dir1a",
                        "dir1/dir1a/file1a.txt",
                        "dir2/dir1a.txt",
                        "dir2/dir2a",
                        "notexists1"])
                    .walk { file, rpath in
                        self.log.d(rpath)
                        if rpath == "dir1/dir1a" {
                            throw IOException()
                        }
                        count += 1
                }}
            self.log.d("# e = \(String(describing: e ))")
            XCTAssertTrue(e is IOException)
            XCTAssertEqual(0, count, "\(count)")
        }
        subtest("Walk(IFilePathCallbackX") {
            var count = 0
            let e = With.error {
                try Filepathset(
                    filesdir,
                    "dir2/notexists",
                    "dir2/dir1a.txt",
                    "dir2/dir2a",
                    "dir2/dir2only.txt",
                    "dir2/dir2a/file2a.txt",
                    "notexists.txt")
                    .includes([
                        "dir1/dir1a",
                        "dir1/dir1a/file1a.txt",
                        "dir2/dir1a.txt",
                        "dir2/dir2a",
                        "notexists1"])
                    .walk(true) { file, rpath in
                        self.log.d(rpath)
                        if rpath == "dir1/dir1a" {
                            throw IOException()
                        }
                        count += 1
                }}
            self.log.d("# e = \(String(describing: e ))")
            XCTAssertTrue(e is IOException)
            XCTAssertEqual(5, count, "\(count)")
        }
    }
}
