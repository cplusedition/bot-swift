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

//////////////////////////////////////////////////////////////////////

/** Tasks that does not require a builder. */
public protocol ICoreTask: AnyObject {
    associatedtype Result
    var log: ICoreLogger { get set }
    func run() -> Result
}

/** Tasks that works with a builder. */
public protocol IBuilderTask : ICoreTask {
    var builder: IBuilder { get set }
}

//////////////////////////////////////////////////////////////////////

/** Tasks that do not depend on builder. */
open class CoreTask<T>: ICoreTask {

    public typealias Result = T

    private var _log: ICoreLogger? = nil
    public var log: ICoreLogger {
        get {
            return _log!
        }
        set(value) {
            _log = value
        }
    }

    public var quiet = false

    public init(_ log: ICoreLogger? = nil) {
        if let l = log {
            self.log = l
        }
    }

    @discardableResult
    public func setQuiet(_ b: Bool) -> CoreTask {
        quiet = b
        return self
    }

    @discardableResult
    open func run() -> T {
        preconditionFailure("TBI")
    }
}

//////////////////////////////////////////////////////////////////////

open class BuilderTask<T>: IBuilderTask {

    public typealias Result = T
    
    private var _builder: IBuilder? = nil
    private var _log: ICoreLogger? = nil
    public var builder: IBuilder {
        get {
            return _builder!
        }
        set(value) {
            _builder = value
            log = builder.log
        }
    }
    public var log: ICoreLogger {
        get {
            return _log!
        }
        set(value) {
            _log = value
        }
    }
    public var quiet = false

    public init(_ builder: IBuilder? = nil) {
        if let b = builder {
            self.builder = b
        }
    }

    @discardableResult
    public func setQuiet(_ b: Bool) -> BuilderTask<T> {
        quiet = b
        return self
    }

    @discardableResult
    open func run() -> T {
        preconditionFailure("TBI")
    }
}

//////////////////////////////////////////////////////////////////////

open class ResultPrinter {

    let ret = StringPrintWriter()
    private let withEmpty: Bool
    private let trailingSpaces = try! Regex("\\s+$")

    public init(_ withempty: Bool) {
        self.withEmpty = withempty
    }
    
    public func print<T>(_ detail: Bool, _ msg: String, _ list: T)  -> ResultPrinter where T: Collection, T.Element == String {
        if withEmpty || !list.isEmpty {
            ret.println("\(msg): \(list.count)")
            if (detail) {
                ret.println(list)
            }
        }
        return self
    }

    public func toString() -> String {
        return trailingSpaces.matcher(ret.toString()).replaceAll("")
    }
}

//////////////////////////////////////////////////////////////////////

open class Copy: CoreTask<Copy.Result> {
    
    private let dstdir: File
    private var filesets = Array<IFileset>()
    private var preserveTimestamp = true
    private var _result = Result()
    public var result: Result {
        return _result
    }
    
    public init(_ dstdir: File, _ filesets: IFileset...) {
        if (!dstdir.isDirectory) { BU.fail("# Expecting a directory: \(dstdir)") }
        self.dstdir = dstdir
        self.filesets.append(filesets)
        super.init()
    }
    
    public convenience init(_ dstdir: File, _ srcdir: File, _ include: String? = nil, _ exclude: String? = nil) {
        self.init(dstdir, Fileset(srcdir, include, exclude))
    }
    
    public func preserveTimestamp(_ b: Bool) -> Copy {
        self.preserveTimestamp = b
        return self
    }
    
    public func add(_ filesets: IFileset...) -> Copy {
        self.filesets.append(filesets)
        return self
    }
    
    public func add(_ dir: File, _ include: String? = nil, _ exclude: String? = nil) -> Copy {
        self.filesets.append(Fileset(dir, include, exclude))
        return self
    }
    
