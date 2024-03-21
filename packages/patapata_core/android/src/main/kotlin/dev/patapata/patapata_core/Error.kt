/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_core

fun Throwable.toPatapataMap() : Map<String, Any?> {
  return mapOf(
    "type" to javaClass.name,
    "message" to message,
    "stackTrace" to stackTrace.map { it.toString() },
    "cause" to cause?.run { toPatapataMap() }
  )
}

enum class Error {
  PPE000,
  PPENLC000
}
