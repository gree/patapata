// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.


public protocol PatapataPlugin {
    var patapataName: String { get }
    func patapataEnable()
    func patapataDisable()
}

public extension PatapataPlugin {
    func patapataEnable() {}
    func patapataDisable() {}
}
