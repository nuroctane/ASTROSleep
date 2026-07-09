package com.astrosleep.app.service

import android.app.Activity
import android.app.Application
import android.content.Intent
import android.net.Uri
import com.astrosleep.app.core.config.AppConfig
import com.astrosleep.app.core.model.SubscriptionTier
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import com.revenuecat.purchases.interfaces.ReceiveOfferingsCallback
import com.revenuecat.purchases.models.StoreTransaction
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
    private var activityProvider: (() -> Activity?)? = null

    fun setActivityProvider(provider: () -> Activity?) {
        activityProvider = provider
    }

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

    /**
     * Purchase first available package from current offerings (subscription preferred).
     * Requires Activity for Play Billing sheet — set via [setActivityProvider] from MainActivity.
     */
    fun purchaseSubscription(onDone: (Result<SubscriptionTier>) -> Unit) {
        if (AppConfig.revenueCatApiKey.isBlank()) {
            onDone(Result.failure(Exception("RevenueCat API key not configured")))
            return
        }
        val activity = activityProvider?.invoke()
        if (activity == null) {
            onDone(Result.failure(Exception("No activity for purchase sheet")))
            return
        }
        Purchases.sharedInstance.getOfferings(object : ReceiveOfferingsCallback {
            override fun onReceived(offerings: com.revenuecat.purchases.Offerings) {
                val pkg: Package? = offerings.current?.availablePackages?.firstOrNull()
                    ?: offerings.all.values.flatMap { it.availablePackages }.firstOrNull()
                if (pkg == null) {
                    onDone(Result.failure(Exception("No packages in RevenueCat offerings")))
                    return
                }
                Purchases.sharedInstance.purchase(
                    PurchaseParams.Builder(activity, pkg).build(),
                    object : PurchaseCallback {
                        override fun onCompleted(storeTransaction: StoreTransaction, customerInfo: CustomerInfo) {
                            val tier = mapTier(customerInfo)
                            _currentTier.value = tier
                            onDone(Result.success(tier))
                        }

                        override fun onError(error: PurchasesError, userCancelled: Boolean) {
                            if (userCancelled) {
                                onDone(Result.failure(Exception("Purchase cancelled")))
                            } else {
                                onDone(Result.failure(Exception(error.message)))
                            }
                        }
                    },
                )
            }

            override fun onError(error: PurchasesError) {
                onDone(Result.failure(Exception(error.message)))
            }
        })
    }

    fun openManageSubscriptions() {
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://play.google.com/store/account/subscriptions"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        app.startActivity(intent)
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
