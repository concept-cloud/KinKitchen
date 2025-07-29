import { StyleSheet, Text, View } from 'react-native'
import { Tabs } from 'expo-router'
import CustomHeaderLayout from '../components/CustomHeaderLayout'

const RootLayout = () => {
  return (
    <CustomHeaderLayout>
   <Tabs screenOptions={{headerShown: false}}>
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="about" options={{ title: 'About Us' }} />
      <Tabs.Screen name="recipie" options={{ title: 'Recipe Card' }} />
    </Tabs>
    </CustomHeaderLayout>
  )
}

export default RootLayout

const styles = StyleSheet.create({})