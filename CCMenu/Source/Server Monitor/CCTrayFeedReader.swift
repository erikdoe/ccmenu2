/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class CCTrayFeedReader: NSObject, FeedReader, URLSessionDataDelegate, URLSessionDelegate {
    
    var pipeline: Pipeline
    var delegate: FeedReaderDelegate?
    var receivedData: Data?

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration,
                          delegate: self, delegateQueue: nil)
    }()
    
    public init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }
    
    public func updatePipelineStatus() {
        let url = URL(string: pipeline.feed.url)!
        receivedData = Data()
        let task = session.dataTask(with: url)
        task.resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode)
        else {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }


    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data)
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.handleClientError(error)
            } else if let receivedData = self.receivedData {
                let parser = CCTrayResponseParser()
                do {
                    try parser.parseResponse(receivedData)
//                    if let p = parser.updatePipeline(self.pipeline) {
//                        self.delegate?.feedReader(self, didUpdate: p)
//                    }
                } catch let error {
                    self.handleParserError(error)
                }
            }
        }
    }

    func handleClientError(_ error: Error) {
        print("client error \(error.localizedDescription)")
    }

    func handleParserError(_ error: Error) {
        print("parser error \(error.localizedDescription)")
    }
    
}
