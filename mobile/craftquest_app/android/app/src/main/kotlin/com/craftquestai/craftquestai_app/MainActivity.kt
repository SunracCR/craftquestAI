package com.craftquestai.craftquestai_app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import com.google.android.play.agesignals.AgeSignalsAccessRequest
import com.google.android.play.agesignals.AgeSignalsException
import com.google.android.play.agesignals.AgeSignalsManager
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import com.google.android.play.agesignals.AgeSignalsResult
import com.google.android.play.agesignals.model.AgeRangeSource
import com.google.android.play.agesignals.model.AgeSignalsStatus
import com.google.android.play.agesignals.model.SignificantChangeStatus
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AGE_SIGNALS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAgeSignals" -> requestAgeSignals(result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Play Age Signals 0.0.4: arquitectura de dos funciones. Primero se pide
     * acceso ([AgeSignalsManager.requestAgeSignalsAccess], que puede mostrar el
     * prompt in-app de Play) y solo si el estado es `SHARED` se consulta
     * [AgeSignalsManager.checkAgeSignals] para obtener los valores reales.
     */
    private fun requestAgeSignals(result: MethodChannel.Result) {
        val ageSignalsManager = AgeSignalsManagerFactory.create(applicationContext)
        val accessRequest = AgeSignalsAccessRequest.builder()
            .setActivity(this)
            .build()

        ageSignalsManager
            .requestAgeSignalsAccess(accessRequest)
            .addOnSuccessListener { accessResult ->
                when (accessResult.ageSignalsStatus()) {
                    AgeSignalsStatus.SHARED -> checkAgeSignals(ageSignalsManager, result)
                    AgeSignalsStatus.VERIFICATION_REQUIRED ->
                        result.success(unsharedPayload("VERIFICATION_REQUIRED"))
                    else -> result.success(unsharedPayload("NOT_SHARED"))
                }
            }
            .addOnFailureListener { error -> result.success(errorPayload(error)) }
    }

    private fun checkAgeSignals(manager: AgeSignalsManager, result: MethodChannel.Result) {
        manager
            .checkAgeSignals(AgeSignalsRequest.builder().build())
            .addOnSuccessListener { ageSignalsResult ->
                result.success(ageSignalsResult.toPayload())
            }
            .addOnFailureListener { error -> result.success(errorPayload(error)) }
    }

    private fun unsharedPayload(ageSignalsStatus: String): HashMap<String, Any?> = hashMapOf(
        "ageSignalsStatus" to ageSignalsStatus,
        "ageRangeSource" to null,
        "ageLower" to null,
        "ageUpper" to null,
        "installId" to null,
        "significantChangeStatus" to null,
        "significantChangeApprovalDate" to null,
        "requiresParentalConsent" to false,
        "errorCode" to null,
        "errorMessage" to null,
    )

    private fun errorPayload(error: Throwable): HashMap<String, Any?> {
        val payload = hashMapOf<String, Any?>(
            "ageSignalsStatus" to null,
            "ageRangeSource" to null,
            "ageLower" to null,
            "ageUpper" to null,
            "installId" to null,
            "significantChangeStatus" to null,
            "significantChangeApprovalDate" to null,
            "requiresParentalConsent" to false,
        )
        if (error is AgeSignalsException) {
            payload["errorCode"] = error.errorCode
            payload["errorMessage"] = error.message
        } else {
            payload["errorCode"] = null
            payload["errorMessage"] = error.message
        }
        return payload
    }

    private fun AgeSignalsResult.toPayload(): HashMap<String, Any?> {
        val source = ageRangeSource()
        val changeStatus = significantChangeStatus()
        val requiresConsent = evaluateRequiresParentalConsent(source, ageLower(), ageUpper())
        return hashMapOf(
            "ageSignalsStatus" to "SHARED",
            "ageRangeSource" to source.toAgeRangeSourceLabel(),
            "ageLower" to ageLower(),
            "ageUpper" to ageUpper(),
            "installId" to installId(),
            "significantChangeStatus" to changeStatus.toSignificantChangeStatusLabel(),
            "significantChangeApprovalDate" to significantChangeApprovalDate()?.toIsoUtc(),
            "requiresParentalConsent" to requiresConsent,
            "errorCode" to null,
            "errorMessage" to null,
        )
    }

    companion object {
        private const val AGE_SIGNALS_CHANNEL = "com.craftquestai.app/age_signals"

        /**
         * Texas SB 2420 / Play Age Signals 0.0.4: `userStatus` fue deprecado y
         * reemplazado por `ageRangeSource` + `significantChangeStatus`. TIER_B
         * indica que la edad la gestiona un padre/tutor (cuenta supervisada), por
         * lo que siempre requiere consentimiento. En TIER_A/TIER_C/TIER_D el
         * propio usuario declaró o verificó su edad, así que solo se exige
         * consentimiento si la banda de edad resultante es menor de edad.
         */
        internal fun evaluateRequiresParentalConsent(
            ageRangeSource: Int?,
            ageLower: Int?,
            ageUpper: Int?,
        ): Boolean {
            if (ageRangeSource == null) {
                return false
            }
            return when (ageRangeSource) {
                AgeRangeSource.TIER_B -> true
                AgeRangeSource.TIER_A,
                AgeRangeSource.TIER_C,
                AgeRangeSource.TIER_D,
                -> isMinorAgeBand(ageLower, ageUpper)
                else -> false
            }
        }

        private fun Int?.toAgeRangeSourceLabel(): String? = when (this) {
            AgeRangeSource.TIER_A -> "TIER_A"
            AgeRangeSource.TIER_B -> "TIER_B"
            AgeRangeSource.TIER_C -> "TIER_C"
            AgeRangeSource.TIER_D -> "TIER_D"
            null -> null
            else -> "UNKNOWN_SOURCE_$this"
        }

        private fun Int?.toSignificantChangeStatusLabel(): String? = when (this) {
            SignificantChangeStatus.APPROVED -> "APPROVED"
            SignificantChangeStatus.PENDING -> "PENDING"
            SignificantChangeStatus.DECLINED -> "DECLINED"
            null -> null
            else -> "UNKNOWN_CHANGE_STATUS_$this"
        }

        private fun isMinorAgeBand(ageLower: Int?, ageUpper: Int?): Boolean {
            if (ageUpper != null && ageUpper < ADULT_AGE_THRESHOLD) {
                return true
            }
            if (ageLower != null && ageLower < ADULT_AGE_THRESHOLD) {
                return true
            }
            return false
        }

        private const val ADULT_AGE_THRESHOLD = 18

        private fun java.util.Date.toIsoUtc(): String {
            val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            formatter.timeZone = TimeZone.getTimeZone("UTC")
            return formatter.format(this)
        }
    }
}
