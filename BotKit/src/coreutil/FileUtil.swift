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

public typealias IFilePredicate = (File) -> Bool
public typealias IFileCallback = (File) -> Void
public typealias IFileCallbackX = (File) throws -> Void
public typealias IFilePathPredicate = (File, String) -> Bool
public typealias IFilePathCallback = (File, String) -> Void
public typealias IFilePathCallbackX = (File, String) throws -> Void
public typealias IFilePathCollector<T> = (File, String) -> T

public protocol FilePathCollectorProtocol {
    associatedtype Element
    func collect(_ includes: IFilePathPredicate?) -> MySeq<Element>
}

public extension FilePathCollectorProtocol {
    func files(_ includes: IFilePathPredicate? = nil) -> MySeq<Element> {
        return collect { file, rpath in
            return file.isFile && (includes?(file, rpath) ?? true)
        }
    }
    
    func dirs(_ includes: IFilePathPredicate? = nil) -> MySeq<Element> {
        return collect { file, rpath in
            return file.isDirectory && (includes?(file, rpath) ?? true)
        }
    }
}

/// A readonly wrapper around a cleaned up absolute file path.
public struct File: Comparable, Hashable {

    public static let SEP = "/"
    public static let SEPCHAR = "/".first!
    public static let SEPCHAR16 = SEP.utf16.first!
    public static let ROOT = File("/")
    public static let TMPDIR = File(FileManager.default.temporaryDirectory.path)
    
    public static var pwd: File {
        return File(FileManager.default.currentDirectoryPath)
    }
    
    public static var home: File {
        return File(FileManager.default.homeDirectoryForCurrentUser.path)
    }
    
    //#Note path is an absolute path.
    private let _path: String
    private let _basepath: Basepath
    
    /// If path is not absolute, it is taken as relative to current directory.
    public init(_ path: String) {
        let cleanpath = TextUtil.removeTrailing(File.SEP, from: FileUtil.getAbsolutePath(path: path))
        self._path = cleanpath.hasPrefix(File.SEP) ? cleanpath : File.SEP + cleanpath
        self._basepath = Basepath(cleanpath)
    }
    
    public init(_ parent: String, _ rpath: String) {
        var path = parent
        if !rpath.isEmpty && rpath != File.SEP {
            if !rpath.hasPrefix(File.SEP) {
                path.append(File.SEP)
            }
            path.append(rpath)
        }
        self.init(path)
    }
    
    public init(_ file: File, _ rpath: String?) {
        var path = file.path
        if let rpath = rpath {
            if !rpath.isEmpty && rpath != File.SEP {
                if !rpath.hasPrefix(File.SEP) {
                    path.append(File.SEP)
                }
                path.append(rpath)
            }
        }
        self.init(path)
    }
    
    public var parent: File? {
        if let dir = _basepath.dir {
            return File(dir.isEmpty ? File.SEP : dir)
        }
        return nil
    }
    
    public var basepath: Basepath {
        return _basepath
    }
    
    public var path: String {
        return _path
    }
    
    public var dir: String? {
            return _basepath.dir
    }
    
    public var name: String {
        return _basepath.name
    }
    
    public var base: String {
        return _basepath.base
    }
    
    public var ext: String? {
        return _basepath.ext
    }
    
    public var suffix: String {
        return _basepath.suffix
    }
    
    public var lcSuffix: String {
        return suffix.lowercased()
    }
    
    public var length: Int64 {
        do {
            if let size = try FileManager.default.attributesOfItem(atPath: _path)[FileAttributeKey.size] {
                return (size as! Int64)
            }
        } catch {
            // Fall through
        }
        return 0
    }
    
