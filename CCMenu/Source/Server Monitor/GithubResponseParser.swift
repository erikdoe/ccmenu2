/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class GithubResponseParser {

    var runList: [Dictionary<String, Any>]?

    func parseResponse(_ data: Data) throws {
        if let response = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
            runList = response["workflow_runs"] as? [Dictionary<String, Any>]
        } else {
            runList = []
        }
    }

    func updatePipeline(_ pipeline: Pipeline) -> Pipeline? {

        let parts = pipeline.name.components(separatedBy: ":")
        if parts.count != 2 {
            return nil // TODO: or, in case count == 1, is there a default workflow name?
        }
        // TODO: is the latest build always first?
        guard let run = runList?.first(where: { $0["name"] as? String == parts[1] }) else {
            return nil
        }

        var newPipeline = pipeline
        newPipeline.webUrl = run["html_url"] as? String
        if let status = run["status"] as? String {
            newPipeline.activity = activityForString(status)
        }
        if let conclusion = run["conclusion"] as? String {
            var build = Pipeline.Build(result: resultForString(conclusion))
            if let runNumber = run["run_number"] as? Int {
                build.label = String(runNumber)
            }
            if let createdAt = run["created_at"] as? String , let createdAtDate = dateForString(createdAt) {
                build.timestamp = createdAtDate
                if let updatedAt = run["updated_at"] as? String, let updatedAtDate = dateForString(updatedAt) {
                    build.duration = updatedAtDate.timeIntervalSince(createdAtDate)
                }
            }
            newPipeline.lastBuild = build
        }

        return newPipeline
    }

    func activityForString(_ string: String?) -> PipelineActivity {
        switch string {
            case "completed": return PipelineActivity.sleeping
            case "in_progress": return PipelineActivity.building
            default: return PipelineActivity.other
        }
    }

    func resultForString(_ string: String?) -> BuildResult {
        switch string {
            case "success": return BuildResult.success
            case "failure": return BuildResult.failure
            default: return BuildResult.unknown
        }
    }

    func dateForString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }


}

