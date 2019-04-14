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

public protocol IBuilderWorkspace {
    var projects: Array<IProject> { get }
}

//////////////////////////////////////////////////////////////////////

public protocol IProject {
    /** The directory that contains the target project. */
    var dir: File { get }
    /** A GAV string that can be parsed by GAV.from(). */
    var gav: GAV { get }
}

//////////////////////////////////////////////////////////////////////

public protocol IBuilderConf {
    var debugging: Bool { get }
    var workspace: IBuilderWorkspace { get }
    /** The builder project that contains this builder. */
    var builder: IProject { get }
    /** The target project that this builder works on. */
    var project: IProject { get }
}

//////////////////////////////////////////////////////////////////////

public protocol IBuilder {
    var conf: IBuilderConf { get }
    var log: ICoreLogger { get }

    /**
     * @param segments Path segments relative to builder project directory.
     * @return A file under builder project directory.
     */
    func builderRes(_ rpath: String?) -> File

    /**
     * @param segments Path segments relative to builder project directory.
     * @return A file under builder project directory if exists, otherwise throw an exception.
     */
    func existingBuilderRes(_ rpath: String?) -> File

    /**
     * @param treepath A path relative to one of the ancestors of the builder project directory.
     * @return The specified file if exists, otherwise throw an exception.
     *
     * For example, if builder project is bot-builder, then
     *     buildAncestorTree("bot/bot-core/src")
     * returns the source directory of the bot-core project if it exists.
     */
    func builderAncestorTree(_ treepath: String) -> File

    /**
     * @param treepath A path relative to one of the sibling of the ancestors of the builder project directory.
     * @return The specified file if exists, otherwise throw an exception.
     *
     * For example, if builder project is bot-builder, then
     *     buildAncestorSiblingTree("bot-core/src")
     * returns the source directory of the bot-core project if it exists.
     */
    func builderAncestorSiblingTree(_ treepath: String) -> File

    /**
     * Similar to buildeRes() but relative to the target project directory.
     */
    func projectRes(_ rpath: String?) -> File

    /**
     * Similar to existingBuildeRes() but relative to the target project directory.
     */
    func existingProjectRes(_ rpath: String?) -> File

    /**
     * Similar to builderAncestorTree() but relative to the target project directory.
     */
    func projectAncestorTree(_ treepath: String) -> File

    /**
     * Similar to builderAncestorSiblingTree() but relative to the target project directory.
     */
    func projectAncestorSiblingTree(_ treepath: String) -> File

    /**
     * Setup and run the given task.
     * @return The task.
     */
    func task0<T>(_ task: T) -> T where T: ICoreTask

    /**
     * Setup and run the given task.
     * @return The task.
     */
    func task0<T>(_ task: T) -> T where T: IBuilderTask

    /**
     * Setup and run the given task.
     * @return The result of run().
     */
    @discardableResult
    func task<T>(_ task: T) -> T.R where T: ICoreTask

    /**
     * Setup and run the given task.
     * @return The result of run().
     */
    @discardableResult
    func task<T>(_ task: T) -> T.R where T: IBuilderTask
}

public protocol IBasicBuilder : IBuilder {}

extension IBasicBuilder {

    public func builderRes(_ rpath: String? = nil) -> File {
        return conf.builder.dir.file(rpath)
    }

    public func existingBuilderRes(_ rpath: String? = nil) -> File {
        return builderRes(rpath).existsOrFail()
    }

    public func builderAncestorTree(_ treepath: String) -> File {
        guard let ret = BU.ancestorTree(treepath, conf.builder.dir) else { BU.fail(treepath) }
        return ret
    }

    public func builderAncestorSiblingTree(_ treepath: String) -> File {
        guard let ret = BU.ancestorSiblingTree(treepath, conf.builder.dir) else { BU.fail(treepath) }
        return ret
    }

    public func projectRes(_ rpath: String? = nil) -> File {
        return conf.project.dir.file(rpath)
    }

    public func existingProjectRes(_ rpath: String? = nil) -> File {
        return projectRes(rpath).existsOrFail()
    }

    public func projectAncestorTree(_ treepath: String) -> File {
        guard let ret = BU.ancestorTree(treepath, conf.project.dir) else { BU.fail(treepath) }
        return ret
    }

    public func projectAncestorSiblingTree(_ treepath: String) -> File {
        guard let ret = BU.ancestorSiblingTree(treepath, conf.project.dir) else { BU.fail(treepath) }
        return ret
    }

    public func task0<T>(_ task: T) -> T where T: ICoreTask {
        task.log = log
        _ = task.run()
        return task
    }
    
    public func task0<T>(_ task: T) -> T where T: IBuilderTask {
        task.builder = self
        _ = task.run()
        return task
    }
    
    @discardableResult
    public func task<T>(_ task: T) -> T.R where T: ICoreTask {
        task.log = log
        return task.run()
    }
    
    @discardableResult
    public func task<T>(_ task: T) -> T.R where T: IBuilderTask {
        task.builder = self
        return task.run()
    }
}

//////////////////////////////////////////////////////////////////////

open class EmptyWorkspace : IBuilderWorkspace {
    public let projects = Array<IProject>(reserve: 0)
    public init() {}
}

//////////////////////////////////////////////////////////////////////

