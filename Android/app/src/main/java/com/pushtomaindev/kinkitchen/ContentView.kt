package com.pushtomaindev.kinkitchen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.pushtomaindev.kinkitchen.components.navigation.KinTabBar
import com.pushtomaindev.kinkitchen.components.navigation.KinTabBarItem
import com.pushtomaindev.kinkitchen.features.CookbooksView
import com.pushtomaindev.kinkitchen.features.GatheringsView
import com.pushtomaindev.kinkitchen.features.RecipesView
import com.pushtomaindev.kinkitchen.features.home.HomeView
import com.pushtomaindev.kinkitchen.features.profile.ProfileView
import com.pushtomaindev.kinkitchen.ui.theme.KinColors
import com.pushtomaindev.kinkitchen.ui.theme.KinIcons
import com.pushtomaindev.kinkitchen.ui.theme.KinKitchenTheme

/** Mirrors iOS `ContentView` — the signed-in tab shell. */
@Composable
fun ContentView(modifier: Modifier = Modifier) {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    val tabItems = listOf(
        KinTabBarItem("Home", KinIcons.home),
        KinTabBarItem("Gatherings", KinIcons.gatherings),
        KinTabBarItem("Recipes", KinIcons.recipes),
        KinTabBarItem("Cookbooks", KinIcons.cookbooks),
        KinTabBarItem("Profile", KinIcons.profile),
    )

    Column(modifier.fillMaxSize().background(KinColors.background)) {
        Box(Modifier.weight(1f).fillMaxWidth().statusBarsPadding()) {
            // iOS keeps every tab alive and toggles opacity; the Compose
            // equivalent is to swap the body and let each tab hold its own
            // state via rememberSaveable.
            when (selectedTab) {
                0 -> HomeView()
                1 -> GatheringsView()
                2 -> RecipesView()
                3 -> CookbooksView()
                else -> ProfileView()
            }
        }

        // The surface is painted on the wrapper so it fills the gesture-bar
        // area too; the bar's own content is inset above it.
        Box(Modifier.fillMaxWidth().background(KinColors.surface)) {
            KinTabBar(
                items = tabItems,
                selectedIndex = selectedTab,
                modifier = Modifier.navigationBarsPadding(),
            ) { selectedTab = it }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun ContentViewPreview() {
    KinKitchenTheme { ContentView() }
}
