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

public typealias Byte = UInt8
public typealias Bytes = [UInt8]
public typealias ByteRange = (Int?, Int?)
public typealias ByteRanges = [ByteRange]

public typealias Char16 = UTF16.CodeUnit

public typealias Fun00 = () -> Void
public typealias Fun10<T> = (T) -> Void
public typealias Fun20<T1, T2> = (T1, T2) -> Void
public typealias Fun30<T1, T2, T3> = (T1, T2, T3) -> Void

public typealias Fun00x = () throws -> Void
public typealias Fun10x<T> = (T) throws -> Void
public typealias Fun20x<T1, T2> = (T1, T2) throws -> Void
public typealias Fun30x<T1, T2, T3> = (T1, T2, T3) throws -> Void

public typealias Fun01<R> = () -> R
public typealias Fun11<T1, R> = (T1) -> R
public typealias Fun21<T1, T2, R> = (T1, T2) -> R
public typealias Fun31<T1, T2, T3, R> = (T1, T2, T3) -> R

public typealias Fun01x<R> = () throws -> R
public typealias Fun11x<T1, R> = (T1) throws -> R
public typealias Fun21x<T1, T2, R> = (T1, T2) throws -> R
public typealias Fun31x<T1, T2, T3, R> = (T1, T2, T3) throws -> R

public typealias IPredicate0 = () -> Bool
public typealias IPredicate1<T> = (T) -> Bool
public typealias IPredicate2<T1, T2> = (T1, T2) -> Bool
public typealias IPredicate3<T1, T2, T3> = (T1, T2, T3) -> Bool

public protocol StringIterator: IteratorProtocol where Element==String {}
public protocol StringSequence: Sequence where Element==String {}
public protocol StringCollection: Collection where Element==String {}

public protocol Cloneable {
}

public protocol Serializable {
}

public protocol Closeable {
    func close()
}
