// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit

///In the Courtesy from
///https://rohitsainier.medium.com/building-a-robust-network-layer-in-ios-using-swift-660870e976a9


@globalActor
public actor NetworkManager : NetworkLayerProtocol {
    public static let shared = NetworkManager()
    private let urlSession = URLSession.shared
    
    
    private init(){}
    
    public func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async -> Result<T, NetworkError>{
        let urlRequest : URLRequest
        do {
            urlRequest = try request.urlRequest()
        } catch {
            return .failure(error as? NetworkError ?? .badURL)
        }
        // Perform network request
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            // Process response
            if let error = processResponse(response: response) {
                return .failure(error)
            }
            
            // Decode data
            return decodeData(data: data, type: T.self)
            
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    public func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async throws -> T {
        let urlRequest : URLRequest
        do {
            urlRequest = try request.urlRequest()
        } catch {
            throw error as? NetworkError ?? .badURL
        }
        // Perform network request
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            // Process response
            if let error = processResponse(response: response) {
                throw error
            }
            
            // Decode data
            return try decodeData(data: data, type: T.self)
            
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func decodeData<T: Decodable>(data: Data, type: T.Type) -> Result<T, NetworkError> {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return .success(decodedObject)
        } catch let decodingError {
            return .failure(.decodingFailed(decodingError))
        }
    }
    private func decodeData<T: Decodable>(data: Data, type: T.Type) throws -> T {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch let decodingError {
            throw NetworkError.decodingFailed(decodingError)
        }
    }
    private func processResponse(response: URLResponse?) -> NetworkError? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return .invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return nil
        case 404:
            return .notFound
        case 500:
            return .internalServerError
        default:
            return .unknownError(statusCode: httpResponse.statusCode)
        }
    }
    
    // Convert send function to use Result
    public func send(_ request: NetworkRequest) async -> Result<Void, NetworkError> {
        // First create URLRequest
        let urlRequest: URLRequest
        do {
            urlRequest = try request.urlRequest()
        } catch {
            return .failure(error as? NetworkError ?? .badURL)
        }
        
        // Perform network request
        do {
            let (_, response) = try await urlSession.data(for: urlRequest)
            
            // Process response
            if let error = processResponse(response: response) {
                return .failure(error)
            }
            
            return .success(())
            
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    public func send(_ request: NetworkRequest) async throws-> Void {
        // First create URLRequest
        let urlRequest: URLRequest
        do {
            urlRequest = try request.urlRequest()
        } catch {
            throw error as? NetworkError ?? .badURL
        }
        
        // Perform network request
        do {
            let (_, response) = try await urlSession.data(for: urlRequest)
            
            // Process response
            if let error = processResponse(response: response) {
                throw error
            }
            
            return
            
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    
}
//Image Downloading and Caching
extension NetworkManager {
    
    
    // Convert downloadFile to use Result
    private func downloadFile(from url: URL) async -> Result<URL, NetworkError> {
        do {
            let (localURL, response) = try await urlSession.download(from: url)
            
            if let error = processResponse(response: response) {
                return .failure(error)
            }
            
            return .success(localURL)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    // Update image downloading to use the new Result-based methods
    public func downloadImage(from url: URL, cacheEnabled: Bool = true) async -> Result<UIImage, NetworkError> {
        if cacheEnabled {
            // Check cache first
            let cachedResult = getCachedImage(for: url)
            switch cachedResult {
            case .success(let image):
                return .success(image)
            case .failure(let error):
                // Only proceed with download if the error is dataNotFound
                guard case .dataNotFound = error else {
                    return .failure(error)
                }
            }
        }
        
        // Download the image if not cached or cache is disabled
        let downloadResult = await downloadFile(from: url)
        
        switch downloadResult {
        case .success(let localURL):
            do {
                let imageData = try Data(contentsOf: localURL)
                
                guard let image = UIImage(data: imageData) else {
                    return .failure(.decodingFailed(
                        NetworkDecodingError(message: "Failed to create image from downloaded data")
                    ))
                }
                
                if cacheEnabled {
                    cacheImage(imageData, for: url)
                }
                
                return .success(image)
            } catch {
                return .failure(.dataNotFound)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // Helper method to maintain cache size
    private func cacheImage(_ imageData: Data, for url: URL) -> Result<Void, NetworkError> {
        do {
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            ) else {
                return .failure(.invalidResponse)
            }
            
            let cachedResponse = CachedURLResponse(response: response, data: imageData)
            URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
            
            checkAndClearCache()
            return .success(())
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    private func checkAndClearCache() {
        let cacheSize = URLCache.shared.currentDiskUsage
        let cacheLimit: Int = 100 * 1024 * 1024 // 100 MB
        if cacheSize > cacheLimit {
            URLCache.shared.removeAllCachedResponses()
        }
    }
    
    // Convert getCachedImage to use Result with additional error handling
    private func getCachedImage(for url: URL) -> Result<UIImage, NetworkError> {
        // Check if we have a cached response
        guard let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)) else {
            return .failure(.dataNotFound)
        }
        
        // Try to create an image from the cached data
        guard let image = UIImage(data: cachedResponse.data) else {
            // If we have data but can't create an image, it's a decoding error
            return .failure(.decodingFailed(
                NetworkDecodingError(message: "Could not create image from cached data")
            ))
        }
        
        return .success(image)
    }
    
}

