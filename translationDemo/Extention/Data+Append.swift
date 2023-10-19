//
//
//  Data+Append.swift
//
//  Created by あぷりしゃちょう@apppman
//

import Foundation

// Data拡張
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
