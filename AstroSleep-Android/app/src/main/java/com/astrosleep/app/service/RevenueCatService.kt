package com.astrosleep.app.service

import android.app.Application
import com.astrosleep.app.core.config.AppConfig
import com.astrosleep.app.core.model.SubscriptionTier
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * RevenueCat wrapper — Free / Subscription / Lifetime entitlements.
 * Configure Play products in RC dashboard to match iOS catalog.
 */
@Singleton
class RevenueCatService @Inject constructor(
    private val app: Application,
) {
    private val _currentTier = MutableStateFlow(SubscriptionTier.FREE)
    val currentTier: StateFlow<SubscriptionTier> = _currentTier.asStateFlow()

    private var configured = false

    fun configureIfNeeded() {
        if (configured) return
        val key = AppConfig.revenueCatApiKey
        if (key.isBlank()) {
            configured = true
            return
        }
        Purchases.configure(
            PurchasesConfiguration.Builder(app, key).build(),
        )
        configured = true
        refreshCustomerInfo()
    }

    fun refreshCustomerInfo() {
        if (AppConfig.revenueCatApiKey.isBlank()) return
        Purchases.sharedInstance.getCustomerInfo(object : ReceiveCustomerInfoCallback {
            override fun onReceived(customerInfo: CustomerInfo) {
                _currentTier.value = mapTier(customerInfo)
            }

            override fun onError(error: PurchasesError) {
                // Keep last known tier
            }
        })
    }

    fun restorePurchases(onDone: (Result<SubscriptionTier>) -> Unit) {
        if (AppConfig.revenueCatApiKey.isBlank()) {
            onDone(Result.success(SubscriptionTier.FREE))
            return
        }
        Purchases.sharedInstance.restorePurchases(object : ReceiveCustomerInfoCallback {
            override fun onReceived(customerInfo: CustomerInfo) {
                val tier = mapTier(customerInfo)
                _currentTier.value = tier
                onDone(Result.success(tier))
            }

            override fun onError(error: PurchasesError) {
                onDone(Result.failure(Exception(error.message)))
            }
        })
    }

    private fun mapTier(info: CustomerInfo): SubscriptionTier {
        val entitlements = info.entitlements.active
        return when {
            entitlements.containsKey("lifetime") || entitlements.containsKey("pro") ->
                SubscriptionTier.LIFETIME
            entitlements.containsKey("subscription") || entitlements.containsKey("basic") ->
                SubscriptionTier.SUBSCRIPTION
            else -> SubscriptionTier.FREE
        }
    }
}
