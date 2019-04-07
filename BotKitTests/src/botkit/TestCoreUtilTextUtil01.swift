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

class TestCoreUtilTextUtil01: TestBase {

    override var DEBUGGING: Bool{
        return false
    }
    
    func testBasic01() {
        XCTAssertEqual("nil", TextUtil.classname(nil))
    }
    
    func testBasepath01() {
        func check(_ path: String, _ dir: String?, _ name: String, _ base: String, _ suffix: String) {
            let basepath = Basepath(path)
            XCTAssertEqual(dir, basepath.dir, path)
            XCTAssertEqual(name, basepath.name, path)
            XCTAssertEqual(base, basepath.base, path)
            XCTAssertEqual(suffix, basepath.suffix, path)
            XCTAssertEqual(suffix.lowercased(), basepath.lcSuffix, path)
            XCTAssertEqual((basepath.ext == nil ? "" : ".\(basepath.ext!)"), suffix, path)
            XCTAssertEqual((basepath.lcExt == nil ? "" : ".\(basepath.lcExt!)"), suffix.lowercased(), path)
        }
        check("/", nil, "", "", "")
        check("", nil, "", "", "")
        check(".", nil, ".", ".", "")
        check("..", nil, "..", "..", "")
        check(".abc", nil, ".abc", ".abc", "")
        check("abc", nil, "abc", "abc", "")
        check("abc.", nil, "abc.", "abc", ".")
        check("abc/", nil, "abc", "abc", "")
        check("a/b/c.d/", "a/b", "c.d", "c", ".d")
        check("abc.123", nil, "abc.123", "abc", ".123")
        check("abc.123.txt", nil, "abc.123.txt", "abc.123", ".txt")
        check("/abc.123", "", "abc.123", "abc", ".123")
        check("/a/abc.123", "/a", "abc.123", "abc", ".123")
        check("/a/abc.123", "/a", "abc.123", "abc", ".123")
        check("/a/b/c/abc.123", "/a/b/c", "abc.123", "abc", ".123")
        check("a/abc.123", "a", "abc.123", "abc", ".123")
        check("a/abc.123/abc.txt", "a/abc.123", "abc.txt", "abc", ".txt")
    }
    
    func testBasepath01a() {
        func check(_ path: String, _ dir: String?, _ name: String, _ base: String, _ suffix: String) {
            let file = File(path)
            let apath: String = {
                let ret = FileUtil.getAbsolutePath(path: path)
                return ret == "/" ? ret : TextUtil.removeTrailing(File.SEP, from: ret)
            }()
            XCTAssertEqual(file.path, apath, path)
            XCTAssertEqual(name, file.name, path)
            XCTAssertEqual(suffix, file.suffix, path)
            XCTAssertEqual(suffix.lowercased(), file.lcSuffix, path)
        }
        // workdir is /Private/tmp
        let workdir = File(FileManager.default.currentDirectoryPath)
        log.d("# workdir= \(workdir)")
        check("/", nil, "", "", "")
        check("", nil, workdir.name, workdir.name, "")
        check(".", nil, workdir.name, workdir.name, "")
        check("..", nil, workdir.parent!.name, workdir.parent!.name, "")
        check(".abc", nil, ".abc", ".abc", "")
        check("abc", nil, "abc", "abc", "")
        check("abc.", nil, "abc.", "abc", ".")
        check("abc/", nil, "abc", "abc", "")
        check("a/b/c.d/", "a/b", "c.d", "c", ".d")
        check("abc.123", nil, "abc.123", "abc", ".123")
        check("abc.123.txt", nil, "abc.123.txt", "abc.123", ".txt")
        check("/abc.123", "", "abc.123", "abc", ".123")
        check("/a/abc.123", "/a", "abc.123", "abc", ".123")
        check("/a/abc.123", "/a", "abc.123", "abc", ".123")
        check("/a/b/c/abc.123", "/a/b/c", "abc.123", "abc", ".123")
        check("a/abc.123", "a", "abc.123", "abc", ".123")
        check("a/abc.123/abc.txt", "a/abc.123", "abc.txt", "abc", ".txt")
    }
    
