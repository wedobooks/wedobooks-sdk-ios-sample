//
//  OrientationNavController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
//

import UIKit

public class OrientationNavController: UINavigationController {
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? .all
    }

    override public var shouldAutorotate: Bool {
        topViewController?.shouldAutorotate ?? true
    }
}
