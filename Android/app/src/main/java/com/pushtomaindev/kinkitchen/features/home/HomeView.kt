package com.pushtomaindev.kinkitchen.features.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.pushtomaindev.kinkitchen.components.buttons.KinIconButton
import com.pushtomaindev.kinkitchen.components.cards.KinCard
import com.pushtomaindev.kinkitchen.components.feedback.KinEmptyState
import com.pushtomaindev.kinkitchen.components.navigation.KinSectionHeader
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `HomeView`. */
@Composable
fun HomeView(modifier: Modifier = Modifier) {
    Column(
        verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
        modifier = modifier
            .fillMaxSize()
            .background(KinColors.background)
            .verticalScroll(rememberScrollState())
            .padding(KinSpacing.large),
    ) {
        Text("Good morning", style = KinTypography.largeTitle, color = KinColors.primaryText)
        Text("Welcome to Kin Kitchen", style = KinTypography.body, color = KinColors.secondaryText)

        KinSectionHeader("Upcoming Gatherings")

        KinCard {
            Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                Text("No upcoming gatherings", style = KinTypography.title3, color = KinColors.primaryText)
                Text(
                    "Your upcoming community meals will appear here.",
                    style = KinTypography.body,
                    color = KinColors.secondaryText,
                )
            }
        }

        KinSectionHeader("Quick Actions")

        Row(horizontalArrangement = Arrangement.spacedBy(KinSpacing.medium)) {
            KinIconButton(KinIcons.add, "Add") {}
            KinIconButton(KinIcons.recipes, "Recipes") {}
            KinIconButton(KinIcons.gatherings, "Gatherings") {}
        }

        KinSectionHeader("My Collections")

        KinEmptyState(
            icon = KinIcons.cookbooks,
            title = "No Collections Yet",
            message = "Your saved recipes and cookbooks will appear here.",
            modifier = Modifier.fillMaxWidth(),
        )

        KinSectionHeader("For You")

        KinCard {
            Text(
                "Personalized recommendations will appear here.",
                style = KinTypography.body,
                color = KinColors.secondaryText,
            )
        }
    }
}

@Preview(showBackground = true, heightDp = 1200)
@Composable
private fun HomeViewPreview() {
    KinKitchenTheme { HomeView() }
}
