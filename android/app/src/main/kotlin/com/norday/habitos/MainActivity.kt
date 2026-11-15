package com.norday.habitos

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Abre un enlace con un Intent ACTION_VIEW; con "paquete", solo con esa
        // app (setPackage). Lo usa lib/services/abrir_enfoque.dart para abrir
        // Norday Focus o su ficha de Google Play. Devuelve false si no hay quien
        // lo abra, como recomienda la documentación de Android: «invoke the
        // intent and handle the ActivityNotFoundException exception if no app
        // is available»
        // (https://developer.android.com/training/package-visibility/use-cases).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_ABRIR)
            .setMethodCallHandler { call, result ->
                if (call.method != "abrir") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val enlace = call.argument<String>("enlace")
                if (enlace == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(enlace))
                call.argument<String>("paquete")?.let { intent.setPackage(it) }
                // En su propia tarea, no encima de Habits: «A new activity, by
                // default, is launched into the task of the activity that
                // called startActivity()», y con FLAG_ACTIVITY_NEW_TASK «The
                // system starts the activity in a new task. If a task is
                // already running for the activity being started, that task is
                // brought to the foreground with its last state restored»
                // (https://developer.android.com/guide/components/activities/tasks-and-back-stack).
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                result.success(abrir(intent))
            }
    }

    private fun abrir(intent: Intent): Boolean =
        try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }

    companion object {
        private const val CANAL_ABRIR = "com.norday.habitos/abrir"
    }
}
