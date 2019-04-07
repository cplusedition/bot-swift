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

class TestCoreUtilFileUtil01 : TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    func testBasic01() {
        XCTAssertTrue(testResDir.file("files/empty.txt").exists)
        XCTAssertTrue(tmpDir().listOrEmpty().isEmpty)
        XCTAssertEqual("/", File.ROOT.path)
        XCTAssertEqual("/", File.ROOT.file(".").path)
        XCTAssertEqual("/..", File.ROOT.file("..").path)
        XCTAssertEqual("/", File("/").path)
        XCTAssertEqual("/", File("/.").path)
        XCTAssertEqual("/..", File("/..").path)
        XCTAssertEqual("/", File("//./").path)
        XCTAssertEqual("/..", File("//../").path)
    }

    
    func testMkdirs01() throws {
        XCTAssertEqual(File("a/b/c.html").path, File("a/c/.././b/c.html").path)
        XCTAssertEqual("a/b/c.html", FileUtil.rpathOrNull(file: File("a/c/.././b/c.html"), base: File.pwd))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: File("../a/c/.././b/c.html"), base: File.pwd))
        XCTAssertNotNil(File.pwd.mkparent())
        XCTAssertNil(File("/").mkparent())
        XCTAssertNotNil(tmpDir().mkdirs()?.existsOrNull)
        XCTAssertNotNil(File("/").mkdirs()?.existsOrNull)
        XCTAssertNil(File("/notexists").mkdirs())
        XCTAssertNotNil(tmpDir().file("test").mkdirs()?.existsOrNull)
        XCTAssertNil(File("/").file("notexists/test").mkdirs())
        XCTAssertNil(File("/").file("notexists/test").mkdirs())
        let tmpdir = tmpDir()
        let tmptestdir = tmpdir.file("test")
        try tmptestdir.file("c/d.txt").mkparentOrThrow().writeText("xxx")
        XCTAssertTrue(tmpdir.file("test").deleteSubtrees())
        XCTAssertNotNil(tmpdir.file("test").existsOrNull)
        XCTAssertNil(tmpdir.file("test/a").existsOrNull)
        XCTAssertNil(tmpdir.file("test/c").existsOrNull)
        XCTAssertNil(tmpdir.file("test/c/d.txt").existsOrNull)
        XCTAssertTrue(tmptestdir.listOrEmpty().isEmpty)
        XCTAssertTrue(With.error { _ = try File.ROOT.mkparentOrThrow() } is IOException)
    }


    func testMkdirs02() {
        let tmpdir = tmpDir()
        XCTAssertEqual(false, File.home.file("notexists").isDirectory)
        XCTAssertEqual(File.home, File.home.mkdirs())
        XCTAssertTrue(File(tmpdir.path).mkdirs() != nil)
        XCTAssertTrue(File(tmpdir.path, "a/b/c").mkdirs() != nil)
        XCTAssertTrue(tmpdir.file("a/b/c").isDirectory)
        XCTAssertTrue(File("/notexists").mkdirs() == nil)
        XCTAssertTrue(File(tmpdir.path, "a/b/c").mkdirs() != nil)
        XCTAssertTrue(File(tmpdir.path, "a/b/c").mkparent() != nil)
        XCTAssertTrue(File(tmpdir.path, "d/e").mkparent() != nil)
        XCTAssertTrue(File.ROOT.mkparent() == nil)
        XCTAssertEqual(File.ROOT.file("home"), File("/home/../test/.//../home/"))
    }


    func testRpathOrNull01() {
        let base = tmpDir()
        XCTAssertEqual("", FileUtil.rpathOrNull(file: base, base: base))
        XCTAssertEqual(base.name, FileUtil.rpathOrNull(file: base, base: base.parent!))
        XCTAssertEqual("a", FileUtil.rpathOrNull(file: base.file("a"), base: base))
        XCTAssertEqual("a/b", FileUtil.rpathOrNull(file: base.file("a/b"), base: base))
        XCTAssertEqual("a/c", FileUtil.rpathOrNull(file: base.file("a/b/..//./c/"), base: base))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: base.parent!, base: base))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: base.parent!.file("test"), base: base))
        XCTAssertEqual("", FileUtil.rpathOrNull(file: base.parent!.file(base.name), base: base))
        XCTAssertEqual("", FileUtil.rpathOrNull(file: File.ROOT, base: File.ROOT))
        XCTAssertEqual("a", FileUtil.rpathOrNull(file: File.ROOT.file("a"), base: File.ROOT))
        XCTAssertEqual("a/b", FileUtil.rpathOrNull(file: File.ROOT.file("a/b"), base: File.ROOT))
        XCTAssertEqual("a/b", FileUtil.rpathOrNull(file: File.ROOT.file("a/b/"), base: File.ROOT))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: base.file(".."), base: base))
        XCTAssertEqual("", FileUtil.rpathOrNull(file: base.file("a/../"), base: base))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: base.file("a/../.."), base: base))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: base.file("a/../../"), base: base))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: File.ROOT.file(".."), base: File.ROOT))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: File.ROOT.file(".."), base: File.ROOT.file("..")))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: File.ROOT, base: File.ROOT.file("..")))
        XCTAssertEqual(nil, FileUtil.rpathOrNull(file: File.ROOT, base: File.ROOT.file("a")))
    }


    func testWalker01() throws {
        let files = testResDir.file("files")
        subtest {
            var list = Array<String>()
            files.walker.walk { _, rpath in list.append(rpath) }
            self.log.d(list)
            XCTAssertTrue(list.firstIndex(of: "dir1")! < list.firstIndex(of: "dir1/dir1a")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
        subtest {
            var list = Array<String>()
            files.walker.walk { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(8, list.count)
        }
        subtest {
            var list = Array<String>()
            files.walker.basepath("prefix").walk { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(8, list.count)
            for s in list {
                XCTAssertTrue(s.hasPrefix("prefix/") && !s.hasPrefix("prefix//"))
            }
        }
        subtest("BottomUp=false") {
            self.subtest {
                var list = Array<String>()
                files.walker.walk { _, rpath in
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(16, list.count)
                XCTAssertTrue(list.firstIndex(of: "dir1")! < list.firstIndex(of: "dir1/dir1a")!)
                XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
            }
            self.subtest {
                var list = Array<String>()
                files.walker.walk { _, rpath in
                    if rpath.contains("dir2") { return }
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
            }
            self.subtest {
                var list = Array<String>()
                files.walker.basepath("prefix").walk { _, rpath in
                    if rpath.contains("dir2") { return }
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
                for s in list {
                    XCTAssertTrue(s.hasPrefix("prefix/") && !s.hasPrefix("prefix//"))
                }
            }
        }
        subtest("BottomUp=true") {
            self.subtest {
                var list = Array<String>()
                files.walker.bottomUp().walk { _, rpath in
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(16, list.count)
                XCTAssertTrue(list.firstIndex(of: "dir1")! > list.firstIndex(of: "dir1/dir1a")!)
                XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
            }
            self.subtest {
                var list = Array<String>()
                files.walker.bottomUp().walk { _, rpath in
                    if rpath.contains("dir2") { return }
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
            }
            self.subtest {
                var list = Array<String>()
                files.walker.basepath("prefix").bottomUp().walk { _, rpath in
                    if rpath.contains("dir2") { return }
                    list.append(rpath)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
                for s in list {
                    XCTAssertTrue(s.hasPrefix("prefix/") && !s.hasPrefix("prefix//"))
                }
            }
        }
    }
    
    
    func testWalkerFiles01() throws {
        let files = testResDir.file("files")
        subtest {
            var list = Array<String>()
            files.walker.files { _, rpath in
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(11, list.count)
        }
        subtest {
            var list = Array<String>()
            files.walker.files { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
        }
        try subtest {
            var list = Array<String>()
            try files.walker.files { file, rpath in
                if file.isDirectory { throw Exception() }
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(11, list.count)
        }
        try subtest {
            var list = Array<String>()
            try files.walker.files { file, rpath in
                if file.isDirectory { throw Exception() }
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
        }
        subtest {
            var list = Array<String>()
            files.walker.basepath("prefix").files { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            for s in list {
                XCTAssertTrue(s.hasPrefix("prefix/") && !s.hasPrefix("prefix//"))
            }
        }
    }
    
    
    func testWalkerDirs01() throws {
        let files = testResDir.file("files")
        subtest {
            var list = Array<String>()
            files.walker.bottomUp().dirs { _, rpath in
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1")!)
        }
        subtest {
            var list = Array<String>()
            files.walker.dirs { _, rpath in
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1")!)
        }
        try subtest {
            var list = Array<String>()
            try files.walker.bottomUp().dirs { file, rpath in
                if file.isFile { throw Exception() }
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1")!)
        }
        try subtest {
            var list = Array<String>()
            try files.walker.dirs { file, rpath in
                if file.isFile { throw Exception() }
                list.append(rpath)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! > list.firstIndex(of: "dir1")!)
        }
        subtest {
            var list = Array<String>()
            files.walker.dirs { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(3, list.count)
        }
        subtest {
            var list = Array<String>()
            files.walker.basepath("prefix").dirs { _, rpath in
                if (!rpath.contains("dir2")) {
                    list.append(rpath)
                }
            }
            self.log.d(list)
            XCTAssertEqual(3, list.count)
            for s in list {
                XCTAssertTrue(s.hasPrefix("prefix/") && !s.hasPrefix("prefix//"))
            }
        }
    }
    
    
    func testWalkerCollectorCollect01() {
        let files = testResDir.file("files")
        subtest {
            XCTAssertEqual(16, files.walker.collector{ ($0, $1) }.collect().count)
            XCTAssertEqual(16, files.walker.collector{ file, _ in file }.collect().count)
            XCTAssertEqual(16, files.walker.collector{ $1 }.collect().count)
            XCTAssertEqual(files.walker.collector{ file, _ in file }.collect { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 7)
            XCTAssertEqual(files.walker.pathCollector().collect { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 7)
            let list = files.walker.pathCollector().collect().toArray()
            XCTAssertTrue(list.firstIndex(of: "dir1")! < list.firstIndex(of: "dir1/dir1a")!)
            XCTAssertTrue(list.firstIndex(of: "dir1/dir1a")! < list.firstIndex(of: "dir1/dir1a/file1a.txt")!)
        }
    }
    
    
    func testWalkerCollectorFiles01() {
        let files = testResDir.file("files")
        subtest {
            XCTAssertEqual(11, files.walker.collector().files().count)
            XCTAssertEqual(11, files.walker.fileCollector().files().count)
            XCTAssertEqual(11, files.walker.pathCollector().files().count)
            XCTAssertEqual(files.walker.fileCollector().files { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 5)
            XCTAssertEqual(files.walker.pathCollector().files { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 5)
        }
    }
    
    
    func testWalkerCollectorDirs01() {
        let files = testResDir.file("files")
        subtest {
            XCTAssertEqual(5, files.walker.collector().dirs().count)
            XCTAssertEqual(5, files.walker.fileCollector().dirs().count)
            XCTAssertEqual(5, files.walker.pathCollector().dirs().count)
            XCTAssertEqual(files.walker.fileCollector().dirs { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 2)
            XCTAssertEqual(files.walker.pathCollector().dirs { _, rpath in
                rpath.hasPrefix("dir1")
                }.count, 2)
            let list = files.walker.pathCollector().dirs().toArray()
            XCTAssertTrue(list.firstIndex(of: "dir1")! < list.firstIndex(of: "dir1/dir1a")!)
        }
    }
    
    
    func testWalkerFind01() {
        let srcdir = testResDir.file("files")
        let ignoresdir = { (_: File, rpath: String) in !rpath.contains("dir2") }
        let builderkt = { (_: File, rpath: String) in rpath.hasSuffix("/dir2only.txt") }
        //
        let file = srcdir.walker.find { file, rpath in
            file.isFile && rpath.hasSuffix("/dir2only.txt")
        }
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.exists)
        //
        XCTAssertNil(srcdir.walker.find { _, _ in false })
        XCTAssertNil(srcdir.walker.basepath("prefix").find { _, _ in false })
        XCTAssertNil(srcdir.walker.ignoresDir(ignoresdir).find { _, _ in false })
        XCTAssertNil(srcdir.walker.basepath("prefix").ignoresDir(ignoresdir).find { _, _ in false })
        //
        XCTAssertNotNil(srcdir.walker.find(builderkt))
        XCTAssertNotNil(srcdir.walker.basepath("prefix").find(builderkt))
        XCTAssertNotNil(srcdir.walker.ignoresDir(ignoresdir).find(builderkt))
        XCTAssertNotNil(srcdir.walker.basepath("prefix").ignoresDir(ignoresdir).find(builderkt))
    }
    
    
    func testWalkerCollect01() {
        let files = testResDir.file("files")
        subtest {
            let s =
                files.walker.ignoresDir { $1 != "dir1" }.collect { file, _ in file.isFile }
            self.log.d(s.map { $1 })
            XCTAssertEqual(5, s.count)
        }
        subtest {
            let s = files.walker.collect { file, _ in file.isFile }
            self.log.d(s.map { $1 })
            XCTAssertEqual(11, s.count)
        }
        subtest {
            let ignoresdir1 = { (_: File, rpath: String) in rpath != "dir1" && !rpath.hasPrefix("dir1") }
            let ignoresdirdir1 = { (_: File, rpath: String) in rpath != "dir/dir1" && !rpath.hasPrefix("dir/dir1") }
            let isfile = { (file: File, _: String) in file.isFile }
            let isdir1file = { (f: File, rpath: String) in f.isFile && rpath.hasPrefix("dir1/") }
            XCTAssertEqual(11, files.walker.collect(isfile).count)
            XCTAssertEqual(5, files.walker.collect(isdir1file).count)
            //
            XCTAssertEqual(files.walker.collect { f, _ in f.isFile }.count, 11)
            XCTAssertEqual(files.walker.collect { f, _ in !f.isFile }.count, 5)
            XCTAssertEqual(files.walker.collect { f, _ in f.isDirectory }.count, 5)
            XCTAssertEqual(files.walker.collect { f, _ in !f.isDirectory }.count, 11)
            XCTAssertEqual(files.walker.collect { _, _ in true }.count, 16)
            //
            XCTAssertEqual(6, files.walker.ignoresDir(ignoresdir1).collect { f, _ in f.isFile }.count)
            XCTAssertEqual(4, files.walker.ignoresDir(ignoresdir1).collect { f, _ in !f.isFile }.count)
            XCTAssertEqual(4, files.walker.ignoresDir(ignoresdir1).collect { f, _ in f.isDirectory }.count)
            XCTAssertEqual(6, files.walker.ignoresDir(ignoresdir1).collect { f, _ in !f.isDirectory }.count)
            XCTAssertEqual(10, files.walker.ignoresDir(ignoresdir1).collect { _, _ in true }.count)
            //
            XCTAssertEqual(11, files.walker.basepath("dir").collect { f, _ in f.isFile }.count)
            XCTAssertEqual(5, files.walker.basepath("dir").collect { f, _ in !f.isFile }.count)
            XCTAssertEqual(5, files.walker.basepath("dir").collect { f, _ in f.isDirectory }.count)
            XCTAssertEqual(11, files.walker.basepath("dir").collect { f, _ in !f.isDirectory }.count)
            XCTAssertEqual(16, files.walker.basepath("dir").collect { f, _ in true }.count)
            XCTAssertTrue(files.walker.basepath("dir").collect { f, _ in true }.all { (_, rpath) in
                rpath.hasPrefix("dir/")
            })
            //
            XCTAssertEqual(
                6, files.walker.basepath("dir").ignoresDir(ignoresdirdir1)
                    .collect { f, _ in f.isFile }.count
            )
            XCTAssertEqual(
                4, files.walker.basepath("dir").ignoresDir(ignoresdirdir1)
                    .collect { f, _ in !f.isFile }.count
            )
            XCTAssertEqual(
                4, files.walker.basepath("dir").bottomUp().ignoresDir(ignoresdirdir1)
                    .collect { f, _ in f.isDirectory }.count
            )
            XCTAssertEqual(
                6, files.walker.basepath("dir").bottomUp().ignoresDir(ignoresdirdir1)
                    .collect { f, _ in !f.isDirectory }.count
            )
            XCTAssertEqual(
                10, files.walker.basepath("dir").bottomUp().ignoresDir(ignoresdirdir1)
                    .collect { f, _ in true }.count
            )
        }
    }
    
    
    func testWalker101() throws {
        let files = testResDir.file("files")
        try subtest {
            var list = Array<File>()
            files.walker1.walk { list.append($0) }
            self.log.d(list)
            XCTAssertEqual(16, list.count)
            var filecount = 0
            var dircount = 0
            try files.walker1.files {
                if $0.isDirectory { throw Exception() }
                filecount += 1
            }
            try files.walker1.dirs {
                if $0.isFile { throw Exception() }
                dircount += 1
            }
            XCTAssertEqual(11, filecount)
            XCTAssertEqual(5, dircount)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1"))! < list.firstIndex(of: files.file("dir1/dir1a"))!)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! < list.firstIndex(of: files.file("dir1/dir1a/file1a.txt"))!)
        }
        subtest {
            var list = Array<File>()
            files.walker1.walk {
                if (!$0.path.contains("/dir2")) {
                    list.append($0)
                }
            }
            self.log.d(list)
            XCTAssertEqual(8, list.count)
        }
        subtest("BottomUp=false") {
            self.subtest {
                var list = Array<File>()
                files.walker1.walk {
                    list.append($0)
                }
                self.log.d(list)
                XCTAssertEqual(16, list.count)
                XCTAssertTrue(list.firstIndex(of: files.file("dir1"))! < list.firstIndex(of: files.file("dir1/dir1a"))!)
                XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! < list.firstIndex(of: files.file("dir1/dir1a/file1a.txt"))!)
            }
            self.subtest {
                var list = Array<File>()
                files.walker1.walk {
                    if $0.path.contains("/dir2") { return }
                    list.append($0)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
            }
        }
        subtest("BottomUp=true") {
            self.subtest {
                var list = Array<File>()
                files.walker1.bottomUp().walk {
                    list.append($0)
                }
                self.log.d(list)
                XCTAssertEqual(16, list.count)
                XCTAssertTrue(list.firstIndex(of: files.file("dir1"))! > list.firstIndex(of: files.file("dir1/dir1a"))!)
                XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! > list.firstIndex(of: files.file("dir1/dir1a/file1a.txt"))!)
            }
            self.subtest {
                var list = Array<File>()
                files.walker1.bottomUp().walk {
                    if $0.path.contains("/dir2") { return }
                    list.append($0)
                }
                self.log.d(list)
                XCTAssertEqual(8, list.count)
            }
        }
    }
    
    
    func testWalker1Files01() throws {
        let files = testResDir.file("files")
        subtest {
            var list = Array<File>()
            files.walker1.files {
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(11, list.count)
        }
        subtest {
            var list = Array<File>()
            files.walker1.files {
                if (!$0.path.contains("/dir2")) {
                    list.append($0)
                }
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
        }
        try subtest {
            var list = Array<File>()
            try files.walker1.files {
                if $0.isDirectory { throw Exception() }
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(11, list.count)
        }
        try subtest {
            var list = Array<File>()
            try files.walker1.files {
                if $0.isDirectory { throw Exception() }
                if (!$0.path.contains("/dir2")) {
                    list.append($0)
                }
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
        }
    }
    
    
    func testWalker1Dirs01() throws {
        let files = testResDir.file("files")
        subtest {
            var list = Array<File>()
            files.walker1.bottomUp().dirs {
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! < list.firstIndex(of: files.file("dir1"))!)
        }
        subtest {
            var list = Array<File>()
            files.walker1.dirs {
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! > list.firstIndex(of: files.file("dir1"))!)
        }
        try subtest {
            var list = Array<File>()
            try files.walker1.bottomUp().dirs {
                if $0.isFile { throw Exception() }
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! < list.firstIndex(of: files.file("dir1"))!)
        }
        try subtest {
            var list = Array<File>()
            try files.walker1.dirs {
                if $0.isFile { throw Exception() }
                list.append($0)
            }
            self.log.d(list)
            XCTAssertEqual(5, list.count)
            XCTAssertTrue(list.firstIndex(of: files.file("dir1/dir1a"))! > list.firstIndex(of: files.file("dir1"))!)
        }
        subtest {
            var list = Array<File>()
            files.walker1.dirs {
                if (!$0.path.contains("/dir2")) {
                    list.append($0)
                }
            }
            self.log.d(list)
            XCTAssertEqual(3, list.count)
        }
    }
    
    
    func testWalker1Find01() {
        let srcdir = testResDir.file("files")
        let ignoresdir = { (file: File) in !file.path.contains("/dir2") }
        let builderkt = { (file: File) in file.path.hasSuffix("/dir2only.txt") }
        //
        let file = srcdir.walker1.find { (file: File) in file.isFile && file.path.hasSuffix("/dir2only.txt") }
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.exists)
        //
        XCTAssertNil(srcdir.walker1.find { _ in false })
        XCTAssertNil(srcdir.walker1.ignoresDir(ignoresdir).find { _ in false })
        //
        XCTAssertNotNil(srcdir.walker1.find(builderkt))
        XCTAssertNotNil(srcdir.walker1.ignoresDir(ignoresdir).find(builderkt))
    }
    
    
    func testWalker1Collect01() {
        let files = testResDir.file("files")
        subtest {
            let s = files.walker1.ignoresDir { $0.name != "dir1" }.collect { $0.isFile }
            self.log.d(s)
            XCTAssertEqual(5, s.count)
        }
        subtest {
            let s = files.walker1.collect { $0.isFile }
            self.log.d(s)
            XCTAssertEqual(11, s.count)
        }
        subtest {
            let ignoresdir1 = { (file: File) in file.name != "dir1" && !file.path.contains("/dir1/") }
            let isfile = { (file: File) in file.isFile }
            let isdir1file = { (file: File) in file.isFile && file.path.contains("/dir1/") }
            XCTAssertEqual(11, files.walker1.collect(isfile).count)
            XCTAssertEqual(5, files.walker1.collect(isdir1file).count)
            //
            XCTAssertEqual(files.walker1.collect { $0.isFile }.count, 11)
            XCTAssertEqual(files.walker1.collect { !$0.isFile }.count, 5)
            XCTAssertEqual(files.walker1.collect { $0.isDirectory }.count, 5)
            XCTAssertEqual(files.walker1.collect { !$0.isDirectory }.count, 11)
            XCTAssertEqual(files.walker1.collect().count, 16)
            //
            XCTAssertEqual(6, files.walker1.ignoresDir(ignoresdir1).collect { $0.isFile }.count)
            XCTAssertEqual(4, files.walker1.ignoresDir(ignoresdir1).collect { !$0.isFile }.count)
            XCTAssertEqual(4, files.walker1.ignoresDir(ignoresdir1).collect { $0.isDirectory }.count)
            XCTAssertEqual(6, files.walker1.ignoresDir(ignoresdir1).collect { !$0.isDirectory }.count)
            XCTAssertEqual(10, files.walker1.ignoresDir(ignoresdir1).collect().count)
            //
            XCTAssertEqual(files.walker1.bottomUp().collect { $0.isFile }.count, 11)
            XCTAssertEqual(files.walker1.bottomUp().collect { !$0.isFile }.count, 5)
            XCTAssertEqual(files.walker1.bottomUp().collect { $0.isDirectory }.count, 5)
            XCTAssertEqual(files.walker1.bottomUp().collect { !$0.isDirectory }.count, 11)
            XCTAssertEqual(files.walker1.bottomUp().collect().count, 16)
            //
            XCTAssertEqual(6, files.walker1.bottomUp().ignoresDir(ignoresdir1).collect { $0.isFile }.count)
            XCTAssertEqual(4, files.walker1.bottomUp().ignoresDir(ignoresdir1).collect { !$0.isFile }.count)
            XCTAssertEqual(4, files.walker1.bottomUp().ignoresDir(ignoresdir1).collect { $0.isDirectory }.count)
            XCTAssertEqual(6, files.walker1.bottomUp().ignoresDir(ignoresdir1).collect { !$0.isDirectory }.count)
            XCTAssertEqual(10, files.walker1.bottomUp().ignoresDir(ignoresdir1).collect().count)
        }
    }
    
    
    func testCopy01() throws {
        let tmpdir = tmpDir()
        let to = tmpdir.file("t")
        let file1 = tmpdir.file("file1.txt")
        let from = testResDir.file("files/dir2/file1.txt")
        try subtest {
            XCTAssertFalse(to.exists)
            try FileUtil.copy(tofile: to, fromfile: from)
            XCTAssertTrue(to.exists)
            XCTAssertTrue(With.error { try FileUtil.copy(tofile: File.ROOT.file("notexists"), fromfile: from) } is IOException)
            try With.inputStream(from) { input1 in
                let fromtext = try input1.asString()
                try With.inputStream(to) { input2 in
                    let data = try input2.asData()
                    XCTAssertEqual(fromtext, String(data: data, encoding: .utf8))
                }
            }
        }
        try subtest {
            _ = file1.delete()
            XCTAssertFalse(file1.exists)
            try FileUtil.copy(todir: tmpdir, fromfile: from, false)
            XCTAssertTrue(file1.exists)

        }
        try subtest {
            _ = file1.delete()
            XCTAssertFalse(file1.exists)
            try FileUtil.copy(todir: tmpdir, fromfile: from, true)
            let to = tmpdir.file(from.name)
            XCTAssertTrue(to.exists)
            XCTAssertEqual(to.lastModified, from.lastModified)
        }
        try subtest {
            let s = from.parent!.walker.collect { f, _ in f.isFile }
            let tmp = self.tmpDir()
            try s.forEach {
                try FileUtil.copy(todir: tmp, fromfile: $0.0)
            }
            let out = tmp.walker.collect{ f, _ in f.isFile }.map { f, _ in f }
            XCTAssertEqual(s.count, out.count)
            out.forEach { _ = $0.delete() }
            XCTAssertEqual(0, tmp.walker.collect{ f, _ in f.isFile }.count)
        }
        try subtest {
            let filesdir = self.testResDir.file("files")
            let tmpdir = self.tmpDir()
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            tmpdir.file("dir1/dir1a").deleteTree()
            _ = tmpdir.file("dir1").setWritable(false, false, false)
            XCTAssertTrue(With.error { _ = try FileUtil.copy(todir: tmpdir, fromdir: filesdir) } is IOException)

        }
    }


    func testCopy02() throws {
        let m = 1000 * 1000
        try subtest {
            for size in
                //                (self.suite.lengthy) ?
                //                [0, 1, 2, 10, 16, 256, 1000, 1024, m, 10 * m, 100 * m] :
                [0, 1, 2, 10, 16, 256, 1000, 1024, m, 10 * m] {
                    let file1 = self.tmpFile()
                    let file2 = self.tmpFile()
                    defer {
                        _ = file1.delete()
                        _ = file2.delete()
                    }
                    var data = [Byte](repeating: 0, count: size)
                    RandUtil.get(to: &data)
                    try file1.writeBytes(data)
                    try FileUtil.copy(tofile: file2, fromfile: file1)
                    XCTAssertFalse(try FileUtil.diff(file1, file2), "\(size)")
            }
        }
    }


    func testMove01() throws {
        let top = tmpDir()
        let dir1 = tmpFile(dir: top).mkdirs()!
        let dir2 = tmpFile(dir: top).mkdirs()!
        let file1 = tmpFile(dir: dir1)
        let file2 = tmpFile(dir: dir1)
        let file3 = tmpFile(dir: dir2)
        try file1.writeText("testing")
        try FileUtil.move(tofile: file2, fromfile: file1)
        XCTAssertFalse(file1.exists)
        XCTAssertTrue(file2.exists)
        XCTAssertTrue(dir1.setWritable(false, false, false))
        defer { XCTAssertTrue(dir1.setWritable(true, false, false)) }
        With.error { try FileUtil.move(tofile: file3, fromfile: file2) }
        XCTAssertFalse(file3.exists)
        XCTAssertTrue(file2.exists)
    }
    
    
    func testDiffDir01() throws {
        let dir1 = testResDir.file("files/dir1")
        let dir2 = testResDir.file("files/dir2")
        let stat = try FileUtil.diffDir(dir1, dir2)
        log.d("# stat:", stat.toString("dir1", "dir2", printsames: true))
        XCTAssertEqual(3, stat.aonly.count)
        XCTAssertEqual(3, stat.bonly.count)
        XCTAssertEqual(1, stat.sames.count)
        XCTAssertEqual(1, stat.diffs.count)
        let tmpdir = tmpDir()
        let file1 = tmpdir.file("file1")
        let file2 = tmpdir.file("file2")
        try file1.writeText("file1111")
        try file2.writeText("file211")
        XCTAssertTrue(try FileUtil.diff(file1, file2))
    }


    func testSetPermission01() throws {
        try subtest {
            let top = self.tmpDir()
            let dir = self.tmpFile(suffix: "", dir: top).mkdirs()!
            let file = self.tmpFile(suffix: ".xxx", dir: dir)
            try file.writeText("testing")
            _ = top.setPerm(0b111_100_000)
            _ = dir.setPerm(0b111_100_000)
            self.log.d(String(format: "# Before: top: 0x%08x, dir: 0x%08x, file: 0x%08x", top.permissions!, dir.permissions!, file.permissions!))
            XCTAssertTrue(FileUtil.setPrivateDirPerm(dir))
            XCTAssertTrue(FileUtil.setPrivateFilePerm(file))
            self.log.d(String(format: "# After: top: 0x%08x, dir: 0x%08x, file: 0x%08x", top.permissions!, dir.permissions!, file.permissions!))
            XCTAssertEqual(0b111_000_000, dir.permissions!)
            XCTAssertEqual(0b110_000_000, file.permissions)
        }
        try subtest {
            let filesdir = self.testResDir.file("files")
            let tmpdir = self.tmpDir()
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            let s = tmpdir.file("dir1").walker.collect()
            s.forEach { _ = $0.0.setPublicPerm() }
            s.forEach { (file, rpath) in
                XCTAssertEqual((file.isDirectory ? 0b111_101_101 : 0b110_100_100), file.permissions!)
            }
            s.forEach { _ = $0.0.setPrivatePerm() }
            s.forEach { (file, rpath) in
                XCTAssertEqual((file.isDirectory ? 0b111_000_000 : 0b110_000_000), file.permissions!)
            }
        }
    }
}