    public var permissions: Int? {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: _path)
            return attrs[FileAttributeKey.posixPermissions] as? Int
        } catch {
            return nil
        }
    }
    
    /// - Return ms since 1970.
    public var lastModified: Int64 {
        do {
            if let date: NSDate = (try FileManager.default.attributesOfItem(atPath: _path)[FileAttributeKey.modificationDate]) as? NSDate {
                return Int64(date.timeIntervalSince1970*1000)
            }
        } catch {
            // Fall through
        }
        return 0
    }
    
    public var exists: Bool {
        return FileManager.default.fileExists(atPath: _path)
    }
    
    public var isFile: Bool {
        return FileUtil.isFile(path: _path)
    }
    
    public var isDirectory: Bool {
        return FileUtil.isDirectory(path: _path)
    }
    
    /// @return FileAttributeType if item exists, otherwise nil.
    public var fileType: FileAttributeType? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: _path)
            return attributes[FileAttributeKey.type] as? FileAttributeType
        } catch {
            return nil
        }
    }
    
    public var canRead: Bool {
        return FileManager.default.isReadableFile(atPath: _path)
    }
    
    public var canWrite: Bool {
        return FileManager.default.isWritableFile(atPath: _path)
    }
    
    public var canDelete: Bool {
        return FileManager.default.isDeletableFile(atPath: _path)
    }
    
    public func file(_ rpath: String? = nil) -> File {
        guard let rpath = rpath else { return self }
        return File(self, rpath)
    }
    
    /// @return name of entries directly under this directory, [] if fail.
    public func listOrEmpty() -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: _path)
        } catch {
            return []
        }
    }
    
    /// @return File object of entries directly under this directory, [] if fail.
    public func listFiles() -> [File] {
        return listOrEmpty().map { return File(_path, $0) }
    }

    public func rename(to: File) -> Bool {
        do {
            // Note that this works on directory too.
            // Note that this fail if destination exists.
            try FileManager.default.moveItem(atPath: _path, toPath: to.path)
            return true
        } catch {
            return false
        }
    }
    
    // Delete a file or a directory recursively, regardless if directory is empty or not.
    public func delete() -> Bool {
        do {
            // Note that unlike other unix filesystems, FileManager delete non-empty directory.
            try FileManager.default.removeItem(atPath: _path)
            return true
        } catch {
            return false
        }
    }
    
    /// @return self if directory already exists or created successfully, otherwise nil
    public func mkdirs() -> File? {
        do {
            try FileManager.default.createDirectory(atPath: _path, withIntermediateDirectories: true)
            return self
        } catch {
            return nil
        }
    }
    
    public func mkparent() -> File? {
        do {
            guard let path = parent?.path else {
                return nil
            }
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            return self
        } catch {
            return nil
        }
    }
    
    public func setLastModified(ms: Int64) -> Bool {
        return setLastModified(date: Date(timeIntervalSince1970: Double(ms)/1000))
    }

    public func setLastModified(date: Date) -> Bool {
        do {
            try FileManager.default.setAttributes([FileAttributeKey.modificationDate: date], ofItemAtPath: _path)
            return true
        } catch {
            return false
        }
    }
    
    public func setPerm(_ to: Int) -> Bool {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: _path)
            var perm = attrs[FileAttributeKey.posixPermissions] as! Int
            perm = to & 0b111_111_111
            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: perm], ofItemAtPath: _path)
            return true
        } catch {
            return false
        }
    }

    /** @throws IllegalStateException if self is ROOT. */
    public func sibling(_ newname: String) throws -> File {
        guard let parent = parent else { throw IllegalStateException() }
        return File(parent, newname)
    }
    
    public func changeBase(_ newbase: String) throws -> File {
        return try sibling(newbase + suffix)
    }
    
    /// @param suffix The string to append to File.base, eg. changeSuffix("-sources.zip")
    public func changeSuffix(_ suffix: String) throws -> File {
        return try sibling(base + suffix)
    }
    
    public static func < (lhs: File, rhs: File) -> Bool {
        return lhs.path < rhs.path
    }
    
    public static func == (lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
    
    public var hashValue: Int {
        return _path.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_path)
    }
    
    public var description: String {
        return _path
    }
}

public extension File {
    var existsOrNull: File? {
        return exists ? self : nil
    }
    
    func mkparentOrThrow() throws -> File {
        guard let ret = mkparent() else { throw IOException(self.path) }
        return ret
    }
}

public extension File {
    func setPrivatePerm() -> Bool {
        return isDirectory ? setPerm(0b111_000_000) : setPerm(0b110_000_000)
    }
    
    func setPublicPerm() -> Bool {
        return isDirectory ? setPerm(0b111_101_101) : setPerm(0b110_100_100)
    }
    
