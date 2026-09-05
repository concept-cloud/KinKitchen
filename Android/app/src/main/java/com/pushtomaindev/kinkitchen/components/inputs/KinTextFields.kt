package com.pushtomaindev.kinkitchen.components.inputs

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.*

/**
 * Shared shell for the Kin text inputs: surface background, medium radius,
 * and a placeholder that behaves like SwiftUI's inline title.
 */
@Composable
private fun KinFieldShell(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier,
    contentPadding: Dp,
    singleLine: Boolean,
    minHeight: Dp?,
    visualTransformation: VisualTransformation,
    keyboardOptions: KeyboardOptions,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        textStyle = KinTypography.body.copy(color = KinColors.primaryText),
        cursorBrush = SolidColor(KinColors.primary),
        singleLine = singleLine,
        visualTransformation = visualTransformation,
        keyboardOptions = keyboardOptions,
        modifier = modifier
            .fillMaxWidth()
            .clip(KinRadius.mediumShape)
            .background(KinColors.surface)
            .then(if (minHeight != null) Modifier.heightIn(min = minHeight) else Modifier),
    ) { innerTextField ->
        Row(
            verticalAlignment = if (singleLine) Alignment.CenterVertically else Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
            modifier = Modifier.padding(contentPadding),
        ) {
            leading?.invoke()

            Box(Modifier.weight(1f)) {
                if (value.isEmpty()) {
                    Text(placeholder, style = KinTypography.body, color = KinColors.secondaryText)
                }
                innerTextField()
            }

            trailing?.invoke()
        }
    }
}

/** Mirrors iOS `KinTextField`. */
@Composable
fun KinTextField(
    title: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
) = KinFieldShell(
    value = value,
    onValueChange = onValueChange,
    placeholder = title,
    modifier = modifier,
    contentPadding = KinSpacing.large,
    singleLine = true,
    minHeight = null,
    visualTransformation = VisualTransformation.None,
    keyboardOptions = keyboardOptions,
)

/**
 * Mirrors iOS `KinSecureField`. iOS sets `.password` content type with
 * autocapitalization and autocorrect off; the Android equivalent is a
 * password keyboard type, which disables both by default.
 */
@Composable
fun KinSecureField(
    title: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    imeAction: ImeAction = ImeAction.Done,
) = KinFieldShell(
    value = value,
    onValueChange = onValueChange,
    placeholder = title,
    modifier = modifier,
    contentPadding = KinSpacing.large,
    singleLine = true,
    minHeight = null,
    visualTransformation = PasswordVisualTransformation(),
    keyboardOptions = KeyboardOptions(
        keyboardType = KeyboardType.Password,
        capitalization = KeyboardCapitalization.None,
        autoCorrectEnabled = false,
        imeAction = imeAction,
    ),
)

/** Mirrors iOS `KinTextEditor` (declared in KintTextEditor.swift). */
@Composable
fun KinTextEditor(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    minHeight: Dp = 120.dp,
) = KinFieldShell(
    value = value,
    onValueChange = onValueChange,
    placeholder = placeholder,
    modifier = modifier,
    contentPadding = KinSpacing.small,
    singleLine = false,
    minHeight = minHeight,
    visualTransformation = VisualTransformation.None,
    keyboardOptions = KeyboardOptions.Default,
)

/** Mirrors iOS `KinSearchBar`. */
@Composable
fun KinSearchBar(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Search",
) = KinFieldShell(
    value = value,
    onValueChange = onValueChange,
    placeholder = placeholder,
    modifier = modifier,
    contentPadding = KinSpacing.medium,
    singleLine = true,
    minHeight = null,
    visualTransformation = VisualTransformation.None,
    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
    leading = {
        androidx.compose.material3.Icon(
            KinIcons.search, contentDescription = null, tint = KinColors.secondaryText
        )
    },
    trailing = {
        if (value.isNotEmpty()) {
            androidx.compose.material3.Icon(
                KinIcons.close,
                contentDescription = "Clear search",
                tint = KinColors.secondaryText,
                modifier = Modifier.clickable { onValueChange("") },
            )
        }
    },
)

@Preview(showBackground = true, backgroundColor = 0xFFF8EFE3)
@Composable
private fun KinInputsPreview() {
    KinKitchenTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
            modifier = Modifier.background(KinColors.background).padding(KinSpacing.large),
        ) {
            KinTextField("Username", "", {})
            KinTextField("Username", "greg", {})
            KinSecureField("Password", "hunter2", {})
            KinSearchBar("", {})
            KinSearchBar("peanut", {})
            KinTextEditor("", {}, placeholder = "Tell us about yourself")
        }
    }
}
