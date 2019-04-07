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

public struct RandUtil {
    
    private static let UMAX = UInt(Int.max)
    private static let ALPHANUM = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".data(using: .ascii)!;

    public static func get(to : UnsafeMutablePointer<UInt8>, length: Int) {
        let rc = SecRandomCopyBytes(kSecRandomDefault, length, to)
        precondition(rc == 0, "# rc=\(rc)")
    }
    
   public static func get(to : inout [UInt8]) {
        let rc = SecRandomCopyBytes(kSecRandomDefault, to.count, &to)
        precondition(rc == 0, "# rc=\(rc)")
    }
    
   public static func get(to: inout Data) {
        let count = to.count;
        to.withUnsafeMutableBytes { (buf:UnsafeMutablePointer<UInt8>) -> Void in
            let rc = SecRandomCopyBytes(kSecRandomDefault, count, buf)
            precondition(rc == 0, "# rc=\(rc)")
        }
    }
    
    public static func getBool() -> Bool {
        var ret = UInt8(0)
        get(to: &ret, length: 1)
        return (ret & 0x1) == 1
    }

    public static func getInt32() -> Int32 {
        return Int32(bitPattern: getUInt32())
    }
    
    public static func getUInt32() -> UInt32 {
        var to = Data(count: 4)
        return to.withUnsafeMutableBytes { (buf:UnsafeMutablePointer<UInt8>) -> UInt32 in
            let rc = SecRandomCopyBytes(kSecRandomDefault, 4, buf)
            precondition(rc == 0, "rc=\(rc),");
            return shift(buf[0], 24) | shift(buf[1], 16) | shift(buf[2], 8) | UInt32(buf[3])
        }
    }
        
    /// Return an UInt32 in range (min..<max]
    public static func getUInt32(_ min: UInt32, _ max: UInt32) -> UInt32 {
        precondition(min < max)
        return min + getUInt32() % (max - min)
    }
    
    public static func getBytes(_ count: Int) -> [UInt8] {
        var ret = [UInt8](repeating: 0, count: count)
        get(to: &ret)
        return ret
    }
    
    public static func getData(_ count: Int) -> Data {
        var ret = Data(count: count)
        get(to: &ret)
        return ret
    }
    
    /**
     * @return A word that consists of only [0-9,a-z,A-Z]
     */
   public static func getWord(length: Int) -> String  {
        var buf = [UInt8](repeating: 0, count: length);
        RandUtil.get(to: &buf);
        let ret = buf.map { b in return ALPHANUM[Int(b % 62)]}
        return String(bytes: ret, encoding: .ascii)!
    }

    private static func shift(_ value: UInt8, _ shift: UInt32) -> UInt32 {
        return UInt32(value) << shift;
    }
    
}
