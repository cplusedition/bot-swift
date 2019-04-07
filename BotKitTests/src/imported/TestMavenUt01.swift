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

class TestMavenUt01 : TestBase {
    
    open override var DEBUGGING: Bool {
        return false
    }
    
    func testGA01() throws {
        func check(_ groupid: String?, _ artifactid: String?, _ ga: GA?) {
            XCTAssertEqual(groupid, ga?.groupId, "\(String(describing: ga))")
            XCTAssertEqual(artifactid, ga?.artifactId, "\(String(describing: ga))")
        }
        subtest {
            check(nil, nil, GA.from(""))
            check(nil, nil, GA.from("com"))
            check(nil, nil, GA.from("com.bot"))
            check(nil, nil, GA.from("com:"))
            check(nil, nil, GA.from(":com"))
            check(nil, nil, GA.from("com/"))
            check(nil, nil, GA.from("/com"))
            check("a", "bot/core", GA.from("a:bot/core"))
            check("a.b", "bot-core", GA.from("a/b:bot-core"))
            check("com.bot", "bot-core", GA.from("com.bot:bot-core"))
            check("com", "bot", GA.from("com/bot"))
            check("com.cplusedition", "bot", GA.from("com/cplusedition/bot"))
            check("com.cplusedition.bot", "bot-core", GA.from("com/cplusedition/bot/bot-core"))
        }
        subtest {
            check("a", "bot/core", GA.of("a:bot/core"))
            check("a.b", "bot-core", GA.of("a/b:bot-core"))
            check("com.bot", "bot-core", GA.of("com.bot:bot-core"))
            check("com", "bot", GA.of("com/bot"))
            check("com.cplusedition", "bot", GA.of("com/cplusedition/bot"))
            check("com.cplusedition.bot", "bot-core", GA.of("com/cplusedition/bot/bot-core"))
            check("com.cplusedition.bot", "bot-core", GA.of("com/cplusedition/bot:bot-core"))
            check("com.cplusedition.bot", "bot-core", GA.of("com.cplusedition.bot/bot-core"))
        }
        subtest {
            var set = Set<GA>()
            XCTAssertTrue(set.insert(GA.of("a/b/c")).inserted)
            XCTAssertFalse(set.insert(GA.of("a/b/c")).inserted)
            XCTAssertTrue(set.insert(GA.of("a/b/c:d")).inserted)
            // XCTAssertFalse(set.insert(GA.of("a/b/c:d:e")).inserted)
            XCTAssertTrue(set.insert(GA.of("a:b")).inserted)
            XCTAssertTrue(set.insert(GA.of("aa:b")).inserted)
            XCTAssertTrue(set.insert(GA.of("a:bb")).inserted)
            XCTAssertFalse(set.insert(GA.of("aa/b")).inserted)
            XCTAssertFalse(set.insert(GA.of("a/bb")).inserted)
        }
        subtest {
            var set = Set<GA>()
            XCTAssertTrue(set.insert(GA.of("a/b/c")).inserted)
            XCTAssertFalse(set.insert(GA.of("a/b/c")).inserted)
            XCTAssertTrue(set.insert(GA.of("a/b/c:d")).inserted)
            // XCTAssertFalse(set.insert(GA.of("a/b/c:d:e")).inserted)
            XCTAssertTrue(set.insert(GA.of("a:b")).inserted)
            XCTAssertTrue(set.insert(GA.of("aa:b")).inserted)
            XCTAssertTrue(set.insert(GA.of("a:bb")).inserted)
            XCTAssertFalse(set.insert(GA.of("aa/b")).inserted)
            XCTAssertFalse(set.insert(GA.of("a/bb")).inserted)
        }
        subtest {
            XCTAssertEqual("com/cplusedition/bot/bot-core", GA.of("com.cplusedition.bot/bot-core").path)
            XCTAssertEqual("com.cplusedition.bot:bot-core", GA.of("com/cplusedition/bot/bot-core").description)
        }
    }

    
    func testGAReadWrite01() throws {
        let oks = [
            "a:bot/core",
            "a/b:bot-core",
            "com.bot:bot-core",
            "com/bot",
            "com/cplusedition/bot",
            "com/cplusedition/bot/bot-core"
        ]
        try subtest {
            let file = FileUtil.tempFile()
            defer { _ = file.delete() }
            try GA.write(file, oks.map { GA.of($0) })
            var ret = Array<GA>()
            try GA.read(&ret, file)
            XCTAssertEqual(6, ret.count)
        }
        try subtest {
            let file = FileUtil.tempFile()
            defer { _ = file.delete() }
            let fails = [
                "com",
                "com.bot",
                "com:",
                ":com",
                "com/",
                "/com"
            ]
            var list = Array<String>()
            list.append(oks)
            list.append(fails)
            list.shuffle()
            try file.writeText(list.joinln())
            var ret = Array<GA>()
            var failcount = 0
            try GA.read(&ret, file) { s in
                XCTAssertTrue(fails.contains(s), s)
                failcount += 1
            }
            XCTAssertEqual(fails.count, failcount)
            XCTAssertEqual(oks.count, ret.count)
        }
    }

    
    func testGAV01() {
        func check(_ groupid: String?, _ artifactid: String?, _ version: String?, _ gav: GAV?) {
            XCTAssertEqual(groupid, gav?.groupId, "\(String(describing: gav))")
            XCTAssertEqual(artifactid, gav?.artifactId, "\(String(describing: gav))")
            XCTAssertEqual(version, gav?.version.description, "\(String(describing: gav))")
        }
        subtest {
            check(nil, nil, nil, GAV.from(""))
            check(nil, nil, nil, GAV.from(":"))
            check(nil, nil, nil, GAV.from("/"))
            check(nil, nil, nil, GAV.from("::"))
            check(nil, nil, nil, GAV.from("//"))
            check(nil, nil, nil, GAV.from("com"))
            check(nil, nil, nil, GAV.from("com.bot"))
            check(nil, nil, nil, GAV.from("com:"))
            check(nil, nil, nil, GAV.from(":com"))
            check(nil, nil, nil, GAV.from("com/"))
            check(nil, nil, nil, GAV.from("/com"))
            check(nil, nil, nil, GAV.from("com:bot:"))
            check(nil, nil, nil, GAV.from(":bot:123"))
            check(nil, nil, nil, GAV.from(":bot:123:"))
            check(nil, nil, nil, GAV.from("com/bot"))
            check(nil, nil, nil, GAV.from("/com/bot"))
            check(nil, nil, nil, GAV.from("com/bot/"))
            check(nil, nil, nil, GAV.from("/com/bot/"))
            check(nil, nil, nil, GAV.from("a/b/c.pom"))
            check("a", "bot/core", "1.0", GAV.from("a:bot/core:1.0"))
            check("a.b", "bot-core", "1.0", GAV.from("a/b:bot-core:1.0"))
            check("com.bot", "bot-core", "1.0", GAV.from("com.bot:bot-core:1.0"))
            check("com", "bot", "1.0", GAV.from("com/bot/1.0"))
            check("com.cplusedition", "bot", "1.0", GAV.from("com/cplusedition/bot/1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.from("com/cplusedition/bot/bot-core/1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.from("com/cplusedition/bot:bot-core:1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.from("com.cplusedition.bot/bot-core/1.0"))
        }
        subtest {
            check("a", "bot/core", "1.0", GAV.of("a:bot/core:1.0"))
            check("a.b", "bot-core", "1.0", GAV.of("a/b:bot-core:1.0"))
            check("com.bot", "bot-core", "1.0", GAV.of("com.bot:bot-core:1.0"))
            check("com", "bot", "1.0", GAV.of("com/bot/1.0"))
            check("com.cplusedition", "bot", "1.0", GAV.of("com/cplusedition/bot/1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.of("com/cplusedition/bot/bot-core/1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.of("com/cplusedition/bot:bot-core:1.0"))
            check("com.cplusedition.bot", "bot-core", "1.0", GAV.of("com.cplusedition.bot/bot-core/1.0"))
            check(
                "com.cplusedition.bot",
                "bot-core",
                "1.0",
                GAV.of("com.cplusedition.bot/bot-core/1.0/bot-core-1.0.pom")
            )
        }
        subtest {
            var set = Set<GAV>() // Treeset
            XCTAssertTrue(set.insert(GAV.of("a/b/c/1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/b/c/1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a/b/c:d:1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/b/c:d:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:b:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("aa:b:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:bb:1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("aa/b/1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/bb/1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:bb:1.1")).inserted)
            XCTAssertTrue(set.insert(GAV.of("b:bb:1.9")).inserted)
            XCTAssertTrue(set.insert(GAV.of("b:bb:2.0")).inserted)
            XCTAssertEqual(8, set.count)
            self.log.d("# Natural order")
            let sorted = set.sorted()
            self.log.d(sorted.map { $0.description })
            let reverse = sorted.reversed()
            self.log.d("# Reverse order")
            self.log.d(reverse.map { $0.description })
            XCTAssertEqual(8, reverse.count)
            XCTAssertEqual("b:bb:2.0", reverse.first?.description)
        }
        subtest {
            var set = Set<GAV>() // HashSet
            XCTAssertTrue(set.insert(GAV.of("a/b/c/1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/b/c/1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a/b/c:d:1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/b/c:d:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:b:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("aa:b:1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:bb:1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("aa/b/1.0")).inserted)
            XCTAssertFalse(set.insert(GAV.of("a/bb/1.0")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:bb:1.1")).inserted)
            XCTAssertTrue(set.insert(GAV.of("a:bb:1.1-alpha")).inserted)
        }
        subtest {
            XCTAssertEqual("com.cplusedition.bot:bot-core:1.0", GAV.of("com/cplusedition/bot/bot-core/1.0").description)
            let gav = GAV.of("com.cplusedition.bot/bot-core/1.0")
            XCTAssertEqual("com/cplusedition/bot/bot-core/1.0", gav.path)
            XCTAssertEqual("com.cplusedition.bot:bot-core:1.0", gav.gav)
            XCTAssertEqual("com/cplusedition/bot/bot-core/1.0/bot-core-1.0", gav.artifactPath)
            XCTAssertEqual("com/cplusedition/bot/bot-core/1.0/bot-core-1.0.pom", gav.artifactPath(".pom"))
            var list = Array<String>()
            gav.artifactPath(&list, ".pom")
            XCTAssertEqual("com/cplusedition/bot/bot-core/1.0/bot-core-1.0.pom", list.first)
        }
    }

    
    func testGAvReadWrite01() throws {
        let oks = [
            "com.cplusedition:bot:1.0.0",
            "com/cplusedition/bot/1.1",
            "com/cplusedition/bot/bot-core/1.2.0",
            "com/cplusedition/bot/bot-core/1.2.1-alpha-1",
            "com/cplusedition/bot/bot-core/1.2.1-alpha-9",
            "com/cplusedition/bot/bot-core/1.2.1-alpha-10",
            "com/cplusedition/bot/bot-core/1.2.1-beta-2",
            "com/cplusedition/bot/bot-core/1.2.1",
            "com/cplusedition/bot/bot-core/1.2.1.3",
            "com/cplusedition/bot/1.2.1.4",
            "com/cplusedition/bot/1.3.0",
            "com/cplusedition/bot/1.4.0"
        ]
        try subtest {
            let file = FileUtil.tempFile()
            defer { _ = file.delete() }
            try GAV.write(file, oks.map { GAV.of($0) })
            var ret = Array<GAV>()
            try GAV.read(&ret, file)
            XCTAssertEqual(oks.count, ret.count)
        }
        try subtest {
            let file = FileUtil.tempFile()
            defer { _ = file.delete() }
            let fails = [
                "com",
                "com.bot",
                "com:bot:",
                ":com:bot",
                "com/1.0",
                "/com"
            ]
            var list = Array<String>()
            list.append(oks)
            list.append(fails)
            list.shuffle()
            try file.writeText(list.joinln())
            var failcount = 0
            var ret = Array<GAV>()
            try GAV.read(&ret, file) {
                XCTAssertTrue(fails.contains($0), $0)
                failcount += 1
            }
            XCTAssertEqual(fails.count, failcount)
            XCTAssertEqual(oks.count, ret.count)
        }
    }

    
    func testArtifactVersion01() {
        subtest {
            let versions = [
                "3.2.0.cr2",
                "3.2.0.ga",
                "3.2.1.ga",
                "3.3.1.ga",
                "3.3.2.GA",
                "3.4.0.GA",
                "3.5.0-Beta-2",
                "3.5.0-CR-1",
                "3.5.0-Final",
                "3.5.0-SP1",
                "3.5.0-SP2",
                "3.5.1-Final",
                "3.5.2-Final",
                "3.5.5-Final",
                "3.6.0.Final",
                "3.6.3.Final",
                "3.6.5.Final",
                "4.0.0.Beta1"
            ]
            var set = Set<ArtifactVersion>()
            for version in versions {
                let v = ArtifactVersion.parse(version)
                XCTAssertTrue(v.qualifier != nil, v.qualifier ?? "null")
                set.insert(v)
            }
            XCTAssertEqual(versions.count, set.count)
            let list = set.sorted()
            self.log.d(list.map { $0.debugDescription })
            for i in 0..<versions.count {
                XCTAssertEqual(versions[i], list[i].description)
            }
            XCTAssertEqual(set.count, list.count)
        }
        subtest {
            let versions = [
                "1-alpha-1",
                "1",
                "1.ga",
                "1.1-alpha-1",
                "1.1",
                "1.1.ga",
                "1.2.0",
                "1.2.1-alpha-1",
                "1.2.1-alpha-9",
                "1.2.1-alpha-10",
                "1.2.1-beta-2",
                "1.2.1",
                "1.2.1.ga",
                "1.2.1.3",
                "1.2.1.4.alpha",
                "1.2.1.4+1",
                "1.2.1.4",
                "1.2.1.4.ga",
                "1.2.1.4-sp1",
                "1.3.0",
                "1.4.0"
            ]
            var set = Set<ArtifactVersion>()
            for v in versions {
                let ver = ArtifactVersion.parse(v)
                set.insert(ver)
            }
            self.debugPrint(set)
            XCTAssertEqual(21, set.count)
            let sorted = set.sorted()
            let last = sorted.last!
            XCTAssertEqual(1, last.majorVersion)
            XCTAssertEqual(4, last.minorVersion)
            XCTAssertEqual(0, last.incrementalVersion)
            XCTAssertEqual(0, last.buildNumber)
            XCTAssertEqual(nil, last.qualifier)
            for i in versions.indices {
                XCTAssertEqual(versions[i], sorted[i].description)
            }
            XCTAssertTrue(ArtifactVersion.parse("1") == ArtifactVersion.parse("1.0"))
            XCTAssertFalse(ArtifactVersion.parse("1a") == ArtifactVersion.parse("1.0"))
        }
        subtest {
            let v1 = ArtifactVersion.parse("1.2.1-alpha-10")
            let v2 = ArtifactVersion.parse("1.2.1-alpha-9")
            XCTAssertEqual(1, v1.majorVersion)
            XCTAssertEqual(2, v1.minorVersion)
            XCTAssertEqual(1, v1.incrementalVersion)
            XCTAssertEqual("-alpha", v1.qualifier)
            XCTAssertEqual(10, v1.buildNumber)
            XCTAssertTrue(v1 > v2)
        }
    }

    
    func testArtifactVersionCompare01() {
        func parse(_ version: String) -> ArtifactVersion {
            return ArtifactVersion.parse(version)
        }

        func compare(_ v1: String, _ v2: String) -> Int {
            let av1 = parse(v1)
            let av2 = parse(v2)
            return av1 > av2 ? 1 : av1 < av2 ? -1 : 0
        }

        subtest {
            XCTAssertEqual(-1, compare("1.0-alpha-9", "1.0.0-alpha-10"))
            XCTAssertEqual(-1, compare("1.0-alpha-9", "1.0.0-beta-1"))
        }
    }

    
    func testArtifactVersionCompare02() {
        subtest {
            let versions = [
                "3.2.0.cr2",
                "3.2.0.ga",
                "3.2.1.ga",
                "3.3.1.ga",
                "3.3.2.GA",
                "3.4.0.GA",
                "3.5.0-Beta-2",
                "3.5.0-CR-1",
                "3.5.0-Final",
                "3.5.1-Final",
                "3.5.2-Final",
                "3.5.5-Final",
                "3.6.0.Final",
                "3.6.3.Final",
                "3.6.5.Final",
                "4.0.0.Beta1"
            ]
            let ret = ArtifactVersion.sort(versions)
            self.log.d(ret)
            XCTAssertEqual("3.2.0.cr2", ret[0])
            XCTAssertEqual("4.0.0.Beta1", ret[ret.count - 1])
        }
        subtest {
            let versions = [
                "3.2.0.cr2",
                "3.2.0.ga",
                "3.2.1.ga",
                "3.3.1.ga",
                "3.3.2.GA",
                "3.4.0.GA",
                "3.5.0-Beta-2",
                "3.5.0-CR-1",
                "3.5.0-Final",
                "3.5.1-Final",
                "3.5.2-Final",
                "3.5.5-Final",
                "3.6.0.Final",
                "3.6.3.Final",
                "3.6.5.Final",
                "4.0.0.Beta1"
            ]
            var set = Set<ArtifactVersion>()
            for version in versions {
                set.insert(ArtifactVersion.parse(version))
            }
            let sorted = set.sorted()
            self.log.d("# Versions:")
            self.log.d(sorted.map { $0.debugDescription })
            var release: String? = nil
            let reversed = sorted.reversed()
            for version in reversed {
                if (self.isRelease(version)) {
                    release = version.unparsed
                    break
                }
            }
            XCTAssertNotNil(release)
            self.log.d("# Release: \(String(describing: release))")
            XCTAssertEqual("4.0.0.Beta1", reversed.first?.unparsed)
            XCTAssertEqual("3.2.0.cr2", sorted.first?.unparsed)
            XCTAssertEqual("3.6.5.Final", release)
        }
    }

    let releases = Set(arrayLiteral: "", "-final", "-ga", "final", "ga")
    let sp = try! Regex("-sp\\d+")

    private func isRelease(_ v: ArtifactVersion) -> Bool {
        guard let q = v.qualifier else { return false }
        let lc = q.lowercased()
        return releases.contains(lc) || sp.matcher(lc).matches()
    }

    
    func test01() {
        let versions = ["1.0-beta-3.0.1", "1.0.0", "1.0.1", "1.0.2-alpha-20"]
        let incrementals = [0, 0, 1, 2]
        var set = Set<ArtifactVersion>()
        for ver in versions {
            set.insert(ArtifactVersion.parse(ver))
        }
        debugPrint(set)
        let array = set.sorted()
        for i in versions.indices {
            let ver = array[i]
            XCTAssertEqual(versions[i], ver.description)
            XCTAssertEqual(incrementals[i], ver.incrementalVersion)
        }
    }

    func testGAVArtifactPaths01() throws {
        let gav = GAV.of("com/cplusedition/bot/bot-core/1.0")
        let paths = gav.artifactPaths()
        log.d("# paths: \(paths.count)")
        log.d(paths)
        XCTAssertEqual(9, paths.count)
    }
    
    private func debugPrint<T>(_ versions: T) where T: Collection, T.Element == ArtifactVersion {
        if (log.debugging) {
            log.d(versions.map { $0.debugDescription })
        }
    }
}
