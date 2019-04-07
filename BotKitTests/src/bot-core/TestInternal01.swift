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
@testable import BotKit

class TestInternal01: TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    func testCoreLogger01() {
        XCTAssertEqual("  0.00", CoreLogger.fmt(0))
        XCTAssertEqual(" 12.34", CoreLogger.fmt(12.34))
        XCTAssertEqual("999.78", CoreLogger.fmt(999.78))
        XCTAssertEqual("  1000", CoreLogger.fmt(1000.78))
        XCTAssertEqual("123456", CoreLogger.fmt(123456.78))
        XCTAssertEqual("999999", CoreLogger.fmt(999999.12))
        XCTAssertEqual("9999999", CoreLogger.fmt(9999999.99))
    }
}
