import os
import SwiftUI
//import Zip

class DownloadManager: NSObject, ObservableObject {
    static var shared = DownloadManager()

    private var urlSession: URLSession!
    private var currentFile: String!
    @Published var tasks: [URLSessionTask] = []

    override private init() {
        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")

        // Warning: Make sure that the URLSession is created only once (if an URLSession still
        // exists from a previous download, it doesn't create a new URLSession object but returns
        // the existing one with the old delegate object attached)

        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())

        updateTasks()
    }

    func startDownload(url: URL) {
        let task = urlSession.downloadTask(with: url)
        currentFile = url.lastPathComponent;
        print(currentFile);
        task.resume()
        tasks.append(task)
    }

    private func updateTasks() {
        urlSession.getAllTasks { tasks in
            DispatchQueue.main.async {
                self.tasks = tasks
            }
        }
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
        os_log("Progress %f for %@", type: .debug, downloadTask.progress.fractionCompleted, downloadTask)
    }
    
    fileprivate func downloadGamesList(_ location: URL) throws {
        print("Got GamesList")
    
        let destinationUrl = URL(fileURLWithPath: documentsDirectory.relativePath + "/allfiles.txt")
        FileManager.default.secureCopyItem(at: location, to: destinationUrl)
        
        do {
            let data = try String(contentsOfFile: destinationUrl.relativePath, encoding: .utf8)
            games2Download = data.components(separatedBy: .newlines)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedGameList"), object: nil)
        } catch {
            print(error)
        }
    }
    
    fileprivate func downloadGames(_ location: URL) throws {
        
        let destinationUrl = URL(fileURLWithPath: documentsDirectory.relativePath + "/tmp.zip")
        FileManager.default.removeIfExists(srcURL: destinationUrl)
        
        try FileManager.default.moveItem(at: location, to: destinationUrl)
        let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        for urls in fileURLs
        {
            let string = urls.relativeString
            if string.hasSuffix("zip")
            {
//                print("Found Zip")
//                do {
//                    try Zip.unzipFile(urls, destination: documentsDirectory, overwrite: true, password: nil, progress: { (progress) -> () in
//                        print(progress)
//                    }) // Unzip
//
//                    try FileManager.default.removeItem(at: destinationUrl)
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedGame"), object: nil)
//                }
//                catch {
//                    print("Something went wrong")
//                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "copyFromBundle"), object: nil)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
                print ("server error")
                return
        }
          
        do {
            if(currentFile! == "allfiles.txt") {
                try downloadGamesList(location)
            }
            else {
                try downloadGames(location)
            }
        } catch {
            print ("file error: \(error)")
        }
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            os_log("Download error: %@", type: .error, String(describing: error))
        } else {
            os_log("Task finished: %@", type: .info, task)
        }
    }
}
