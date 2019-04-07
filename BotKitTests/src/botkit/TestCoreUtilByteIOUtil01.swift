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

class TestCoreUtilByteIOUtil01: TestBase {

    override var DEBUGGING: Bool {
        return false
    }
    
    let M: UInt32 = 1000 * 1000

    func testBufferedInputStream01() throws {
        subtest {
            /// A small test
            let bytes = RandUtil.getBytes(1000)
            let input = ByteInputStream(bytes)
            let buffered = BufferedInputStream(input, bufsize: 64)
            defer { buffered.close() }
            var output = [UInt8](repeating: 0, count: bytes.count)
            let ptr = UnsafeMutablePointer(&output)
            var off = 0
            while off < bytes.count {
                let n = RandUtil.getUInt32(1, 200)
                let read = buffered.read(ptr + off, maxLength: Int(n))
                XCTAssertTrue(read >= 0)
                off += read
                XCTAssertTrue(off <= bytes.count)
            }
            XCTAssertTrue(bytes == output)
        }
        try subtest {
            /// Check read()
            let bytes = RandUtil.getBytes(1234)
            let input = ByteInputStream(bytes)
            let buffered = BufferedInputStream(input, bufsize: 64)
            defer { buffered.close() }
            var output = [UInt8]()
            while true {
                guard let ret = try buffered.read() else {
                    break
                }
                output.append(ret)
            }
            XCTAssertTrue(bytes == output)
        }
    }
    
    func testPerfBufferedInputStreamBulkRead01() throws {
        /// Same as above, but copy more
        let bytes = RandUtil.getBytes(Int(RandUtil.getUInt32(M, 2*M)))
        var output = [UInt8](repeating: 0, count: bytes.count)
        let input = ByteInputStream(bytes)
        defer { input.close() }
        let buffered = BufferedInputStream(input, bufsize: ByteIOUtil.K.BUFSIZE * 2)
        output = [UInt8](repeating: 0, count: bytes.count)
        let ptr = UnsafeMutablePointer(&output)
        var off = 0
        while true {
            let n = RandUtil.getUInt32(1, UInt32(ByteIOUtil.K.BUFSIZE4 + 100))
            let read = buffered.read(ptr + off, maxLength: Int(n))
            XCTAssertTrue(read >= 0)
            if read == 0 {
                break
            }
            off += read
            XCTAssertTrue(off <= bytes.count)
        }
        XCTAssertTrue(bytes == output)
    }
    
    /// Check read()
    func testPerfBufferedInputStreamRead01() throws {
        let bytes = RandUtil.getBytes(Int(RandUtil.getUInt32(M, 2*M)))
        var output = [UInt8]()
        do {
            let input = ByteInputStream(bytes)
            defer { input.close() }
            let buffered = BufferedInputStream(input, bufsize: ByteIOUtil.K.BUFSIZE*2)
            output = [UInt8]()
            while true {
                guard let ret = try buffered.read() else {
                    break
                }
                output.append(ret)
            }
        } catch {
            XCTFail()
        }
        XCTAssertTrue(bytes == output)
    }
    
    /// Check mixed read(buffer) and read()
    func testPerfBufferedInputStreamMixed01() throws {
        let ITER = 10
        for _ in 0..<ITER {
            /// A mix fo read() and read(buffer, maxLength)
            let bytes = RandUtil.getBytes(Int(RandUtil.getUInt32(M, 2 * M)))
            var output = [UInt8](repeating: 0, count: bytes.count)
            do {
                let input = ByteInputStream(bytes)
                defer { input.close() }
                let buffered = BufferedInputStream(input, bufsize: ByteIOUtil.K.BUFSIZE * 2)
                output = [UInt8](repeating: 0, count: bytes.count)
                let ptr = UnsafeMutablePointer(&output)
                var off = 0
                DONE: while true {
                    let n = RandUtil.getUInt32(1, UInt32(ByteIOUtil.K.BUFSIZE4 + 100))
                    if n & 0x1 == 0 {
                        guard let read  = try buffered.read() else {
                            break DONE;
                        }
                        output[off] = read
                        off += 1
                        continue
                    }
                    let read = buffered.read(ptr + off, maxLength: Int(n))
                    XCTAssertTrue(read >= 0)
                    if read == 0 {
                        break
                    }
                    off += read
                    XCTAssertTrue(off <= bytes.count)
                }
            } catch {
                XCTFail()
            }
            XCTAssertTrue(bytes == output)
        }
    }

    func testWriteFullyData01() throws {
        let expected = RandUtil.getData(Int(RandUtil.getUInt32(M, 2 * M)))
        // Write data in one shot
        try subtest {
            let file1 = self.tmpFile()
            if true {
                let output = try FileUtil.openOutputStream( file1.path)
                defer { output.close() }
                try output.writeFully(expected)
            }
            try XCTAssertTrue(expected == file1.readData())
        }
        // Write data in pieces
        try subtest {
            let file2 = self.tmpFile()
            if true {
                let output = try FileUtil.openOutputStream(file2.path)
                defer { output.close() }
                var off = 0
                var len = expected.count
                let chunk = 100*1024
                while len > chunk {
                    try output.writeFully(expected, off, chunk)
                    off += chunk
                    len -= chunk
                }
                try output.writeFully(expected, off, len)
            }
            try XCTAssertTrue(expected == file2.readData())
        }
    }
    
    func testWriteFullyBytes01() throws {
        let expected = RandUtil.getBytes(Int(RandUtil.getUInt32(M, 2 * M)))
        // Write data in one shot
        try subtest {
            let file1 = self.tmpFile()
            if true {
                let output = try FileUtil.openOutputStream(file1.path)
                defer { output.close() }
                try output.writeFully(expected)
            }
            try XCTAssertTrue(expected == file1.readBytes())
        }
        // Write bytes in pieces
        try subtest {
            let file2 = self.tmpFile()
            if true {
                let output = try FileUtil.openOutputStream(file2.path)
                defer { output.close() }
                var off = 0
                var len = expected.count
                let chunk = 100*1024
                while len > chunk {
                    try output.writeFully(expected, off, chunk)
                    off += chunk
                    len -= chunk
                }
                try output.writeFully(expected, off, len)
            }
            try XCTAssertTrue(expected == file2.readBytes())
        }
    }
    
    func testWriteFullyString01() throws {
        let expected = try testResDir.file("html/manual.html").readText()
        // Write data in one shot
        try subtest {
            let file1 = self.tmpFile()
            if true {
                let output = try FileUtil.openOutputStream(file1.path)
                defer { output.close() }
                try output.writeFully(expected)
            }
            try XCTAssertTrue(expected == file1.readText())
        }
    }
}

