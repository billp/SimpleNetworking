


<p align="center">
  <img src="https://raw.githubusercontent.com/billp/TermiNetwork/master/TermiNetworkLogo.svg" alt="" data-canonical-src="" width="80%" />
</p>

<p align="center"><b>A zero-dependency networking solution for building modern and secure iOS applications.</b>
  <br /><br />
  <img src="https://img.shields.io/badge/Language-Swift%205-blue" />
  <img src="https://travis-ci.org/billp/TermiNetwork.svg?branch=1.0.0-new-structure" />
  <img src="https://img.shields.io/cocoapods/v/TermiNetwork.svg?style=flat" />
  <img src="https://img.shields.io/github/license/billp/TermiNetwork" />
  <img src="https://img.shields.io/cocoapods/p/TermiNetwork" />
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
	  - [Parameters](#parameters)
  - [Advanced usage of <b>TNRequest</b> with <b>Configuration</b> and custom <b>Queue</b>](#advanced_usage)
	  - [Additional Parameters](#parameters)
  - [Complete project setup with <b>Environments</b> and <b>Routers</b> (Recommended)](#complete_setup)
	  - [Setup your Environments](#setup_environments)
- [Debug Logging](#debug_logging)

<a name="installation" />

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

<a name="demo_app" />

## Demo Application
To see all the features of TermiNetwork in action, download the source code and run the **TermiNetworkExamples** scheme.

<a name="usage" />

## Usage

<a name="simple_usage" />

### Simple usage (TNRequest)

Let's say you have the following Codable model

```swift
struct Todo: Codable {
   let id: Int
   let title: String
}
```

You construct the request to add a new Todo with title "Go shopping." like this:

```swift
let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

TNRequest(method: .post,
          url: "https://myweb.com/api/todos",
          headers: headers,
          params: params).start(responseType: Todo.self, onSuccess: { todo in
	print(todo)
}) { (error, data) in
    print(error)
}
```
<a name="parameters" />

#### Parameters

##### method
One of the following supported HTTP methods:
```
.get, .head, .post, .put, .delete, .connect, .options, .trace or .patch
```

##### responseType
One of the following supported response types
```
JSON.self, Codable.self, UIImage.self, Data.self or String.self
```

##### onSuccess
A callback returning an object of type specified in responseType.

##### onFailure
a callback returning **TNError** and optionally the response data **Data**.

<a name="advanced_usage" />

### Advanced usage of TNRequest with Configuration and custom Queue

```swift
let myQueue = TNQueue(failureMode: .continue)
myQueue.maxConcurrentOperationCount = 2

let configuration = TNRequestConfiguration(
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
The request above uses a custom queue *myQueue* with a failure mode of value *.continue* (default), which means that the queue continues its execution even if a request fails, and also sets the maximum concurrent operation count to 2. Finally, it uses a TNRequestConfiguration object to provide some additional settings.

#### Additional parameters

##### configuration (optional)
The configuration object to use.
- *cachePolicy*: The **NSURLRequest.CachePolicy** used by **NSURLRequest**. Default value: *.useProtocolCachePolicy* (see apple docs for available values)
- *timeoutInterval*: The timeout interval used by NSURLRequest internally. Default value: 60 (see apple docs for more info)
- *requestBodyType*: It specifies the content type of request params. Available values:
  - .xWWWFormURLEncoded (default): The params are being sent with 'application/x-www-form-urlencoded' content type.
  - .JSON: The params are being sent with 'application/json' content type.

##### queue (optional)
Specifies the queue in which the request will be added. If you omit this argument, the request will be added to a shared queue **TNQueue.shared**.

<a name="complete_setup" />

## Complete setup with <b>Environments</b> and routers <b>Routers</b>
The complete and recommended usage of TermiNetwork library consists of creating your environments and define your routers.  

<a name="setup_environments" />

#### Setup your Environments
Create a swift class that implements the **TNEnvironmentProtocol** and define your environments. See bellow for an example:
```swift
enum Environment: TNEnvironmentProtocol {
    case localhost
    case dev
    case production

    func configure() -> TNEnvironment {
        let requestConfiguration = TNRequestConfiguration(cachePolicy: .useProtocolCachePolicy,
                                                          timeoutInterval: 30,
                                                          requestBodyType: .JSON)
        switch self {
        case .localhost:
            return TNEnvironment(scheme: .https,
                                 host: "localhost",
                                 port: 8080,
                                 requestConfiguration: requestConfiguration)
        case .dev:
            return TNEnvironment(scheme: .https,
                                 host: "mydevserver.com",
                                 suffix: path("v1"),
                                 requestConfiguration: requestConfiguration)
        case .production:
            return TNEnvironment(scheme: .http,
                                 host: "myprodserver.com",
                                 suffix: path("v1"),
                                 requestConfiguration: requestConfiguration)
        }
    }
}
```
*Optionally you can  pass a **requestConfiguration** object to make all requests inherit the configuration settings.*

#### TodosRouter.swift

```swift
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
            return TNRouteConfiguration(method: .get, path: path("todos"), headers: headers, requestConfiguration: configuration) // GET /todos
        case .show(let id):
            return TNRouteConfiguration(method: .get, path: path("todo", String(id)), headers: headers, requestConfiguration: configuration) // GET /todos/[id]
        case .add(let title):
            return TNRouteConfiguration(method: .post, path: path("todos"), params: ["title": title], headers: headers, requestConfiguration: configuration) // POST /todos
        case .remove(let id):
            return TNRouteConfiguration(method: .delete, path: path("todo", String(id)), headers: headers, requestConfiguration: configuration) // DELETE /todo/[id]
        case .setCompleted(let id, let completed):
            return TNRouteConfiguration(method: .patch, path: path("todo", String(id)), params: ["completed": completed], headers: headers, requestConfiguration: configuration) // PATCH /todo/[id]
        }
    }
}
```
You can optionally pass a requestConfiguration object to specify settings for each route. (see 'Advanced usage with configuration and custom queue' above for instructions of how to create a configuration object.)


#### Finally use the TNRouter to start a request

```swift
TNRouter.start(TodosRouter.add(title: "Go shopping!"), responseType: Todo.self, onSuccess: { todo in
    // do something with todo
}) { (error, data) in
    // show error
}
```

## TNQueue Hooks
Hooks run before and/or after a request execution in a queue. The following hooks are executed in the default queue:

```swift
TNQueue.shared.beforeAllRequestsCallback = {
    // e.g. show progress loader
}

TNQueue.shared.afterAllRequestsCallback = { completedWithError in // Bool
    // e.g. hide progress loader
}

TNQueue.shared.beforeEachRequestCallback = { request in // TNRequest
    // e.g. print log
}

TNQueue.shared.afterEachRequestCallback = { request, data, urlResponse, error in // request: TNRequest, data: Data, urlResponse: URLResponse, error: Error
    // e.g. print log
}
```

## Error Handling

Available error cases (TNError) passed in *onFailure* callback of a TNRequest:
- *.environmentNotSet*: You didn't set the Environment.
- *.invalidURL*: The url cannot be parsed, e.g. it contains invalid characters.
- *.responseDataIsEmpty*: the server response body is empty. You can avoid this error by setting *TNRequest.allowEmptyResponseBody* to *true*.
- *.responseInvalidImageData*: failed to convert response Data to UIImage.
- *.cannotDeserialize(Error)*: e.g. your model's structure and types doesn't match with the server's response. It carries the the error thrown by deserializer (DecodingError.dataCorrupted),
- *.cannotConvertToJSON*: cannot convert the response Data to JSON object (SwiftyJSON).
- *.networkError(Error)*: e.g. timeout error. It carries the error from URLSessionDataTask.
- *.notSuccess(Int)*: The http status code is different from *2xx*. It carries the actual status code of the completed request.
- *.cancelled(Error)*: The request is cancelled. It carries the error from URLSessionDataTask.

In any case you can use the **error.localizedDescription** method to get a readable error message in onFailure callback.

#### Example

```swift
TNRequest(method: .get, url: "https://myweb.com/todos").start(responseType: JSON.self, onSuccess: { json in
            print(json)
        }) { (error, data) in
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
        }
```

## UIImageView Extension
You can use the *setRemoteImage* method of UIImageView to download an image from a remote server

Example:
```swift
imageView.setRemoteImage(url: "http://www.website.com/image.jpg", defaultImage: UIImage(named: "DefaultImage"), beforeStart: {
	imageView.activityIndicator.startAnimating()
}, preprocessImage: { image in // This block will run in background
	let newImage = image.resize(100, 100)
	return newImage
}) { image, error in
	imageView.activityIndicator.stopAnimating()
}
```

<a name="debug_logging" />

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