    func setReadable(_ user: Bool?, _ group: Bool?, _ other: Bool?) -> Bool {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: _path)
            var perm = attrs[FileAttributeKey.posixPermissions] as! Int
            if let user = user {
                perm = user  ? (perm | 0b100_000_000) : (perm & ~0b100_000_000)
            }
            if let group = group {
                perm = group  ? (perm | 0b000_100_000) : (perm & ~0b000_100_000)
            }
            if let other = other {
                perm = other  ? (perm | 0b000_000_100) : (perm & ~0b000_000_100)
            }
            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: perm], ofItemAtPath: _path)
            return true
        } catch {
            return false
        }
    }
    
    func setWritable(_ user: Bool?, _ group: Bool?, _ other: Bool?) -> Bool {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: _path)
            var perm = attrs[FileAttributeKey.posixPermissions] as! Int
            if let user = user {
                perm = user  ? (perm | 0b010_000_000) : (perm & ~0b010_000_000)
            }
            if let group = group {
                perm = group  ? (perm | 0b000_010_000) : (perm & ~0b000_010_000)
            }
            if let other = other {
                perm = other  ? (perm | 0b000_000_010) : (perm & ~0b000_000_010)
            }
            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: perm], ofItemAtPath: _path)
            return true
        } catch {
            return false
        }
    }
    
    func setExcludeFromBackup(_ exclude: Bool) -> Bool {
        do {
            try NSURL(fileURLWithPath: self.path).setResourceValue(exclude, forKey: URLResourceKey.isExcludedFromBackupKey)
            return true
        } catch {
            return false
        }
    }
    
    func isExcludedFromBackup() -> Bool? {
        do {
            var ret: Bool? = nil
            //# NOTE: This seems to always return false in simulator.
            try NSURL(fileURLWithPath: self.path).getResourceValue(AutoreleasingUnsafeMutablePointer(&ret), forKey: URLResourceKey.isExcludedFromBackupKey)
            return ret
        } catch {
            return false
        }
    }
}

/// Content access functions
public extension File {
    func readText(_ encoding: String.Encoding = .utf8) throws -> String {
        do {
            return try String(contentsOfFile: self.path, encoding: encoding)
        } catch let e {
            throw IOException("\(e)")
        }
    }
    
    func readLines(_ encoding: String.Encoding = .utf8) throws -> Array<String> {
        return try readText(encoding).lines
    }
    
    func readData() throws -> Data {
        if let data = FileManager.default.contents(atPath: self.path) {
            return data
        }
        throw IOException(self.path)
    }
    
    func readBytes() throws -> [UInt8] {
        if let data = FileManager.default.contents(atPath: self.path) {
            return Array(data)
        }
        throw IOException(self.path)
    }

    func writeData(_ data: Data, _ attributes: [FileAttributeKey : Any]? = nil) throws {
        if !FileManager.default.createFile(atPath: self.path, contents: data, attributes: attributes) {
            throw IOException(self.path)
        }
    }

    func writeBytes(_ bytes: [UInt8], _ attributes: [FileAttributeKey : Any]? = nil) throws {
        try writeData(Data(bytes), attributes)
    }
    
    func writeText(_ text: String, _ encoding: String.Encoding = .utf8, _ attributes: [FileAttributeKey : Any]? = nil) throws {
        guard let data = text.data(using: encoding) else {
            throw CharacterEncodingException(self.path)
        }
        try writeData(data, attributes)
    }
    
    func writeLines(_ lines: [String], _ encoding: String.Encoding = .utf8, _ attributes: [FileAttributeKey : Any]? = nil) throws {
        try writeText(lines.joinln(), encoding, attributes)
    }
}

public extension File {
    /// @return true if destination not exists or delete is successful.
    @discardableResult
    func deleteTree() -> Bool {
        /// NOTE that macos and iOS delete non-empty directories.
        return self.delete()
    }
    
    /// @return true if destination not exist or delete is successful.
    @discardableResult
    func deleteSubtrees() -> Bool {
        guard exists else { return true }
        guard isDirectory else { return false }
        var ok = true
        for name in listOrEmpty() {
            if !File(self, name).delete() {
                ok = false
            }
        }
        return ok
    }
    
    func deleteEmptySubtrees() {
        for file in listFiles() {
            if file.isDirectory {
                file.deleteEmptyTree()
            }
        }
    }
    
    func deleteEmptyTree() {
        deleteEmptySubtrees()
        if listOrEmpty().isEmpty {
            _ = delete()
        }
    }
}

public extension File {
    var walker: Treewalker { return Treewalker(self) }
    var walker1: Treewalker1 { return Treewalker1(self) }
}

////////////////////////////////////////////////////////////////////

public class FileUtil {
    
    private static let queue = DispatchQueue(label: "FU")

    public static func getAbsolutePath(path: String) -> String {
        let ret = TextUtil.cleanupFilepath(path)
        if ret.hasPrefix(File.SEP) {
            return ret
        }
        let pwd = FileManager.default.currentDirectoryPath
        //#Note pwd seems to has trailing /, but just to be safe
        let apath = pwd.hasSuffix(File.SEP) ?  (pwd + ret) : (pwd + File.SEP + ret)
        return TextUtil.cleanupFilepath(apath)
    }
    
