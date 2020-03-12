//
//  APIFoodRouter.swift
//  SimpleNetworking_Example
//
//  Created by Vasilis Panagiotopoulos on 15/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import TermiNetwork

enum APIFoodRouter: TNRouterProtocol {
    // Define your routes
    case categories
    case filter(categoryTitle: String)
    case createCategory(title: String)
    
    // Set method, path, params, headers for each route
    func configure() -> TNRouteConfiguration {
        switch self {
        case .categories:
            return TNRouteConfiguration(
                method: .get,
                path: .path(["categories.php"]) // Generates: http(s)://.../categories.php
            )
        case .filter(let term):
            return TNRouteConfiguration(
                method: .get,
                path: .path(["search.php"]), // Generates: http(s)://.../search.php?filter=[term]
                params: ["filter": term]
            )
        case .createCategory(let title):
            return TNRouteConfiguration(
                method: .post,
                path: .path(["categories", "create"]), // Generates: http(s)://.../categories/create
                params: ["title": title]
            )
        }
    }
}

enum TodosRouter: TNRouterProtocol {
    // Define your routes
    case list
    case show(id: Int)
    case add(title: String)
    case remove(id: Int)
    case setCompleted(id: Int, completed: Bool)
    
    // Set method, path, params, headers for each route
    func configure() -> TNRouteConfiguration {
        let headers = ["x-auth": "abcdef1234"]
        let configuration = TNRequestConfiguration(requestBodyType: .JSON)
        
        switch self {
        case .list:
            return TNRouteConfiguration(method: .get, path: TNPath("todos"), headers: headers, requestConfiguration: configuration) // GET /todos
        case .show(let id):
            return TNRouteConfiguration(method: .get, path: TNPath("todo", String(id)), headers: headers, requestConfiguration: configuration) // GET /todos/[id]
        case .add(let title):
            return TNRouteConfiguration(method: .post, path: TNPath("todos"), params: ["title": title], headers: headers, requestConfiguration: configuration) // POST /todos
        case .remove(let id):
            return TNRouteConfiguration(method: .delete, path: TNPath("todo", String(id)), headers: headers, requestConfiguration: configuration) // DELETE /todo/[id]
        case .setCompleted(let id, let completed):
            return TNRouteConfiguration(method: .patch, path: TNPath("todo", String(id)), params: ["completed": completed], headers: headers, requestConfiguration: configuration) // PATCH /todo/[id]
        }
    }
}