    open override func run() -> Copy.Result {
        for fileset in filesets {
            fileset.walk { file, rpath in
                let dstfile = File(dstdir, rpath)
                if (file.isDirectory) {
                    _ = dstfile.mkdirs()
                } else if (file.isFile) {
                    do {
                        try FileUtil.copy(tofile: dstfile, fromfile: file)
                        if (preserveTimestamp) {
                            _ = dstfile.setLastModified(ms: file.lastModified)
                        }
                        _result.copied.append(rpath)
                    } catch let e {
                        log.e("# ERROR: Copy failed: \(rpath)", e)
                        _result.copyFailed.append(rpath)
                    }
                }
            }
        }
        if (!quiet) {
            log.d("# Copy: \(_result.copied.count) OK, \(_result.copyFailed.count) failed")
        }
        return _result
    }
    
    public class Result {
        public var copied = Array<String>()
        public var copyFailed = Array<String>()
        
        public func toString(copied: Bool = false, failed: Bool = true) -> String {
            return ResultPrinter(true).print(copied, "# Copied", self.copied)
                .print(failed, "# Copy failed", copyFailed)
                .toString()
        }
    }
}

//////////////////////////////////////////////////////////////////////

/**
 * Like Copy but only copy files that are dffer if destination exists.
 */
open class CopyDiff: CoreTask<CopyDiff.Result> {

    private let dstdir: File
    private var filesets = Array<IFileset>()
    private var preserveTimestamp = true
    private var _result = Result()
    public var result: Result { return _result }

    public init(_ dstdir: File, _ filesets: IFileset...) {
        if !dstdir.isDirectory { BU.fail("# Expecting a directory: \(dstdir)") }
        self.dstdir = dstdir
        self.filesets.append(filesets)
        super.init()
    }

    public convenience init(_ dstdir: File, _ srcdir: File, _ include: String? = nil, _ exclude: String? = nil) {
        self.init(dstdir, Fileset(srcdir, include, exclude))
    }

    public func preserveTimestamp(_ b: Bool) -> CopyDiff {
        self.preserveTimestamp = b
        return self
    }

    public func add(_ filesets: IFileset...) -> CopyDiff {
        self.filesets.append(filesets)
        return self
    }

    public func add(_ dir: File, _ include: String? = nil, _ exclude: String? = nil) -> CopyDiff {
        self.filesets.append(Fileset(dir, include, exclude))
        return self
    }

    open override func run() -> CopyDiff.Result {
        for fileset in filesets {
            fileset.walk { file, rpath in
                let dstfile = File(dstdir, rpath)
                if (file.isDirectory) {
                    _ = dstfile.mkdirs()
                } else if (file.isFile) {
                    do {
                        if try dstfile.exists && !FileUtil.diff(dstfile, file) {
                            _result.notCopied.append(rpath)
                        } else {
                            try FileUtil.copy(tofile: dstfile, fromfile: file)
                            if preserveTimestamp { _ = dstfile.setLastModified(ms: file.lastModified) }
                            _result.copied.append(rpath)
                        }
                    } catch let e {
                        log.e("# ERROR: Copy failed: \(rpath)", e)
                        _result.copyFailed.append(rpath)
                    }
                }
            }
        }
        if (!quiet) {
            log.d("# Copy: \(_result.copied.count) OK, \(_result.notCopied.count) not copied, \(_result.copyFailed.count) failed")
        }
        return _result
    }

    public class Result {
        public var notCopied = Array<String>()
        public var copied = Array<String>()
        public var copyFailed = Array<String>()
        
        public func toString(notcopied: Bool = false, copied: Bool = true, failed: Bool = true) -> String {
            return ResultPrinter(true)
                .print(notcopied, "# Not copied", notCopied)
                .print(copied, "# Copied", self.copied)
                .print(failed, "# Copy failed", copyFailed)
                .toString()
        }
    }
}

//////////////////////////////////////////////////////////////////////

/**
 * Like CopyDiff but delete extra destination files that are not part of the source fileset.
 */
open class CopyMirror: CoreTask<CopyMirror.Result> {
    
    private let dstdir: File
    private let fileset: IFileset
    private var preservePredicates = Array<IFilePathPredicate>()
    private var preserveTimestamp = true
    private var _result = Result()
    public var result: Result { return _result }

    public init(_ dstdir: File, _ fileset: IFileset) {
        if !dstdir.isDirectory { BU.fail("# Expecting a directory: \(dstdir)") }
        self.dstdir = dstdir
        self.fileset = fileset
        super.init()
    }
    
