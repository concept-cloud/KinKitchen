// app/_layout.jsx
import { Drawer } from 'expo-router/drawer';
import { useFonts } from 'expo-font';
import { Lobster_400Regular } from '@expo-google-fonts/lobster';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import CustomDrawerContent from '../components/CustomDrawerContent';

export default function RootLayout() {
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

  return (
    <Drawer
  screenOptions={({ route }) => ({
    headerShown: false,
    title: route?.params?.drawerLabel ?? route.name,
    drawerPosition: 'right',
    drawerStyle: {
      backgroundColor: '#c8dbbe',
      width: 240,
    },
  })}
  drawerContent={(props) => <CustomDrawerContent {...props} />}
/>
  );
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
