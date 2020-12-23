
<p></p>
<p align="center">
  <img src="https://raw.githubusercontent.com/billp/TermiNetwork/master/TermiNetworkLogo.svg" alt="" data-canonical-src="" width="80%" />
</p>

<p align="center"><b>A zero-dependency networking solution for building modern and secure iOS applications.</b>
  <br /><br />
    <img src="https://travis-ci.org/billp/TermiNetwork.svg?branch=1.0.0-new-structure" />
  <img src="https://img.shields.io/cocoapods/v/TermiNetwork.svg?style=flat" />
  <img src="https://img.shields.io/badge/Language-Swift 5.3-blue" />
  <img src="https://img.shields.io/github/license/billp/TermiNetwork" />
  <img src="https://img.shields.io/cocoapods/p/TermiNetwork" />
  <img src="https://img.shields.io/cocoapods/metrics/doc-percent/TermiNetwork" />
</p>

## Features
<p align="center">
Model deserialization with <b>Codables</b> 🔸 Multi-Environment configuration 🔸 Convert responses to the given type (<b>Codable</b>, <b>UIImage</b>, <b>Data</b> or <b>String</b>) 🔸 <b>UIKit</b>/<b>SwiftUI</b> helpers for downloading remote images 🔸 Request fragmentation with Routers (perfect for modular environments) 🔸 Transformers (convert rest models to domain models) 🔸 Error handling 🔸 Mock requests 🔸 Certificate pinning 🔸 Flexible configuration 🔸 Middlewares 🔸 File/Data Upload/Download 🔸 Pretty printed debug information in console
</p>