    public convenience init(_ dstdir: File, _ srcdir: File, _ include: String? = nil, _ exclude: String? = nil) {
        self.init(dstdir, Fileset(srcdir, include, exclude))
    }

    public func preserveTimestamp(_ b: Bool) -> CopyMirror {
        self.preserveTimestamp = b
        return self
    }

    public func preserve(_ predicates: IFilePathPredicate...) -> CopyMirror {
        self.preservePredicates.append(predicates)
        return self
    }

    open override func run() -> CopyMirror.Result {
        fileset.walk { file, rpath in
            do {
                let dstfile = File(dstdir, rpath)
                if (file.isDirectory) {
                    _ = dstfile.mkdirs()
                } else if (file.isFile) {
                    if try dstfile.exists && !FileUtil.diff(dstfile, file) {
                        _result.notCopied.append(rpath)
                    } else {
                        try FileUtil.copy(tofile: dstfile, fromfile: file)
                        if preserveTimestamp { _ = dstfile.setLastModified(ms: file.lastModified) }
                        _result.copied.append(rpath)
                    }
                }
            } catch let e {
                log.e("# ERROR: Copy failed: \(rpath)", e)
                _result.copyFailed.append(rpath)
            }
        }
        let srcdir = fileset.dir
        dstdir.walker.bottomUp().walk { file, rpath in
            if srcdir.file(rpath).exists { return }
            if (file.isDirectory) {
                _result.extraDirs.insert(rpath)
                if (preservePredicates.any { $0(file, rpath) }) { return }
                if file.listOrEmpty().isEmpty && file.delete() {
                    _result.extraDirsRemoved.insert(rpath)
                } else {
                    _result.extraDirsRemoveFailed.insert(rpath)
                }
            } else {
                _result.extraFiles.insert(rpath)
                if (preservePredicates.any() { $0(file, rpath) }) { return }
                if file.delete() {
                    _result.extraFilesRemoved.insert(rpath)
                } else {
                   _result.extraFilesRemoveFailed.insert(rpath)
                }
            }
        }
        if (!quiet) {
            log.d("# Copy: \(_result.copied.count) OK, \(_result.notCopied.count) not copied, \(_result.copyFailed.count) failed")
            log.d(
                "# Remove extras: \(_result.extraFilesRemoved.count) files OK, \(_result.extraDirsRemoved.count) dirs OK, " +
                "\(_result.extraFilesRemoveFailed.count) files failed, \(_result.extraDirsRemoveFailed.count) dirs failed"
            )
        }
        if (_result.extraFilesRemoveFailed.count > 0) {
            log.e("# ERROR: Removing \(_result.extraFilesRemoveFailed.count) extra files")
            log.d(_result.extraFilesRemoveFailed)
        }
        if (_result.extraDirsRemoveFailed.count > 0) {
            log.e("# ERROR: Removing \(_result.extraDirsRemoveFailed.count) extra dirs")
            log.d(_result.extraDirsRemoveFailed)
        }
        return _result
    }

    public class Result {
        public var extraFiles = Set<String>() // reverseOrder()
        public var extraDirs = Set<String>() // reverseOrder()
        public var extraFilesRemoved = Set<String>() // reverseOrder()
        public var extraDirsRemoved = Set<String>() // reverseOrder()
        public var extraFilesRemoveFailed = Set<String>() // reverseOrder()
        public var extraDirsRemoveFailed = Set<String>() // reverseOrder()
        public var notCopied = Array<String>()
        public var copied = Array<String>()
        public var copyFailed = Array<String>()

        public func toString() -> String {
            return toString(notcopied: false)
        }

        /** Default prints everything except not copied. */
        public func toString(
            notcopied: Bool = false,
            extras: Bool = true,
            extrasremoved: Bool = true,
            copied: Bool = true,
            failed: Bool = true,
            withempty: Bool = true
        ) -> String {
            return tostring(
                notcopied,
                extras,
                extrasremoved,
                copied,
                failed,
                withempty
            )
        }

        /** Default prints nothing. */
        public func toString0(
            notcopied: Bool = false,
            extras: Bool = false,
            extrasremoved: Bool = false,
            copied: Bool = false,
            failed: Bool = false,
            withempty: Bool = true
        ) -> String {
            return tostring(
                notcopied,
                extras,
                extrasremoved,
                copied,
                failed,
                withempty
            )
        }

