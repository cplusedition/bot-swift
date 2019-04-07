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

open class FilesetCollector<T> {

    /**
     * @param bottomup true to return sequence in depth first bottom up order, ie. children before parent directory.
     * @param include(file, rpath) true of include the file/directory in the output sequence.
     * Note that rpath includes the basepath.
     */
    open func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<T> {
        preconditionFailure("TBI")
    }
}

public extension FilesetCollector {

    /**
     * Collect only files.
     */
    public func files(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<T>  {
        return collect(bottomup) { file, rpath in
            return file.isFile && (includes?(file, rpath) ?? true)
        }
    }

    /**
     * Collect only directories.
     */
    public func dirs(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<T>  {
        return collect(bottomup) { file, rpath in
            return file.isDirectory && (includes?(file, rpath) ?? true)
        }
    }
}

open class IFileset {
    
    public let dir: File
    
    public init(_ dir: File) {
        self.dir = dir
    }
    
    public func collector<T>(_ collector: @escaping IFilePathCollector<T>) -> FilesetCollector<T> {
        preconditionFailure("TBI")
    }

    /**
     * Walk the fileset, calling callback on each accepted file.
     *
     * @param bottomup If true, return result in depth first bottom up order, ie. children before parent. Default is false.
     * @param callback(file, rpath).
     */
    public func walk(_ bottomup: Bool = false, _ callback: IFilePathCallback) {
        preconditionFailure("TBI")
    }

    public func walk(_ bottomup: Bool = false, _ callback: IFilePathCallbackX) throws {
        preconditionFailure("TBI")
    }
    
    /**
     * @param bottomup If true, return result in depth first bottom up order, ie. children before parent. Default is false.
     * @param includes File, rpath filter.
     * @return The file and relative path of files or dirs in the fileset.
     */
    public func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<(File, String)> {
        preconditionFailure("TBI")
    }
}

public extension IFileset {
    /**
     * Shortcut collect() to returns only files, not directories.
     */
    public func files(_ bottomup: Bool = false) -> MySeq<(File, String)> {
        return collect(bottomup) { file, _ in file.isFile }
    }

    /**
     * Shortcut collect() to returns only directories.
     */
    public func dirs(_ bottomup: Bool = false) -> MySeq<(File, String)> {
        return collect(bottomup) { file, _ in file.isDirectory }
    }
}

//////////////////////////////////////////////////////////////////////

public protocol IFilemap {
    /** src -> dst mapping. */
    var mapping: Dictionary<File, File> { get }

    /**
     * src -> dst mapping where src has a modified timestamp later than dst.
     */
    func modified() -> Dictionary<File, File>

    /** @return dst -> src mappping. */
    func reversed() -> Dictionary<File, File>
}

//////////////////////////////////////////////////////////////////////

open class Fileset: IFileset {
    
    public typealias Result = MySeq<(File, String)>

    private var includePredicates = Array<IFilePathPredicate>()
    private var excludePredicates = Array<IFilePathPredicate>()
    private var ignoreDirPredicates = Array<IFilePathPredicate>()

    /**
     * @param basepath The path for the basedir used to create the rpath parameter
     * of the inculdes predicate. Default is "".
     */
    public var basePath: String = ""

    /**
     * @param include Include regex.
     * @param exclude Optional exnclude regex. If not specified excludes nothing.
     */
    public init(_ dir: File, _ include: IFilePathPredicate? = nil, _ exclude: IFilePathPredicate? = nil) {
        if (!dir.isDirectory) { BU.fail("# Expecting a directory: \(dir)") }
        super.init(dir)
        if let include = include { includePredicates.append(include) }
        if let exclude = exclude { excludePredicates.append(exclude) }
    }
    
    /**
     * @param include Include regex.
     * @param exclude Optional exnclude regex. If not specified excludes nothing.
     */
    public convenience init(_ dir: File, _ include: String?, _ exclude: String? = nil) {
        self.init(
            dir,
            With.nullable(include) { SelectorFilter.predicate([$0]) },
            With.nullable(exclude) { SelectorFilter.predicate([$0]) })
    }

    public convenience init(_ dir: File, _ include: Regex?, _ exclude: Regex? = nil) {
        self.init(
            dir,
            With.nullable(include) { RegexFilter.predicate([$0]) },
            With.nullable(exclude) { RegexFilter.predicate([$0]) })
    }

    private func acceptdir(_ file: File, _ rpath: String) -> Bool {
        return (ignoreDirPredicates.isEmpty || ignoreDirPredicates.none { $0(file, rpath) })
    }

    private func accept(_ file: File, _ rpath: String) -> Bool {
        return (includePredicates.isEmpty || includePredicates.any { $0(file, rpath) })
                && (excludePredicates.isEmpty || excludePredicates.none { $0(file, rpath) })
    }

    public func includes(_ patterns: String...) -> Fileset {
        return includes(SelectorFilter.predicate(patterns))
    }

    public func includes<S>(_ patterns: S) -> Fileset where S: Sequence, S.Element == String {
        return includes(SelectorFilter.predicate(patterns))
    }
    
    public func includes(_ regexs: Regex...) -> Fileset {
        return includes(RegexFilter.predicate(regexs))
    }
    
    public func includes<S>(_ regexs: S) -> Fileset where S: Sequence, S.Element == Regex {
        return includes(RegexFilter.predicate(regexs))
    }
    
    public func includes(_ predicates: IFilePathPredicate...) -> Fileset {
        includePredicates.append(predicates)
        return self
    }
    
    public func includes<S>(_ predicates: S) -> Fileset where S: Sequence, S.Element == IFilePathPredicate {
        includePredicates.append(contentsOf: predicates)
        return self
    }
    
    public func excludes(_ patterns: String...) -> Fileset {
        return excludes(SelectorFilter.predicate(patterns))
    }

    public func excludes<S>(_ patterns: S) -> Fileset where S: Sequence, S.Element == String {
        return excludes(SelectorFilter.predicate(patterns))
    }
    
    public func excludes(_ regexs: Regex...) -> Fileset {
        return excludes(RegexFilter.predicate(regexs))
    }

    public func excludes<S>(_ regexs: S) -> Fileset where S: Sequence, S.Element == Regex {
        return excludes(RegexFilter.predicate(regexs))
    }
    
    public func excludes(_ predicates: IFilePathPredicate...) -> Fileset {
        excludePredicates.append(predicates)
        return self
    }

    public func excludes<S>(_ predicates: S) -> Fileset where S: Sequence, S.Element == IFilePathPredicate {
        excludePredicates.append(contentsOf: predicates)
        return self
    }
    
    public func ignoresDir(_ patterns: String...) -> Fileset {
        return ignoresDir(SelectorFilter.predicate(patterns))
    }
    
    public func ignoresDir<S>(_ patterns: S) -> Fileset where S: Sequence, S.Element == String {
        return ignoresDir(SelectorFilter.predicate(patterns))
    }
    
    public func ignoresDir(_ patterns: Regex...) -> Fileset {
        return ignoresDir(RegexFilter.predicate(patterns))
    }
    
    public func ignoresDir<S>(_ patterns: S) -> Fileset where S: Sequence, S.Element == Regex {
        return ignoresDir(RegexFilter.predicate(patterns))
    }
    
    public func ignoresDir(_ predicates: IFilePathPredicate...) -> Fileset {
        ignoreDirPredicates.append(predicates)
        return self
    }
    
    public func basepath(_ path: String) -> Fileset {
        self.basePath = path
        return self
    }

    public func filesOnly() -> Fileset {
        excludePredicates.append({ file, _ in !file.isFile })
        return self
    }

    public func dirsOnly() -> Fileset {
        excludePredicates.append({ file, _ in !file.isDirectory })
        return self
    }

    public override func collector<T>(_ collector: @escaping IFilePathCollector<T>) -> FilesetCollector<T> {
        return FilesetCollector1(self, collector)
    }
    
    public override func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<(File, String)> {
        return collector { ($0, $1) }.collect(bottomup, includes)
    }

    public override func walk(_ bottomup: Bool = false, _ callback: IFilePathCallback) {
        _walk(dir, basePath, bottomup, callback, acceptdir, accept)
    }

    public override func walk(_ bottomup: Bool = false, _ callback: IFilePathCallbackX) throws {
        try _walk(dir, basePath, bottomup, callback, acceptdir, accept)
    }
    
    private func _walk(
        _ dir: File,
        _ dirpath: String,
        _ bottomup: Bool,
        _ callback: IFilePathCallback,
        _ acceptdir: IFilePathPredicate,
        _ accept: IFilePathPredicate
    ) {
        for name in dir.listOrEmpty() {
            let file = File(dir, name)
            let filepath = (dirpath.isEmpty ? name : "\(dirpath)\(File.SEPCHAR)\(name)")
            if (!bottomup && accept(file, filepath)) {
                callback(file, filepath)
            }
            if (file.isDirectory && acceptdir(file, filepath)) {
                _walk(file, filepath, bottomup, callback, acceptdir, accept)
            }
            if (bottomup && accept(file, filepath)) {
                callback(file, filepath)
            }
        }
    }

    private func _walk(
        _ dir: File,
        _ dirpath: String,
        _ bottomup: Bool,
        _ callback: IFilePathCallbackX,
        _ acceptdir: IFilePathPredicate,
        _ accept: IFilePathPredicate
        ) throws {
        for name in dir.listOrEmpty() {
            let file = File(dir, name)
            let filepath = (dirpath.isEmpty ? name : "\(dirpath)\(File.SEPCHAR)\(name)")
            if (!bottomup && accept(file, filepath)) {
                try callback(file, filepath)
            }
            if (file.isDirectory && acceptdir(file, filepath)) {
                try _walk(file, filepath, bottomup, callback, acceptdir, accept)
            }
            if (bottomup && accept(file, filepath)) {
                try callback(file, filepath)
            }
        }
    }
    
    open class RegexFilter {
    
        private var regexs = Array<Regex>()

        public static func predicate<S>(_ pats: S) -> IFilePathPredicate where S: Sequence, S.Element == String {
            let filter = RegexFilter(pats)
            return { file, rpath in
                return filter.invoke(file, rpath)
            }
        }
        
        public static func predicate<S>(_ pats: S) -> IFilePathPredicate where S: Sequence, S.Element == Regex {
            let filter = RegexFilter(pats)
            return { file, rpath in
                return filter.invoke(file, rpath)
            }
        }
        
        public init<S>(_ regexs: S) where S: Sequence, S.Element == Regex {
            self.regexs.append(contentsOf: regexs)
        }
        
        public convenience init(_ regexs: Regex...) {
            self.init(regexs)
        }
        
        public convenience init<S>(_ regexs: S) where S: Sequence, S.Element == String{
            self.init(try! MatchUtil.compile(regexs))
        }
        
        public convenience init(_ regexs: String...) {
            self.init(try! MatchUtil.compile(regexs))
        }

        public func invoke(_ file: File, _ rpath: String) -> Bool {
            return regexs.any { $0.matches(rpath) }
        }
    }

    /** Path matching using ant path selectors. */
    open class SelectorFilter {

        private let caseSensitive: Bool
        private let tokenizedPat: Array<[String]>
        
        public static func predicate<S>(_ pat: S) -> IFilePathPredicate where S: Sequence, S.Element == String {
            let filter = SelectorFilter(Array(pat))
            return { file, rpath in
                return filter.invoke(file, rpath)
            }
        }
        
        public init<S>(_ patterns: S, _ caseSensitive: Bool = true) where S: Sequence, S.Element == String {
            self.caseSensitive = caseSensitive
            self.tokenizedPat = patterns.map { SelectorUtils.tokenizePathAsArray($0) }
        }

        public convenience init(_ patterns: String...) {
            self.init(patterns, true)
        }

        public convenience init(_ caseSensitive: Bool, _ patterns: String...) {
            self.init(patterns, caseSensitive)
        }

        public func invoke(_ file: File, _ rpath: String) -> Bool {
            let tokenizedPath = SelectorUtils.tokenizePathAsArray(rpath)
            return tokenizedPat.any { SelectorUtils.matchPath($0, tokenizedPath, caseSensitive) }
        }
    }

    open class FilesetCollector1<T>: FilesetCollector<T> {

        private let fileset: Fileset
        private let collector: IFilePathCollector<T>

        public init(_ fileset: Fileset, _ collector: @escaping IFilePathCollector<T>) {
            self.fileset = fileset
            self.collector = collector
        }
        
        open override func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<T> {
            var ret = MySeq<T>()
            func collect1(_ dir: File, _ dirpath: String) {
                for name in dir.listOrEmpty() {
                    let file = File(dir, name)
                    let filepath = (dirpath.isEmpty ? name : "\(dirpath)\(File.SEPCHAR)\(name)")
                    if (!bottomup && (includes?(file, filepath) ?? true) && fileset.accept(file, filepath)) {
                        ret.append(collector(file, filepath))
                    }
                    if (file.isDirectory && fileset.acceptdir(file, filepath)) {
                        collect1(file, filepath)
                    }
                    if (bottomup && (includes?(file, filepath) ?? true) && fileset.accept(file, filepath)) {
                        ret.append(collector(file, filepath))
                    }
                }
            }
            collect1(fileset.dir, fileset.basePath)
            return ret
        }
    }
}

//////////////////////////////////////////////////////////////////////

open class Filepathset: IFileset {

    private var rpaths = Set<String>()
    
    /**
     * @param basedir
     * @param rpaths File paths relative to basedir.
     */
    public init(_ dir: File, _ rpaths: String...) {
        if !dir.isDirectory { BU.fail("# Expecting a directory: \(dir)") }
        super.init(dir)
        self.rpaths.formUnion(rpaths)
    }

    public func includes(_ rpaths: String...) -> Filepathset {
        self.rpaths.formUnion(rpaths)
        return self
    }

    public func includes<S>(_ rpaths: S) -> Filepathset where S: Sequence, S.Element == String {
        self.rpaths.formUnion(rpaths)
        return self
    }
    
    public override func collector<T>(_ collector: @escaping IFilePathCollector<T>) -> FilesetCollector<T> {
        return Collector(self, collector)
    }
    
    public override func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<(File, String)> {
        return collector { file, rpath in return (file, rpath) }.collect(bottomup, includes)
    }

    public override func walk(_ bottomup: Bool = false, _ callback: IFilePathCallback) {
        let sorted = rpaths.sorted()
        _walk(dir, (bottomup ? sorted.reversed() : sorted), callback)
    }

    public override func walk(_ bottomup: Bool = false, _ callback: IFilePathCallbackX) throws {
        let sorted = rpaths.sorted()
        try _walk(dir, (bottomup ? sorted.reversed() : sorted), callback)
    }
    
    private func _walk(
        _ dir: File,
        _ rpaths: Array<String>,
        _ callback: IFilePathCallback
    ) {
        for rpath in rpaths {
            let file = dir.file(rpath)
            if file.exists {
                callback(file, rpath)
            }
        }
    }
    
    private func _walk(
        _ dir: File,
        _ rpaths: Array<String>,
        _ callback: IFilePathCallbackX
        ) throws {
        for rpath in rpaths {
            let file = dir.file(rpath)
            if file.exists {
                try callback(file, rpath)
            }
        }
    }
    
    public class Collector<T>: FilesetCollector<T> {

        public typealias Element = T
        public typealias Result = Array<T>
        
        private let filepathset: Filepathset
        private let collector: IFilePathCollector<T>
        
        public init(_ filepathset: Filepathset, _ collector: @escaping IFilePathCollector<T>) {
            self.filepathset = filepathset
            self.collector = collector
        }
        
        open override func collect(_ bottomup: Bool = false, _ includes: IFilePathPredicate? = nil) -> MySeq<T> {
            var ret = MySeq<T>()
            let sorted = filepathset.rpaths.sorted()
            for rpath in (bottomup ? sorted.reversed() : sorted) {
                let file = filepathset.dir.file(rpath)
                if file.exists && (includes?(file, rpath) ?? true) {
                    ret.append(collector(file, rpath))
                }
            }
            return ret
        }
    }
}

//////////////////////////////////////////////////////////////////////

open class Filemap : IFilemap {

    public var mapping = Dictionary<File, File>()

    public init() {}
    
    public func add(_ src: File, _ dst: File) -> Filemap {
        mapping[src] = dst
        return self
    }

    public func add<F: IFileset>(_ src: F, _ dstdir: File) -> Filemap {
        src.walk(false) { file, rpath in
            mapping[file] = File(dstdir, rpath)
        }
        return self
    }

    public func add<F: IFileset>(_ src: F, _ transform: (File, String) -> File) -> Filemap {
        src.walk(false) { file, rpath in
            mapping[file] = transform(file, rpath)
        }
        return self
    }

    public func modified() -> Dictionary<File, File> {
        return mapping.filter { (src, dst) in
            src.exists && (!dst.exists || src.lastModified > dst.lastModified)
        }
    }

    public func reversed() -> Dictionary<File, File> {
        var ret = Dictionary<File, File>()
        mapping.forEach { entry in
            ret[entry.value] = entry.key
        }
        return ret
    }
}

//////////////////////////////////////////////////////////////////////

