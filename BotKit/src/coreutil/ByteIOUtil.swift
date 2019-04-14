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

// //////////////////////////////////////////////////////////////////////

public protocol IInputStream {
    // Note that len is Int instead of Int64 here, as in the system InputStream.read() method signature.
    // Since we are going to deal with 64 bit devices only, this should not be a problem.
    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int
    func close()
}

public extension IInputStream {
    func readAsMuchAsPossible(_ ptr: UnsafeMutablePointer<UInt8>, _ length: Int) -> Int {
        var len = length
        var off = 0
        while (len > 0) {
            let n = self.read(ptr + off, maxLength: len)
            if n < 0 { return -1 }
            if n == 0 { break }
            len -= n;
            off += n;
        }
        return length - len
    }
    
    /** Like readFully(), except that it allow partial reads if EOF is reached, and returns number of bytes read. */
    func readAsMuchAsPossible(_ ret: inout [UInt8], _ offset: Int, _ length: Int) -> Int {
        var len = length
        let end = offset + len
        if end > ret.count {
            len = ret.count - offset
        }
        precondition(len > 0)
        let ptr = UnsafeMutablePointer<UInt8>(mutating: ret)
        return readAsMuchAsPossible(ptr + offset, len)
    }
    
    /** Like readFully(), except that it allow partial reads if EOF is reached, and returns number of bytes read. */
    func readAsMuchAsPossible(_ ret: inout Data, _ offset: Int, _ length: Int) -> Int {
        let end = offset + length
        if ret .count < end {
            ret.count = end
        }
        return ret.withUnsafeMutableBytePointer { (ptr: UnsafeMutablePointer<UInt8>) -> Int in
            return readAsMuchAsPossible(ptr + offset, length)
        }
    }
    
    func readFully(_ ptr: UnsafeMutablePointer<UInt8>, _ length: Int) throws {
        var len = length
        var off = 0
        while (len > 0) {
            let n = self.read(ptr + off, maxLength: len)
            if n < 0 { throw ReadException() }
            if n == 0 { throw EOFException() }
            len -= n;
            off += n;
        }
    }
    
    func readFully(_ ret: inout [UInt8]) throws {
        try readFully(&ret, 0, ret.count);
    }
    
    /// Note that an exception is thrown if offset + length is beyond ret.count.
    func readFully(_ ret: inout [UInt8], _ offset: Int, _ length: Int) throws {
        let end = offset + length
        if end > ret.count {
            throw IllegalArgumentException("limit=\(ret.count), offset=\(offset), length=\(length)")
        }
        let ptr = UnsafeMutablePointer<UInt8>(mutating: ret)
        try readFully(ptr + offset, length)
    }
    
    func readFully(_ ret: inout Data) throws {
        try readFully(&ret, 0, ret.count);
    }
    
    /// Note that ret is grow to offset + length to accomodate all the data if neccessary.
    func readFully(_ ret: inout Data, _ offset: Int, _ length: Int) throws {
        let end = offset + length
        if ret .count < end {
            ret.count = end
        }
        try ret.withUnsafeMutableBytePointer { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
            try readFully(ptr + offset, length)
        }
    }
    
    /// Read whole input stream
    func asData() throws -> Data {
        let len = ByteIOUtil.K.BUFSIZE
        var ret = Data(count: len)
        var total = 0
        var n = 0
        repeat {
            let retcount = ret.count
            try ret.withUnsafeMutableBytePointer { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
                n = readAsMuchAsPossible(ptr + total, retcount - total)
                if n < 0 { throw ReadException() }
                total += n
            }
            if n > 0 && (ret.count - total) < ByteIOUtil.K.BUFSIZE {
                ret.count *= 2
            }
        } while n > 0
        ret.count = total
        return ret
    }
    
    func asString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try asData()
        guard let ret = String(data: data, encoding: encoding) else { throw CharacterEncodingException() }
        return ret
    }
}

// //////////////////////////////////////////////////////////////////////

public protocol IOutputStream {
    // Note that len is Int instead of Int64 here, as in the system OutputStream.write() method signature.
    // Since we are going to deal with 64 bit devices only, this should not be a problem.
    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int
    func close()
}

public extension IOutputStream {
    func writeFully(_ ptr: UnsafePointer<UInt8>, _ length: Int) throws {
        var len = length
        var off = 0
        while (len > 0) {
            let n = self.write(ptr + off, maxLength: len)
            if n < 0 { throw WriteException() }
            if n == 0 { throw EOFException() }
            len -= n;
            off += n;
        }
    }
    
    func writeFully(_ data: Data) throws {
        try writeFully(data, 0, data.count)
    }
    
    func writeFully(_ data: Data, _ offset: Int, _ length: Int) throws {
        try data.withUnsafeBytePointer { (ptr: UnsafePointer<UInt8>) -> Void in
            try writeFully(ptr + offset, length)
        }
    }
    
    func writeFully(_ data: [UInt8]) throws {
        let ptr = UnsafePointer(data)
        try writeFully(ptr, data.count)
    }
    
    func writeFully(_ data: [UInt8], _ offset: Int, _ length: Int) throws {
        let ptr = UnsafePointer(data)
        try writeFully(ptr + offset, length)
    }
    
