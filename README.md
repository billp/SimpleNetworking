<p align="center">
  <img src="https://raw.githubusercontent.com/billp/TermiNetwork/master/TermiNetworkLogo.svg" alt="" data-canonical-src="" width="80%" />
</p>

[![Build Status](https://travis-ci.org/billp/TermiNetwork.svg?branch=master)](https://travis-ci.org/billp/TermiNetwork)
[![Pod](https://img.shields.io/cocoapods/v/TermiNetwork.svg?style=flat)](https://cocoapods.org/pods/terminetwork)
[![Tweet](https://img.shields.io/twitter/url/https/github.com/billp/TermiNetwork.svg?style=social)](https://twitter.com/home?status=https%3A%2F%2Fgithub.com%2Fbillp%2FTermiNetwork%20TermiNetwork%20is%20a%20networking%20abstraction%20layer%20written%20on%20top%20of%20Swift%27s%20URLRequest%20that%20supports%20multi-environment%20configuration%2C%20routing%20and%20automatic%20deserialization.)

TermiNetwork is a networking abstraction layer written on top of Swift's URLRequest and it is designed to work with Codables.

# Features
- Automatic model deserialization with Codable
- Multi-environment configuration
- Convert responses to the wanted type (Codable model, UIImage, Data or String)
- Request fragmentation with Routes (perfect for modular environments)
- Error handling
- Mock requests
- Certificate pinning
- Flexible configuration
- Middlewares (e.g. you can add an extra layer of encryption to your requests)
- File upload and download (with files or raw data)
- Descriptive debug information right in the console

## Installation

TermiNetwork is available via [CocoaPods](http://cocoapods.org).  Simply add the following lines to your Podfile and run **pod install** from your terminal:

```ruby
platform :ios, '9.0'
use_frameworks!

target 'YourTarget' do
    pod 'TermiNetwork', '~> 0.3'
end
```

## Usage

### Simple usage

Imagine that you have the following Codable model

```swift
struct Todo: Codable {
   let id: Int
   let title: String
}
```

You can call the **TNRequest(...).start(...)** to add a new Todo with the title "Go shopping." like this:

```swift
let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

TNRequest(method: .post, url: "https://myweb.com/api/todos", headers: headers, params: params).start(responseType: Todo.self, onSuccess: { todo in
    print(todo)
}) { (error, data) in
    print(error)
}
```

If the request completes successfully (2xx), a new instance of Todo is being created and passed in onSuccess callback. If the deserialization fails for any reason, the onFailure callback is being called with the appropriate error. See more information about errors in *Error Handling* section.


The JSON response of the service is the following:

```swift
{
   "id": 5,
   "title": "Go shopping."
}
```


#### Parameters

**method**: one of the following supported HTTP methods

```
.get, .head, .post, .put, .delete, .connect, .options, .trace or .patch
```

**responseType**: one of the following supported response types
```
JSON.self, Codable.self, UIImage.self, Data.self or String.self
```

**onSuccess**: a callback returning an object with the data type specified by

**onFailure**: a callback returning an error+data on failure. There are two cases when this callback being called: the first is that the http status code is different than 2xx and the second is that there is an error with data conversion, e.g. it fails on deserialization of the *responseType*.

### Advanced usage with configuration and custom queue

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
          configuration: configuration).start(queue: myQueue, responseType: JSON.self, onSuccess: { json in
    print(json)
}) { (error, data) in
    print(error)
}
```
The request above uses a custom queue *myQueue* with a failure mode of value *.continue* (default), which means that the queue continues its execution even if a request fails, and also sets the maximum concurrent operation count to 2. Finally, it uses a TNRequestConfiguration object to provide some additional settings.

#### Additional parameters

**configuration (optional)**: The configuration object to use. The available configuration properties are:
- *cachePolicy*: The NSURLRequest.CachePolicy used by NSURLRequest internally. Default value: *.useProtocolCachePolicy* (see apple docs for available values)
- *timeoutInterval*: The timeout interval used by NSURLRequest internally. Default value: 60 (see apple docs for more info)
- *requestBodyType*: It specifies the content type of request params. Available values:
  - .xWWWFormURLEncoded (default): The params are being sent with 'application/x-www-form-urlencoded' content type.
  - .JSON: The params are being sent with 'application/json' content type.

**queue (optional):** Specify the queue in which the request will be  added. If you omit this argument, the request will be added to a shared queue (TNQueue.shared).

## Router
You can organize your requests by creating an Environment (class) and a Router (enum) that conform TNEnvironmentProtocol and TNRouterProtocol respectively. To do so, create an environment enum and at least one router class as shown bellow:

#### Environment.swift

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
You can optionally pass a requestConfiguration object to make all requests inherit the specified settings. (see 'Advanced usage with configuration and custom queue' above for how to create a configuration object.)

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

## Logging

You can turn on verbose mode to see what's going on in terminal for each request by setting the **TNEnvironment.verbose** to **true**

## Tests

To run the tests open the Sample project, select Product -> Test or simply press ⌘U on keyboard.

## TODO
- [x] Write test cases
- [x] Add support for request cancelation
- [x] Error handling
- [ ] Add support for downloading/uploading files

## Contribution

Feel free to contribute to the project by creating a pull request and/or by reporting any issue(s) you find

## Author

Bill Panagiotopoulos, billp.dev@gmail.com

## Contributors

Alex Athanasiadis, alexanderathan@gmail.com

## License

TermiNetwork is available under the MIT license. See the LICENSE file for more info.