    /**
     * Specialize cleanPath() for rpathOrNull.
     * Result may not be same as cleanPath(), but good for rpathOrNull.
     */
    static func cleanPathSegments(_ s: String) -> Array<String> { /* not private for testing */ 
        let b = Array(s)
        let blen = b.count
        let sep = File.SEPCHAR
        var ret = Array<String>()
        var buf = String()
        var i = 0
        var c: Character
        while (i < blen) {
            c = b[i]
            if (buf.isEmpty) {
                if (c == sep) {
                    // s~//~/~
                    i += 1
                    continue
                }
                if (c == ".") {
                    if (i + 1 < blen && b[i + 1] == sep || i + 1 >= blen) {
                        // s~^\./~~
                        i += 1
                        i += 1
                        continue
                    }
                    if (i + 1 < blen && b[i + 1] == "." && (i + 2 >= blen || b[i + 2] == sep)) {
                        // /../
                        let retsize = ret.count
                        if (retsize > 0 && ".." != ret.last) {
                            ret.removeLast()
                            i += 1
                            i += 1
                            continue
                        }
                    }
                }
            }
            if (c == sep) {
                ret.append(buf)
                buf = String()
            } else {
                buf.append(c)
            }
            i += 1
        }
        if !buf.isEmpty {
            ret.append(buf)
        }
        return ret
    }

    /**
     * @return Relative path without leading / or nil if file is not under base.
     */
    public static func rpathOrNull(file: File, base: File) -> String? {
        let f = cleanPathSegments(file.path)
        let b = cleanPathSegments(base.path)
        if f.contains("..") || b.contains("..") { return nil }
        let blen = b.count
        let flen = f.count
        var i = 0
        while (i < blen && i < flen) {
            if (b[i] != f[i]) {
                break
            }
            i += 1
        }
        if (i < blen) {
            return nil
        }
        return f[i..<flen].joined(separator: File.SEP)
    }

    public static func openInputStream(_ file: File) throws -> IInputStream {
        //#NOTE In iOS simulator, both InputStream() and open() succeed without error even if file not exists.
        guard file.isFile else { throw FileNotFoundException(file.path) }
        return try openInputStreamWithoutChecking(file.path)
    }
    
    /// Open the given location without checking that it is a regular file.
    /// @return An inputstream that may fail on read if the input path does not exists or not a regular file.
    public static func openInputStreamWithoutChecking(_ path: String) throws -> IInputStream {
        //#NOTE In iOS simulator, both InputStream() and open() succeed without error even if file not exists.
        guard let inputstream = InputStream(fileAtPath: path) else { throw FileNotFoundException(path) }
        inputstream.open()
        return inputstream
    }
    
    public static func openOutputStream(_ file: File, append: Bool = false) throws -> IOutputStream {
        return try openOutputStream(file.path, append: append)
    }
    
    public static func openOutputStream(_ path: String, append: Bool = false) throws -> IOutputStream {
        guard let outputstream = OutputStream(toFileAtPath: path, append: append)
            else { throw FileNotFoundException(path) }
        outputstream.open()
        return outputstream
    }
    
    /** @return Number of files copied + number of directory created. */
    @discardableResult
    public static func copy(
        todir: File,
        fromdir: File,
        _ preservetimestamp: Bool = false,
        _ includes: IFilePathPredicate? = nil) throws -> Int {
        var count = 0
        try fromdir.walker.walk { file, rpath in
            guard includes?(file, rpath) ?? true else { return }
            let tofile = todir.file(rpath)
            if file.isDirectory {
                guard tofile.mkdirs() != nil else { throw IOException() }
            } else {
                try FileUtil.copy(tofile: tofile, fromfile: file, preservetimestamp)
            }
            count += 1
        }
        return count
    }
    
    public static func copy(todir: File, fromfile: File, _ preservetimestamp: Bool = false) throws {
        try copy(tofile: File(todir, fromfile.name), fromfile: fromfile, preservetimestamp)
    }
    
    public static func copy(tofile: File, fromfile: File, _ preservetimestamp: Bool = false) throws {
        if tofile.mkparent() == nil { throw IOException() }
        let output = try openOutputStream(tofile.path)
        defer {output.close() }
        let input = try openInputStreamWithoutChecking(fromfile.path)
        defer { input.close() }
        try ByteIOUtil.copy(to: output, from: input)
        if preservetimestamp {
            if !tofile.setLastModified(ms: fromfile.lastModified) {
                throw IOException()
            }
        }
    }
    
