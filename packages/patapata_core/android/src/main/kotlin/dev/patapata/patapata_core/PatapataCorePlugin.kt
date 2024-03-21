/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_core

import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.Keep
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

private class PatapataPluginContainer(val plugin: PatapataPlugin, val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding)

private val sPlugins = mutableSetOf<PatapataPluginContainer>()

/** PatapataCorePlugin */
class PatapataCorePlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var mChannel : MethodChannel
  private lateinit var mBinding : FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    mBinding = flutterPluginBinding
    // Lines up with Flutter's override of Dart's Directory.systemTemp directory.
    val tNativeLibDirectoryInfoFile = File(flutterPluginBinding.applicationContext.codeCacheDir, "patapataNativeLib")

    if (tNativeLibDirectoryInfoFile.exists()) {
      tNativeLibDirectoryInfoFile.delete()
    }

    tNativeLibDirectoryInfoFile.writeText(flutterPluginBinding.applicationContext.applicationInfo.nativeLibraryDir)

    mChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "dev.patapata.patapata_core")
    mChannel.setMethodCallHandler(this)

    // Register default plugins.
    flutterPluginBinding.registerPatapataPlugin(NativeLocalConfig(mBinding.applicationContext, mBinding.binaryMessenger))
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "enablePlugin" -> {
        val tName = call.arguments as? String

        if (tName == null) {
          result.error(Error.PPE000.name, "Invalid plugin name passed to enablePlugin", null)

          return
        }

        enablePlugin(tName)
        result.success(null)
      }
      "disablePlugin" -> {
        val tName = call.arguments as? String

        if (tName == null) {
          result.error(Error.PPE000.name, "Invalid plugin name passed to disablePlugin", null)

          return
        }

        disablePlugin(tName)
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    mChannel.setMethodCallHandler(null)
  }

  private fun enablePlugin(pluginName: String) {
    sPlugins.firstOrNull {
      it.plugin.patapataName == pluginName && it.flutterPluginBinding.binaryMessenger == mBinding.binaryMessenger
    }?.plugin?.patapataEnable()
  }

  private fun disablePlugin(pluginName: String) {
    sPlugins.firstOrNull {
      it.plugin.patapataName == pluginName && it.flutterPluginBinding.binaryMessenger == mBinding.binaryMessenger
    }?.plugin?.patapataDisable()
  }
}

fun FlutterPlugin.FlutterPluginBinding.registerPatapataPlugin(plugin: PatapataPlugin) {
  sPlugins.removeAll { it.plugin == plugin }
  sPlugins.add(PatapataPluginContainer(plugin, this))
}

fun FlutterPlugin.FlutterPluginBinding.unregisterPatapataPlugin(plugin: PatapataPlugin) {
  sPlugins.removeAll { it.plugin == plugin }
}
