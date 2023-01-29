/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct PipelineListToolbar: ToolbarContent {

    @ObservedObject var settings: UserSettings

    let add: (_: Pipeline.FeedType) -> Void
    let edit: () -> Void
    let remove: () -> Void
    let canEdit: () -> Bool
    let canRemove: () -> Bool

    var body: some ToolbarContent {
        ToolbarItem() {
            Menu() {
                Picker(selection: $settings.showStatusInPipelineWindow, label: EmptyView()) {
                    Text("Pipeline URL").tag(false)
                    Text("Build Status").tag(true)
                }
                .pickerStyle(InlinePickerStyle())
                .accessibility(label: Text("Details picker"))
                Button(settings.showMessagesInPipelineWindow ? "Hide Messages" : "Show Messages") {
                    settings.showMessagesInPipelineWindow.toggle()
                }
                .disabled(!settings.showStatusInPipelineWindow)
                Button(settings.showAvatarsInPipelineWindow ? "Hide Avatars" : "Show Avatars") {
                    settings.showAvatarsInPipelineWindow.toggle()
                }
                .disabled(!settings.showStatusInPipelineWindow)
            }
            label: {
                Image(systemName: "list.dash.header.rectangle")
            }
            .menuStyle(.borderlessButton)
            .help("Select which details to show for the pipelines")
        }
        ToolbarItem() {
            Spacer()
        }
        ToolbarItem() {
            Button(action: updatePipelines) {
                Label("Update", systemImage: "arrow.clockwise")
            }
            .help("Update status of all pipelines")
        }
        ToolbarItem() {
            Spacer()
        }
        ToolbarItem() {
            Menu() {
                Button("Add project from CCTray feed...") {
                    add(.cctray)
                }
                Button("Add Github workflow...") {
                    add(.github)
                }
            }
            label: {
                Image(systemName: "plus.rectangle.on.folder")
            }
            .menuStyle(.borderlessButton)
            .help("Add a pipeline")
        }
        ToolbarItem {
            Button(action: edit) {
                Label("Edit", systemImage: "gearshape")
            }
            .help("Edit pipeline")
            .accessibility(label: Text("Edit pipeline"))
            .disabled(!canEdit())
        }
        ToolbarItem() {
            Button(action: remove) {
                Label("Remove", systemImage: "trash")
            }
            .help("Remove pipeline")
            .accessibility(label: Text("Remove pipeline"))
            .disabled(!canRemove())
        }
    }
    
    func updatePipelines() {
        NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
    }
    
}
