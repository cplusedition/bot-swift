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

open class SystemLogger: ILog {
    
    private let debugging: Bool

    public init(debugging: Bool = true) {
        self.debugging = debugging
    }

    public func d(_ msg: String) {
        if (debugging) {
            print(msg)
        }
    }

    public func i(_ msg: String) {
        print(msg)
    }
    
    public func w(_ msg: String) {
        print(msg)
    }
    
    public func e(_ msg: String) {
        print(msg)
    }
    
    public func d(_ msg: String, _ e: Error?) {
        if (debugging) {
            print(msg)
            if let err = e {
                print("\(err)")
            }
        }
    }

    public func i(_ msg: String, _ e: Error?) {
        print(msg)
        if debugging,
            let err = e {
            print("\(err)")
        }
    }

    public func w(_ msg: String, _ e: Error?) {
        print(msg)
        if debugging,
            let err = e {
            print("\(err)")
        }
    }

    public func e(_ msg: String, _ e: Error?) {
        print(msg)
        if let err = e {
            print("\(err)")
        }
    }
}

open class StringLogger: ILog {

    private let debugging: Bool
    private let out = StringPrintWriter()

    public init(_ debugging: Bool = true) {
        self.debugging = debugging
    }

    public func d(_ msg: String) {
        if (debugging) {
            out.println(msg)
        }
    }
    
    public func i(_ msg: String) {
        out.println(msg)
    }
    
    public func w(_ msg: String) {
        out.println(msg)
    }
    
    public func e(_ msg: String) {
        out.println(msg)
    }
    
    public func d(_ msg: String, _ e: Error?) {
        if (debugging) {
            out.println(msg)
            if let err = e {
                out.println("\(err)")
            }
        }
    }

    public func i(_ msg: String, _ e: Error?) {
        out.println(msg)
        if debugging,
            let err = e {
            out.println("\(err)")
        }
    }

    public func w(_ msg: String, _ e: Error?) {
        out.println(msg)
        if debugging,
            let err = e {
            out.println("\(err)")
        }
    }

    public func e(_ msg: String, _ e: Error?) {
        out.println(msg)
        if let err = e {
            out.println("\(err)")
        }
    }
    
    public func toString() -> String {
        return out.toString()
    }
}

