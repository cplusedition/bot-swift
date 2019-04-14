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

open class BuilderBase: XCTestCase, IBasicBuilder {

    private var singleTestGuard: Bool = {
        class MyObserver: NSObject, XCTestObservation {
            func testSuiteWillStart(_ testSuite: XCTestSuite) {
                if testSuite.tests.count > 1 {
                    preconditionFailure("Please launch a single method at a time")
                }
            }
        }
        XCTestObservationCenter.shared.addTestObserver(MyObserver())
        return true
    }()
    
    static let GROUP = "com.cplusedition.bot"
    static let VERSION = "1.4"
    
    class Workspace : BasicWorkspace {
        static var singleton = Workspace()
        static let dir = File.home.file("projects/macos/bot-swift/botKit")
        var botKitProject = SwiftProject(GAV(GROUP, "BotKit", VERSION), dir.file("BotKit"))
        var botKitTestsProject = SwiftProject(GAV(GROUP, "BotKitTests", VERSION), dir.file("BotKitTests"))
        var botKitBuildProject = SwiftProject(GAV(GROUP, "BotKitBuild", VERSION), dir.file("BotKitBuild"))
    }

    open var DEBUGGING: Bool {
        return false
    }
    
    public lazy var conf: IBuilderConf = BasicBuilderConf(
            project: Workspace.singleton.botKitBuildProject,
            builder: Workspace.singleton.botKitBuildProject,
            debugging: DEBUGGING,
            workspace: Workspace.singleton)
    
    public lazy var log: ICoreLogger = BuilderLogger(DEBUGGING, "\(type(of: self))")

}
