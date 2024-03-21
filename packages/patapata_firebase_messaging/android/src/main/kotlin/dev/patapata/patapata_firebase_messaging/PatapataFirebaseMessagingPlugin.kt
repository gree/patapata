/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_firebase_messaging

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** PatapataFirebaseMessagingPlugin */
class PatapataFirebaseMessagingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  private lateinit var mChannel : MethodChannel
  private lateinit var mBinding : FlutterPlugin.FlutterPluginBinding
  private lateinit var mActivity : Activity
  private lateinit var mPluginBinding : ActivityPluginBinding
  private var mResult: Result? = null

  companion object {
    const val PERMISSION_REQUEST_CODE = 1001
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    mBinding = flutterPluginBinding
    mChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "dev.patapata.patapata_firebase_messaging")
    mChannel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "requestPermission" -> {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
          result.success(true)
        } else {
          val tResult: Int = ContextCompat.checkSelfPermission(
            mBinding.applicationContext, Manifest.permission.POST_NOTIFICATIONS)

          if (tResult == PackageManager.PERMISSION_DENIED) {
            ActivityCompat.requestPermissions(
              mActivity,
              arrayOf(Manifest.permission.POST_NOTIFICATIONS),
              PERMISSION_REQUEST_CODE
            )
            // このタイミングでユーザが許可したかどうかは判定されないため,onRequestPermissionsResultで実行する
            mResult = result
          } else {
            // 既に通知許可されている場合
            result.success(true)
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
    // 通知許可のダイアログを出した後、許可・許可しないの選択をした時の処理
    if (requestCode == PERMISSION_REQUEST_CODE) {
      val tIsSuccess : Boolean = (grantResults.isNotEmpty() &&
        grantResults[0] == PackageManager.PERMISSION_GRANTED)
      mResult?.success(tIsSuccess)
      mResult = null
      return tIsSuccess
    }

    return false
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    mChannel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    mPluginBinding = binding
    mActivity = binding.activity
    mPluginBinding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

  }

  override fun onDetachedFromActivity() {
    mPluginBinding.removeRequestPermissionsResultListener(this)
  }
}
