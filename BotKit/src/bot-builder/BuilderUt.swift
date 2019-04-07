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

//////////////////////////////////////////////////////////////////////

public let BU = BuilderUtil()

open class BuilderUtil {

    /**
     * Walk up to the ancestors and return the first subtree that exists. For example:
     *      ancestorTree("workspace/opt/loca/bin")
     * look for an ancestor named workspace that contains a subtree opt/local/bin.
     *
     * @return The bottom most file/dir of the subtree or null if not found.
     * In the example above, it returns the bin directory.
     */
    public func ancestorTree(_ tree: String, _ dir: File? = nil) -> File? {
        if tree.isEmpty { return nil }
        let (first, second) = TextUtil.split2(tree, sep: File.SEP)
        var parent = dir ?? File.pwd
        while (true) {
            guard let p = parent.parent else { return nil }
            parent = p
            if (p.name == first) {
                if (second == nil) {
                    return p
                } else {
                    let subdir = File(p, second)
                    if (subdir.exists) {
                        return subdir
                    }
                }
            }
        }
    }

    /**
     * Walk up the ancestor, look at its siblings and return the first subtree that exists. For example:
     *      ancestorSiblingTree("workspace/opt/loca/bin")
     * look for an ancestor with a child called workspace and contains a subtree opt/local/bin.
     *
     * @return The bottom most file/dir of the subtree or null if not found.
     * In the example above, it returns the bin directory.
     */
    public func ancestorSiblingTree(_ tree: String, _ dir: File? = nil) -> File? {
        if tree.isEmpty { return nil }
        let (first, second) = TextUtil.split2(tree, sep: File.SEP)
        var parent = dir ?? File.pwd
        while (true) {
            guard let p = parent.parent else { return nil }
            parent = p
            for name in p.listOrEmpty() {
                if (name == first) {
                    guard let second = second else {
                        return File(p, name)
                    }
                    let subdir = File(p, "\(name)\(File.SEPCHAR)\(second)")
                    if (subdir.exists) {
                        return subdir
                    }
                }
            }
        }
    }

    /**
     * @return A human readable size string, eg 1210 kB.
     */
    public func filesizeString(_ size: Int64) -> String {
        return TextUtil.sizeUnit4String(size) + "B"
    }
    
    /**
     * @return A human readable size string, eg 1210 kB, where k is 1000.
     */
    public func filesizeString(_ file: File) -> String {
        return filesizeString(file.length)
    }
    
    public func fail(_ msg: String = "") -> Never {
        preconditionFailure(msg)
    }
}

//////////////////////////////////////////////////////////////////////

extension File {
    
    public func existsOrFail() -> File {
        guard exists else { BU.fail("\(#function): \(self.path)") }
        return self
    }
    
    public func mkdirsOrFail() -> File {
        guard let _ = mkdirs() else { BU.fail("\(#function): \(self.path)") }
        return self
    }
    
    public func mkparentOrFail() -> File {
        guard let _ = mkparent() else { BU.fail("\(#function): \(self.path)") }
        return self
    }
}

extension Treewalker {
    func findOrFail(_ accept: IFilePathPredicate) -> File {
        guard let ret = find(accept) else { BU.fail("\(#function): \(dir.path)") }
        return ret
    }
}

//////////////////////////////////////////////////////////////////////

