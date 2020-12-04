//
//  TestTransformer.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 3/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class TestTransformer: TNTransformer<TestParams, TestModel> {
    override func transform(_ object: TestParams) -> TestModel {
        let model = TestModel()
        model.name = object.param1

        return model
    }
}
