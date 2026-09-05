package com.pushtomaindev.kinkitchen.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.People
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Mirrors iOS `KinIcons`. SF Symbols have no Android equivalent, so each
 * symbol maps to its closest Material counterpart.
 */
object KinIcons {
    // Tab bar
    val home: ImageVector = Icons.Filled.Home
    val gatherings: ImageVector = Icons.Filled.Groups
    val recipes: ImageVector = Icons.Filled.Restaurant
    val cookbooks: ImageVector = Icons.AutoMirrored.Filled.MenuBook
    val profile: ImageVector = Icons.Filled.AccountCircle

    // Actions
    val add: ImageVector = Icons.Filled.Add
    val edit: ImageVector = Icons.Filled.Edit
    val delete: ImageVector = Icons.Filled.Delete
    val search: ImageVector = Icons.Filled.Search
    val filter: ImageVector = Icons.Filled.FilterList
    val share: ImageVector = Icons.Filled.Share

    // Status
    val warning: ImageVector = Icons.Filled.Warning
    val info: ImageVector = Icons.Outlined.Info
    val success: ImageVector = Icons.Filled.CheckCircle
    val error: ImageVector = Icons.Filled.Cancel

    // Navigation
    val close: ImageVector = Icons.Filled.Close
    val back: ImageVector = Icons.AutoMirrored.Filled.ArrowBack
    val forward: ImageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight
    val dropdown: ImageVector = Icons.Filled.KeyboardArrowDown
    val more: ImageVector = Icons.Filled.MoreHoriz

    // Media
    val camera: ImageVector = Icons.Filled.PhotoCamera
    val photo: ImageVector = Icons.Filled.Photo

    // Gatherings
    val calendar: ImageVector = Icons.Filled.CalendarMonth
    val time: ImageVector = Icons.Filled.Schedule
    val location: ImageVector = Icons.Filled.LocationOn
    val notifications: ImageVector = Icons.Filled.Notifications
    val invite: ImageVector = Icons.Filled.PersonAdd
    val participants: ImageVector = Icons.Filled.People

    // Dietary
    val dietary: ImageVector = Icons.Filled.Eco
    val allergen: ImageVector = Icons.Filled.Warning

    // Recipes
    val servings: ImageVector = Icons.Outlined.People
    val ingredients: ImageVector = Icons.AutoMirrored.Filled.List
    val instructions: ImageVector = Icons.Filled.FormatListNumbered

    // Saved
    val favorite: ImageVector = Icons.Filled.Favorite
    val save: ImageVector = Icons.Filled.Bookmark
    val history: ImageVector = Icons.Filled.History

    // Misc
    val settings: ImageVector = Icons.Filled.Settings
    val check: ImageVector = Icons.Filled.Check
    val lock: ImageVector = Icons.Filled.Lock
    val unlock: ImageVector = Icons.Filled.LockOpen
}