open class BasicWorkspace : IBuilderWorkspace {
    public lazy var projects: Array<IProject> = {
        var ret = Array<IProject>()
        let c = Mirror(reflecting: self)
        c.children.forEach { child in
            /// Note: Don't declare projects as lazy var, it may not work here.
            if let project = (child.value as? IProject) {
                ret.append(project)
            }
        }
        return ret
    }()
    public init() {}
}

//////////////////////////////////////////////////////////////////////

/**
 * A basic IBuilderConf with the following defaults:
 *  - Project gav is "group:project:0".
 *  - Project directory is the current directory.
 *  - Debugging is false.
 *  - Builder gav is "group:builder:0"
 *  - Builder directory is current directory.
 *  - An empty workspace.
 */

open class BasicBuilderConf: IBuilderConf {

    public let project: IProject
    public let builder: IProject
    public let debugging: Bool
    public let workspace: IBuilderWorkspace

    public init(
        project: IProject,
        builder: IProject,
        debugging: Bool = false,
        workspace: IBuilderWorkspace = EmptyWorkspace()) {
        self.project = project
        self.builder = builder
        self.debugging = debugging
        self.workspace = workspace
    }
    
    public convenience init(
        debugging: Bool = false,
        projectdir: File = File.pwd,
        builderdir: File = File.pwd,
        projectgav: GAV = GAV("group", "project", "0"),
        buildergav: GAV = GAV("group", "builder", "0"),
        workspace: IBuilderWorkspace = EmptyWorkspace()
        ) {
        self.init(
            project: BasicProject(projectgav, projectdir),
            builder: BasicProject(buildergav, builderdir),
            debugging: debugging,
            workspace: workspace)
    }
}

//////////////////////////////////////////////////////////////////////

open class BuilderLogger: CoreLogger {
    
    private class Listener: ICoreLoggerLifecycleListener {
        private let debugging: Bool
        private let classname: String
        init(_ debugging: Bool, _ classname: String) {
            self.debugging = debugging
            self.classname = classname
        }
        func onStart(_ msg: String, _ starttime: Int64, _ logger: Fun10<String>) {
            if (debugging) {
                logger("#### Class \(classname) START: \(DateUtil.simpleDateTimeString(starttime))")
            }
        }
        
        func onDone(_ msg: String, _ endtime: Int64, _ errors: Int, _ logger: Fun10<String>) {
            if (debugging) {
                let ok = (errors == 0 ? "OK" : "FAIL")
                logger("#### Class \(classname) \(ok): \(DateUtil.simpleDateTimeString(endtime))")
            }
        }
    }
    
    public init(_ debugging: Bool, _ classname: String) {
        super.init(debugging: debugging)
        addLifecycleListener(Listener(debugging, classname))
    }
}

//////////////////////////////////////////////////////////////////////

open class BasicBuilder: IBasicBuilder {
    public let conf: IBuilderConf
    public lazy var log: ICoreLogger = BuilderLogger(conf.debugging, "\(type(of: self))")
    public init(_ conf: IBuilderConf) {
        self.conf = conf
    }
}

//////////////////////////////////////////////////////////////////////

open class BasicProject: IProject {
    public let gav: GAV
    public let dir: File
    public init(_ gav: GAV, _ dir: File = File.pwd) {
        self.gav = gav
        self.dir = dir
    }
}

open class KotlinProject : BasicProject {
    public var srcDir: File { return dir.file("src") }
    public var buildDir: File { return dir.file("build") }
    public var outDir: File { return dir.file("out") }
    public var mainSrcs: Array<File> {
        return [
            dir.file("src/main/java"),
            dir.file("src/main/kotlin")
        ]
    }
    public var testSrcs: Array<File> {
        return [
            dir.file("src/test/java"),
            dir.file("src/test/kotlin")
        ]
    }
    public var mainRes: File {
        return dir.file("src/main/resources")
    }
    public var testRes: File {
        return dir.file("src/test/resources")
    }
}

open class SwiftProject : BasicProject {
    public var srcDir: File { return dir.file("src") }
    public var resDir: File { return dir.file("resources.bundle") }
}

//////////////////////////////////////////////////////////////////////

open class TestLogger: CoreLogger {
    public init(_ debugging: Bool) {
        super.init(debugging: debugging)
    }
}

open class DebugBuilder : IBasicBuilder {
    public lazy var conf: IBuilderConf = BasicBuilderConf(debugging: true)
    public lazy var log: ICoreLogger = TestLogger(true)
    public init() {}
}

/**
 * Basic builder for tests.
 */
public protocol ITestBuilder: IBasicBuilder {
    var tmpdir: File { get set }
    func testResPath(_ rpath: String?) -> String
}

public extension ITestBuilder {

    func subtest(_ msg: String? = nil, _ test: @escaping Fun00x) throws {
        try log.enterX(msg) {
            try test()
        }
    }
    
    func subtest(_ msg: String? = nil, _ test: @escaping Fun00) {
        log.enter(msg) {
            test()
        }
    }
    
    func tmpDir() -> File {
        return FileUtil.createTempDir(dir: tmpdir)
    }
    
    func tmpFile(suffix: String = ".tmp", dir: File? = nil) -> File {
        return FileUtil.tempFile(suffix: suffix, dir: dir ?? tmpdir)
    }

    var testResDir: File {
        return File(testResPath(nil))
    }
    
    func testResData(_ rpath: String? = nil) throws -> Data {
        guard let data = FileManager.default.contents(atPath: testResPath(rpath)) else {
            throw IOException(rpath)
        }
        return data
    }
}

//////////////////////////////////////////////////////////////////////

