package com.learnx.mapd_demo

import io.flutter.embedding.android.FlutterActivity


import android.annotation.SuppressLint
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.location.Location
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.provider.Settings
import androidx.annotation.NonNull
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "wificustom"
    var wifi: WifiManager? = null
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            // Note: this method is invoked on the main thread.
            if (call.method == "getAllWifi") {
                val allwifi = getWifi()
                result.success(allwifi);
            } else {
                result.notImplemented()
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun getWifi(): HashMap<String, List<Any?>>? {
        wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        var loc: Location? =null;
        fusedLocationClient.lastLocation
                .addOnSuccessListener { location : Location? ->
                    loc = location
                    print(loc.toString())
                }



        val alertDialog = AlertDialog.Builder(this)
        alertDialog.setTitle("Confirm...")
        alertDialog.setMessage("Scanning requires WiFi.")
        alertDialog.setPositiveButton("Turn on WiFi"
        ) { dialog, which -> // Activity transfer to wifi settings
            startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
        }
        alertDialog.setCancelable(false)
        if (!wifi!!.isWifiEnabled) {
            alertDialog.show()
        }

        wifi!!.startScan()
        var results: List<ScanResult>? =wifi!!.scanResults
        val resultsData: HashMap<String,List<Any?>>? = HashMap<String,List<Any?>>()
        resultsData?.put("Location", listOf(loc?.latitude,loc?.longitude))


        var mydata = mutableListOf<Any>("x")
        for (i in results!!.indices) {
            // System.out.println("test2");
            val ssid0 = results[i].SSID
            val bssid = results[i].BSSID
            val rssi0 = results[i].level
            mydata.add(listOf(ssid0,bssid,rssi0))
        }
        resultsData?.put("Wifi", mydata)

        return resultsData
    }
}
