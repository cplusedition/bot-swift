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

open class Exception: Error, CustomStringConvertible {
    private var message: String?
    public init(_ msg: String? = nil) {
        self.message = msg
    }
    public var description: String {
        return self.message ?? TextUtil.classname(self)
    }
}

open class OutOfBoundException: Exception {
    public init(limit: Int64, actual: Int64) {
        super.init("Limit=\(limit), actual=\(actual)")
    }
    public init(limit: Int, actual: Int) {
        super.init("Limit=\(limit), actual=\(actual)")
    }
}

open class IOException: Exception {
}

open class ReadException: IOException {
}

open class WriteException: IOException {
}

open class EOFException: IOException {
}

open class FileNotFoundException: IOException {
}

open class IllegalArgumentException: Exception {
}

open class IllegalStateException: Exception {
}

open class UnsupportedOperationException: Exception {
}

open class TimeoutException: Exception {
}

open class ConcurrentModificationException: Exception {
}

open class DontCareException: Exception {
}

open class CharacterEncodingException: Exception {
}

open class CharacterDecodingException: Exception {
}

public struct Assert {

    public static func fail(_ msg: String = "") -> Never {
        preconditionFailure(msg)
    }

    public static func notReach(_ msg: String = "") -> Never {
        preconditionFailure(msg)
    }
}

