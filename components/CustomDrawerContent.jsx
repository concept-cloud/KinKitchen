import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { DrawerContentScrollView, DrawerItem } from '@react-navigation/drawer';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

// ✅ Map for pretty drawer labels
const labelMap = {
  index: 'Home',
  about: 'About Us',
  recipie: 'Recipe Card',
};

export default function CustomDrawerContent(props) {
  const router = useRouter();

  // Remove routes you want at the bottom
  const filteredProps = {
    ...props,
    state: {
      ...props.state,
      routes: props.state.routes.filter(
        (route) => !['Contact', 'profile', 'create', '_sitemap', '+not-found'].includes(route.name)
      ),
    },
  };

  return (
    <DrawerContentScrollView {...props} contentContainerStyle={{ flex: 1 }}>
      <View style={styles.mainItems}>
        {/* ✅ Use DrawerItem to manually label */}
        {filteredProps.state.routes.map((route, index) => (
          <DrawerItem
            key={route.key}
            label={labelMap[route.name] || route.name}
            onPress={() => props.navigation.navigate(route.name)}
            focused={index === filteredProps.state.index}
            activeTintColor="#000"
            inactiveTintColor="#000"
          />
        ))}
      </View>

      {/* ✅ Bottom Section */}
      <View style={styles.bottomItems}>
        <TouchableOpacity
          style={styles.bottomItem}
          onPress={() => router.push('/Contact')}
        >
          <Ionicons name="mail-outline" size={20} color="#000" />
          <Text style={styles.bottomLabel}>Contact Us</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.bottomItem}
          onPress={() => router.push('/profile')}
        >
          <Ionicons name="settings-outline" size={20} color="#000" />
          <Text style={styles.bottomLabel}>Settings</Text>
        </TouchableOpacity>
      </View>
    </DrawerContentScrollView>
  );
}

const styles = StyleSheet.create({
  mainItems: {
    flex: 1,
  },
  bottomItems: {
    paddingHorizontal: 20,
    paddingBottom: 20,
    borderTopWidth: 1,
    borderColor: '#ccc',
  },
  bottomItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
  },
  bottomLabel: {
    marginLeft: 10,
    fontSize: 16,
    color: '#000',
  },
});
