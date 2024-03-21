/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_karte_core

import android.util.Log
import androidx.annotation.NonNull
import dev.patapata.patapata_core.PatapataPlugin
import dev.patapata.patapata_core.registerPatapataPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.karte.android.KarteApp

/** PatapataKarteCorePlugin */
class PatapataKarteCorePlugin: FlutterPlugin, PatapataPlugin {

  private var mIsSetup = false
  private var mIsEnabled = false
  private var mBinding: FlutterPlugin.FlutterPluginBinding? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    mBinding = flutterPluginBinding
    flutterPluginBinding.registerPatapataPlugin(this)

    if (mIsEnabled) {
      setup()
    }
  }

  private fun setup() {
    mBinding?.apply {
      mIsSetup = true
      val tKarteAppKey = applicationContext.resources.getIdentifier("patapata_karte_app_key", "string", applicationContext.packageName)
      if (tKarteAppKey != 0) {
        //KarteApp.setLogLevel(LogLevel.DEBUG)
        KarteApp.setup(applicationContext, applicationContext.getString(tKarteAppKey))

        if (!mIsEnabled) {
          KarteApp.optOut()
        }
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    KarteApp.optOut()
    mBinding = null
  }

  override fun patapataEnable() {
    mIsEnabled = true

    if (!mIsSetup) {
      setup()
    }
  }

  override fun patapataDisable() {
    mIsEnabled = false

    if (mIsSetup) {
      KarteApp.optOut()
    }
  }

  override val patapataName: String
    get() = "KarteCorePlugin<Environment>"
}
