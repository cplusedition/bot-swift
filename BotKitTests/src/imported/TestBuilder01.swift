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

class TestBuilder01 : TestBase {

    open override var DEBUGGING: Bool {
        return false
    }
    
    func testBasic01() throws {
        log.d("# builderDir: \(builderRes())")
        log.d("# projectDir: \(projectRes())")
        XCTAssertTrue(self.builderRes("files").exists)
        XCTAssertTrue(self.existingBuilderRes("files").exists)
    }
    
    func testIBasicBuilder01() throws {
        subtest {
            XCTAssertTrue(self.builderRes().exists)
            XCTAssertTrue(self.builderRes("files").exists)
            XCTAssertFalse(self.builderRes("notexists").exists)
            XCTAssertTrue(self.existingBuilderRes().exists)
            XCTAssertTrue(self.existingBuilderRes("files").exists)
            //            try With.errorOrFail { _ = self.existingBuilderRes("notexists") }
        }
        subtest {
            XCTAssertTrue(self.projectRes().exists)
            XCTAssertTrue(self.projectRes("files").exists)
            XCTAssertFalse(self.projectRes("notexists").exists)
            XCTAssertTrue(self.existingProjectRes().exists)
            XCTAssertTrue(self.existingProjectRes("files").exists)
            //            try With.errorOrFail { _ = self.existingProjectRes("notexists") }
        }
        subtest {
            class Builder : IBasicBuilder {
                public lazy var conf: IBuilderConf = BasicBuilderConf(
                    project: BasicProject(GAV("group", "project", "0"), File(TestBase.resourcesBundlePath("files/dir1/dir1a"))),
                    builder: BasicProject(GAV("group", "builder", "0"), File(TestBase.resourcesBundlePath("files/dir2/dir2a"))),
                    debugging: true
                )
                public lazy var log: ICoreLogger = TestLogger(true)
                public init() {}
                func test() {
                    log.enter {
                        XCTAssertTrue(self.builderAncestorTree("files/dir1").exists)
                        XCTAssertTrue(self.builderAncestorTree("resources.bundle/html/manual.html").exists)
                        //                try With.errorOrFail { _ = self.builderAncestorTree("") }
                        //                try With.errorOrFail { _ = self.builderAncestorTree("notexists") }
                        //                try With.errorOrFail { _ = self.builderAncestorTree("bot-core") }
                        //                try With.errorOrFail { _ = self.builderAncestorTree("bot-builder/src/notexists") }
                    }
                    log.enter {
                        XCTAssertTrue(self.projectAncestorTree("files/dir2").exists)
                        XCTAssertTrue(self.projectAncestorTree("resources.bundle/html/manual.html").exists)
                        //                try With.errorOrFail { _ = self.projectAncestorTree("") }
                        //                try With.errorOrFail { _ = self.projectAncestorTree("notexists") }
                        //                try With.errorOrFail { _ = self.projectAncestorTree("bot-core") }
                        //                try With.errorOrFail { _ = self.projectAncestorTree("bot-builder/src/notexists") }
                    }
                    log.enter {
                        XCTAssertTrue(self.builderAncestorSiblingTree("dir1").exists)
                        XCTAssertTrue(self.builderAncestorSiblingTree("html/manual.html").exists)
                        //                try With.errorOrFail { _ = self.builderAncestorSiblingTree("") }
                        //                try With.errorOrFail { _ = self.builderAncestorSiblingTree("notexists") }
                        //                try With.errorOrFail { _ = self.builderAncestorSiblingTree("bot-core/src/notexists") }
                    }
                    log.enter {
                        XCTAssertTrue(self.projectAncestorSiblingTree("dir2").exists)
                        XCTAssertTrue(self.projectAncestorSiblingTree("html/manual.html").exists)
                        //                try With.errorOrFail { _ = self.projectAncestorSiblingTree("") }
                        //                try With.errorOrFail { _ = self.projectAncestorSiblingTree("notexists") }
                        //                try With.errorOrFail { _ = self.projectAncestorSiblingTree("bot-core/src/notexists") }
                    }
                }
            }
            Builder().test()
        }
        subtest {
            class Workspace: BasicWorkspace {
                let builderProject = KotlinProject(GAV.of("com.cplusedition.bot:bot-builder:1"))
            }
            let builder = BasicBuilder(
                BasicBuilderConf(
                    project: BasicProject(GAV.of("a/a/1.0")),
                    builder: BasicProject(GAV.of("b/b/1.0")),
                    debugging: false,
                    workspace: Workspace()
                )
            )
            XCTAssertEqual(1, builder.conf.workspace.projects.count)
        }
    }


