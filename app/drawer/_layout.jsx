import React from 'react';
import { Slot } from 'expo-router';
import { useFonts } from 'expo-font';
import { Lobster_400Regular } from '@expo-google-fonts/lobster';
import { View, ActivityIndicator, StyleSheet } from 'react-native';

export default function DrawerLayout() {
  const [fontsLoaded] = useFonts({
    Lobster_400Regular,
  });

  if (!fontsLoaded) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return <Slot />; // 🔁 expo-router auto-loads matching files like /drawer/index.jsx, /drawer/about.jsx, etc.
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
