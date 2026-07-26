//
//  HTTPURLResponse+StatusCode.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

extension HTTPURLResponse {
    private static var OK_200: Int { return 200 }

    var isOK: Bool {
        return statusCode == HTTPURLResponse.OK_200
    }

    var is2xx: Bool {
        return (200...299).contains(statusCode)
    }
}