    func writeFully(_ string: String, _ encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw CharacterEncodingException()
        }
        try writeFully(data)
    }
    
}

// //////////////////////////////////////////////////////////////////////

public protocol IInputStreamProvider {
    func getInputStream() throws -> IInputStream
}

// //////////////////////////////////////////////////////////////////////

public class ByteIOUtil {

    public struct K {
        // The defualt buffer size.
        public static let BUFSIZE = 8192
        public static let BUFSIZE4 = BUFSIZE * 4
    }

    // //////////////////////////////////////////////////////////////////////
    
    public static let isLittleEndian = UInt16(0x1234).littleEndian == 0x1234

    //    // //////////////////////////////////////////////////////////////////////
    
    /// Copy everything available from the input to the output.
    public static func copy(to: IOutputStream, from: IInputStream) throws {
        let len = K.BUFSIZE
        var buf = [UInt8](repeating: 0, count: len)
        var n: Int
        while true {
            n = from.readAsMuchAsPossible(&buf, 0, len)
            if n < 0 { throw ReadException() }
            if n == 0 { break }
            try to.writeFully(buf, 0, n)
        }
    }
    
}

// ////////////////////////////////////////////////////////////////////////

open class ByteInputStream: IInputStream {
    private let myStream: MyStream
    public init(_ data: Data) {
        self.myStream = MyStream(data: data)
        // super.init(myStream)
    }
    public init(_ bytes: [UInt8]) {
        self.myStream = MyStream(bytes: bytes)
        // super.init(myStream)
    }
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return myStream.read(buffer, maxLength: len)
    }
    open func close() {
        myStream.close()
    }
    class MyStream: IInputStream {
        private let data: Data
        private var position = 0
        init(data: Data) {
            self.data = data
        }
        init(bytes: [UInt8]) {
            self.data = Data(bytes)
        }
        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            let available = data.count - position
            if available <= 0 { return 0 }
            let count = (len > available) ? available : len
            if count > 0 {
                let end = position + count
                data.copyBytes(to: buffer, from: position..<end)
                position = end
            }
            return count
        }
        func close() {
        }
    }
}

// ////////////////////////////////////////////////////////////////////////

public protocol IBufferedInputStream: IInputStream {
    /// Note that this may or may not block, depending on the underlying stream.
    /// For IBufferedInputStream, this can be more efficient and convenient than using read(buffer, maxLength)
    func read() throws -> UInt8?
    func readline() throws -> String?
    func readline(_ encoding: String.Encoding) throws -> String?
}

public extension IBufferedInputStream {
    func readline() throws -> String? {
        return try readline(.utf8)
    }
    func readline(_ encoding: String.Encoding) throws -> String? {
        var line = Bytes(reserve: 256)
        var prev: Byte? = nil
        while let byte = try self.read() {
            if byte == 0x0a {
                if prev == 0x0d {
                    line.removeLast()
                }
                return String(bytes: line, encoding: encoding)
            }
            line.append(byte)
            prev = byte
        }
        return line.isEmpty ? nil : String(bytes: line, encoding: encoding)
    }
}

open class BufferedInputStream: IBufferedInputStream {
    private let _input: IInputStream
    private var _buf: Data
    private var _position: Int
    private var _limit: Int
    public init(_ input: IInputStream, bufsize: Int = ByteIOUtil.K.BUFSIZE4) {
        self._input = input
        self._buf = Data(count: bufsize)
        self._position = 0
        self._limit = 0
    }
    /// Read as much as possible from the input stream.
    /// @return -1 on error, 0 for end of input, else the number of bytes read.
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength length: Int)  -> Int {
        let available = _limit - _position
        if length <= available {
            let end = _position + length
            _buf.copyBytes(to: buffer, from: _position..<end)
            _position = end
            return length
        }
        var off = 0
        var len = length
        if available > 0 {
            _buf.copyBytes(to: buffer, from: _position..<_limit)
            off = available
            len -= available
        }
        _position = 0
        _limit = 0
        // Our buffer is now empty, if still need more than half of the bufsize,
        // we copy directly to the destination, otherwise, we fill our buffer and
        // move data to destination from there.
        if len >= (_buf.count / 2) {
            let ret = _input.readAsMuchAsPossible(buffer + off, len)
            if ret < 0 { return -1 }
            return off + ret
        }
        let ret = fill()
        if ret < 0 { return -1 }
        if ret == 0 { return off }
        _limit = ret
        if len > _limit {
            len = _limit
        }
        _buf.copyBytes(to: buffer + off, count: len)
        _position += len
        return off + len
    }
    public func close() {
        _input.close()
    }
    public func read() throws -> UInt8? {
        let available = _limit - _position
        if available > 0 {
            _position += 1
            return _buf[_position - 1]
        }
        _position = 0
        _limit = 0
        let ret = fill()
        if ret < 0 { throw ReadException() }
        if ret == 0 { return nil }
        _limit = ret
        _position = 1
        return _buf[0]
    }
    private func fill() -> Int {
        let count = _buf.count
        return _buf.withUnsafeMutableBytePointer { (ptr: UnsafeMutablePointer<UInt8>) -> Int in
            return _input.read(ptr, maxLength: count)
        }
    }
}

// ////////////////////////////////////////////////////////////////////////

