// app/_layout.jsx
import { Slot } from 'expo-router';
// app/tabs/_layout.jsx
import { Tabs, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import PlusButton from '../components/Buttons/PlusButton';

export default function RootLayout() {
  return <Slot />;
}
export default function TabLayout() {
  const router = useRouter();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#91b87d',
      }}
    >
          <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home-outline" color={color} size={size} />
          ),
        }}
     />


          <Tabs.Screen
        name="create"
        options={{
          tabBarButton: (props) => (
            <PlusButton
              {...props}
              size={50}
              onPress={() => {
                router.push('/create');
              }}
            />
          ),
        }}
        listeners={{
          tabPress: (e) => {
            e.preventDefault(); // prevent normal tab navigation
          },
        }}
      />

      <Tabs.Screen
        name="books"
        options={{
          title: 'Cook Books',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="book-outline" color={color} size={size} />
          ),
        }}
     />
     <Tabs.Screen
        name="tabs"
        options={{
          href:null
        }}
     />
     <Tabs.Screen
        name="drawer"
        options={{
          href:null
        }}
     />
    </Tabs>
  );
}
