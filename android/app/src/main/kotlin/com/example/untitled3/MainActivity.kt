package com.example.untitled3

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), SensorEventListener{
    lateinit var sm : SensorManager
    val channel: String = "wasd"
    var long: Long = 0
    lateinit var methodChannel: MethodChannel
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sm = getSystemService(SENSOR_SERVICE) as SensorManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,channel)
        methodChannel.setMethodCallHandler { call, result ->
            val sp = getSharedPreferences("MoveGoPrefs",MODE_PRIVATE)
            when(call.method){
                "save" ->{
                    val js = call.argument<String>("json")
                    sp.edit().putString("app_data",js).apply()
                    result.success(true)
                }
                "load" ->{
                    val sj = sp.getString("app_data","")
                    result.success(sj)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        sm.registerListener(this,sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),1)
        sm.registerListener(this,sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE),1)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            when(it.sensor.type){
                Sensor.TYPE_ACCELEROMETER ->{
                    val x = it.values[0]
                    val y = it.values[1]
                    val z = it.values[2]
                    val a = sqrt(x*x+y*y+z*z)
                    if (a > 15){
                        val n = System.currentTimeMillis()
                        if (n - long > 15){
                            long = n
                            methodChannel.invokeMethod("onsss",null)
                        }
                    }
                }
                Sensor.TYPE_GYROSCOPE ->{
                    val gd = mapOf(
                        "x" to it.values[0],
                        "y" to it.values[1]
                    )
                    methodChannel.invokeMethod("onggg",gd)
                }
            }
        }
    }
}
