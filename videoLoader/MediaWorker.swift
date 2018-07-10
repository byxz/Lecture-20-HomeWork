//
//  MediaWorker.swift
//  videoLoader
//
//  Created by Mac on 07.07.2018.
//  Copyright © 2018 testOrg. All rights reserved.
//

import Foundation

protocol MediaWorkerDelegate: class {
    func mediaWorker(_ worker: MediaWorker, didFinishLoadingTo url: URL, source: URL)
    func mediaWorker(_ worker: MediaWorker, didUpdateProgress progress: Float)
    func mediaWorker(_ worker: MediaWorker, failWith error: Error)
}

final class MediaWorker: NSObject, URLSessionDownloadDelegate {
    
    // MARK: - Declarations
    
    enum Error: Swift.Error {
        case badUrl
        
        var localizedDescription: String {
            switch self {
            case .badUrl: return "Your url is bad"
            }
        }
    }
    
    // MARK: - Properties
    
    private let storage = ResumeDataStorage()
    
    private lazy var session: URLSession = {
        return URLSession(configuration: .background(withIdentifier: "some id"), delegate: self, delegateQueue: .main)
    }()
    
    private var task: URLSessionDownloadTask?
    private(set) var isTaskRunning: Bool = false
    weak var delegate: MediaWorkerDelegate?
    
    var hasDataToResume: Bool {
        return storage.data != nil
    }
    
    // MARK: - Methods
    
    func loadFile(path: String) {
        guard let url = URL(string: path) else {
            delegate?.mediaWorker(self, failWith: Error.badUrl)
            return
        }
        isTaskRunning = true
        task = session.downloadTask(with: url)
        task?.resume()
    }
    
    func cancel(completion: (() -> Void)? = nil) {
        isTaskRunning = false
        task?.cancel { [weak self] data in
            guard let data = data else { return }
            self?.storage.save(data: data)
            completion?()
        }
    }
    
    func resume() {
        guard let resumeData = storage.data else { return }
        storage.clear()
        isTaskRunning =  true
        task = session.downloadTask(withResumeData: resumeData)
        task?.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        isTaskRunning = false
        storage.clear()
        delegate?.mediaWorker(self, didFinishLoadingTo: location, source: (downloadTask.currentRequest?.url)!)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        delegate?.mediaWorker(self, didUpdateProgress: progress)
            print("Progress \(totalBytesWritten / (1024*1024)) из \(totalBytesExpectedToWrite / (1024*1024))")
        }
}
