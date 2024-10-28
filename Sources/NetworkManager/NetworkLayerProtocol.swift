//
//  NetworkLayerProtocol.swift
//
//
//  Created by Jeongseok Kang on 10/16/24.
//

import Foundation

public protocol NetworkLayerProtocol {
    func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async -> Result<T, NetworkError>
    func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async throws -> T
    func send(_ request: NetworkRequest) async throws-> Void
    func send(_ request: NetworkRequest) async -> Result<Void, NetworkError> 
}
