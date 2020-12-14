//
//  EncryptedModelTransformer.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 14/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class EncryptedModelTransformer: TNTransformer<RSEncryptedModel, EncryptedModel> {
    override func transform(_ object: RSEncryptedModel) throws -> EncryptedModel {
        return EncryptedModel(text: object.value)
    }
}
