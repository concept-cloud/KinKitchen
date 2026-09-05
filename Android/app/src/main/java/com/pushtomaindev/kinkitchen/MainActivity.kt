package com.pushtomaindev.kinkitchen

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import com.pushtomaindev.kinkitchen.ui.theme.AppearanceStore
import com.pushtomaindev.kinkitchen.ui.theme.KinKitchenTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppearanceStore.init(this)
        enableEdgeToEdge()
        setContent {
            KinKitchenTheme {
                // Insets are handled per-screen so the tab bar can paint its
                // surface behind the system navigation bar.
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    contentWindowInsets = WindowInsets(0, 0, 0, 0),
                ) { _ ->
                    KinKitchenRoot(modifier = Modifier.fillMaxSize())
                }
            }
        }
    }
}
