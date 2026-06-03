package com.craftquestai.craftquestai_app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import com.google.android.play.agesignals.AgeSignalsException
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import com.google.android.play.agesignals.AgeSignalsResult
import com.google.android.play.agesignals.model.AgeSignalsVerificationStatus
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

    private fun requestAgeSignals(result: MethodChannel.Result) {
        val ageSignalsManager = AgeSignalsManagerFactory.create(applicationContext)
        ageSignalsManager
            .checkAgeSignals(AgeSignalsRequest.builder().build())
            .addOnSuccessListener { ageSignalsResult ->
                result.success(ageSignalsResult.toPayload())
            }
            .addOnFailureListener { error ->
                val payload = hashMapOf<String, Any?>(
                    "requiresParentalConsent" to false,
                    "userStatus" to null,
                    "ageLower" to null,
                    "ageUpper" to null,
                    "installId" to null,
                    "mostRecentApprovalDate" to null,
                )
                if (error is AgeSignalsException) {
                    payload["errorCode"] = error.errorCode
                    payload["errorMessage"] = error.message
                } else {
                    payload["errorCode"] = null
                    payload["errorMessage"] = error.message
                }
                result.success(payload)
            }
    }

    private fun AgeSignalsResult.toPayload(): HashMap<String, Any?> {
        val status = userStatus()
        val requiresConsent = evaluateRequiresParentalConsent(status, ageLower(), ageUpper())
        return hashMapOf(
            "userStatus" to status.toUserStatusLabel(),
            "ageLower" to ageLower(),
            "ageUpper" to ageUpper(),
            "installId" to installId(),
            "mostRecentApprovalDate" to mostRecentApprovalDate()?.toIsoUtc(),
            "requiresParentalConsent" to requiresConsent,
            "errorCode" to null,
            "errorMessage" to null,
        )
    }

    companion object {
        private const val AGE_SIGNALS_CHANNEL = "com.craftquestai.app/age_signals"

        /**
         * Texas SB 2420 / Play Age Signals: minor or supervised account needs
         * parental consent for restricted experiences.
         */
        internal fun evaluateRequiresParentalConsent(
            status: Int?,
            ageLower: Int?,
            ageUpper: Int?,
        ): Boolean {
            if (status == null) {
                return false
            }
            return when (status) {
                AgeSignalsVerificationStatus.SUPERVISED,
                AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_PENDING,
                AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_DENIED,
                -> true
                AgeSignalsVerificationStatus.VERIFIED,
                AgeSignalsVerificationStatus.DECLARED,
                -> isMinorAgeBand(ageLower, ageUpper)
                AgeSignalsVerificationStatus.UNKNOWN -> false
                else -> false
            }
        }

        private fun Int?.toUserStatusLabel(): String? = when (this) {
            AgeSignalsVerificationStatus.VERIFIED -> "VERIFIED"
            AgeSignalsVerificationStatus.SUPERVISED -> "SUPERVISED"
            AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_PENDING ->
                "SUPERVISED_APPROVAL_PENDING"
            AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_DENIED ->
                "SUPERVISED_APPROVAL_DENIED"
            AgeSignalsVerificationStatus.UNKNOWN -> "UNKNOWN"
            AgeSignalsVerificationStatus.DECLARED -> "DECLARED"
            null -> null
            else -> "UNKNOWN_STATUS_$this"
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
