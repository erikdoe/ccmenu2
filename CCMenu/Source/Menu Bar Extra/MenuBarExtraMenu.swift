/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import SettingsAccess


struct MenuBarExtraMenu: View {
    @ObservedObject var model: PipelineModel
    @AppStorage(.orderInMenu) var orderInMenu = .asArranged
    @AppStorage(.showBuildTimesInMenu) private var showBuildTimesInMenu = false
    @AppStorage(.showBuildLabelsInMenu) private var showBuildLabelsInMenu = false
    @AppStorage(.hideSuccessfulBuildsInMenu) private var hideSuccessfulBuildsInMenu = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let filteredPipelines = filteredAndSortedPipelines(model.pipelines)
        ForEach(filteredPipelines) { p in
            let viewModel = MenuItemViewModel(pipeline: p, showBuildTimesInMenu: showBuildTimesInMenu, showBuildLabelsInMenu: showBuildLabelsInMenu)
            Button() {
                NSWorkspace.shared.openWebPage(pipeline: p)
            } label: {
                Label(title: { Text(viewModel.title) }, icon: { Image(nsImage: viewModel.icon) } )
                .labelStyle(.titleAndIcon)
            }
        }
        let hiddenCount = model.pipelines.count - filteredPipelines.count
        if hiddenCount > 0 {
            let text = (hiddenCount == 1) ? "1 pipeline" : "\(hiddenCount) pipelines"
            Button("(\(text) hidden)") { }
            .disabled(true)
        }
        Divider()
        Button("Pipelines") {
            NSApp.activateThisApp()
            openWindow(id: "pipeline-list")
        }
        Divider()
        Button("About CCMenu") {
            NSApp.activateThisApp()
            NSApp.sendAction(#selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)), to: nil, from: self)
        }
        SettingsLink {
            Text("Settings...")
        } preAction: { NSApp.activateThisApp()
        } postAction: { }
        Divider()
        Button("Quit CCMenu") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func filteredAndSortedPipelines(_ pipelines: [Pipeline]) -> [Pipeline] {
        let filtered = model.pipelines.filter({ !hideSuccessfulBuildsInMenu || $0.status.currentBuild != nil || $0.status.lastBuild?.result != .success })
        switch orderInMenu {
        case .asArranged: 
            return filtered
        case .sortedAlphabetically:
            return filtered.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        case .sortedByBuildTime:
            return filtered.sorted(by: {p1, p2 in
				let r1 = p1.status.lastBuild?.result
				let r2 = p2.status.lastBuild?.result
				if (r1 != r2) {
					if (r1 == nil) {
						return false
					}
					else if (r2 == nil) {
						return true
					}
					let resultOrder = [
						BuildResult.failure, BuildResult.success,
						BuildResult.unknown, BuildResult.other
					]
					return resultOrder.firstIndex(of: r1!)! < resultOrder.firstIndex(of: r2!)!
				}
				return p1.status.lastBuild?.timestamp ?? Date.distantFuture > p2.status.lastBuild?.timestamp ?? Date.distantFuture
			})
        }
    }

}


struct MenuBarExtraContent_Previews: PreviewProvider {
    static var previews: some View {
        Menu("menu") {
            MenuBarExtraMenu(model: viewModelForPreview())
        }
        .menuStyle(.borderlessButton)
        .padding(8)
        .frame(width: 300)

    }

    static func viewModelForPreview() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: PipelineFeed(type: .cctray, url: URL(string: "http://localhost")!, name: "connectfour"))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "ccmenu2 (build-and-run)", feed: PipelineFeed(type: .github, url: URL(string: "http://localhost")!, name: ""))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]

        model.update(pipeline: p0)
        model.update(pipeline: p1)

        return model
    }

}
