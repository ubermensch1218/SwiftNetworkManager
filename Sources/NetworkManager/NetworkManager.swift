// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit

///In the Courtesy from
///https://rohitsainier.medium.com/building-a-robust-network-layer-in-ios-using-swift-660870e976a9


@globalActor
actor NetworkManager {
    static let shared = NetworkManager()
    private let urlSession = URLSession.shared
    
    
    private init(){}
    
    
    func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async throws -> T {
        let urlRequest = try request.urlRequest()
        let (data, response) = try await urlSession.data(for: urlRequest)
        try processResponse(response: response)
        return try decodeData(data: data, type: T.self)
    }
    func send(_ request: NetworkRequest) async throws {
        let urlRequest = try request.urlRequest()
        let (_, response) = try await urlSession.data(for: urlRequest)
        return try processResponse(response: response)
    }
    
    private func decodeData<T: Decodable>(data: Data, type: T.Type) throws -> T {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch let decodingError {
            throw NetworkError.decodingFailed(decodingError)
        }
    }
    
    private func processResponse(response: URLResponse?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            throw NetworkError.notFound
        case 500:
            throw NetworkError.internalServerError
        default:
            throw NetworkError.unknownError(statusCode: httpResponse.statusCode)
        }
    }
    
    func downloadFile(from url: URL) async throws -> URL {
        let (localURL, response) = try await urlSession.download(from: url)
        try processResponse(response: response)
        return localURL
    }
}
//Image Downloading and Caching
extension NetworkManager {
    func downloadImage(from url: URL, cacheEnabled: Bool = true) async -> Result<UIImage, NetworkError> {
        do {
            if cacheEnabled, let cachedImage = try getCachedImage(for: url) {
                return .success(cachedImage)
            }
            
            let localURL = try await NetworkManager.shared.downloadFile(from: url)
            let imageData = try Data(contentsOf: localURL)
            if let image = UIImage(data: imageData) {
                if cacheEnabled {
                    cacheImage(imageData, for: url)
                }
                return .success(image)
            } else {
                return .failure(.decodingFailed(NetworkDecodingError(message: "Failed to decode image data")))
            }
        } catch {
            return .failure(error as? NetworkError ?? .invalidResponse)
        }
    }
    
    private func cacheImage(_ imageData: Data, for url: URL) {
        let cachedResponse = CachedURLResponse(response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data: imageData)
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        checkAndClearCache()
    }
    
    private func checkAndClearCache() {
        let cacheSize = URLCache.shared.currentDiskUsage
        let cacheLimit: Int = 100 * 1024 * 1024 // 100 MB
        if cacheSize > cacheLimit {
            URLCache.shared.removeAllCachedResponses()
        }
    }
    
    private func getCachedImage(for url: URL) throws -> UIImage? {
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            return image
        }
        return nil
    }
}

