//
//  NetworkRequest.swift
//
//
//  Created by Jeongseok Kang on 10/16/24.
//

import Foundation
//MARK: -- NetworkRequest Protocol
protocol NetworkRequest {
    //The endpoint URL.
    var url: URL? { get }
    //The HTTP method (GET, POST, etc.).
    var method: HTTPMethod { get }
    //Any headers required for the request.
    var headers: [HTTPHeader: String]? { get }
    //The request parameters, conforming to the Encodable protocol.
    var parameters: Encodable? { get }
}

/// Extend NetworkRequest for URLRequest Creation
extension NetworkRequest {
    ///Converts a NetworkRequest into a URLRequest object.
    func urlRequest() throws -> URLRequest {
        //Checks if the URL is valid, otherwise throws a badURL error.
        guard let url = url else {
            throw NetworkError.badURL
        }
        
        //Sets the HTTP method.
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        //Sets any provided headers.
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key.rawValue)
            }
        }
        //Encodes and sets parameters:
        if let parameters = parameters {
            if method == .get {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let parameterData = try JSONEncoder().encode(parameters)
                let parameterDictionary = try JSONSerialization.jsonObject(with: parameterData, options: []) as? [String: Any]
                //For GET requests, adds parameters as query items.
                urlComponents?.queryItems = parameterDictionary?.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                request.url = urlComponents?.url
            } else {
                do {
                    //For other methods, encodes parameters to JSON and sets them as the request body.
                    let jsonData = try JSONEncoder().encode(parameters)
                    request.httpBody = jsonData
                } catch {
                    //Throws an encodingFailed error if encoding fails.
                    throw NetworkError.encodingFailed(error)
                }
            }
        }
        
        return request
    }
}

//MARK: Example Usage -
/*
 struct ExampleAPIRequest: NetworkRequest {
    var url: URL? {
        return URL(string: "https://api.example.com/data")
    }
    var method: HTTPMethod {
        return .get
    }
    var headers: [HTTPHeader: String]? {
        return [.contentType: ContentType.json.rawValue]
    }
    var parameters: Encodable? {
        return ExampleParameters(param1: "value1", param2: "value2")
    }
 }
 
 struct ExampleParameters: Encodable {
    let param1: String
    let param2: String
 }
 
 struct ExampleData: Decodable {
    let id: Int
    let name: String
 }
 
 func fetchExampleData() async {
    let request = ExampleAPIRequest()
     do {
        let data: ExampleData = try await NetworkManager.shared.perform(request, decodeTo: ExampleData.self)
        print("Fetched data: \(data)")
     } catch {
        print("Failed to fetch data: \(error)")
     }
 }
 */
