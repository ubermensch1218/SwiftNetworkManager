//
//  NetworkError.swift
//
//
//  Created by Jeongseok Kang on 10/16/24.
//

import Foundation
//MARK: -- Error
public enum NetworkError: Error {
    /// Indicates an invalid URL.
    case badURL
    ///Indicates a failure in the network request, storing the original error.
    case requestFailed(Error)
    ///Indicates that the response received is not valid.
    case invalidResponse
    /// Indicates that the data expected from the response was not found.
    case dataNotFound
    /// Indicates failure in decoding the response data into the expected type.
    case decodingFailed(Error)
    /// Indicates failure in encoding the request parameters.
    case encodingFailed(Error)
    ///Indicates a 404 error.
    case notFound
    /// Indicates a 500 error.
    case internalServerError
    /// Indicates an unknown error with the associated status code.
    case unknownError(statusCode: Int)
}

public struct NetworkDecodingError: Error {
    let message: String
}
