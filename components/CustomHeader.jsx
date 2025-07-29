import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useNavigation, useRoute, DrawerActions } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons'; // uses built-in expo icons

// Friendly screen title mappings
const screenTitles = {
  index: 'Kin-Kitchen',
  about: 'About Us',
  Contact: 'Contact Us',
  recipie: 'Recipe Card',
  profile: 'Profile',
};

export default function CustomHeader() {
  const navigation = useNavigation();
  const route = useRoute();

  const isHome = route.name === 'index';
  const title = screenTitles[route.name] || route.name;

  const handleDrawerOpen = () => {
    navigation.dispatch(DrawerActions.openDrawer());
  };

  return (
    <View style={styles.header}>
      {/* Back Arrow if not Home */}
      {!isHome ? (
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={28} color="#000" />
        </TouchableOpacity>
      ) : (
        // Spacer to keep title centered
        <View style={{ width: 28 }} />
      )}

      {/* Page Title */}
      <Text style={styles.title}>{title}</Text>

      {/* Drawer Button */}
      <TouchableOpacity onPress={handleDrawerOpen}>
        <Ionicons name="menu" size={32} color="#000" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#91b87d',
    paddingTop: 60,
    paddingBottom: 10,
    paddingHorizontal: 15,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    zIndex: 10,
  },
  title: {
    fontSize: 35,
    fontFamily: 'Lobster_400Regular',
    color: '#000',
  },
});
