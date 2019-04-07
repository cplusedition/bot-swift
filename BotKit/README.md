# **B**uild **O**n **T**est

## Introduction

**BOT** is a light framework for scripting in your favourite type safe
language, which is Swift in this case. There is also a variant in Kotlin.
This project contains a simple build framework and some pretty decent
utilities for logging, working with file, text, and process, ... etc., to get
you started. However, that is not the key.

The key is two ideas that it builds on. First, you can write scripts with your
favourite type safe language that is well supported by the IDE. Second,
you can launch the script directly from the IDE through the unit test
framework by wrapping it as a test method.

With proper IDE support, you can easily modify, launch and see the result
instantly. Take advantage of all the coding and debugging support of the
IDE. Enjoy coding in a modern, safe and expressive language as well as the
quick modify / run cycle of a scripting language.

**NOTE** There is a catch. You almost always want to launch a single
test method (ie. script) at a time. However, the unit test framework may
more than happy to launch all the test methods in a class or a project when
you accidentally hit a wrong button. The workaround in XCode is to stop
the test run when the test suite contains more than one test using a 
XCTestObservation. See BuilderBase.swift in the BotKitBuild project
for an example.

**NOTE** Your builder should extends XCTestCase and implements IBasicBuilder.
See BuilderBase.swft in the BotKitBuild project for an example.

**NOTE** This is not a full-fledged build system or a library for standalone 
command line applications. It is used for custom tasks and automation that 
is not in the standard build system workflow and inside an IDE with proper 
language and unit test support.

**NOTE** The project has only been tested to work under MacOS and XCode.

## License

Copyright (c) Cplusedition Limited. All rights reserved.

Licensed under the [Apache](LICENSE.txt) License.
