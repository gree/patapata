/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package dev.patapata.patapata_core

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

private val Context.nativeLocalConfigStore: DataStore<Preferences> by preferencesDataStore(name = "dev.patapata.native_local_config")

class NativeLocalConfig(private val context: Context, messenger: BinaryMessenger) : PatapataPlugin, MethodChannel.MethodCallHandler {
  private val mChannel : MethodChannel = MethodChannel(messenger, "dev.patapata.native_local_config")
  private val mMainScope = CoroutineScope(Dispatchers.Main)
  private var mJob: Job? = null

  override val patapataName: String
    get() = "dev.patapata.native_local_config"

  override fun patapataEnable() {
    mChannel.setMethodCallHandler(this)

    mJob = mMainScope.launch {
      context.nativeLocalConfigStore.data
        .map {
          it.asMap().map { entry -> entry.key.name to entry.value }.toMap()
        }
        .onEach {
          withContext(Dispatchers.Main) {
            mChannel.invokeMethod("syncAll", it)
          }
        }
        .cancellable()
        .catch {
          withContext(Dispatchers.Main) {
            mChannel.invokeMethod("error", it.toPatapataMap())
          }
        }
        .collect()
    }
  }

  override fun patapataDisable() {
    mJob?.cancel()
    mJob = null
    mChannel.setMethodCallHandler(null)
    super.patapataDisable()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val tExceptionHandler = CoroutineExceptionHandler { _, exception ->
      result.error(Error.PPENLC000.name, null, exception.toPatapataMap())
    }

    mMainScope.launch(tExceptionHandler) {
      when (call.method) {
        "reset" -> context.nativeLocalConfigStore.edit {
          // PreferenceKey's equality only checks the name.
          it.remove(stringPreferencesKey(call.arguments as String))
          result.success(null)
        }
        "resetMany" -> context.nativeLocalConfigStore.edit { store ->
          (call.arguments as? List<*>)?.forEach {
            // PreferenceKey's equality only checks the name.
            store.remove(stringPreferencesKey(it as String))
          }

          result.success(null)
        }
        "resetAll" -> context.nativeLocalConfigStore.edit {
          it.clear()
          result.success(null)
        }
        "setBool" -> context.nativeLocalConfigStore.edit {
          val tArgs = call.arguments as List<*>
          it[booleanPreferencesKey(tArgs[0] as String)] = tArgs[1] as Boolean
          result.success(null)
        }
        "setInt" -> context.nativeLocalConfigStore.edit {
          val tArgs = call.arguments as List<*>
          it[intPreferencesKey(tArgs[0] as String)] = tArgs[1] as Int
          result.success(null)
        }
        "setDouble" -> context.nativeLocalConfigStore.edit {
          val tArgs = call.arguments as List<*>
          it[doublePreferencesKey(tArgs[0] as String)] = tArgs[1] as Double
          result.success(null)
        }
        "setString" -> context.nativeLocalConfigStore.edit {
          val tArgs = call.arguments as List<*>
          it[stringPreferencesKey(tArgs[0] as String)] = tArgs[1] as String
          result.success(null)
        }
        "setMany" -> context.nativeLocalConfigStore.edit { store ->
          (call.arguments as? Map<*, *>)?.forEach {
            val tKey = it.key

            if (tKey is String) {
              when (val tValue = it.value) {
                is Boolean -> store[booleanPreferencesKey(tKey)] = tValue
                is Int -> store[intPreferencesKey(tKey)] = tValue
                is Double -> store[doublePreferencesKey(tKey)] = tValue
                is String -> store[stringPreferencesKey(tKey)] = tValue
              }
            }
          }
          result.success(null)
        }
      }
    }
  }
}
