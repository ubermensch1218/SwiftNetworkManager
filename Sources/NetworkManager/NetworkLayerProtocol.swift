//
//  NetworkLayerProtocol.swift
//
//
//  Created by Jeongseok Kang on 10/16/24.
//

import Foundation

public protocol NetworkLayerProtocol {
    func perform<T: Decodable>(_ request: NetworkRequest, decodeTo type: T.Type) async throws -> T
}
extension NetworkManager : NetworkLayerProtocol {
    
}
