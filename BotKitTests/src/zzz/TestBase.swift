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

/**
 * Base class for tests.
 */
open class TestBase : XCTestCase, ITestBuilder {

    open var DEBUGGING: Bool {
        return false
    }
    public lazy var conf: IBuilderConf = BasicBuilderConf(
        debugging: DEBUGGING,
        projectdir: testResDir,
        builderdir: testResDir)
    public lazy var log: ICoreLogger = TestLogger(DEBUGGING)
    public var tmpdir = FileUtil.createTempDir()

    open override func setUp() {
        log.enter(testRun?.test.name)
        tmpdir.deleteTree()
        tmpdir = FileUtil.createTempDir()
    }
    
    open override func tearDown() {
        log.leave(nil)
        tmpdir.deleteTree()
    }
    
    public func testResPath(_ rpath: String? = nil) -> String {
        return TestBase.resourcesBundlePath(rpath)
    }
    
    public static func resourcesBundlePath(_ rpath: String? = nil) -> String {
        guard var url = Bundle(for: TestBase.self).resourceURL?.appendingPathComponent("resources.bundle", isDirectory: true) else {
            preconditionFailure()
        }
        if rpath != nil {
            url = url.appendingPathComponent(rpath!, isDirectory: false)
        }
        return url.path
    }
    
    //////////////////////////////////////////////////////////////////////

    struct SuiteConf {
        let lengthy: Bool
        let performance: Bool
        let screenshots: Bool
        
        static let QUICK = SuiteConf(lengthy: false, performance: false, screenshots: false)
        static let LENGTHY = SuiteConf(lengthy: true, performance: false, screenshots: false)
        static let STANDARD = SuiteConf(lengthy: true, performance: true, screenshots: false)
        static let FULL = SuiteConf(lengthy: true, performance: true, screenshots: true)
    }
    
    let suite = SuiteConf.FULL
    
    func lengthy(_ desc: String = "", _ code: @escaping Fun00) {
        if (suite.lengthy) {
            subtest(desc, code)
        } else {
            log.d("# Ignored lengthy test: \(desc)")
        }
    }
}

/// InputStream for testing. Return -1 instead of 0 on EOF and beyond.
class TestErrorInputStream: ByteInputStream {
    init(_ len: Int) {
        let data = RandUtil.getData(len)
        super.init(data)
    }
    override init(_ data: Data) {
        super.init(data)
    }
    override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let ret = super.read(buffer, maxLength: len)
        if ret == 0 { return -1}
        return ret
    }
}

//////////////////////////////////////////////////////////////////////

