// Queue.swift
//
// Copyright © 2018-2021 Vasilis Panagiotopoulos. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

/// Type that specifies the behavior of the queue when a request fails
public enum QueueFailureMode {
    /// Cancels the execution of the queue after a request (operation) fails
    case cancelAll
    /// Continues the execution of the queue after a request (operation) fails
    case `continue`
}

/// Hook type for beforeAllRequestsCallback queue property
public typealias BeforeQueueStartCallbackType = () -> Void
/// Hook type for afterAllRequestsCallback queue property
/// - Parameters:
///   - hasError:Passes a Boolean value which indicates if any of the request in queue has completed with error.
public typealias AfterAllRequestsCallbackType = (_ hasError: Bool) -> Void
/// Hook type for beforeEachRequestCallback queue property
/// - Parameters:
///   - request:The actual Request instance.
public typealias BeforeEachRequestCallbackType = (_ request: Request) -> Void
/// Hook type for afterEachRequestCallback queue property
/// - Parameters:
///   - request:The actual Request instance.
///   - data: The response data
///   - response: The URLResponse
///   - error:The network error (if any)
public typealias AfterEachRequestCallbackType = (
    _ request: Request,
    _ data: Data?,
    _ response: URLResponse?,
    _ error: Error?) -> Void

/// Use this class to create custom queues.
public final class Queue: OperationQueue {
    // MARK: Static properties

    /// The default queue of TermiNetwork used in all Request objects.
    public static var shared = Queue()

    // MARK: Private properties

    private var completedWithError = false

    // MARK: Hooks

    /// A closure to be executed before the queue starts executing its requests.
    public var beforeAllRequestsCallback: BeforeQueueStartCallbackType?
    /// A closure to be executed after the queue finishes the execution of all its requests.
    public var afterAllRequestsCallback: AfterAllRequestsCallbackType?
    /// A closure to be executed before a request execution in queue.
    public var beforeEachRequestCallback: BeforeEachRequestCallbackType?
    /// A closure to be executed after a request finishes its execution in queue.
    public var afterEachRequestCallback: AfterEachRequestCallbackType?

    internal var failureMode: QueueFailureMode = .continue

    // MARK: Initializers

    /// Initializes a new queue.
    ///
    /// - parameters:
    ///     - failureMode: Supported values are .continue (continues the execution of queue even if a request fails,
    ///      this is the default) and .cancelAll (cancels all the remaining requests in queue)
    public init(failureMode: QueueFailureMode = .continue) {
        super.init()

        self.failureMode = failureMode
    }

    internal func afterOperationFinished(request: Request,
                                         data: Data?,
                                         response: URLResponse?,
                                         tnError: Error?) {
        self.completedWithError = tnError != nil ? true : self.completedWithError

        if self.operationCount == 0 {
            afterAllRequestsCallback?(self.completedWithError)
            self.completedWithError = false
        }

        afterEachRequestCallback?(request, data, response, tnError)
    }

    // MARK: Public methods

    /// Adds a Request instance into queue.
    ///
    /// - parameters:
    ///     - failureMode: Supported values are .continue (continues the execution of queue even if a request fails,
    ///      this is the default) and .cancelAll (cancels all the remaining requests in queue)
    override public func addOperation(_ operation: Foundation.Operation) {
        guard !operation.isExecuting && !operation.isFinished else {
            return
        }
        if operationCount == 0 {
            beforeAllRequestsCallback?()
        }

        if let request = operation as? Request {
            guard !request.shouldMockResponse() else {
                return
            }
            guard request.dataTask != nil else {
                return
            }
        }

        super.addOperation(operation)
    }
}
