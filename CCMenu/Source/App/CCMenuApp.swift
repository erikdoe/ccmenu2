/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

@main
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject public var viewModel: ViewModel
    var serverMonitor: ServerMonitor

    init() {
        let model = ViewModel()
        viewModel = model
        serverMonitor = ServerMonitor(model: model)
        appDelegate.viewModel = model
        
        if let filename = UserDefaults.standard.string(forKey: "loadTestData") {
            model.loadPipelinesFromFile(filename)
        } else {
            model.loadPipelinesFromUserDefaults()
            serverMonitor.start()
        }
    }
    
    
    var body: some Scene {

        WindowGroup("Pipelines") {
            PipelineListView(model: viewModel)
                .handlesExternalEvents(preferring: ["pipelines"], allowing: ["pipelines"])
        }
        .commands {
            AppCommands()
        }
        .handlesExternalEvents(matching: ["pipelines"])
        
        Settings {
            SettingsView()
        }

    }

}
