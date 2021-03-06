//
//  main.swift
//  Natrium
//
//  Created by Bas van Kuijck on 07/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation
import CommandLineKit
import AppKit
import Yaml
import XcodeEdit

let dic = ProcessInfo.processInfo.environment
let natrium: Natrium

let args = CommandLine.arguments
var url = URL(fileURLWithPath: CommandLine.arguments.first!)
url.deleteLastPathComponent()
FileManager.default.changeCurrentDirectoryPath(url.path)

// Did natrium run from a pre-action build script?
if let projectDir = dic["PROJECT_DIR"], let targetName = dic["TARGET_NAME"], let configuration = dic["CONFIGURATION"] {
    Logger.shouldPrint = false
    if args.isEmpty {
        Logger.fatalError("Missing environment argument")
        exit(EX_USAGE)
    }
    let environment = args[1]

    // Set the currentDirectory to the current file path

    natrium = Natrium(projectDir: projectDir,
                      target: targetName,
                      configuration: configuration,
                      environment: environment,
                      force: false)
// ./natrium install
} else if (args.count == 2 || args.count == 3) && args[1] == "install" {

    let quiet = (args.count == 3 && args[2] == "--silent-fail")
    if !NatriumLock.file.isExisting {
        if !quiet {
            Logger.warning("Natrium.lock file not created yet, run natrium with the correct arguments")
        }
        exit(EX_USAGE)
    }
    guard let tmpNatrium = NatriumLock.getNatrium(quiet: quiet) else {
        if !quiet {
            Logger.fatalError("Error parsing Natrium.lock")
        }
        exit(EX_USAGE)
    }
    natrium = tmpNatrium

} else {
    // Else use the cli

    let cli = CommandLineKit.CommandLine()

    let projectDirOption = StringOption(shortFlag: "p",
                                        longFlag: "project_dir",
                                        required: true,
                                        helpMessage: "Project directory.")

    let configOption = StringOption(shortFlag: "c",
                                    longFlag: "configuration",
                                    required: true,
                                    helpMessage: "Configuration name.")

    let environmentOption = StringOption(shortFlag: "e",
                                         longFlag: "environment",
                                         required: true,
                                         helpMessage: "Environment.")

    let targetOption = StringOption(shortFlag: "t",
                                    longFlag: "target",
                                    required: true,
                                    helpMessage: "Target name.")

    let timeOption = BoolOption(shortFlag: "n",
                                    longFlag: "no_timestamp",
                                    required: false,
                                    helpMessage: "Hide timestamp in logs")

    cli.addOptions(projectDirOption, configOption, environmentOption, targetOption, timeOption)

    do {
        try cli.parse()
    } catch {
        print("Natrium version: \(Natrium.version)")
        print("")
        cli.printUsage(error)
        exit(EX_USAGE)
    }

    Logger.showTime = !timeOption.value
    natrium = Natrium(projectDir: projectDirOption.value!,
                      target: targetOption.value!,
                      configuration: configOption.value!,
                      environment: environmentOption.value!)
}

natrium.run()
