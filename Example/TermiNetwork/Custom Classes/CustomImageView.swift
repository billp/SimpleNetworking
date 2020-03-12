//
//  SNImageView.swift
//  SimpleNetworking_Example
//
//  Created by Vasilis Panagiotopoulos on 19/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import TermiNetwork

class CustomImageView: UIImageView {
    var call: TNRequest?

    var url: String! {
        didSet {
            try? self.setRemoteImage(url: url, defaultImage: nil, beforeStart: nil, preprocessImage: nil, onFinish: nil)
        }
    }
}