    public static func move(tofile: File, fromfile: File) throws {
        // Note that destination timestamp is updated on move as if it is copied.
        if fromfile.isFile,
            fromfile.setLastModified(ms: DateUtil.ms),
            fromfile.rename(to: tofile) {
            return
        }
        try copy(tofile: tofile, fromfile: fromfile)
        guard fromfile.delete() else {
            _ = tofile.delete()
            throw IOException()
        }
    }
}

/// Attribute utilities
public extension FileUtil {
    /// @return true if item exists and is a regular file.
    static func isFile(path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[FileAttributeKey.type] as! FileAttributeType == FileAttributeType.typeRegular
        } catch {
            return false
        }
    }
    
    /// @return true if item exists and is a directory.
    static func isDirectory(path: String) -> Bool {
        var ret: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &ret)
        return ret.boolValue
    }
    
    /** @return false If any operation fail. */
    static func setPrivateDirPerm(_ dirs: File...) -> Bool {
        var ok = true
        for dir in dirs {
            if dir.exists && dir.isDirectory {
                if !dir.setPerm(0b111_000_000) {
                    ok = false
                }
            }
        }
        return ok
    }
    
    /** @return false If any operation fail. */
    static func setPrivateFilePerm(_ files: File...) -> Bool {
        var ok = true
        for file in files {
            if file.exists && file.isFile {
                if !file.setPerm(0b110_000_000) {
                    ok = false
                }
            }
        }
        return ok
    }
    
    /** @return false If any operation fail. */
    static func excludeFromBackup(_ files: [File]) -> Bool {
        var ok = true
        for file in files {
            if !file.setExcludeFromBackup(true) {
                ok = false
            }
        }
        return ok
    }
    
    static func touch(dir: File, ms: Int64 = DateUtil.ms) -> Bool {
        return touch(dir: dir, date: Date(ms: ms))
    }
    
    static func touch(dir: File, date: Date = Date()) -> Bool {
        var ok = true
        if dir.isDirectory {
            dir.walker1.walk {
                if !$0.setLastModified(date: date) {
                    ok = false
                }
            }
        }
        if !dir.setLastModified(date: date) {
            ok = false
        }
        return ok
    }
}

/// File diff methods
public extension FileUtil {
    /// Returns true if the two files differ.
    static func diff(_ file1: File, _ file2: File) throws -> Bool {
        let input1 = try FileUtil.openInputStream(file1)
        defer { input1.close() }
        let input2 = try FileUtil.openInputStream(file2)
        defer { input2.close() }
        return try diff(input1, input2)
    }
    
    static func diff(_ input1: IInputStream, _ input2: IInputStream) throws -> Bool {
        let len = ByteIOUtil.K.BUFSIZE4
        let buf1 = [UInt8](repeating: 0, count: len)
        let buf2 = [UInt8](repeating: 0, count: len)
        let ptr1 = UnsafeMutablePointer<UInt8>(mutating: buf1)
        let ptr2 = UnsafeMutablePointer<UInt8>(mutating: buf2)
        var n1: Int
        repeat {
            n1 = input1.readAsMuchAsPossible(ptr1, len)
            guard n1 >= 0 else {
                throw ReadException()
            }
            let n2 = input2.readAsMuchAsPossible(ptr2, len)
            guard n2 >= 0 else {
                throw ReadException()
            }
            if n2 != n1 {
                return true
            }
            //# Note that as of xcode 8.2.1, this is incredibly slow, takes ~15x longer than the byte-wise compare below!
            // testCopy01AndReturnError:]' measured [Time, seconds] average: 3.475, relative standard deviation: 1.569%
            //            if n1 == len {
            //                if buf1 != buf2 {
            //                    return true
            //                }
            //            } else {
            //# testCopy01AndReturnError:]' measured [Time, seconds] average: 0.246, relative standard deviation: 8.448%
            for i in 0..<n1 {
                if buf1[i] != buf2[i] {
                    return true
                }
            }
            //            }
        } while(n1 == len)
        return false
    }

    /**
     * Diff files, ignoring empty directories, in the given directories.
     */
    static func diffDir(_ dir1: File, _ dir2: File) throws -> DiffStat<String> {
        let stat = DiffStat<String>()
        try dir1.walker.files { file1, rpath in
            let file2 = File(dir2, rpath)
            if !file2.isFile { stat.aonly.insert(rpath) }
            else if try FileUtil.diff(file1, file2) { stat.diffs.insert(rpath) }
            else { stat.sames.insert(rpath) }
        }
        dir2.walker.files { _, rpath in
            if (!File(dir1, rpath).isFile) {
                stat.bonly.insert(rpath)
            }
        }
        return stat
    }
    
}

