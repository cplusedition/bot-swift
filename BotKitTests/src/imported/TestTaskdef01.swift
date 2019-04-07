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

class TestTaskdef01 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testCopy01() throws {
        try log.enterX(#function) {
            let filesdir = testResDir.file("files")
            subtest("constructors") {
                XCTAssertEqual(11, self.task(Copy(self.tmpDir(), Fileset(filesdir))).copied.count)
                XCTAssertEqual(11, self.task(Copy(self.tmpDir(), filesdir)).copied.count)
                XCTAssertEqual(5, self.task(Copy(self.tmpDir(), filesdir, "dir1/**/*.txt")).copied.count)
                XCTAssertEqual(4, self.task(Copy(self.tmpDir(), filesdir, "dir1/**/*.txt", "**/dir1a/**")).copied.count)
                XCTAssertEqual(10, self.task(Copy(self.tmpDir(), filesdir, nil, "**/dir1a/**")).copied.count)
            }
            subtest("add") {
                XCTAssertEqual(11, self.task(Copy(self.tmpDir()).add(Fileset(filesdir))).copied.count)
                XCTAssertEqual(11, self.task(Copy(self.tmpDir()).add(filesdir)).copied.count)
                XCTAssertEqual(5, self.task(Copy(self.tmpDir()).add(filesdir, "dir1/**/*.txt")).copied.count)
                XCTAssertEqual(4, self.task(Copy(self.tmpDir()).add(filesdir, "dir1/**/*.txt", "**/dir1a/**")).copied.count)
                XCTAssertEqual(10, self.task(Copy(self.tmpDir()).add(filesdir, nil, "**/dir1a/**")).copied.count)
            }
            subtest("preserveTimestamp=true") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(Copy(tmpdir).add(Fileset(filesdir))).copied {
                    XCTAssertEqual(filesdir.file(rpath).lastModified, tmpdir.file(rpath).lastModified)
                }
            }
            subtest("preserveTimestamp=false") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(Copy(tmpdir).add(Fileset(filesdir)).preserveTimestamp(false)).copied {
                    XCTAssertFalse(filesdir.file(rpath).lastModified == tmpdir.file(rpath).lastModified)
                }
            }
            subtest("Copy fail") {
                let tmpdir = self.tmpDir()
                self.task(Copy(tmpdir, filesdir))
                let dir1 = tmpdir.file("dir1")
                dir1.deleteSubtrees()
                _ = dir1.setWritable(false, false, false)
                defer { _ = dir1.setWritable(true, true, false) }
                let result = self.task(Copy(tmpdir, filesdir))
                self.log.d(result.toString())
                /// Note that in macOS, opening a readonly file for write do not fail, it only fail when trying to write to it.
                /// Since dir1/dir1only.txt and dir2a.txt are empty, no write happen and no exception.
                XCTAssertEqual(3, result.copyFailed.count)
                XCTAssertEqual(3, self.log.resetErrorCount())
            }
        }
    }
    
    func testCopyDiff01() throws {
        try log.enterX(#function) {
            let filesdir = testResDir.file("files")
            subtest("constructors") {
                XCTAssertEqual(11, self.task(CopyDiff(self.tmpDir(), Fileset(filesdir))).copied.count)
                XCTAssertEqual(11, self.task(CopyDiff(self.tmpDir(), filesdir)).copied.count)
                XCTAssertEqual(5, self.task(CopyDiff(self.tmpDir(), filesdir, "dir1/**/*.txt")).copied.count)
                XCTAssertEqual(4, self.task(CopyDiff(self.tmpDir(), filesdir, "dir1/**/*.txt", "**/dir1a/**")).copied.count)
                XCTAssertEqual(10, self.task(CopyDiff(self.tmpDir(), filesdir, nil, "**/dir1a/**")).copied.count)
            }
            subtest("add") {
                XCTAssertEqual(11, self.task(CopyDiff(self.tmpDir()).add(Fileset(filesdir))).copied.count)
                XCTAssertEqual(11, self.task(CopyDiff(self.tmpDir()).add(filesdir)).copied.count)
                XCTAssertEqual(5, self.task(CopyDiff(self.tmpDir()).add(filesdir, "dir1/**/*.txt")).copied.count)
                XCTAssertEqual(4, self.task(CopyDiff(self.tmpDir()).add(filesdir, "dir1/**/*.txt", "**/dir1a/**")).copied.count)
                XCTAssertEqual(10, self.task(CopyDiff(self.tmpDir()).add(filesdir, nil, "**/dir1a/**")).copied.count)
            }
            subtest("preserveTimestamp=true") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(CopyDiff(tmpdir).add(Fileset(filesdir))).copied {
                    XCTAssertEqual(filesdir.file(rpath).lastModified, tmpdir.file(rpath).lastModified)
                }
            }
            subtest("preserveTimestamp=false") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(CopyDiff(tmpdir).add(Fileset(filesdir)).preserveTimestamp(false)).copied {
                    XCTAssertFalse(filesdir.file(rpath).lastModified == tmpdir.file(rpath).lastModified)
                }
            }
        }
    }

    
    func testCopyDiffWithDebug01() throws {
        class Builder: DebugBuilder {
            func test(_ filesdir: File, _ tmpdir: File) throws {
                XCTAssertEqual(11, self.task(Copy(tmpdir).add(Fileset(filesdir))).copied.count)
                self.task(Remove(tmpdir, "dir1/**"))
                let rpath = "dir2/file1.txt"
                let fromfile = filesdir.file(rpath)
                let tofile = tmpdir.file(rpath)
                try tofile.writeText("xxxxxxx")
                XCTAssertTrue(try FileUtil.diff(fromfile, tofile))
                XCTAssertFalse(tmpdir.file("dir1/file1.txt").exists)
                let copydiff = task(CopyDiff(tmpdir, filesdir).preserveTimestamp(false))
                XCTAssertFalse(log.getLog().joined().contains("dir2/file1.txt"))
                log.d(copydiff.toString(notcopied: true))
                XCTAssertTrue(log.getLog().joinln().contains("dir2/file1.txt"))
                XCTAssertFalse(try FileUtil.diff(filesdir.file(rpath), tmpdir.file(rpath)))
                XCTAssertFalse(fromfile.lastModified == tofile.lastModified)
                XCTAssertTrue(tmpdir.file("dir1/file1.txt").exists)
                XCTAssertEqual(
                    filesdir.file("dir2/file2.txt").lastModified,
                    tmpdir.file("dir2/file2.txt").lastModified
                )
            }
        }
        try Builder().test(testResDir.file("files"), tmpDir())
    }

    
    func testCopyDiffWithDebug02() throws {
        class Builder: DebugBuilder {
            func test(_ filesdir: File, _ tmpdir: File) throws {
                self.task(Copy(tmpdir, filesdir))
                let dir1 = tmpdir.file("dir1")
                dir1.deleteSubtrees()
                _ = dir1.setWritable(false, false, false)
                defer { _ = dir1.setWritable(true, true, false) }
                self.task(Remove(tmpdir, "dir2/file1.txt"))
                let result = self.task(CopyDiff(tmpdir, filesdir))
                XCTAssertEqual(3, result.copied.count)
                XCTAssertEqual(5, result.notCopied.count)
                XCTAssertEqual(3, result.copyFailed.count)
                // Not printing not copied.
                XCTAssertFalse(result.toString().contains("dir2/file2.txt"))
                // Printing copied and failed.
                XCTAssertTrue(result.toString().contains("dir2/file1.txt"))
                XCTAssertTrue(result.toString().contains("dir1/file2.txt"))
                XCTAssertEqual(3, log.resetErrorCount())
            }
        }
        try Builder().test(testResDir.file("files"), tmpDir())
    }

    
    func testCopyDiff02() throws {
        try log.enterX(#function) {
            let tmpdir = self.tmpDir()
            let filesdir = testResDir.file("files")
            try subtest {
                let copy = self.task(Copy(tmpdir, Fileset(filesdir)))
                let total = copy.copied.count
                self.log.d(copy.copied)
                let removed = self.task(
                    Remove(Fileset(tmpdir).includes("empty*", "dir1/**").filesOnly())
                ).okCount
                XCTAssertEqual(6, removed)
                try tmpdir.file("dir2/new.txt").writeText("testing 3435273")
                let files = Fileset(tmpdir, ".*").files().count
                let dirs = Fileset(tmpdir, ".*").dirs().count
                self.log.d("# \(files) files, \(dirs) dirs")
                let copydiff = self.task(CopyDiff(tmpdir, Fileset(filesdir)))
                let actual = copydiff.copied.count
                XCTAssertEqual(removed, actual)
                XCTAssertEqual(total - removed, copydiff.notCopied.count)
            }
        }
    }

    
    func testCopyMirror01() throws {
        try log.enterX(#function) {
            let filesdir = testResDir.file("files")
            subtest("constructors") {
                XCTAssertEqual(11, self.task(CopyMirror(self.tmpDir(), Fileset(filesdir))).copied.count)
                XCTAssertEqual(11, self.task(CopyMirror(self.tmpDir(), filesdir)).copied.count)
                XCTAssertEqual(5, self.task(CopyMirror(self.tmpDir(), filesdir, "dir1/**/*.txt")).copied.count)
                XCTAssertEqual(4, self.task(CopyMirror(self.tmpDir(), filesdir, "dir1/**/*.txt", "**/dir1a/**")).copied.count)
                XCTAssertEqual(10, self.task(CopyMirror(self.tmpDir(), filesdir, nil, "**/dir1a/**")).copied.count)
            }
            subtest("preserveTimestamp=true") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(CopyMirror(tmpdir, Fileset(filesdir))).copied {
                    XCTAssertEqual(filesdir.file(rpath).lastModified, tmpdir.file(rpath).lastModified)
                }
            }
            subtest("preserveTimestamp=false") {
                let tmpdir = self.tmpDir()
                for rpath in self.task(CopyMirror(tmpdir, Fileset(filesdir)).preserveTimestamp(false)).copied {
                    XCTAssertFalse(filesdir.file(rpath).lastModified == tmpdir.file(rpath).lastModified)
                }
            }
        }
    }

    func testCopyMirror02() {
        let filesdir = testResDir.file("files")
        subtest("Preserve dir") {
            let tmpdir = self.tmpDir()
            self.task(Copy(tmpdir, Fileset(filesdir)))
            self.task(Remove(Fileset(tmpdir).includes("empty*", "dir1", "dir1/**")))
            let tmpdir2 = self.tmpDir()
            self.task(Copy(tmpdir2, Fileset(filesdir)))
            let task = self.task(CopyMirror(tmpdir2, Fileset(tmpdir)).preserve { file, _ in file.isDirectory })
            XCTAssertEqual(6, task.extraFilesRemoved.count)
            XCTAssertEqual(0, task.extraDirsRemoved.count)
        }
        subtest("Preserve file") {
            let tmpdir = self.tmpDir()
            self.task(Copy(tmpdir, Fileset(filesdir)))
            self.task(Remove(Fileset(tmpdir).includes("empty*", "dir1", "dir1/**")))
            let tmpdir2 = self.tmpDir()
            self.task(Copy(tmpdir2, Fileset(filesdir)))
            let task = self.task(CopyMirror(tmpdir2, Fileset(tmpdir)).preserve { file, _ in file.isFile })
            XCTAssertEqual(0, task.extraFilesRemoved.count)
            XCTAssertEqual(1, task.extraDirsRemoved.count) // empty.dir
        }
        subtest("Copy fail") {
            let tmpdir = self.tmpDir()
            self.task(Copy(tmpdir, filesdir))
            let dir1 = tmpdir.file("dir1")
            dir1.deleteSubtrees()
            _ = dir1.setWritable(false, false, false)
            defer { _ = dir1.setWritable(true, true, false) }
            let result = self.task(CopyMirror(tmpdir, filesdir))
            self.log.d(result.toString())
            XCTAssertEqual(3, result.copyFailed.count)
            XCTAssertEqual(3, self.log.resetErrorCount())
        }
        subtest("Remove extras fail") {
            let tmpdir1 = self.tmpDir()
            let tmpdir2 = self.tmpDir()
            self.task(Copy(tmpdir1, filesdir))
            self.task(Copy(tmpdir2, filesdir))
            let dir1 = tmpdir2.file("dir1")
            _ = dir1.setWritable(false, false, false)
            defer { _ = dir1.setWritable(true, true, false) }
            tmpdir1.file("dir1").deleteTree()
            let result = self.task(CopyMirror(tmpdir2, tmpdir1))
            self.log.d(result.toString())
            XCTAssertEqual(4, result.extraFilesRemoveFailed.count)
            XCTAssertEqual(2, result.extraDirsRemoveFailed.count)
            XCTAssertEqual(2, self.log.resetErrorCount())
        }
    }

    
    func testCopyMirrorLog01() throws {
        class Builder: DebugBuilder {
            func checkPrintStat(_ summary: Bool, _ detail: Bool, _ logs: Array<String>) {
                XCTAssertEqual(summary, logs.any { $0 == "# Not copied: 5" })
                XCTAssertEqual(summary, logs.any { $0 == "# Extra files: 6" })
                XCTAssertEqual(summary, logs.any { $0 == "# Extra dirs: 3" })
                XCTAssertEqual(summary, logs.any { $0 == "# Extra files removed: 6" })
                XCTAssertEqual(summary, logs.any { $0 == "# Extra dirs removed: 3" })
                XCTAssertEqual(summary, logs.any { $0 == "# Copied: 1" })
                XCTAssertEqual(detail, logs.any { $0 == "empty.txt" })
                XCTAssertEqual(detail, logs.any { $0 == "dir1/dir1a/file1a.txt" })
            }
            func test(_ filesdir: File, _ tmpdir: File, _ tmpdir2: File) throws {
                let copy = self.task(Copy(tmpdir, Fileset(filesdir)))
                XCTAssertEqual(11, copy.copied.count)
                let remove = self.task(Remove(Fileset(tmpdir).includes("empty*", "dir1/**")))
                XCTAssertEqual(6, remove.filesOK.count)
                XCTAssertEqual(3, remove.dirsOK.count)
                try tmpdir.file("dir2/a/b/new.txt").mkparentOrFail().writeText("testing 3435273")
                _ = tmpdir.file("dir3/a").mkdirs()
                task(Copy(tmpdir2, Fileset(filesdir)))
                let result = task(CopyMirror(tmpdir2, Fileset(tmpdir)))
                checkPrintStat(false, false, log.getLog().joined().lines)
                log.d(result.toString0()) // Default print nothing.
                checkPrintStat(true, false, log.getLog().joined().lines)
                log.d(result.toString())
                checkPrintStat(true, true, log.getLog().joined().lines)
                log.d(result.toString(notcopied: true))
                XCTAssertEqual(true, log.getLog().joined().lines.any { $0.hasPrefix("# Not copied:") })
                XCTAssertEqual(1, result.copied.count)
                XCTAssertEqual(copy.copied.count - remove.filesOK.count, result.notCopied.count)
                XCTAssertEqual(6, result.extraFiles.count)
                XCTAssertEqual(3, result.extraDirs.count)
                XCTAssertEqual(6, result.extraFilesRemoved.count)
                XCTAssertEqual(3, result.extraDirsRemoved.count)
                XCTAssertTrue(tmpdir2.file("dir3/a").exists)
            }
        }
        try Builder().test(testResDir.file("files"), tmpDir(), tmpDir())
    }

    
    func testRemove01() throws {
        try log.enterX(#function) {
            let filesdir = testResDir.file("files")
            subtest("constructor(Fileset)") {
                let tmpdir = self.tmpDir()
                let expected = self.task(Copy(tmpdir, Fileset(filesdir))).copied.count
                XCTAssertEqual(expected, Fileset(tmpdir).files().count)
                let actual = self.task(Remove(Fileset(tmpdir).filesOnly())).okCount
                XCTAssertEqual(expected, actual)
            }
            subtest("constructor(File, String, String)") {
                let tmpdir = self.tmpDir()
                self.task(Copy(tmpdir, Fileset(filesdir)))
                let expected = Fileset(tmpdir).collect().count
                let actual = self.task(Remove(tmpdir, "**", nil)).okCount
                XCTAssertEqual(expected, actual)
            }
            subtest("add(Fileset)") {
                let tmpdir = self.tmpDir()
                self.task(Copy(tmpdir, Fileset(filesdir)))
                let expected = Fileset(tmpdir).dirs().count
                self.task(Remove().add(Fileset(tmpdir).filesOnly()))
                let actual = self.task(Remove(Fileset(tmpdir).dirsOnly())).okCount
                XCTAssertEqual(expected, actual)
            }
            subtest("add(File, String, String)") {
                let tmpdir = self.tmpDir()
                self.task(Copy(tmpdir, Fileset(filesdir)))
                let expected = Fileset(tmpdir).collect().count
                let actual = self.task(Remove().add(tmpdir, "**", nil)).okCount
                XCTAssertEqual(expected, actual)
            }
            subtest("Multi filesets") {
                let tmpdir = self.tmpDir()
                self.task(Copy(tmpdir, Fileset(filesdir)))
                let remove = self.task(
                    Remove(
                        Fileset(tmpdir).includes("empty*"),
                        Fileset(tmpdir).includes("dir1/**")
                    )
                )
                XCTAssertEqual(9, remove.total)
                XCTAssertEqual(9, remove.okCount)
                XCTAssertEqual(0, remove.failedCount)
                XCTAssertEqual(6, remove.filesOK.count)
                XCTAssertEqual(3, remove.dirsOK.count)
                XCTAssertEqual(0, remove.filesFailed.count)
                XCTAssertEqual(0, remove.dirsFailed.count)
            }
        }
    }

    
    func testRemoveLog01() {
        class Builder: DebugBuilder {
            func test(_ filesdir: File, _ tmpdir: File) {
                func checkPrintStat(_ summary: Bool, _ logs: Array<String>) {
                    XCTAssertEqual(summary, logs.any { $0 == "# Remove file OK: 6" })
                    XCTAssertEqual(summary, logs.any { $0 == "# Remove dir OK: 3" })
                    XCTAssertEqual(summary, logs.any { $0 == "# Remove file failed: 0" })
                    XCTAssertEqual(summary, logs.any { $0 == "# Remove dir failed: 0" })
                }
                
                self.task(Copy(tmpdir, Fileset(filesdir)))
                let remove = self.task(Remove(Fileset(tmpdir).includes("empty*", "dir1/**")))
                checkPrintStat(false, log.getLog().joined().lines)
                log.d(remove.toString())
                checkPrintStat(true, log.getLog().joined().lines)
                XCTAssertEqual(9, remove.total)
                XCTAssertEqual(9, remove.okCount)
                XCTAssertEqual(0, remove.failedCount)
                XCTAssertEqual(6, remove.filesOK.count)
                XCTAssertEqual(3, remove.dirsOK.count)
                XCTAssertEqual(0, remove.filesFailed.count)
                XCTAssertEqual(0, remove.dirsFailed.count)
            }
        }
        Builder().test(testResDir.file("files"), tmpDir())
    }

    
    func testRemoveFai01() {
        class Builder: DebugBuilder {
            func checkPrintStat(_ summary: Bool, _ detail: Bool, _ logs: Array<String>) {
                XCTAssertEqual(summary, logs.any { $0 == "# Remove file OK: 5" })
                XCTAssertEqual(summary, logs.any { $0 == "# Remove dir OK: 1" })
                XCTAssertEqual(summary, logs.any { $0 == "# Remove file failed: 1" })
                XCTAssertEqual(summary, logs.any { $0 == "# Remove dir failed: 2" })
                XCTAssertEqual(detail, logs.any { $0 == "empty.dir" })
                XCTAssertEqual(detail, logs.any { $0 == "dir1/dir1a/file1a.txt" })
                XCTAssertEqual(detail, logs.any { $0 == "dir1" })
            }
            func test(_ filesdir: File, _ tmpdir: File) {
                self.task(Copy(tmpdir, Fileset(filesdir)))
                tmpdir.file("dir1").walker.bottomUp().walk { file, _ in
                    _ = file.setWritable(false, false, false)
                }
                defer {
                    tmpdir.file("dir1").walker.walk { file, _ in
                        _ = file.setWritable(true, true, false)
                    }
                    log.resetErrorCount()
                }
                let remove = self.task(Remove(Fileset(tmpdir).includes("empty*", "dir1/**")))
                XCTAssertEqual(9, remove.total)
                XCTAssertEqual(6, remove.okCount)
                XCTAssertEqual(3, remove.failedCount)
                XCTAssertEqual(5, remove.filesOK.count)
                XCTAssertEqual(1, remove.dirsOK.count)
                XCTAssertEqual(1, remove.filesFailed.count)
                XCTAssertEqual(2, remove.dirsFailed.count)
                checkPrintStat(false, false, log.getLog().joined().lines)
                log.d(remove.toString(oks: true))
                checkPrintStat(true, true, log.getLog().joined().lines)
            }
        }
        Builder().test(testResDir.file("files"), tmpDir())
    }
}
