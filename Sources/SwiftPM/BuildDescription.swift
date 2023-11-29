//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

// FIXME: should not import this module
import Build
// FIXME: should be internal imports
import PackageGraph
/*private*/ import SPMBuildCore

public protocol BuildTarget {
    // FIXME: should not use `ResolvedTarget` in the public interface
     var target: ResolvedTarget { get }
     var sources: [URL] { get }

     func compileArguments() throws -> [String]
 }

extension ClangTargetBuildDescription: BuildTarget {
    public var sources: [URL] {
        return (try? compilePaths().map { URL(fileURLWithPath: $0.source.pathString) }) ?? []
    }

    public func compileArguments() throws -> [String] {
        var args = try self.basicArguments()
        args += sources.map { $0.path }
        return args
    }
}

private struct WrappedSwiftTargetBuildDescription: BuildTarget {
    private let description: SwiftTargetBuildDescription
    private let buildParameters: BuildParameters

    init(description: SwiftTargetBuildDescription, buildParameters: BuildParameters) {
        self.description = description
        self.buildParameters = buildParameters
    }

    var target: ResolvedTarget {
        return description.target
    }

    var sources: [URL] {
        return description.sources.map { URL(fileURLWithPath: $0.pathString) }
    }

    func compileArguments() throws -> [String] {
        var args = try description.compileArguments()
        args += sources.map { $0.path }
        args += ["-I", buildParameters.buildPath.pathString]
        return args
    }
}

public struct BuildDescription {
    private let buildPlan: Build.BuildPlan

    // FIXME: should not use `BuildPlan` in the public interface
    public init(buildPlan: Build.BuildPlan) {
        self.buildPlan = buildPlan
    }

    // FIXME: should not use `ResolvedTarget` in the public interface
    public func getBuildTarget(for target: ResolvedTarget) -> BuildTarget? {
        if let description = buildPlan.targetMap[target] {
            switch description {
            case .clang(let description):
                return description
            case .swift(let description):
                return WrappedSwiftTargetBuildDescription(description: description, buildParameters: buildPlan.buildParameters)
            }
        } else {
            if target.type == .plugin, let package = self.buildPlan.graph.package(for: target) {
                return PluginTargetBuildDescription(target: target, toolsVersion: package.manifest.toolsVersion)
            }
            return nil
        }
    }
}