public extension FileUtil {
    static func documentUrl(_ rpath: String? = nil) -> URL {
        do {
            let docurl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return (rpath == nil) ? docurl : docurl.appendingPathComponent(rpath!)
        } catch {
            // Should not happen
            preconditionFailure()
        }
    }
}

public extension FileUtil {
    
    /// @return An unique and created tmp directory.
    static func createTempDir(dir: File? = nil) -> File {
        return FileUtil.queue.sync {
            let dir = dir ?? File.TMPDIR
            var ret: File
            var count = 100
            while count > 0 {
                ret = dir.file("tmp\(RandUtil.getWord(length: 8))\(DateUtil.ms)")
                if !ret.exists && ret.mkdirs() != nil {
                    precondition(ret.setPerm(0b111_000_000))
                    precondition(ret.setExcludeFromBackup(true))
                    return ret
                }
                count -= 1
                usleep(2000)
            }
            // Something is wrong if we cannot create a tmp file after so many tries.
            preconditionFailure()
        }
    }
    
    /// @return A temp file that does not exists yet.
    static func tempFile(suffix: String = ".tmp", dir: File? = nil) -> File {
        return FileUtil.queue.sync {
            let dir = dir ?? File.TMPDIR
            var ret: File
            var count = 100
            while count > 0 {
                ret = dir.file("tmp\(RandUtil.getWord(length: 8))\(DateUtil.ms)\(suffix)")
                if !ret.exists {
                    return ret
                }
                count -= 1
                usleep(2000)
            }
            // Something is wrong if we cannot create a tmp file after so many tries.
            preconditionFailure()
        }
    }
    
}

////////////////////////////////////////////////////////////////////

open class Treewalker {
    public let dir: File
    public var basepath = ""
    public var bottomup = false
    public var ignoresdir: IFilePathPredicate? = nil
    
    public init(_ dir: File) {
        self.dir = dir
    }
    
    /**
     * Use the given path as path for the initial directory to create relative
     * paths for the callbacks. Default is "".
     */
    public func basepath(_ path: String) -> Treewalker {
        self.basepath = path
        return self
    }
    
    /**
     * Walk in bottom up order, ie. children before parent. Default is top down.
     */
    public func bottomUp() -> Treewalker {
        self.bottomup = true
        return self
    }
    
    /**
     * Do not recurse into directories that the given predicate returns true.
     * However, the directory itself would be visited.
     */
    public func ignoresDir(_ predicate: @escaping IFilePathPredicate) -> Treewalker {
        self.ignoresdir = predicate
        return self
    }
    
    /**
     * Walk the given directory recursively.
     * Invoke the given callback on each file/directory visited.
     *
     * @param callback(file, rpath)
     */
    public func walk(_ callback: IFilePathCallback) {
        U._walk(dir, basepath, bottomup, ignoresdir, callback)
    }
    
    /**
     * Shortcut for walk1() that invoke callback on directories only.
     */
    public func dirs(_ callback: IFilePathCallback) {
        walk { file, rpath in
            if file.isDirectory {
                callback(file, rpath)
            }
        }
    }
    
    /**
     * Shortcut for walk1() that invoke callback on files only.
     */
    public func files(_ callback: IFilePathCallback) {
        walk { file, rpath in
            if file.isFile {
                callback(file, rpath)
            }
        }
    }
    
    /**
     * Walk the given directory recursively.
     * Invoke the given callback on each file/directory visited.
     *
     * @param callback(file, rpath)
     */
    public func walk(_ callback: IFilePathCallbackX) throws {
        try U._walk(dir, basepath, bottomup, ignoresdir, callback)
    }
    
    /**
     * Shortcut for walk1() that invoke callback on directories only.
     */
    public func dirs(_ callback: IFilePathCallbackX) throws {
        try walk { file, rpath in
            if file.isDirectory {
                try callback(file, rpath)
            }
        }
    }
    
    /**
     * Shortcut for walk1() that invoke callback on files only.
     */
    public func files(_ callback: IFilePathCallbackX) throws {
        try walk { file, rpath in
            if file.isFile {
                try callback(file, rpath)
            }
        }
    }
    
    /**
     * Like walk() but it stop searching and return the first file
     * with which the predicate returns true.
     */
    public func find(_ accept: IFilePathPredicate) -> File? {
        return U.find1(dir, basepath, bottomup, ignoresdir, accept)
    }
    
