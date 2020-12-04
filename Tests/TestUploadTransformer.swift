//
//  TestUploadTransformer.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 4/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class TestUploadTrasnformer: TNTransformer<FileResponse, TestModel> {
    override func transform(_ object: FileResponse) -> TestModel {
        let testModel = TestModel()
        testModel.name = object.checksum
        return testModel
    }
}
