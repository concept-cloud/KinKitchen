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

/** Mirrors iOS `SignUpView`. */
@Composable
fun SignUpView(
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit,
) {
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var isCreatingAccount by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var successMessage by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()

    fun createAccount() {
        errorMessage = null
        successMessage = null
        val cleanEmail = email.trim()

        if (cleanEmail.isEmpty() || password.isEmpty() || confirmPassword.isEmpty()) {
            errorMessage = "Please complete all required fields."
            return
        }
        if (!cleanEmail.contains("@") || !cleanEmail.contains(".")) {
            errorMessage = "Please enter a valid email address."
            return
        }
        if (password != confirmPassword) {
            errorMessage = "Passwords do not match."
            return
        }

        scope.launch {
            isCreatingAccount = true
            try {
                AuthService.signUp(cleanEmail, password)
                successMessage = "Check your email to continue setting up your account."
            } catch (e: Exception) {
                errorMessage = e.userFacingAuthMessage()
            } finally {
                isCreatingAccount = false
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
        Text("Create Account", style = KinTypography.largeTitle, color = KinColors.primaryText)
        Text("Join Kin Kitchen", style = KinTypography.body, color = KinColors.secondaryText)

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

            KinSecureField("Password", password, { password = it }, imeAction = ImeAction.Next)
            KinSecureField("Confirm Password", confirmPassword, { confirmPassword = it })

            errorMessage?.let {
                Text(it, style = KinTypography.body, color = KinColors.error, modifier = Modifier.fillMaxWidth())
            }

            successMessage?.let {
                Text(it, style = KinTypography.body, color = KinColors.success, modifier = Modifier.fillMaxWidth())
            }
        }

        KinPrimaryButton(
            title = if (isCreatingAccount) "Creating Account..." else "Create Account",
            color = KinColors.success,
            enabled = !isCreatingAccount,
        ) { createAccount() }

        KinSecondaryButton(
            title = "Already have an account? Sign In",
            color = KinColors.success,
        ) { onDismiss() }
    }
}

@Preview(showBackground = true)
@Composable
private fun SignUpViewPreview() {
    KinKitchenTheme { SignUpView(onDismiss = {}) }
}
