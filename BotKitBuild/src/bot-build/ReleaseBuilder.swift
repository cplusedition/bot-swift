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

class ReleaseBuilder: BuilderBase {

    open override var DEBUGGING: Bool {
        return false
    }

    func testSanityCheck() {
        log.i("# zipfile: \(Dist.zipfile.path)")
        for project in conf.workspace.projects {
            log.i("# \(project.gav.artifactId)")
        }
        XCTAssertEqual(3, conf.workspace.projects.count)
    }
    
    func testDistSrcZip() throws {
        let zipfile = Dist.zipfile.mkparentOrFail()
        let workdir = Workspace.singleton.botKitProject.dir.parent!
        func zip() throws {
            log.i("# Zip file: \(zipfile.path)")
            _ = zipfile.delete()
            var files = 0
            log.d(try ProcessUtil.Builder("/usr/bin/zip",  "-ry", zipfile.path, "-@" )
                .workdir(workdir)
                .input { out in
                    for fileset in Dist.filesets {
                        let name = fileset.dir.name
                        fileset.walk { _, rpath in
                            files += 1
                            out.write("\(name)\(File.SEPCHAR)\(rpath)\n".data)
                        }
                    }
                    Fileset(Workspace.dir).includes(Dist.srcs).walk { _, rpath in
                        files += 1
                        out.write("\(rpath)\n".data)
                    }

                }.backtick().wait())
            log.i("# Zip \(zipfile.name): \(files) files, \(BU.filesizeString(zipfile))")
        }
        func checksum() throws {
            let checksumfile = try zipfile.sibling(zipfile.name + ".sha256")
            log.i("# Checksum file: \(checksumfile.path)")
            try checksumfile.writeText(
                try ProcessUtil.Builder("/usr/bin/shasum", "-a", "256", zipfile.path)
                .workdir(workdir)
                .backtick().wait())
        }
        try log.enterX(#function) {
            try zip()
            try checksum()
        }
    }
    
    func testFixCopyrights() throws {
        let copyright = try Workspace.singleton.botKitProject.dir.file("COPYRIGHT").existsOrFail().readText()
        let regex = try! Regex("(?si)\\s*/\\*.*?Cplusedition Limited.*?\\s+All rights reserved.*?\\*/\\s*")
        for project in conf.workspace.projects {
            log.i("### \(project.gav.artifactId)")
            guard project is SwiftProject else { return }
            var modified = Array<String>()
            try Fileset(project.dir).includes("*.h", "src/**/*.swift").walk { file, rpath in
                let text = try file.readText()
                if text.hasPrefix(copyright) { return }
                let output = copyright + regex.matcher(text).replaceAll("")
                try file.writeText(output)
                log.i("\(rpath): modified")
                modified.append(rpath)
            }
            log.i("# Updated \(modified.count) files")
        }
    }

    class Dist {
        static let zipfile = Workspace.dir.parent!.file(
            "dist/\(Workspace.singleton.botKitProject.gav.artifactId)-\(VERSION)-\(DateUtil.today)-src.zip")
        static let srcs = [
            "src/**/*.swift",
            "*.h",
            "Info.plist",
            "COPYRIGHT",
            "LICENSE.txt",
            "README.md",
            ".gitignore"
        ]
        static let filesets = [
            Fileset(Workspace.singleton.botKitProject.dir).includes(srcs).includes("docs/**"),
            Fileset(Workspace.singleton.botKitTestsProject.dir).includes(srcs).includes("resources.bundle/**"),
            Fileset(Workspace.singleton.botKitBuildProject.dir).includes(srcs),
        ]
    }
}
