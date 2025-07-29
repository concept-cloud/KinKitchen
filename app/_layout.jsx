import { StyleSheet, Text, View } from 'react-native'
import { Stack } from 'expo-router'

const RootLayout = () => {
  return (
        <Stack>
            <Stack.Screen name="index" options={{title: 'Home'}} />
            <Stack.Screen name="about" options={{title: 'About Us'}} />
            <Stack.Screen name="Contact" options={{title: 'Contact Us'}} />
            <Stack.Screen name="recipie" options={{title: 'Recipie Card'}} />
        </Stack>
  )
}

export default RootLayout

const styles = StyleSheet.create({})