        private func tostring(
            _ notcopied: Bool,
            _ extras: Bool,
            _ extrasremoved: Bool,
            _ copied: Bool,
            _ failed: Bool,
            _ withempty: Bool
            ) -> String {
            return ResultPrinter(withempty)
                .print(notcopied, "# Not copied", notCopied)
                .print(extras, "# Extra files", extraFiles)
                .print(extras, "# Extra dirs", extraDirs)
                .print(extrasremoved, "# Extra files removed", extraFilesRemoved)
                .print(extrasremoved, "# Extra dirs removed", extraDirsRemoved)
                .print(failed, "# Extra files remove failed", extraFilesRemoveFailed)
                .print(failed, "# Extra dirs remove failed", extraDirsRemoveFailed)
                .print(copied, "# Copied", self.copied)
                .print(failed, "# Copy failed", copyFailed)
                .toString()
        }
    }
}


//////////////////////////////////////////////////////////////////////

open class Remove: CoreTask<Remove.Result> {
    private var filesets = Array<IFileset>()
    private var _result = Result()
    public var result: Result { return _result }

    public init(_ filesets: IFileset...) {
        self.filesets.append(filesets)
        super.init()
    }
    
    public convenience init(_ dir: File, _ include: String? = nil, _ exclude: String? = nil) {
        self.init(Fileset(dir, include, exclude))
    }

    public func add(_ filesets: IFileset...) -> Remove {
        self.filesets.append(filesets)
        return self
    }

    public func add(_ dir: File, _ include: String? = nil, _ exclude: String? = nil) -> Remove {
        return add(Fileset(dir, include, exclude))
    }

    /**
     * @return Number of files successfullly removed.
     */
    open override func run() -> Remove.Result {
        if filesets.count == 1 {
            filesets.first!.walk(true) { file, rpath in
                if file.isFile {
                    removefile(_result, file, rpath)
                } else if file.isDirectory {
                    removedir(_result, file, rpath)
                }
            }
        } else if filesets.count > 1 {
            filesets.forEach {
                $0.walk { file, rpath in
                    if (file.isFile) {
                        removefile(_result, file, rpath)
                    }
                }
            }
            filesets.forEach {
                $0.walk(true) { file, rpath in
                    if (file.isDirectory) {
                        removedir(_result, file, rpath)
                    }
                }
            }
        }
        if (_result.filesFailed.count + _result.dirsFailed.count > 0) {
            log.e("# ERROR: Remove: \(_result.filesOK.count) files OK, \(_result.dirsOK.count) dirs OK, " +
                "\(_result.filesFailed.count) files failed, \(_result.dirsFailed.count) dirs failed")
        } else if (!quiet) {
            log.d("# Remove: \(_result.filesOK.count) files OK, \(_result.dirsOK.count) dirs OK")
        }
        return _result
    }

    private func removefile(_ result: Result, _ file: File, _ rpath: String) {
        result.total += 1
        if (file.delete()) {
            result.filesOK.append(rpath)
        } else {
            result.filesFailed.append(rpath)
        }
    }

    private func removedir(_ result: Result, _ file: File, _ rpath: String) {
        result.total += 1
        if (file.listOrEmpty().isEmpty && file.delete()) {
            result.dirsOK.append(rpath)
        } else {
            result.dirsFailed.append(rpath)
        }
    }
    
    public class Result {
        public var filesOK = Array<String>()
        public var dirsOK = Array<String>()
        public var filesFailed = Array<String>()
        public var dirsFailed = Array<String>()
        public var total = 0
        public var okCount: Int { return filesOK.count + dirsOK.count }
        public var failedCount: Int { return filesFailed.count + dirsFailed.count }
        
        public func toString(oks: Bool = false, fails: Bool = true) -> String {
            return ResultPrinter(true)
                .print(oks, "# Remove file OK", filesOK)
                .print(oks, "# Remove dir OK", dirsOK)
                .print(fails, "# Remove file failed", filesFailed)
                .print(fails, "# Remove dir failed", dirsFailed)
                .toString()
        }
    }
}

//////////////////////////////////////////////////////////////////////