    /**
     * For example, to collect (rpath, filesize):
     *     collector { file, rpath in return (rpath, file.length()) }.collect()
     *
     * @param collector A FilePathCollector that returns a T object.
     * @return A TreewalkerCollector.
     */
    public func collector<T>(_ collector: @escaping IFilePathCollector<T>) -> TreewalkerCollector<T> {
        return TreewalkerCollector(self, collector)
    }
    
    /** A shorthand for collection(FilePathCollectors.filePathCollector) */
    public func collector() -> TreewalkerCollector<(File, String)> {
        return TreewalkerCollector(self) { file, rpath in return (file, rpath) }
    }
    
    /** A shorthand for collection(FliePathCollectors::pathCollector) */
    public func pathCollector() -> TreewalkerCollector<String> {
        return TreewalkerCollector(self) { _, rpath in return rpath }
    }
    
    /** A shorthand for collection(FliePathCollectors::fileCollector) */
    public func fileCollector() -> TreewalkerCollector<File> {
        return TreewalkerCollector(self) { file, _ in return file }
    }
    
    /**
     * A shorthand for collector((file, rpath)).collect(includes).
     *
     * @return MySeq<(File, String)> File/directory where includes() return true.
     */
    public func collect(_ includes: IFilePathPredicate? = nil) -> MySeq<(File, String)> {
        return collector{ file, rpath in return (file, rpath) }.collect(includes)
    }
    
    open class TreewalkerCollector<T>: FilePathCollectorProtocol {
        public typealias Element = T
        private let walker: Treewalker
        private let collector: IFilePathCollector<T>
        public init(_ walker: Treewalker, _ collector: @escaping IFilePathCollector<T>) {
            self.walker = walker
            self.collector = collector
        }
        public func collect(_ includes: IFilePathPredicate? = nil) -> MySeq<T> {
            return U.collect(walker.dir, walker.basepath, walker.bottomup, walker.ignoresdir, collector, includes)
        }
    }

    private struct U {
        static func _walk(
            _ dir: File,
            _ rpath: String,
            _ bottomup: Bool,
            _ ignoresdir: IFilePathPredicate?,
            _ callback: IFilePathCallback
            ) {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                let filepath = (rpath.isEmpty ? name : "\(rpath)\(File.SEPCHAR)\(name)")
                if !bottomup { callback(file, filepath) }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file, filepath))) {
                    _walk(file, filepath, bottomup, ignoresdir, callback)
                }
                if bottomup { callback(file, filepath) }
            }
        }
        
        static func _walk(
            _ dir: File,
            _ rpath: String,
            _ bottomup: Bool,
            _ ignoresdir: IFilePathPredicate?,
            _ callback: IFilePathCallbackX
            ) throws {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                let filepath = (rpath.isEmpty ? name : "\(rpath)\(File.SEPCHAR)\(name)")
                if !bottomup { try callback(file, filepath) }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file, filepath))) {
                    try _walk(file, filepath, bottomup, ignoresdir, callback)
                }
                if bottomup { try callback(file, filepath) }
            }
        }
        
        static func find1(
            _ dir: File,
            _ rpath: String,
            _ bottomup: Bool,
            _ ignoresdir: IFilePathPredicate?,
            _ accept: IFilePathPredicate
            ) -> File? {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                let filepath = (rpath.isEmpty ? name : "\(rpath)\(File.SEPCHAR)\(name)")
                if !bottomup && accept(file, filepath) { return file }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file, filepath))) {
                    if let ret = find1(file, filepath, bottomup, ignoresdir, accept) {
                        return ret
                    }
                }
                if bottomup && accept(file, filepath) { return file }
            }
            return nil
        }
        
        static func collect<T>(
            _ dir: File,
            _ dirpath: String,
            _ bottomup: Bool,
            _ ignoresdir: IFilePathPredicate?,
            _ collector: @escaping IFilePathCollector<T>,
            _ includes: IFilePathPredicate?
            ) -> MySeq<T> {
            var ret = MySeq<T>()
            func collect1(_ dir: File, _ dirpath: String){
                for name in dir.listOrEmpty() {
                    let file = File(dir, name)
                    let filepath = (dirpath.isEmpty ? name : "\(dirpath)\(File.SEPCHAR)\(name)")
                    if (!bottomup && (includes == nil || includes!(file, filepath))) {
                        ret.append(collector(file, filepath))
                    }
                    if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file, filepath))) {
                        collect1(file, filepath)
                    }
                    if (bottomup && (includes == nil || includes!(file, filepath))) {
                        ret.append(collector(file, filepath))
                    }
                }
            }
            collect1(dir, dirpath)
            return ret
        }
    }
}

