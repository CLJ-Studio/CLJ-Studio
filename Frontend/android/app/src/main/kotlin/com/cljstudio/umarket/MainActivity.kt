package com.cljstudio.umarket

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cljstudio.umarket/pantalla",
        ).setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "altaFrecuencia" -> {
                    pedirAltaFrecuencia(llamada.arguments as? Boolean ?: false)
                    resultado.success(null)
                }
                else -> resultado.notImplemented()
            }
        }
    }

    /**
     * Pide la tasa de refresco mas alta de la pantalla (90 o 120 Hz), o
     * devuelve la eleccion al sistema.
     *
     * Muchos Android dejan las apps en 60 Hz aunque la pantalla de mas. Lo
     * que se anima mucho (la mesa de blackjack de MacIAs) lo pide solo
     * mientras esta abierto, para no gastar bateria en el resto de la app.
     */
    private fun pedirAltaFrecuencia(activar: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val pantalla = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        } ?: return
        val actual = pantalla.mode
        val modo = if (activar) {
            pantalla.supportedModes
                .filter {
                    it.physicalWidth == actual.physicalWidth &&
                        it.physicalHeight == actual.physicalHeight
                }
                .maxByOrNull { it.refreshRate }
        } else {
            null
        }
        val atributos = window.attributes
        atributos.preferredDisplayModeId = modo?.modeId ?: 0
        window.attributes = atributos
    }
}