#### Table of contents
- [Installation](#installation)
- [Demo Application](#demo_app)
- [Usage](#usage)
  - [Simple usage of <b>TNRequest</b>](#simple_usage)
  - [Advanced usage of <b>TNRequest</b> with <b>Configuration</b> and custom <b>Queue</b>](#advanced_usage)
  - [Complete project setup with <b>Environments</b> and <b>Routers</b> (Recommended)](#complete_setup)
	  - [Setup your Environment](#setup_environments)
	  - [Setup your Routes](#setup_routers)
	  - [Make a request](#construct_request)
- [Queue Hooks](#queue_hooks)
- [Error Handling](#error_handling)
	- [Global Error Handlers](#global_error_handlers)
- [Image Helpers](#image_helpers)
- [Debug Logging](#debug_logging)

<a name="installation"></a>

## Installation
You can install **TermiNetwork** with one of the following ways...
### CocoaPods

Add the following line to your **Podfile** and run **pod install** in your terminal:
```ruby
pod 'TermiNetwork', '~> 1.0.0'
```

### Carthage

Add the following line to your **Carthage** and run **carthage update** in your terminal:
```ruby
github "billp/TermiNetwork" ~> 1.0.0
```

### Swift Package Manager

Go to **File** > **Swift Packages** > **Add Package Dependency** and add the following URL :
```
https://github.com/billp/TermiNetwork
```

<a name="demo_app"></a>

## Demo Application
To see all the features of TermiNetwork in action, download the source code and run the **TermiNetworkExamples** scheme.

<a name="usage"></a>

## Usage

<a name="simple_usage"></a>

### Simple usage (TNRequest)

Let's say you have the following Codable model:

```swift
struct Todo: Codable {
   let id: Int
   let title: String
}
```

To construct a request which adds a new todo using a REST API, do the following:

```swift
let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

TNRequest(method: .post,
          url: "https://myweb.com/api/todos",
          headers: headers,
          params: params).start(responseType: Todo.self,
                                onSuccess: { todo in
    print(todo)
}) { (error, data) in
    print(error)
}
```

#### Parameters Explanation

##### method
One of the following supported HTTP methods:
```
.get, .head, .post, .put, .delete, .connect, .options, .trace or .patch
```

##### responseType
One of the following supported response types
```
JSON.self, Codable.self (subclasses), UIImage.self, Data.self or String.self
```

##### onSuccess
A callback that returns an object of the given type (specified in responseType parameter).

##### onFailure
a callback that returns a **TNError** and optionally the response **Data**.

<a name="advanced_usage"></a>

### Advanced usage of TNRequest with Configuration and custom Queue

The following example uses a custom queue that specifies the **maxConcurrentOperationCount** (how many requests run in parallel) and a configuration object. To see the full list of available configuration properties, take a look at <a href="https://billp.github.io/TermiNetwork/Classes/TNConfiguration.html#/Public%20properties" target="_blank">TNConfiguration properties</a> in documentation.

```swift
let configuration = TNConfiguration(
    cachePolicy: .useProtocolCachePolicy,
    timeoutInterval: 30,
    requestBodyType: .JSON
)

let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

TNRequest(method: .post,
          url: "https://myweb.com/todos",
          headers: headers,
          params: params,
          configuration: configuration).start(queue: myQueue,
                                              responseType: String.self,
                                              onSuccess: { response in
    print(response)
}) { (error, data) in
    print(error)
}
```
The request above uses a custom queue *myQueue* with a failure mode of value *.continue* (default), which means that the queue continues its execution if a request fails.

<a name="complete_setup"></a>

## Complete setup with <b>Environments</b> and <b>Routers</b>
The complete and recommended usage of TermiNetwork library consists of creating your environments and define your own routers.  

<a name="setup_environments"></a>

#### Setup your Environment
Create a swift class that implements the **TNEnvironmentProtocol** and define your environments. See bellow for an example:
```swift
enum Environment: TNEnvironmentProtocol {
    case localhost
    case dev
    case production

    func configure() -> TNEnvironment {
        let configuration = TNConfiguration(cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 30,
                                            requestBodyType: .JSON)
        switch self {
        case .localhost:
            return TNEnvironment(scheme: .https,
                                 host: "localhost",
                                 port: 8080,
                                 configuration: configuration)
        case .dev:
            return TNEnvironment(scheme: .https,
                                 host: "mydevserver.com",
                                 suffix: .path(["v1"]),
                                 configuration: configuration)
        case .production:
            return TNEnvironment(scheme: .http,
                                 host: "myprodserver.com",
                                 suffix: .path(["v1"]),
                                 configuration: configuration)
        }
    }
}
```
*Optionally you can  pass a **configuration** object to make all requests inherit the given configuration settings.*

<a name="setup_routers"></a>

#### Setup your Routes
The following code creates a TodosRoute enumeration with all the required routes in order to create the requests later.

```swift
enum TodosRoute: TNRouteProtocol {
    // Define your routes
    case list
    case show(id: Int)
    case add(title: String)
    case remove(id: Int)
    case setCompleted(id: Int, completed: Bool)

    // Set method, path, params, headers for each route
    func configure() -> TNRouteConfiguration {
        let configuration = TNConfiguration(requestBodyType: .JSON,
                                            headers: ["x-auth": "abcdef1234"])

        switch self {
        case .list:
            return TNRouteConfiguration(method: .get,
                                        path: .path(["todos"]), // GET /todos
                                        configuration: configuration)
        case .show(let id):
            return TNRouteConfiguration(method: .get,
                                        path: .path(["todo", String(id)]), // GET /todos/[id]
                                        configuration: configuration)
        case .add(let title):
            return TNRouteConfiguration(method: .post,
                                        path: .path(["todos"]), // POST /todos
                                        params: ["title": title],
                                        configuration: configuration)
        case .remove(let id):
            return TNRouteConfiguration(method: .delete,
                                        path: .path(["todo", String(id)]), // DELETE /todo/[id]
                                        configuration: configuration)
        case .setCompleted(let id, let completed):
            return TNRouteConfiguration(method: .patch,
                                        path: .path(["todo", String(id)]), // PATCH /todo/[id]
                                        params: ["completed": completed],
                                        configuration: configuration)
        }
    }
}
```
You can optionally pass a **configuration** object to specify settings for each route.

<a name="construct_request"></a>

#### Make a request
Use **TNRouter** instance by specializing it with **TodosRoute** to create and execute the request:
```swift
TNRouter<TodosRoute>().request(for: .add(title: "Go shopping!"))
    .start(responseType: Todo.self,
           onSuccess: { todo in
    // do something with todo
}) { (error, data) in
    // show error
}
```

<a name="queue_hooks"></a>

## Queue Hooks
You can define closures that  run before and/or after a request execution in a queue. The following hooks are available:

```swift
TNQueue.shared.beforeAllRequestsCallback = {
    // e.g. show progress loader
}

TNQueue.shared.afterAllRequestsCallback = { completedWithError in
    // e.g. hide progress loader
}

TNQueue.shared.beforeEachRequestCallback = { request in
    // do something with request
}

TNQueue.shared.afterEachRequestCallback = { request, data, urlResponse, error
    // do something with request, data, urlResponse, error
}
```

 For more information take a look at <a href="https://billp.github.io/TermiNetwork/Classes/TNQueue.html" target="_blank">TNQueue</a> in documentation.

<a name="error_handling"></a>

## Error Handling

TermiNetwork provides its own error types (TNError) for all the possible cases. Those errors are typically returned by onFailure callbacks from requests. You can use the **localizedDescription** property to get a localized error message.

To see all the available cases, please visit at <a href="https://billp.github.io/TermiNetwork/Enums/TNError.html" target="_blank">TNError</a> in documentation.


#### Example

```swift
TNRouter<TodosRoute>().request(for: .add(title: "Go shopping!"))
            .start(responseType: Todo.self,
   onSuccess: { todo in
    // do something with todo
   },
   onFailure: { (error, data) in
    switch error {
    case .notSuccess(let statusCode):
        debugPrint("Status code " + String(statusCode))
        break
    case .networkError(let error):
        debugPrint("Network error: " + error.localizedDescription)
        break
    case .cancelled(let error):
        debugPrint("Request cancelled with error: " + error.localizedDescription)
        break
    default:
        debugPrint("Error: " + error.localizedDescription)
    }
})
```
<a name="global_error_handlers"></a>
### Global Error Handlers
TermiNetwork allows you to define your own global error handlers, which means you can have a catch-all error closure to do the handling. To create a global error handler you have to create a class that implements the **TNErrorHandlerProtocol**.

#### Example
```swift 
class GlobalNetworkErrorHandler: TNErrorHandlerProtocol {
    func requestFailed(withResponse response: Data?, error: TNError, request: TNRequest) {
        if case .networkError(let error) = error {
	        /// Do something with the network error
        }
    }

    func shouldHandleRequestFailure(withResponse response: Data?, error: TNError, request: TNRequest) -> Bool {
        return true
    }

    // Add default initializer
    required init() { }
}
```

Then you have to pass them to your configuration object:

#### Example
```swift
let configuration = TNConfiguration()
configuration.errorHandlers = [GlobalNetworkErrorHandler.self]
```

<a name="image_helpers"></a>

## SwiftUI/UIKit Image Helpers 
TermiNetwork provides two different helpers for setting remote images:
### TNImage helper (SwiftUI) 
#### Example


### UIImageView/NSImageView/WKInterfaceImage Extensions

1. **Example with URL**
```swift
let imageView = UIImageView() // or NSImageView (macOS), or WKInterfaceImage (watchOS)
imageView.tn_setRemoteImage(url: sampleImageURL,
                            defaultImage: UIImage(named: "DefaultThumbImage"),
                            preprocessImage: { image in
    // Optionally pre-process image and return the new image.
    return image
}, onFinish: { image, error in
    // Optionally handle response
})
```
2. **Example with TNRequest and Route**
```swift
let imageView = UIImageView() // or NSImageView (macOS), or WKInterfaceImage (watchOS)
imageView.tn_setRemoteImage(request: TNRouter<CityRoute>().request(for: .thumb(withID: "3125")),
                            defaultImage: UIImage(named: "DefaultThumbImage"),
                            preprocessImage: { image in
    // Optionally pre-process image and return the new image.
    return image
}, onFinish: { image, error in
    // Optionally handle response
})
```

<a name="debug_logging"></a>

## Debug Logging

You enable the debug logging by setting the **verbose** to **true** in your configuration
```swift
let configuration = TNConfiguration()
configuration.verbose = true
```
And you will see a beautiful pretty-printed debug output in your console.
<img width="750px" src="https://user-images.githubusercontent.com/1566052/102597522-75be5200-4123-11eb-9e6e-5740e42a20a5.png">

## Tests

To run the tests open the Sample project, select Product -> Test or simply press ⌘U on keyboard.

## Contributors

Alex Athanasiadis, alexanderathan@gmail.com

## License

TermiNetwork is available under the MIT license. See the LICENSE file for more info.
