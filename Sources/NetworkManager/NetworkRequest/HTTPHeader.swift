//
//  HTTPHeader.swift
//
//
//  Created by Jeongseok Kang on 10/16/24.
//

import Foundation

public enum HTTPHeader: RawRepresentable, Hashable {
    // RawRepresentable conformance: Custom initializer to handle predefined and custom cases
    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "content-type":
            self = .contentType
        case "authorization":
            self = .authorization
        default:
            self = .custom(rawValue)
        }
    }
    public typealias RawValue = String
    
    case contentType
    case authorization
    case custom(String)
    
    public var rawValue: String {
        switch self {
        case .contentType:
            return "Content-Type"
        case .authorization:
            return "Authorization"
        case .custom(let string):
            return string
        }
    }
}