    func testBasepath02() throws {
        func check(_ path: String, _ dir: String?, _ name: String, _ base: String, _ suffix: String) {
            let basepath = Basepath(path)
            XCTAssertEqual(dir, basepath.dir)
            XCTAssertEqual(name, basepath.name)
            XCTAssertEqual(base, basepath.base)
            XCTAssertEqual(suffix, basepath.suffix)
        }
        check(Basepath("abc.123").sibling("123.abc"), nil, "123.abc", "123", ".abc")
        check(Basepath("abc.123").sibling("123abc"), nil, "123abc", "123abc", "")
        check(Basepath("abc123").sibling("123.abc"), nil, "123.abc", "123", ".abc")
        check(Basepath("a/abc/abc.123").sibling("123"), "a/abc", "123", "123", "")
        check(Basepath("abc.123").changeBase("cde"), nil, "cde.123", "cde", ".123")
        check(Basepath("a/abc/abc.123").changeBase("cde"), "a/abc", "cde.123", "cde", ".123")
        check(Basepath("abc.123").changeSuffix(".cde"), nil, "abc.cde", "abc", ".cde")
        check(Basepath("a/abc/abc.123").changeSuffix("cde"), "a/abc", "abccde", "abccde", "")
        XCTAssertEqual("a/abc", Basepath("a/123.abc").sibling("abc"))
        XCTAssertEqual(File("a/abc"), try File("a/123.abc").sibling("abc"))
        XCTAssertEqual("a/abc.abc", Basepath("a/123.abc").changeBase("abc"))
        XCTAssertEqual(File("a/abc.abc"), try File("a/123.abc").changeBase("abc"))
        XCTAssertEqual("a/123cde", Basepath("a/123.abc").changeSuffix("cde"))
        XCTAssertEqual(File("a/123cde"), try File("a/123.abc").changeSuffix("cde"))
    }
    
    func testBasepath03() {
        let set = Set(arrayLiteral: Basepath("/a/b"), Basepath("/a/b/"), Basepath("/a/b/c"), Basepath("/b"))
        log.d("# \(set)")
        XCTAssertEqual(3, set.count)
    }
    
