
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
Multi-environment setup 🔸 Model deserialization with <b>Codables</b> 🔸 Choose the response type you want: <b>Codable</b>, <b>UIImage</b>, <b>Data</b> or <b>String</b> 🔸 <b>UIKit</b>/<b>SwiftUI</b> helpers for downloading remote images 🔸 Routers 🔸 Transformers (convert rest models to domain models) 🔸 Error handling 🔸 Mock responses 🔸 Certificate pinning  🔸 Flexible configuration  🔸 Middlewares  🔸 File/Data Upload/Download 🔸 Pretty printed debug information
</p>

#### Table of contents
- [Installation](#installation)
- [Demo Application](#demo_app)
- [Usage](#usage)
  - [Simple usage of <b>Request</b>](#simple_usage)
  - [Advanced usage of <b>Request</b> with <b>Configuration</b> and custom <b>Queue</b>](#advanced_usage)
  - [Complete project setup with <b>Environments</b> and <b>Routers</b> (Recommended)](#complete_setup)
	  - [Environment setup](#setup_environments)
	  - [Router setup](#setup_routers)
	  - [Make a request](#construct_request)
- [Queue Hooks](#queue_hooks)
- [Error Handling](#error_handling)
- [Transformers](#transformers)
- [Mock responses](#mock_responses)
- [Interceptors](#interceptors)
- [Image Helpers](#image_helpers)
	- [SwiftUI Image Helper](#swift_ui_image_helper)
	- [UIImageView, NSImageView, WKInterfaceImage Extensions](#image_extensions)
- [Middlewares](#middlewares)
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

### Simple usage (Request)

Let's say you have the following Codable model:

```swift
struct Todo: Codable {
   let id: Int
   let title: String
}
```

The following example creates a request that adds a new Todo:

```swift
let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

Request(method: .post,
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
A callback that returns an object of the given type. (specified in responseType parameter)

##### onFailure
A callback that returns a **Error** and the response **Data** (if any).

<a name="advanced_usage"></a>

### Advanced usage of Request with Configuration and custom Queue

The following example uses a custom **Queue** with **maxConcurrentOperationCount** and a configuration object. To see the full list of available configuration properties, take a look at <a href="https://billp.github.io/TermiNetwork/Classes/Configuration.html#/Public%20properties" target="_blank">Configuration properties</a> in documentation.

```swift
let myQueue = Queue(failureMode: .continue)
myQueue.maxConcurrentOperationCount = 2

let configuration = Configuration(
    cachePolicy: .useProtocolCachePolicy,
    timeoutInterval: 30,
    requestBodyType: .JSON
)

let params = ["title": "Go shopping."]
let headers = ["x-auth": "abcdef1234"]

Request(method: .post,
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
The request above uses a custom queue **myQueue** with a failure mode of **.continue** (default), which means that the queue continues its execution if a request fails.

<a name="complete_setup"></a>

## Complete setup with <b>Environments</b> and <b>Routers</b>
The complete and recommended setup of TermiNetwork consists of defining **Environments** and **Routers**.  

<a name="setup_environments"></a>

#### Environment setup
Create a swift **enum** that implements the **EnvironmentProtocol** and define your environments. 

##### Example
```swift
enum MyAppEnvironments: EnvironmentProtocol {
    case localhost
    case dev
    case production

    func configure() -> Environment {
        let configuration = Configuration(cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 30,
                                          requestBodyType: .JSON)
        switch self {
        case .localhost:
            return Environment(scheme: .https,
                               host: "localhost",
                               port: 8080,
                               configuration: configuration)
        case .dev:
            return Environment(scheme: .https,
                               host: "mydevserver.com",
                               suffix: .path(["v1"]),
                               configuration: configuration)
        case .production:
            return Environment(scheme: .http,
                               host: "myprodserver.com",
                               suffix: .path(["v1"]),
                               configuration: configuration)
        }
    }
}
```
*Optionally you can  pass a **configuration** object to make all Routers and Requests to inherit the given configuration settings.*

<a name="setup_routers"></a>

#### Router setup
Create a swift **enum** that implements the **RouteProtocol** and define your environments. 

The following example creates a TodosRoute with all the required API routes (cases).

##### Example
```swift
enum TodosRoute: RouteProtocol {
    // Define your routes
    case list
    case show(id: Int)
    case add(title: String)
    case remove(id: Int)
    case setCompleted(id: Int, completed: Bool)

    // Set method, path, params, headers for each route
    func configure() -> RouteConfiguration {
        let configuration = Configuration(requestBodyType: .JSON,
                                          headers: ["x-auth": "abcdef1234"])

        switch self {
        case .list:
            return RouteConfiguration(method: .get,
                                      path: .path(["todos"]), // GET /todos
                                      configuration: configuration)
        case .show(let id):
            return RouteConfiguration(method: .get,
                                      path: .path(["todo", String(id)]), // GET /todos/[id]
                                      configuration: configuration)
        case .add(let title):
            return RouteConfiguration(method: .post,
                                      path: .path(["todos"]), // POST /todos
                                      params: ["title": title],
                                      configuration: configuration)
        case .remove(let id):
            return RouteConfiguration(method: .delete,
                                      path: .path(["todo", String(id)]), // DELETE /todo/[id]
                                      configuration: configuration)
        case .setCompleted(let id, let completed):
            return RouteConfiguration(method: .patch,
                                      path: .path(["todo", String(id)]), // PATCH /todo/[id]
                                      params: ["completed": completed],
                                      configuration: configuration)
        }
    }
}

```
You can optionally pass a **configuration** object to each case if you want provide different  configuration for each route.

<a name="construct_request"></a>

#### Make a request
To create the request you have to initialize a **Router** instance and specialize it with your defined Router, in our case **TodosRoute**:
```swift
Router<TodosRoute>().request(for: .add(title: "Go shopping!"))
    .start(responseType: Todo.self,
           onSuccess: { todo in
    // do something with todo
}) { (error, data) in
    // show error
}
```

<a name="queue_hooks"></a>

## Queue Hooks
Hooks are closures that  run before and/or after a request execution in a queue. The following hooks are available:

```swift
Queue.shared.beforeAllRequestsCallback = {
    // e.g. show progress loader
}

Queue.shared.afterAllRequestsCallback = { completedWithError in
    // e.g. hide progress loader
}

Queue.shared.beforeEachRequestCallback = { request in
    // do something with request
}

Queue.shared.afterEachRequestCallback = { request, data, urlResponse, error
    // do something with request, data, urlResponse, error
}
```

 For more information take a look at <a href="https://billp.github.io/TermiNetwork/Classes/Queue.html" target="_blank">Queue</a> in documentation.

<a name="error_handling"></a>

## Error Handling

TermiNetwork provides its own error types (TNError) for all the possible error cases. These errors are typically returned in onFailure callbacks of **start** methods. 

To see all the available errors, please visit the <a href="https://billp.github.io/TermiNetwork/Enums/TNError.html" target="_blank">TNError</a> in documentation.


#### Example

```swift
Router<TodosRoute>().request(for: .add(title: "Go shopping!"))
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
<a name="transformers"></a>
## Transformers

Transformers enables you to convert your Rest models to Domain models by defining your custom **transform** functions. To do so, you have to create a class that inherits the **Transformer** class and specializing it by providing the FromType and ToType generics.

The following example transforms an array of **RSCity** (rest) to an array of **City** (domain) by overriding the transform function.

#### Example

```swift
final class CitiesTransformer: Transformer<[RSCity], [City]> {
    override func transform(_ object: [RSCity]) throws -> [City] {
        object.map { rsCity in
            City(id: UUID(),
                 cityID: rsCity.id,
                 name: rsCity.name,
                 description: rsCity.description,
                 countryName: rsCity.countryName,
                 thumb: rsCity.thumb,
                 image: rsCity.image)
        }
    }
}
```

Finally, pass the **CitiesTransformer** in the Request's start method:
#### Example
```swift
Router<CityRoute>()
    .request(for: .cities)
    .start(transformer: CitiesTransformer.self,
           onSuccess: { cities in
    // Cities are of type [City] (domain)
    self.cities = cities
}, onFailure: { (error, data) in
   // Handle error
})
```

<a name="mock_responses"></a>
## Mock responses
**Mock responses** is a powerful feature of TermiNetwork that enables you to provide a local resource file as Request's response. This is useful, for example, when the API service is not yet available and you need to implement the app's functionality without losing any time. (Prerequisite for this is to have an API contract) 

#### Steps to enable mock responses

1. Create a Bundle resource and put your files there. (File > New -> File... > Settings Bundle)
2. Specify the Bundle path in Configuration
	#### Example
	```swift
	let configuration = Configuration()
	if let path = Bundle.main.path(forResource: "MockData", ofType: "bundle") {
	    configuration.mockDataBundle = Bundle(path: path)
	}
	```
3. Enable Mock responses in Configuration
	#### Example
 	```swift
	configuration.mockDataEnabled = true
	```
4. Define the mockFilePath path in your Routes
	 #### Example
 	```swift
	enum CityRoute: RouteProtocol {
    case cities

    func configure() -> RouteConfiguration {
        switch self {
        case .cities:
            return RouteConfiguration(method: .get,
                                        path: .path(["cities"]),
                                        mockFilePath: .path(["Cities", "cities.json"]))
	        }
	    }
	}
	```
	The example above loads the **Cities/cities.json** from **MockData.bundle** and returns its data as Request's response.

For a complete example, open the demo application and take a look at **City Explorer - Offline Mode**.

<a name="interceptors"></a>
## Interceptors
Interceptors offers you a way to change or augment the usual processing cycle of a Request.  For instance, you can refresh an expired access token (unauthorized status code 401) and then retry the original request. To do so, you just have to implement the **InterceptorProtocol**.

The following Interceptor implementation tries to refresh the access token with a retry limit (5).

#### Example
```swift
final class UnauthorizedInterceptor: InterceptorProtocol {
    let retryDelay: TimeInterval = 0.1
	let retryLimit = 5

    func requestFinished(responseData data: Data?,
                         error: TNError?,
                         request: Request,
                         proceed: @escaping (InterceptionAction) -> Void) {
        switch error {
        case .notSuccess(let statusCode):
            if statusCode == 401, request.retryCount < retryLimit {
                // Login and get a new token.
                Request(method: .post,
                        url: "https://www.myserviceapi.com/login",
                        params: ["username": "johndoe",
                                 "password": "p@44w0rd"])
                    .start(responseType: LoginResponse.self) { response in
                        let authorizationValue = String(format: "Bearer %@", response.token)

                        // Update the global header in configuration which is inherited by all requests.
                        Environment.current.configuration?.headers["Authorization"] = authorizationValue

                        // Update current request's header.
                        request.headers["Authorization"] = authorizationValue

                        // Finally retry the original request.
                        proceed(.retry(delay: retryDelay))
                    }
            } else {
	            // Continue if the retry limit is reached
	            proceed(.continue)
            }
        default:
            proceed(.continue)
        }
    }
}

```

Finally, you have to pass the **UnauthorizedInterceptor** to the interceptors property in Configuration:

#### Example
```swift
let configuration = Configuration()
configuration.interceptors = [UnauthorizedInterceptor.self]
```

<a name="image_helpers"></a>

## SwiftUI/UIKit Image Helpers
TermiNetwork provides two different helpers for setting remote images.
<a name="swift_ui_image_helper"></a>
### SwiftUI Image Helper
#### Example
1.  **Example with URL**
```swift
var body: some View {
    TermiNetwork.Image(withURL: "https://example.com/path/to/image.png",
	               defaultImage: UIImage(named: "DefaultThumbImage"))
}
```
2.  **Example with Request**
```swift
var body: some View {
    TermiNetwork.Image(withRequest: Router<CityRoute>().request(for: .image(city: city)),
                       defaultImage: UIImage(named: "DefaultThumbImage"))
}
```

<a name="image_extensions"></a>
### UIImageView, NSImageView, WKInterfaceImage Extensions

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
2. **Example with Request**
```swift
let imageView = UIImageView() // or NSImageView (macOS), or WKInterfaceImage (watchOS)
imageView.tn_setRemoteImage(request: Router<CityRoute>().request(for: .thumb(withID: "3125")),
                            defaultImage: UIImage(named: "DefaultThumbImage"),
                            preprocessImage: { image in
    // Optionally pre-process image and return the new image.
    return image
}, onFinish: { image, error in
    // Optionally handle response
})
```

<a name="middlewares"></a>

## Middlewares
Middlewares enables you to modify headers, params and response before they reach the success/failure callbacks. You can create your own middlewares by implementing the **RequestMiddlewareProtocol** and passing it to a **Configuration** object.

Take a look at *./Examples/Communication/Middlewares/CryptoMiddleware.swift*  for an example that adds an additional encryption layer to the application.

<a name="debug_logging"></a>

## Debug Logging

You can enable the debug logging by setting the **verbose** property to **true** in your **Configuration**.
```swift
let configuration = Configuration()
configuration.verbose = true
```
... and you will see a beautiful pretty-printed debug output in debug window

<img width="750px" src="https://user-images.githubusercontent.com/1566052/102597522-75be5200-4123-11eb-9e6e-5740e42a20a5.png">

## Tests

To run the tests open the Xcode Project > TermiNetwork scheme, select Product -> Test or simply press ⌘U on keyboard.

## Contributors

Alex Athanasiadis, alexanderathan@gmail.com

## License

TermiNetwork is available under the MIT license. See the LICENSE file for more info.
