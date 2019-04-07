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

class TestCoreUtilFileUtil02: TestBase {
    
    override var DEBUGGING: Bool {
        return false
    }
    
    func testChangeSuffix01() throws {
        XCTAssertEqual("b-test.css", try File("b.html").changeSuffix("-test.css").name)
        XCTAssertTrue(With.error { _ = try File.ROOT.sibling("impossible")} is IllegalStateException)
    }
    
    
    func testFile01() throws {
        subtest {
            let filesdir = self.testResDir.file("files")
            let basepath = filesdir.basepath
            XCTAssertEqual("files", basepath.name)
            XCTAssertEqual(self.testResDir.path, filesdir.dir)
            XCTAssertEqual(nil, filesdir.ext)
            XCTAssertEqual(0, File("/notexists").listOrEmpty().count)
        }
        try subtest {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            XCTAssertEqual(nil, file.permissions)
            XCTAssertEqual(0, file.lastModified)
            XCTAssertEqual(0, file.length)
            XCTAssertEqual(0, dir.listOrEmpty().count)
            XCTAssertEqual(0, dir.listFiles().count)
            XCTAssertTrue(dir.setPrivatePerm())
            XCTAssertFalse(file.setPrivatePerm())
            XCTAssertEqual(0b111000000, dir.permissions)
            XCTAssertEqual(nil, file.fileType)
            XCTAssertEqual(false, file.canRead)
            XCTAssertEqual(false, file.canWrite)
            XCTAssertEqual(true, file.canDelete)
            try file.writeText("testing")
            XCTAssertTrue(file.setPrivatePerm())
            XCTAssertTrue(abs(file.lastModified - DateUtil.ms) < 1000)
            XCTAssertEqual(7, file.length)
            XCTAssertEqual(0b110000000, file.permissions)
            XCTAssertEqual(true, file.canRead)
            XCTAssertEqual(true, file.canWrite)
            XCTAssertEqual(true, file.canDelete)
            XCTAssertEqual(FileAttributeType.typeRegular, file.fileType)
            XCTAssertEqual(FileAttributeType.typeDirectory, dir.fileType)
            XCTAssertEqual(1, dir.listOrEmpty().count)
            XCTAssertEqual(1, dir.listFiles().count)
        }
        try subtest {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            XCTAssertFalse(file.rename(to: try file.sibling("test123.txt")))
            try file.writeText("testing")
            XCTAssertTrue(file.rename(to: try file.sibling("test123.txt")))
        }
        try subtest("setReadable") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            XCTAssertFalse(file.setReadable(false, true, true))
            try file.writeText("testing")
            XCTAssertTrue(file.setReadable(false, true, true))
            XCTAssertFalse(file.canRead)
            XCTAssertTrue(file.setReadable(false, false, false))
            XCTAssertEqual(0, file.permissions! & 0b100100100)
            XCTAssertTrue(file.setReadable(true, false, false))
            XCTAssertTrue(file.canRead)
            let perm1 = file.permissions!
            XCTAssertEqual(0b100000000, perm1 & 0b100000000)
            XCTAssertEqual(0, perm1 & 0b000100100)
            XCTAssertTrue(file.setReadable(true, true, true))
            XCTAssertEqual(0b100100100, file.permissions! & 0b100100100)
        }
        try subtest("setWritable") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            XCTAssertFalse(file.setWritable(false, true, true))
            try file.writeText("testing")
            XCTAssertTrue(file.setWritable(false, true, true))
            XCTAssertFalse(file.canWrite)
            XCTAssertTrue(file.setWritable(false, false, false))
            XCTAssertEqual(0, file.permissions! & 0b010010010)
            XCTAssertTrue(file.setWritable(true, false, false))
            XCTAssertTrue(file.canWrite)
            let perm1 = file.permissions!
            XCTAssertEqual(0b010000000, perm1 & 0b010000000)
            XCTAssertEqual(0, perm1 & 0b000010010)
            XCTAssertTrue(file.setWritable(true, true, true))
            XCTAssertEqual(0b010010010, file.permissions! & 0b010010010)
        }
        try subtest("ExcludeFromBackup") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            if #available(OSX 10, *) {
                XCTAssertEqual(false, file.isExcludedFromBackup()!)
                XCTAssertFalse(file.setExcludeFromBackup(true))
                try file.writeText("testing")
                XCTAssertEqual(false, file.isExcludedFromBackup()!)
                XCTAssertTrue(file.setExcludeFromBackup(true))
                XCTAssertEqual(false, file.isExcludedFromBackup()!)
                XCTAssertTrue(file.setExcludeFromBackup(false))
                XCTAssertEqual(false, file.isExcludedFromBackup()!)
                XCTAssertTrue(FileUtil.excludeFromBackup([dir, file]))
                XCTAssertEqual(false, dir.isExcludedFromBackup()!)
                XCTAssertEqual(false, file.isExcludedFromBackup()!)
            }
        }
    }
    
    func testFileReadWrite01() throws {
        let text = "testing 123\nline2\nline3"
        let lines = text.lines
        try subtest("Text") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            try file.writeText(text)
            XCTAssertEqual(text, try file.readText())
        }
        try subtest("Lines") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            try file.writeLines(lines)
            XCTAssertEqual(lines, try file.readLines().map { String($0) })
        }
        try subtest("Data") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            let data = text.data
            try file.writeData(data)
            XCTAssertEqual(data, try file.readData())
        }
        try subtest("Bytes") {
            let dir = self.tmpDir()
            let file = self.tmpFile(dir: dir)
            let bytes = text.bytes
            try file.writeBytes(bytes)
            XCTAssertEqual(bytes, try file.readBytes())
        }
        subtest("Fail") {
            let file = File("/notexists")
            XCTAssertTrue(With.error { try file.writeText(text) } is IOException)
            XCTAssertTrue(With.error { try _ = file.readText() } is IOException)
            XCTAssertTrue(With.error { try file.writeLines(lines) } is IOException)
            XCTAssertTrue(With.error { try _ = file.readLines() } is IOException)
            XCTAssertTrue(With.error { try file.writeData(text.data) } is IOException)
            XCTAssertTrue(With.error { try _ = file.readData() } is IOException)
            XCTAssertTrue(With.error { try file.writeBytes(text.bytes) } is IOException)
            XCTAssertTrue(With.error { try _ = file.readBytes() } is IOException)
        }
        try subtest("Encoding") {
            let file = File("/notexists")
            let tmpfile = self.tmpFile()
            let unicode = "\u{1234}\u{f100}"
            XCTAssertTrue(With.error { try file.writeText(unicode) } is IOException)
            XCTAssertTrue(With.error { try file.writeText(unicode, .ascii) } is CharacterEncodingException)
            try tmpfile.writeText(unicode, .utf32)
            XCTAssertEqual(unicode, try tmpfile.readText(.utf32))
            XCTAssertTrue(With.error { try _ = tmpfile.readText(.utf8) } is IOException)
        }
    }
    
    func testFileCompare01() throws {
        let filesdir = testResDir.file("files")
        subtest {
            let sorted = filesdir.walker1.collect().toSet().sorted()
            self.log.d(sorted.map { "\($0.description)" })
            XCTAssertEqual("dir1", sorted.first!.name)
            XCTAssertEqual("dir1a", sorted[1].name)
            XCTAssertTrue(sorted[1].description.hasSuffix("files/dir1/dir1a"))
            XCTAssertEqual("empty.txt", sorted.last!.name)
        }
    }
    
    func testFileDelete01() throws {
        let filesdir = testResDir.file("files")
        try subtest("deleteTree") {
            let tmpdir = self.tmpDir()
            let dir1 = tmpdir.file("dir1")
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            XCTAssertTrue(dir1.deleteTree())
            XCTAssertFalse(dir1.exists)
            XCTAssertFalse(dir1.file("dir1a").exists)
            XCTAssertFalse(dir1.file("dir1a/file1a.txt").exists)
            XCTAssertFalse(dir1.file("file1.txt").exists)
            XCTAssertTrue(tmpdir.file("dir2").exists)
            XCTAssertTrue(tmpdir.file("empty.txt").exists)
        }
        try subtest("deleteSubtrees") {
            let tmpdir = self.tmpDir()
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            XCTAssertTrue(tmpdir.file("notexists").deleteSubtrees())
            XCTAssertFalse(tmpdir.file("dir1/file1.txt").deleteSubtrees())
            XCTAssertTrue(tmpdir.file("dir1").setWritable(false, false, false))
            XCTAssertFalse(tmpdir.file("dir1").deleteSubtrees())
            XCTAssertEqual(15, tmpdir.walker.collect().count)
            XCTAssertFalse(tmpdir.file("dir1/dir1a/file1a.txt").exists)
            XCTAssertTrue(tmpdir.file("dir2").deleteSubtrees())
            XCTAssertEqual(9, tmpdir.walker.collect().count)
            XCTAssertTrue(tmpdir.file("dir2").exists)
            XCTAssertFalse(tmpdir.file("dir2/dir2a").exists)
        }
            try subtest("deleteEmptySubtrees") {
            let tmpdir = self.tmpDir()
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            tmpdir.deleteEmptySubtrees()
            XCTAssertEqual(15, tmpdir.walker.collect().count)
            tmpdir.file("dir1").walker1.files { XCTAssertTrue($0.delete()) }
            tmpdir.file("dir1").deleteEmptyTree()
            XCTAssertEqual(8, tmpdir.walker.collect().count)
        }
    }
    
    func testDocumentUrl01() {
        let path = FileUtil.documentUrl().path
        log.d("# document path: \(path)")
        XCTAssertTrue(path.hasSuffix("/Documents"))
        XCTAssertTrue(FileUtil.documentUrl("a/b/test123.txt").path.hasSuffix("/Documents/a/b/test123.txt"))
    }
    
    func testReadline01() throws {
        let tmpfile = tmpFile()
        try tmpfile.writeText("line1\r\nline2\rline3\r\n\r\n\n")
        try With.bufferedInputStream(tmpfile) { buf in
            XCTAssertEqual("line1", try buf.readline())
            XCTAssertEqual("line2\rline3", try buf.readline())
            XCTAssertEqual("", try buf.readline())
            XCTAssertEqual("", try buf.readline())
            XCTAssertEqual(nil, try buf.readline())
        }
    }
    
    func testTouch01() throws {
        let filesdir = testResDir.file("files")
        try subtest {
            let tmpdir = self.tmpDir()
            XCTAssertEqual(16, try FileUtil.copy(todir: tmpdir, fromdir: filesdir))
            let ms = DateUtil.date(2001, 08, 28).ms
            XCTAssertTrue(FileUtil.touch(dir: tmpdir, ms: ms))
            var count = 0
            tmpdir.walker1.walk {
                XCTAssertEqual(ms, $0.lastModified)
                count += 1
            }
            XCTAssertEqual(16, count)
        }
    }
}
