# **B**uild **O**n **T**est User Guide

## BotKit

This module contains some utility classes for logging (CoreLogger),
working with file (FileUtil, Treewalker, ... etc), text (TextUtil), random
(RandUtil) and process (ProcessUtil), ... etc.

It also contains a simple build framework with Workspace, Builder,
Project and Task. The taskdef file contains a few standard tasks. 
The tasks use the Fileset class for file selection and filtering.

**IBuilderWorkspace** is a convenient centralized place for the 
project definitions. The BasicWorkspace class automatically create 
a list of all the projects, using reflection, from all the instance fields 
of IProject type.

**IProject** contains information about projects/modules. The only
mandatory information is the **G**roup:**A**rtifactId:**V**erson and the
project directory for the project.

**IBuilder** Each builder is basically a test class with test methods that
perform tasks on the target project. A concrete builder class should
extends XCTestCase and implements IBasicBuilder. It provide a logger 
and some convenient methods to access the builder and target projects. 
Typically, you have a test module that contains the builders for the other 
modules in the project, that is called the builder project. The project that 
a builder works on is the target project. The BuilderBase class in the 
BotKitBuild project is a good starting point to derive your own builders.

**IBuilderConf** Each IBuilder has an IBuilderConf object. Here you 
specify the builder and target projects, the debugging flag and the 
workspace.

**ICoreTask** A runnable with a logger. See the taskdef file for some
sample task definitions.

**IBuilderTask** A runnable with an associated builder.

Again, these framework classes are just for convenient. You may not
need any of these to write your scripts.

## BotKitTests

This module also contain the tests for the BotKit module.

## BotKitBuild

This module contains builders for managing this project. It also work as a
simple example on how to use the `BotKit` framework.

For example, invoke the `ReleaseBuilder.testDistSrcZip()` method 
as a unit test in the IDE create the source zip and checksum files.
