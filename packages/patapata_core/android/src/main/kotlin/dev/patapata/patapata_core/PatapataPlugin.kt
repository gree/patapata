/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_core

interface PatapataPlugin {
  val patapataName: String
  fun patapataEnable() {}
  fun patapataDisable() {}
}
