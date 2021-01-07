//
//  ServiceHandling.swift
//  SampleAws
//
//  Created by Akansha Dixit on 06/01/21.
//

import Foundation
import CryptoSwift

class ServiceHandling: NSObject, URLSessionDelegate ,URLSessionDownloadDelegate{
    
    var url = ""
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourIdentifier")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func downloadFile() {
        url = Constants.DownloadEndPoint
        downloadStarts(url: url)
    }
    
    func downloadStarts(url:String){
        guard let URL = URL(string: url) else { return }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        request.addValue(Constants.SHA256Hash, forHTTPHeaderField: "x-amz-content-sha256")
        guard let signedRequest = sign(request: request, secretSigningKey: Constants.SecretKey, accessKeyId: Constants.AccessKey) else { return }
        urlSession.downloadTask(with: signedRequest).resume()
    }
    
    
    func sign(request: URLRequest, secretSigningKey: String, accessKeyId: String) -> URLRequest? {
        var signedRequest = request
        let date = getDate()
        let dateShort = getDateString()
        
        guard let url = signedRequest.url, let host = url.host
        else { return .none }
        
        signedRequest.addValue(host, forHTTPHeaderField: "Host")
        signedRequest.addValue(date, forHTTPHeaderField: "X-Amz-Date")
        
        guard let headers = signedRequest.allHTTPHeaderFields, let method = signedRequest.httpMethod
        else { return .none }
        
        let signedHeaders = headers.map{ $0.key.lowercased() }.sorted().joined(separator: ";")
        
        let canonicalRequestHash = [
            method,
            url.path,
            url.query ?? "",
            headers.map{ $0.key.lowercased() + ":" + $0.value }.sorted().joined(separator: "\n"),
            "",
            signedHeaders,
            Constants.SHA256Hash
        ].joined(separator: "\n").sha256()
        
        let credential = [dateShort, Constants.RegionName, Constants.ServiceName, Constants.Terminator].joined(separator: "/")
        
        
        let stringToSign = [
            Constants.Algorithm,
            date,
            credential,
            canonicalRequestHash
        ].joined(separator: "\n")
        
        guard let signature = hmacStringToSign(stringToSign: stringToSign, secretSigningKey: secretSigningKey, shortDateString: dateShort)
        else { return .none }
        
        let authorization = Constants.Algorithm + " Credential=" + accessKeyId + "/" + credential + ", SignedHeaders=" + signedHeaders + ", Signature=" + signature
        signedRequest.addValue(authorization, forHTTPHeaderField: "Authorization")
        return signedRequest
    }
    
    private func hmacStringToSign(stringToSign: String, secretSigningKey: String, shortDateString: String) -> String? {
        let k1 = "AWS4" + secretSigningKey
        guard let sk1 = try? HMAC(key: [UInt8](k1.utf8), variant: .sha256).authenticate([UInt8](shortDateString.utf8)),
              let sk2 = try? HMAC(key: sk1, variant: .sha256).authenticate([UInt8](Constants.RegionName.utf8)),
              let sk3 = try? HMAC(key: sk2, variant: .sha256).authenticate([UInt8](Constants.ServiceName.utf8)),
              let sk4 = try? HMAC(key: sk3, variant: .sha256).authenticate([UInt8](Constants.Terminator.utf8)),
              let signature = try? HMAC(key: sk4, variant: .sha256).authenticate([UInt8](stringToSign.utf8)) else { return .none }
        return signature.toHexString()
    }
    
    func getDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC") as TimeZone?
        
        let datestring = dateFormatter.string(from: date)
        return datestring
    }
    
    func getDateString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let now =  df.string(from: Date())
        return now
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print(totalBytesExpectedToWrite)
        print(totalBytesWritten)
        let progress = ((Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100)
        debugPrint("Progress is \(progress)")
    }
    
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            print("Download successful")
            return
        }
        print(error)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print ("server error")
            return
        }
        var savedURL:URL = URL(string: "abc")!
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            savedURL = documentsURL.appendingPathComponent(
                "zipFolder")
            print(location)
            print(savedURL)
            try FileManager.default.moveItem(at: location, to: savedURL)
            
        } catch {
            print ("file error: \(error)")
        }
        session.finishTasksAndInvalidate()
    }
    
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let backgroundCompletionHandler =
                    appDelegate.backgroundCompletionHandler else {
                return
            }
            appDelegate.backgroundCompletionHandler = nil
            backgroundCompletionHandler()
            print("returned from background")
        }
    }
    
}
