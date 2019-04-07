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

class TestByteIOUtil02: TestBase {
    
    override var DEBUGGING: Bool {
        return false
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func randsize() -> Int {
        return Int(RandUtil.getUInt32(1000*1000, 3000*1000))
    }
    
    func testAsDataCount01() throws {
        subtest() {
            let count = 200
            var data = Data(count: 0)
            for i in 0..<count {
                data.count = i+1
                data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>)  -> Void in
                    (ptr+i).pointee = UInt8(i)
                }
            }
            for i in 0..<count {
                XCTAssertEqual(UInt8(i), data[i])
            }
        }
        subtest {
            var data = Data(count: 10)
            for v in data {
                XCTAssertEqual(0, v)
            }
            data.count += 1024 * 1024
            for i in 900*1024..<1024*1024 {
                XCTAssertEqual(0, data[i])
            }
        }
    }
    
    func testReadAsMuchAsPossible01() {
        subtest {
            let input = ByteInputStream([UInt8]())
            var output = [UInt8](repeating: 0, count: 128)
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 128))
        }
        subtest {
            let input = ByteInputStream([UInt8](repeating: 9, count: 1))
            var output = [UInt8](repeating: 0, count: 128)
            XCTAssertEqual(1, input.readAsMuchAsPossible(&output, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 128))
            XCTAssertEqual(9, output[0])
        }
        subtest("error") {
            let input = TestErrorInputStream(9)
            var output = [UInt8](repeating: 0, count: 128)
            XCTAssertEqual(-1, input.readAsMuchAsPossible(&output, 128))
        }
        subtest {
            let input = ByteInputStream([UInt8]())
            var output = [UInt8](repeating: 0, count: 128)
            var data = Data(count: 128)
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 0, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 0, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&data, 0, 128))
            XCTAssertEqual(0, output[0])
            XCTAssertEqual(0, data[0])
        }
        subtest("bytes") {
            let input = ByteInputStream([UInt8](repeating: 9, count: 1))
            var output = [UInt8](repeating: 0, count: 128)
            XCTAssertEqual(1, input.readAsMuchAsPossible(&output, 0, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&output, 1, 128))
            XCTAssertEqual(9, output[0])
            XCTAssertEqual(0, output[1])
        }
        subtest("data") {
            let input = ByteInputStream([UInt8](repeating: 9, count: 1))
            var data = Data(count: 128)
            XCTAssertEqual(1, input.readAsMuchAsPossible(&data, 0, 128))
            XCTAssertEqual(0, input.readAsMuchAsPossible(&data, 1, 128))
            XCTAssertEqual(9, data[0])
            XCTAssertEqual(0, data[1])
        }
        subtest("bytes error") {
            let input = TestErrorInputStream(9)
            var output = [UInt8](repeating: 0, count: 128)
            XCTAssertEqual(9, input.readAsMuchAsPossible(&output, 0, 9))
            XCTAssertEqual(-1, input.readAsMuchAsPossible(&output, 9, 9))
        }
        subtest("data error") {
            let input = TestErrorInputStream(9)
            var data = Data(count: 128)
            XCTAssertEqual(9, input.readAsMuchAsPossible(&data, 0, 9))
            XCTAssertEqual(-1, input.readAsMuchAsPossible(&data, 9, 9))
        }
    }
    
    func testReadFully01() throws {
        try subtest {
            let input = ByteInputStream([UInt8]())
            var output = [UInt8](repeating: 0, count: 128)
            var data = Data(count: 128)
            try input.readFully(&output, 0)
            try input.readFully(&output, 0, 0)
            try input.readFully(&output, 0, 0)
            try input.readFully(&data, 0, 0)
        }
        try subtest("bytes") {
            var output = [UInt8](repeating: 0, count: 128)
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                var output = [UInt8](repeating: 0, count: 2)
                try input.readFully(&output)
            }
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&output, 0)
                try input.readFully(&output, 2)
            }
            XCTAssertTrue(With.error {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&output, 3)
                } is EOFException)
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&output, 1)
                try input.readFully(&output, 1)
            }
            XCTAssertTrue(With.error {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&output, 0, 1)
                try input.readFully(&output, 1, 1)
                try input.readFully(&output, 2, 1)
                } is EOFException)
            XCTAssertTrue(With.error {
                let input = TestErrorInputStream(2)
                var output = [UInt8](repeating: 0, count: 4)
                try input.readFully(&output)
                } is ReadException)
            XCTAssertTrue(With.error {
                let input = ByteInputStream([UInt8](repeating: 9, count: 10))
                var output = [UInt8](repeating: 0, count: 4)
                try input.readFully(&output, 0, 8)
                } is IllegalArgumentException)
            XCTAssertTrue(With.error {
                let input = TestErrorInputStream(2)
                var output = [UInt8](repeating: 0, count: 2)
                try input.readFully(&output, 0, 4)
                } is IllegalArgumentException)
        }
        try subtest("data") {
            var data = Data(count: 128)
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                var data = Data(count: 2)
                try input.readFully(&data)
            }
            XCTAssertTrue(With.error {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&data, 0, 3)
                } is EOFException)
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&data, 0, 1)
                try input.readFully(&data, 1, 1)
            }
            XCTAssertTrue(With.error {
                let input = ByteInputStream([UInt8](repeating: 9, count: 2))
                try input.readFully(&data, 0, 1)
                try input.readFully(&data, 1, 1)
                try input.readFully(&data, 2, 1)
                } is EOFException)
            XCTAssertTrue(With.error {
                let input = TestErrorInputStream(2)
                var data = Data(count: 4)
                try input.readFully(&data)
                } is ReadException)
            XCTAssertTrue(With.error {
                let input = TestErrorInputStream(2)
                try input.readFully(&data, 0, 3)
                } is ReadException)
            if true {
                let input = ByteInputStream([UInt8](repeating: 9, count: 10))
                var data = Data(count: 4)
                try input.readFully(&data, 0, 8)
                XCTAssertEqual(8, data.count)
            }
        }
    }
}
