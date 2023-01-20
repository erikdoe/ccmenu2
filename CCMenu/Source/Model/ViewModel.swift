/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import Combine


final class ViewModel: ObservableObject {

    @Published var pipelines: [Pipeline] = []
    @Published var avatars: Dictionary<URL, NSImage>

    @Published var pipelinesForMenu: [LabeledPipeline] = []

    @Published var imageForMenuBar: NSImage
    @Published var textForMenuBar: String

    private var settings: UserSettings

    private var subscribers: [AnyCancellable] = []

    init() {
        imageForMenuBar = ImageManager().defaultImage
        textForMenuBar = ""
        avatars = Dictionary()
        settings = UserSettings()
    }

    convenience init(settings: UserSettings) {
        self.init()
        self.settings = settings
        settings.$useColorInStatusItem
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in self.updateMenuBar() } )
            .store(in: &subscribers)
    }

    func update(pipeline: Pipeline) {
        guard let idx = pipelines.firstIndex(where: { $0.id == pipeline.id }) else {
            debugPrint("trying to update unknown pipeline \(pipelines.debugDescription)")
            return
        }

        pipelines[idx] = pipeline

        if let avatarUrl = pipeline.lastBuild?.avatar {
            if avatars[avatarUrl] == nil {
                retrieveAvatar(url: avatarUrl)
            }
        }

        updateMenuBar()
        updateMenu()
    }

    private func updateMenuBar() {
        if let pipeline = pipelineForMenuBar() {
            imageForMenuBar = ImageManager().image(forPipeline: pipeline, asTemplate: !settings.useColorInStatusItem)
        } else {
            imageForMenuBar = ImageManager().defaultImage
        }
        textForMenuBar = ""
    }

    private func pipelineForMenuBar() -> Pipeline? {
        return pipelines[0] // TODO: choose most relevant pipeline
    }


    private func updateMenu() {
        pipelinesForMenu = []
        for p in pipelines {
            let l = p.name
            pipelinesForMenu.append(LabeledPipeline(pipeline: p, label: l))
        }
    }



    private func retrieveAvatar(url avatarUrl: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data.init(contentsOf: avatarUrl)
                DispatchQueue.main.async {
                    let avatarImage: NSImage? = NSImage(data: data)
                    debugPrint("did load avatar for \(avatarUrl)")
                    self.avatars[avatarUrl] = avatarImage
                    debugPrint("did set avatar for \(avatarUrl)")
                }
            }
            catch let errorLog {
                print(errorLog.localizedDescription)
            }
        }
    }


    func loadPipelinesFromUserDefaults() {
        if let legacyProjects = UserDefaults.standard.array(forKey: "Projects") as? Array<Dictionary<String, String>> {
            for project in legacyProjects {
                if let name = project["projectName"], let feedUrl = project["serverUrl"] {
                    if !name.hasPrefix("erikdoe/") {
                        pipelines.append(Pipeline(name: name, feedUrl: feedUrl))
                    }
                }
            }
        }
//        pipelines.append(Pipeline(name: "erikdoe/ccmenu2:CI", feedType: .github, feedUrl: "https://api.github.com/repos/erikdoe/ccmenu2/actions/runs"))
//        pipelines.append(Pipeline(name: "thoughtworks/epirust:cargo-audit", feedType: .github, feedUrl: "https://api.github.com/repos/thoughtworks/epirust/actions/runs"))
    }

    func loadPipelinesFromFile(_ filename: String) {
        let data: Data

        do {
            data = try Data(contentsOf: URL(fileURLWithPath: filename))
        } catch {
            fatalError("Couldn't load test data from \(filename):\n\(error)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date string \(string)")
            }
            pipelines = try decoder.decode([Pipeline].self, from: data)
            updateMenuBar()
            updateMenu()
        } catch {
            fatalError("Couldn't parse \(filename) as [Pipeline]:\n\(error)")
        }
    }

}

