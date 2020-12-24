//
//  TestUploadTransformer.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 4/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class TestUploadTrasnformer: Transformer<FileResponse, TestModel> {
    override func transform(_ object: FileResponse) -> TestModel {
        let testModel = TestModel(value: object.checksum,
                                  param: object.param)
        return testModel
    }
}
