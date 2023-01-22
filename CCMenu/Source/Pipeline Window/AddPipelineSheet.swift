/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AddPipelineSheet: View {
    @ObservedObject var model: ViewModel
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Add pipeline")
                .font(.headline)
            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                Button("Apply") {
                    var p = Pipeline(name: "erikdoe/ocmock", feedUrl: "http://localhost:4567/cc.xml")
                    p.status = Pipeline.Status(activity: .sleeping)
                    p.status.lastBuild = Build(result: .success)
                    model.pipelines.append(p)
                    presentation.dismiss()
                }
                .buttonStyle(DefaultButtonStyle())
            }
        }
        .padding(EdgeInsets(top: 10, leading:10, bottom: 10, trailing: 10))
    }
}


struct AddPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddPipelineSheet(model: makeViewModel())
        }
    }
    
    static func makeViewModel() -> ViewModel {
        let model = ViewModel()

        var p0 = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cctray.xml")
        p0.status = Pipeline.Status(activity: .building)
        p0.status.lastBuild = Build(result: .failure)
        model.pipelines = [p0]
        return model
    }
    
}