open class Treewalker1 {
    public let dir: File
    public var bottomup = false
    public var ignoresdir: IFilePredicate? = nil
    
    public init(_ dir: File) {
        self.dir = dir
    }
    
    /**
     * Walk in bottom up order, ie. children before parent. Default is top down.
     */
    public func bottomUp() -> Treewalker1 {
        self.bottomup = true
        return self
    }
    
    /**
     * Do not recurse into directories that the given predicate returns true.
     * However, the directory itself would be visited.
     */
    public func ignoresDir(_ predicate: @escaping IFilePredicate) -> Treewalker1 {
        self.ignoresdir = predicate
        return self
    }
    
    /**
     * Walk the given directory recursively.
     * Invoke the given callback on each file/directory visited.
     *
     * @param callback(file, rpath)
     */
    public func walk(_ callback: IFileCallback) {
        U._walk(dir, bottomup, ignoresdir, callback)
    }
    
    /**
     * Shortcut for walk1() that invoke callback on directories only.
     */
    public func dirs(_ callback: IFileCallback) {
        walk {
            if $0.isDirectory {
                callback($0)
            }
        }
    }
    
    /**
     * Shortcut for walk1() that invoke callback on files only.
     */
    public func files(_ callback: IFileCallback) {
        walk {
            if $0.isFile {
                callback($0)
            }
        }
    }
    
    /**
     * Walk the given directory recursively.
     * Invoke the given callback on each file/directory visited.
     *
     * @param callback(file, rpath)
     */
    public func walk(_ callback: IFileCallbackX) throws {
        try U._walk(dir, bottomup, ignoresdir, callback)
    }
    
    /**
     * Shortcut for walk1() that invoke callback on directories only.
     */
    public func dirs(_ callback: IFileCallbackX) throws {
        try walk {
            if $0.isDirectory {
                try callback($0)
            }
        }
    }
    
    /**
     * Shortcut for walk1() that invoke callback on files only.
     */
    public func files(_ callback: IFileCallbackX) throws {
        try walk {
            if $0.isFile {
                try callback($0)
            }
        }
    }
    
    /**
     * Like walk() but it stop searching and return the first file
     * with which the predicate returns true.
     */
    public func find(_ accept: IFilePredicate) -> File? {
        return U.find1(dir, bottomup, ignoresdir, accept)
    }
    
    /**
     * @return MySeq<(File)> File/directory where includes() return true.
     */
    public func collect(_ includes: IFilePredicate? = nil) -> MySeq<File> {
        return U.collect(dir, bottomup, ignoresdir, includes)
    }
    
    private struct U {
        static func _walk(
            _ dir: File,
            _ bottomup: Bool,
            _ ignoresdir: IFilePredicate?,
            _ callback: IFileCallback
            ) {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                if !bottomup { callback(file) }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file))) {
                    _walk(file, bottomup, ignoresdir, callback)
                }
                if bottomup { callback(file) }
            }
        }
        
        static func _walk(
            _ dir: File,
            _ bottomup: Bool,
            _ ignoresdir: IFilePredicate?,
            _ callback: IFileCallbackX
            ) throws {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                if !bottomup { try callback(file) }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file))) {
                    try _walk(file, bottomup, ignoresdir, callback)
                }
                if bottomup { try callback(file) }
            }
        }
        
        static func find1(
            _ dir: File,
            _ bottomup: Bool,
            _ ignoresdir: IFilePredicate?,
            _ accept: IFilePredicate
            ) -> File? {
            for name in dir.listOrEmpty() {
                let file = File(dir, name)
                if !bottomup && accept(file) { return file }
                if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file))) {
                    if let ret = find1(file, bottomup, ignoresdir, accept) {
                        return ret
                    }
                }
                if bottomup && accept(file) { return file }
            }
            return nil
        }
        
        static func collect(
            _ dir: File,
            _ bottomup: Bool,
            _ ignoresdir: IFilePredicate?,
            _ includes: IFilePredicate?
            ) -> MySeq<File> {
            var ret = MySeq<File>()
            func collect1(_ dir: File){
                for name in dir.listOrEmpty() {
                    let file = File(dir, name)
                    if (!bottomup && (includes == nil || includes!(file))) {
                        ret.append(file)
                    }
                    if (file.isDirectory && (ignoresdir == nil || !ignoresdir!(file))) {
                        collect1(file)
                    }
                    if (bottomup && (includes == nil || includes!(file))) {
                        ret.append(file)
                    }
                }
            }
            collect1(dir)
            return ret
        }
    }
}

////////////////////////////////////////////////////////////////////