    func testBuilderConf01() {
        subtest {
            let builder = BasicBuilder(BasicBuilderConf())
            builder.log.enter("test1") {
                builder.log.d("# debug")
            }
            let lines = builder.log.getLog()
            XCTAssertEqual(0, lines.count)
            XCTAssertEqual("0", builder.conf.builder.gav.version.description)
            XCTAssertEqual("0", builder.conf.project.gav.version.description)
        }
        subtest {
            let builder = BasicBuilder(
                BasicBuilderConf(
                    project: BasicProject(GAV.of("a/a/1.0")),
                    builder: BasicProject(GAV.of("b/b/2.0")),
                    debugging: false
                )
            )
            builder.log.enter("test1") {
                builder.log.d("# debug")
            }
            let lines = builder.log.getLog()
            XCTAssertEqual(0, lines.count)
            XCTAssertEqual("2.0", builder.conf.builder.gav.version.description)
            XCTAssertEqual("1.0", builder.conf.project.gav.version.description)
        }
        subtest {
            let builder = BasicBuilder(
                BasicBuilderConf(
                    project: BasicProject(GAV.of("a/a/1.0")),
                    builder: BasicProject(GAV.of("b/b/1.0")),
                    debugging: true
                )
            )
            builder.log.enter("test1") {
                builder.log.d("# debug")
            }
            let output = builder.log.getLog().joined()
            let lines = output.trimmed().lines
            XCTAssertEqual(5, lines.count)
            XCTAssertTrue(output.contains("START"))
            XCTAssertTrue(output.contains("OK"))
            XCTAssertTrue(output.contains("BasicBuilder"))
        }
    }


    func testIBuilderLogger01() {
        subtest {
            let log = BuilderLogger(false, "\(type(of: self))")
            log.enter("test1") {
                log.d("# debug")
            }
            let lines = log.getLog()
            XCTAssertEqual(0, lines.count)
        }
        subtest {
            let log = BuilderLogger(true, "\(type(of: self))")
            log.enter("test1") {
                log.d("# debug")
            }
            let output = log.getLog().joined()
            let lines = output.trimmed().lines
            XCTAssertEqual(5, lines.count)
            XCTAssertTrue(output.contains("START"))
            XCTAssertTrue(output.contains("OK"))
            XCTAssertTrue(output.contains("\(type(of: self))"))
        }
    }


    func testBasicWorkspace01() {
        class Workspace: BasicWorkspace {
            let coreProject = KotlinProject(GAV.of("com.cplusedition.bot:bot-core:1"), File(TestBase.resourcesBundlePath()))
            let builderProject = KotlinProject(GAV.of("com.cplusedition.bot:bot-builder:1"), File(TestBase.resourcesBundlePath()))
        }
        let workspace = Workspace()
        subtest {
            XCTAssertEqual(2, workspace.projects.count)
            XCTAssertTrue(workspace.coreProject.dir.file("files").exists)
            XCTAssertTrue(workspace.builderProject.dir.file("files").exists)
        }
        subtest {
            let project = workspace.builderProject
            XCTAssertEqual("bot-builder", project.gav.artifactId)
            XCTAssertTrue(project.mainSrcs.count == 2)
            XCTAssertTrue(project.testSrcs.count == 2)
            XCTAssertTrue(project.mainRes.name == "resources")
            XCTAssertTrue(project.testRes.name == "resources")
        }
    }


    func testCoreTask01() {
        
        class Task: CoreTask<Int> {
            static let message = "CoreTask: 123"
            static let quietMessage = "!!! Quiet !!!"
            @discardableResult
            override func run() -> Int {
                if (quiet) {
                    log.d(Task.quietMessage)
                } else {
                    log.d(Task.message)
                }
                return 123
            }
            func ok() -> Bool {
                return true
            }
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    XCTAssertEqual(123, task(Task()))
                    XCTAssertTrue(log.getLog().joined().contains(Task.message))
                }
            }
            Builder().test()
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    let task = Task(log)
                    task.run()
                    XCTAssertTrue(task.ok())
                    XCTAssertTrue(log.getLog().joined().contains(Task.message))
                    XCTAssertFalse(log.getLog().joined().contains(Task.quietMessage))
                }
            }
            Builder().test()
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    let task = Task()
                    task.setQuiet(true)
                    XCTAssertTrue(task0(task).ok())
                    XCTAssertTrue(log.getLog().joined().contains(Task.quietMessage))
                }
            }
            Builder().test()
        }
    }

    
    func testBuilderTask01() {
        class Task: BuilderTask<Int> {
            static let quietMessage = "!!! Quiet !!!"
            @discardableResult
            override func run() -> Int {
                log.d("\(type(of: self))")
                if (quiet) {
                    log.d(Task.quietMessage)
                }
                return 123
            }
            
            func ok() -> Bool {
                return true
            }
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    XCTAssertEqual(123, task(Task()))
                    XCTAssertTrue(log.getLog().joined().contains("\(Task.self)"))
                }
            }
            Builder().test()
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    XCTAssertTrue(task0(Task()).ok())
                    XCTAssertTrue(log.getLog().joined().contains("\(Task.self)"))
                    XCTAssertFalse(log.getLog().joined().contains(Task.quietMessage))
                }
            }
            Builder().test()
        }
        subtest {
            class Builder: DebugBuilder {
                func test() {
                    let task = Task(self)
                    task.setQuiet(true)
                    task.run()
                    XCTAssertTrue(task.ok())
                    XCTAssertTrue(log.getLog().joined().contains(Task.quietMessage))
                }
            }
            Builder().test()
        }
    }
}
