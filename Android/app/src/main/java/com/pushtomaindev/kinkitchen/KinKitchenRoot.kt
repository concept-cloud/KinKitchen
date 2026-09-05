package com.pushtomaindev.kinkitchen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import android.util.Log
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.components.feedback.KinLoadingView
import com.pushtomaindev.kinkitchen.features.authentication.SignInView
import com.pushtomaindev.kinkitchen.features.authentication.SignUpView
import com.pushtomaindev.kinkitchen.features.profile.ProfileSetupView
import com.pushtomaindev.kinkitchen.services.supabase.AuthService
import com.pushtomaindev.kinkitchen.services.supabase.ProfileService
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.launch

private const val TAG = "KinKitchen"

/** Mirrors iOS `KinKitchenApp.OnboardingStep`. */
enum class OnboardingStep { CHECKING, PROFILE, DIETARY_RESTRICTIONS, DIETARY_PREFERENCES, COMPLETE }

/**
 * Mirrors the routing in iOS `KinKitchenApp`: hold the gate closed while the
 * session loads, show sign-in when there is none, and otherwise route through
 * onboarding before the tab shell.
 */
@Composable
fun KinKitchenRoot(modifier: Modifier = Modifier) {
    val isLoadingSession by AuthService.isLoadingSession.collectAsState()
    val isAuthenticated by AuthService.isAuthenticated.collectAsState()

    var showSignUp by rememberSaveable { mutableStateOf(false) }
    var onboardingStep by remember { mutableStateOf(OnboardingStep.CHECKING) }
    val scope = rememberCoroutineScope()

    // iOS: .task(id: authService.isAuthenticated)
    LaunchedEffect(isAuthenticated) {
        if (!isAuthenticated) {
            onboardingStep = OnboardingStep.CHECKING
            showSignUp = false
            return@LaunchedEffect
        }
        onboardingStep = checkOnboardingStatus()
    }

    Box(modifier.fillMaxSize().background(KinColors.background)) {
        when {
            isLoadingSession -> KinLoadingView(
                message = "Loading...",
                modifier = Modifier.systemBarsPadding(),
            )

            !isAuthenticated -> if (showSignUp) {
                SignUpView(
                    modifier = Modifier.systemBarsPadding(),
                    onDismiss = { showSignUp = false },
                )
            } else {
                SignInView(
                    modifier = Modifier.systemBarsPadding(),
                    onShowSignUp = { showSignUp = true },
                )
            }

            else -> when (onboardingStep) {
                OnboardingStep.CHECKING -> KinLoadingView(
                    message = "Loading...",
                    modifier = Modifier.systemBarsPadding(),
                )

                // iOS: ProfileSetupView { Task { await profileSetupCompleted() } }
                OnboardingStep.PROFILE -> ProfileSetupView(
                    modifier = Modifier.systemBarsPadding(),
                ) {
                    scope.launch { onboardingStep = profileSetupCompleted() }
                }

                OnboardingStep.DIETARY_RESTRICTIONS -> OnboardingPlaceholder(
                    title = "Dietary Restrictions",
                    detail = "DietaryRestrictionsSetupView lands in phase 6.",
                    nextLabel = "Continue",
                ) { onboardingStep = OnboardingStep.DIETARY_PREFERENCES }

                OnboardingStep.DIETARY_PREFERENCES -> OnboardingPlaceholder(
                    title = "Dietary Preferences",
                    detail = "DietaryPreferencesSetupView lands in phase 6.",
                    nextLabel = "Continue",
                ) { onboardingStep = OnboardingStep.COMPLETE }

                OnboardingStep.COMPLETE -> ContentView()
            }
        }
    }
}

/**
 * Mirrors iOS `checkOnboardingStatus`. On error iOS falls back to the profile
 * step, on the assumption that a profile row could not be read.
 */
private suspend fun checkOnboardingStatus(): OnboardingStep = try {
    if (!ProfileService.isCurrentProfileComplete()) {
        Log.d(TAG, "PROFILE CHECK: INCOMPLETE")
        OnboardingStep.PROFILE
    } else {
        Log.d(TAG, "PROFILE CHECK: COMPLETE")
        if (!ProfileService.isDietarySetupComplete()) {
            Log.d(TAG, "DIETARY SETUP CHECK: INCOMPLETE")
            OnboardingStep.DIETARY_RESTRICTIONS
        } else if (ProfileService.isDietaryReviewDue()) {
            Log.d(TAG, "DIETARY REVIEW: DUE")
            OnboardingStep.DIETARY_RESTRICTIONS
        } else {
            Log.d(TAG, "DIETARY REVIEW: CURRENT")
            OnboardingStep.COMPLETE
        }
    }
} catch (e: Exception) {
    Log.e(TAG, "ONBOARDING CHECK ERROR: ${e.message}", e)
    OnboardingStep.PROFILE
}

/**
 * Mirrors iOS `profileSetupCompleted` — re-checks the profile before moving
 * on, so a partial save sends the user back rather than forward.
 */
private suspend fun profileSetupCompleted(): OnboardingStep = try {
    if (ProfileService.isCurrentProfileComplete()) {
        Log.d(TAG, "PROFILE CHECK: COMPLETE")
        OnboardingStep.DIETARY_RESTRICTIONS
    } else {
        Log.d(TAG, "PROFILE CHECK: INCOMPLETE")
        OnboardingStep.PROFILE
    }
} catch (e: Exception) {
    Log.e(TAG, "PROFILE COMPLETION ERROR: ${e.message}", e)
    OnboardingStep.PROFILE
}

/** Temporary stand-in for the remaining phase 6 onboarding screens. */
@Composable
private fun OnboardingPlaceholder(
    title: String,
    detail: String,
    nextLabel: String,
    onNext: () -> Unit,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.large, Alignment.CenterVertically),
        modifier = Modifier.fillMaxSize().padding(KinSpacing.xLarge),
    ) {
        Text(title, style = KinTypography.largeTitle, color = KinColors.primaryText)
        Text(detail, style = KinTypography.body, color = KinColors.secondaryText, textAlign = TextAlign.Center)
        KinPrimaryButton(nextLabel, onClick = onNext)
    }
}