    func testCleanPath01() {
        XCTAssertEqual("", TextUtil.cleanupFilepath(""))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("/"))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("//"))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("/////"))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("/."))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("/./"))
        XCTAssertEqual("", TextUtil.cleanupFilepath("."))
        XCTAssertEqual("", TextUtil.cleanupFilepath("./"))
        XCTAssertEqual("", TextUtil.cleanupFilepath("./."))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("/././/"))
        XCTAssertEqual("/", TextUtil.cleanupFilepath("//a/../"))
        XCTAssertEqual("/a/b/c", TextUtil.cleanupFilepath("/a/b/./c"))
        XCTAssertEqual("/a/b/c/", TextUtil.cleanupFilepath("/a/b/./c/"))
        XCTAssertEqual("/a/c/", TextUtil.cleanupFilepath("/a/b/../c/"))
        XCTAssertEqual("/a/c", TextUtil.cleanupFilepath("/a/b/../c"))
        XCTAssertEqual("/a/", TextUtil.cleanupFilepath("/a/b/..//.//c/.."))
        XCTAssertEqual("/a/", TextUtil.cleanupFilepath("/a/b/..//.//c/../"))
        XCTAssertEqual("..", TextUtil.cleanupFilepath(".."))
        XCTAssertEqual("../a", TextUtil.cleanupFilepath("../a"))
        XCTAssertEqual("../a/", TextUtil.cleanupFilepath("../a/."))
        XCTAssertEqual("../a/", TextUtil.cleanupFilepath("../a/./"))
        XCTAssertEqual("../../", TextUtil.cleanupFilepath("../../."))
        XCTAssertEqual("../..", TextUtil.cleanupFilepath("../a/b/../../.."))
        XCTAssertEqual("../../", TextUtil.cleanupFilepath("../a/b/../../..///"))
        XCTAssertEqual("..", TextUtil.cleanupFilepath("a/b/../../.."))
        XCTAssertEqual("../c", TextUtil.cleanupFilepath("a/b/../../../c"))
        XCTAssertEqual("/a/b", TextUtil.cleanupFilepath("////a////b"))
        XCTAssertEqual("/a/b/", TextUtil.cleanupFilepath("////a////b///"))
        XCTAssertEqual("a/b/c/d", TextUtil.cleanupFilepath("a/b/c/d"))
        XCTAssertEqual("/aaa/bb/cc/dd/", TextUtil.cleanupFilepath("/aaa/bb/cc/dd/"))
    }
    
    func testTrim01() {
        subtest {
            XCTAssertEqual("", TextUtil.removeLeading("/", from: ""))
            XCTAssertEqual("", TextUtil.removeLeading("/", from: "/"))
            XCTAssertEqual("", TextUtil.removeLeading("/", from: "///"))
            XCTAssertEqual("a///", TextUtil.removeLeading("/", from: "a///"))
            XCTAssertEqual("a/b/c", TextUtil.removeLeading("/", from: "/a/b/c"))
            XCTAssertEqual("a/b/c", TextUtil.removeLeading("/", from: "///a/b/c"))
        }
        subtest {
            XCTAssertEqual("", TextUtil.removeTrailing("/", from: ""))
            XCTAssertEqual("", TextUtil.removeTrailing("/", from: "/"))
            XCTAssertEqual("", TextUtil.removeTrailing("/", from: "///"))
            XCTAssertEqual("a", TextUtil.removeTrailing("/", from: "a///"))
            XCTAssertEqual("/a/b/c", TextUtil.removeTrailing("/", from: "/a/b/c"))
            XCTAssertEqual("///a/b/c", TextUtil.removeTrailing("/", from: "///a/b/c//"))
        }
        subtest {
            XCTAssertEqual("/", TextUtil.ensureLeading("/", for: ""))
            XCTAssertEqual("/", TextUtil.ensureLeading("/", for: "/"))
            XCTAssertEqual("///", TextUtil.ensureLeading("/", for: "///"))
            XCTAssertEqual("/a", TextUtil.ensureLeading("/", for: "a"))
            XCTAssertEqual("/a/", TextUtil.ensureLeading("/", for: "a/"))
            XCTAssertEqual("/a", TextUtil.ensureLeading("/", for: "/a"))
            XCTAssertEqual("/a/", TextUtil.ensureLeading("/", for: "/a/"))
            XCTAssertEqual("/", TextUtil.ensureTrailing("/", for: ""))
            XCTAssertEqual("/", TextUtil.ensureTrailing("/", for: "/"))
            XCTAssertEqual("///", TextUtil.ensureTrailing("/", for: "///"))
            XCTAssertEqual("a/", TextUtil.ensureTrailing("/", for: "a"))
            XCTAssertEqual("a/", TextUtil.ensureTrailing("/", for: "a/"))
            XCTAssertEqual("/a/", TextUtil.ensureTrailing("/", for: "/a"))
            XCTAssertEqual("/a/", TextUtil.ensureTrailing("/", for: "/a/"))
        }
    }
    
    func testSizeUnit01() {
        subtest {
            func check(_ expected: (Int, String), _ actual: (Int64, String)) {
                XCTAssertEqual(Int64(expected.0), actual.0)
                XCTAssertEqual(expected.1, actual.1)
            }
            check((0, ""), TextUtil.sizeUnit4(0))
            check((1000, ""), TextUtil.sizeUnit4(1000))
            check((9999, ""), TextUtil.sizeUnit4(9999))
            check((10, "k"), TextUtil.sizeUnit4(10000))
            check((123, "k"), TextUtil.sizeUnit4(123000))
            check((9999, "k"), TextUtil.sizeUnit4(9999400))
            check((10, "m"), TextUtil.sizeUnit4(10000000))
        }
        subtest {
            XCTAssertEqual("0 ", TextUtil.sizeUnit4String(0))
            XCTAssertEqual("1000 ", TextUtil.sizeUnit4String(1000))
            XCTAssertEqual("9999 ", TextUtil.sizeUnit4String(9999))
            XCTAssertEqual("10 k", TextUtil.sizeUnit4String(10000))
            XCTAssertEqual("123 k", TextUtil.sizeUnit4String(123000))
            XCTAssertEqual("9999 k", TextUtil.sizeUnit4String(9999400))
            XCTAssertEqual("10 m", TextUtil.sizeUnit4String(10000000))
        }
        subtest {
            XCTAssertEqual("19 k", TextUtil.sizeUnit4String(self.testResDir.file("html/manual.html")))
        }
    }
    
    func testSplit201() {
        subtest {
            func check(_ expected: (String, String?), _ actual: (String, String?)) {
                XCTAssertEqual(expected.0, actual.0)
                XCTAssertEqual(expected.1, actual.1)
            }
            check(("", nil), TextUtil.split2("", sep: "/"))
            check(("", ""), TextUtil.split2("/", sep: "/"))
            check(("", "/"), TextUtil.split2("//", sep: "/"))
            check(("", "//"), TextUtil.split2("///", sep: "/"))
            check(("a", nil), TextUtil.split2("a", sep: "/"))
            check(("a", ""), TextUtil.split2("a/", sep: "/"))
            check(("", "a"), TextUtil.split2("/a", sep: "/"))
            check(("", "a/b"), TextUtil.split2("/a/b", sep: "/"))
            check(("a", "b"), TextUtil.split2("a/b", sep: "/"))
            check(("a", "b/c"), TextUtil.split2("a/b/c", sep: "/"))
        }
    }
    
    func testHex01() throws {
        try subtest {
            XCTAssertEqual("00010cabef", Hex.encode([0, 1, 12, 0xab, 0xef]))
            XCTAssertEqual("00010cabef", Hex.encode([0, 1, 12, 0xAB, 0xEF]))
            XCTAssertEqual("00010CABEF", Hex.encode([0, 1, 12, 0xab, 0xEF], true))
            XCTAssertEqual([0, 1, 12, 0xab, 0xEF], try Hex.decode("00010cabef"))
            XCTAssertEqual([0, 1, 12, 0xab, 0xef], try Hex.decode("00010CABEF"))
            XCTAssertEqual([0, 1, 12, 0xab, 0xef], try Hex.decode("00010CabEF"))
            XCTAssertTrue(With.error { _ = try Hex.decode("012") } is Exception)
            XCTAssertTrue(With.error { _ = try Hex.decode("01ag12") } is Exception)
        }
    }
}
