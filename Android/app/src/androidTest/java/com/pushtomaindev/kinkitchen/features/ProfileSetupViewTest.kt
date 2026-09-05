package com.pushtomaindev.kinkitchen.features

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.pushtomaindev.kinkitchen.features.profile.ProfileSetupView
import com.pushtomaindev.kinkitchen.ui.theme.KinKitchenTheme
import com.pushtomaindev.kinkitchen.services.supabase.AuthService
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Renders the profile setup form directly, bypassing the auth gate, so the
 * validation rules ported from iOS are exercised without a live session.
 */
@RunWith(AndroidJUnit4::class)
class ProfileSetupViewTest {

    @get:Rule val compose = createComposeRule()

    /**
     * The form renders in create mode only when no profile is loaded. With a
     * live session it loads the real profile and switches to update mode,
     * where completed fields are read-only by design — so these create-mode
     * cases do not apply and are skipped rather than failed.
     */
    @Before
    fun requireSignedOut() {
        assumeTrue(
            "skipped: a session is active, so the form renders in update mode",
            AuthService.currentUserOrNull() == null,
        )
    }

    /**
     * A validation message renders twice by design, matching iOS: inline
     * beneath the form and inside the alert.
     */
    private fun assertShownInlineAndInDialog(message: String) {
        compose.onAllNodesWithText(message).assertCountEquals(2)
    }

    private fun render(onCompleted: () -> Unit = {}) {
        compose.setContent { KinKitchenTheme { ProfileSetupView(onProfileCompleted = onCompleted) } }
    }

    @Test
    fun rendersInCreateModeWhenThereIsNoProfile() {
        render()
        compose.onNodeWithText("Create Your Profile").assertIsDisplayed()
        compose.onNodeWithText("Tell us a little about yourself.").assertIsDisplayed()
        compose.onNodeWithText("You must be at least 13 years old.").assertIsDisplayed()
    }

    @Test
    fun emptyFirstNameIsRejected() {
        render()
        compose.onNodeWithText("Continue").performClick()
        assertShownInlineAndInDialog("First name is required.")
    }

    @Test
    fun lastNameIsRequiredOnceFirstNameIsPresent() {
        render()
        compose.onNodeWithText("Enter First Name").performTextInput("Greg")
        compose.onNodeWithText("Continue").performClick()
        assertShownInlineAndInDialog("Last name is required.")
    }

    @Test
    fun usernameIsRequiredOnceNamesArePresent() {
        render()
        compose.onNodeWithText("Enter First Name").performTextInput("Greg")
        compose.onNodeWithText("Enter Last Name").performTextInput("Hudler")
        compose.onNodeWithText("Continue").performClick()
        assertShownInlineAndInDialog("Username is required.")
    }

    @Test
    fun shortUsernameIsRejectedBeforeAnyNetworkCheck() {
        render()
        compose.onNodeWithText("Enter First Name").performTextInput("Greg")
        compose.onNodeWithText("Enter Last Name").performTextInput("Hudler")
        compose.onNodeWithText("Choose Username").performTextInput("ab")
        compose.onNodeWithText("Continue").performClick()
        assertShownInlineAndInDialog("Username must be at least 3 characters.")
    }

    @Test
    fun availabilityMustResolveBeforeSubmitting() {
        render()
        compose.onNodeWithText("Enter First Name").performTextInput("Greg")
        compose.onNodeWithText("Enter Last Name").performTextInput("Hudler")
        compose.onNodeWithText("Choose Username").performTextInput("greghudler")
        compose.onNodeWithText("Continue").performClick()
        // Anonymous availability checks cannot succeed, so the guard must hold.
        assertShownInlineAndInDialog(
            "Please wait for the username availability check to complete."
        )
    }

    @Test
    fun dismissingAnErrorClosesTheDialog() {
        render()
        compose.onNodeWithText("Continue").performClick()
        assertShownInlineAndInDialog("First name is required.")
        compose.onNodeWithText("OK").performClick()
        compose.onNodeWithText("Profile Setup").assertDoesNotExist()
    }
}
