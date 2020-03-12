//
//  TNPath.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 15/02/2018.
//  Copyright © 2018 Vasilis Panagiotopoulos. All rights reserved.
//

import Foundation

public enum TNPath {
    case path(_ components: [String])
    
    public init(_ components: String...) {
        self = .path(components)
    }
    
    func convertedPath() -> String {
        switch self {
        case .path(let components):
            return components.joined(separator: "/")
        }
    }
}

internal enum SNPathType: Error {
    case normal
    case full
}
