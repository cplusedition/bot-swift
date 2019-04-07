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

class TestBuilder : BuilderBase {
    
    override var DEBUGGING: Bool {
        return false
    }

    func testDebugOff() {
        let regex = try! Regex("(?s)(var\\s+DEBUGGING\\s*:\\s+Bool\\s*\\{\\s*return)\\s+(true|super\\.DEBUGGING)")
        task(SetDebug { regex.finding($0)?.replaceAll("$1 false") ?? $0 })
    }

    func testDebugOn() {
        let regex = try! Regex("(?s)(var\\s+DEBUGGING\\s*:\\s+Bool\\s*\\{\\s*return)\\s+(false|super\\.DEBUGGING)")
        task(SetDebug { regex.finding($0)?.replaceAll("$1 true") ?? $0 })
    }

    class SetDebug: CoreTask<Void> {

        private let code: Fun11<String, String>

        init(_ code: @escaping Fun11<String, String>) {
            self.code = code
            
        }
        override func run() {
            for project in [Workspace.singleton.botKitTestsProject, Workspace.singleton.botKitBuildProject] {
                let dir = (project as SwiftProject).srcDir
                log.d("### \(dir.path)")
                var count = 0
                dir.walker.files { file, rpath in
                    if (!rpath.hasSuffix(".swift")) { return }
                    do {
                        let content = try file.readText()
                        let output = code(content)
                        if (output != content) {
                            try file.writeText(output)
                            log.d("# \(rpath): modified")
                            count += 1
                        }
                    } catch let e {
                        log.e("# ERROR: \(rpath)", e)
                    }
                }
                log.d("## \(count) modified")
            }
        }
    }
}
