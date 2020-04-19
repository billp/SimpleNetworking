// TNQueue.swift
//
// Copyright © 2018-2020 Vasilis Panagiotopoulos. All rights reserved.
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

///
/// Type that specifies the behavior of the queue when a request fails
///
public enum TNQueueFailureMode {
    /// Cancels the execution of the queue after a request (operation) fails
    case cancelAll
    /// Continues the execution of the queue after a request (operation) fails
    case `continue`
}

public typealias TNBeforeAllRequestsCallbackType = () -> Void
public typealias TNAfterAllRequestsCallbackType = (_ error: Bool) -> Void
public typealias TNBeforeEachRequestCallbackType = (_ request: TNRequest) -> Void
public typealias TNAfterEachRequestCallbackType = (
    _ request: TNRequest,
    _ data: Data?,
    _ response: URLResponse?,
    _ error: Error?) -> Void

open class TNQueue: OperationQueue {
    // MARK: - Static variables
    public static var shared = TNQueue()

    // MARK: - Private variables
    private var completedWithError = false

    // MARK: - Pulblic variables
    public var beforeAllRequestsCallback: TNBeforeAllRequestsCallbackType?
    public var afterAllRequestsCallback: TNAfterAllRequestsCallbackType?
    public var beforeEachRequestCallback: TNBeforeEachRequestCallbackType?
    public var afterEachRequestCallback: TNAfterEachRequestCallbackType?

    var failureMode: TNQueueFailureMode!

    ///
    /// Initializes a new queue.
    ///
    /// parameters:
    ///  failureMode: Supported values are .continue (continues the execution of queue even if a request fails,
    ///      this is the default) and .cancelAll (cancels all the remaining requests in queue)
    ///
    public init(failureMode: TNQueueFailureMode = .continue) {
        super.init()

        self.failureMode = failureMode
    }

    internal func beforeOperationStart(request: TNRequest) {
        if operationCount == 0 {
            beforeAllRequestsCallback?()
        }
        beforeEachRequestCallback?(request)
    }

    internal func afterOperationFinished(request: TNRequest, data: Data?, response: URLResponse?, error: Error?) {
        self.completedWithError = error != nil ? true : self.completedWithError

        if self.operationCount == 0 {
            afterAllRequestsCallback?(self.completedWithError)
            self.completedWithError = false
        }

        afterEachRequestCallback?(request, data, response, error)
    }

    override open func addOperation(_ operation: Operation) {
        if let request = operation as? TNRequest {
            guard !request.shouldMockRequest() else {
                return
            }
        }

        super.addOperation(operation)
    }
}
