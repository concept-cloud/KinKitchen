import { StyleSheet, Text, View } from 'react-native'
import { Tabs } from 'expo-router'

const RootLayout = () => {
  return (
   <Tabs screenOptions={{headerShown: false}}>
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="about" options={{ title: 'About Us' }} />
      <Tabs.Screen name="Contact" options={{ title: 'Contact Us' }} />
      <Tabs.Screen name="recipie" options={{ title: 'Recipe Card' }} />
    </Tabs>
  )
}

export default RootLayout

const styles = StyleSheet.create({})