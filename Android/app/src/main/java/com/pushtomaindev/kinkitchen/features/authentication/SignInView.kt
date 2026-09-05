package com.pushtomaindev.kinkitchen.features.authentication

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.components.buttons.KinSecondaryButton
import com.pushtomaindev.kinkitchen.components.inputs.KinSecureField
import com.pushtomaindev.kinkitchen.components.inputs.KinTextField
import com.pushtomaindev.kinkitchen.services.supabase.AuthService
import com.pushtomaindev.kinkitchen.services.supabase.userFacingAuthMessage
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.launch

/** Mirrors iOS `SignInView`. */
@Composable
fun SignInView(
    modifier: Modifier = Modifier,
    onShowSignUp: () -> Unit,
) {
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var isSigningIn by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()

    fun signIn() {
        errorMessage = null
        val cleanEmail = email.trim()

        if (cleanEmail.isEmpty() || password.isEmpty()) {
            errorMessage = "Please enter your email and password."
            return
        }
        if (!cleanEmail.contains("@") || !cleanEmail.contains(".")) {
            errorMessage = "Please enter a valid email address."
            return
        }

        scope.launch {
            isSigningIn = true
            try {
                AuthService.signIn(cleanEmail, password)
            } catch (e: Exception) {
                errorMessage = e.userFacingAuthMessage()
            } finally {
                isSigningIn = false
            }
        }
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
        modifier = modifier
            .fillMaxSize()
            .background(KinColors.background)
            .verticalScroll(rememberScrollState())
            .padding(KinSpacing.xLarge),
    ) {
        Text("Welcome Back", style = KinTypography.largeTitle, color = KinColors.primaryText)
        Text("Sign in to Kin Kitchen", style = KinTypography.body, color = KinColors.secondaryText)

        Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.large)) {
            KinTextField(
                title = "Email",
                value = email,
                onValueChange = { email = it },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next,
                ),
            )

            KinSecureField(
                title = "Password",
                value = password,
                onValueChange = { password = it },
            )

            errorMessage?.let {
                Text(
                    it,
                    style = KinTypography.body,
                    color = KinColors.error,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        KinPrimaryButton(
            title = if (isSigningIn) "Signing In..." else "Sign In",
            color = KinColors.success,
            enabled = !isSigningIn,
        ) { signIn() }

        KinSecondaryButton(
            title = "Don't have an account? Sign Up",
            color = KinColors.success,
        ) { onShowSignUp() }
    }
}

@Preview(showBackground = true)
@Composable
private fun SignInViewPreview() {
    KinKitchenTheme { SignInView(onShowSignUp = {}) }
}
