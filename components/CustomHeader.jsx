import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useFonts, Lobster_400Regular } from '@expo-google-fonts/lobster';

 const CustomHeader = () => {
  const [open, setOpen] = useState(false);

  const [fontsLoaded] = useFonts({
    Lobster_400Regular,
  });

  if (!fontsLoaded) {
    return null; // Optionally return a loading spinner
  }

  return (
    <View style={styles.header}>
      <Text style={styles.logo}>Kin-Kitchen</Text>
      <TouchableOpacity onPress={() => setOpen(!open)}>
        <Text style={styles.menu}>☰  </Text>
      </TouchableOpacity>
      {open && (
        <View style={styles.dropdown}>
          <Text style={styles.item}>Profile</Text>
          <Text style={styles.item}>Settings</Text>
          <Text style={styles.item}>Logout</Text>
        </View>
      )}
    </View>
  );
}
export default CustomHeader

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#fae3d9',
    paddingTop: 60,
    paddingBottom: 10,
    paddingHorizontal: 15,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logo: {
    fontSize: 20,
    fontWeight: 'bold',
    fontFamily: 'Lobster_400Regular',
  },
  menu: {
    fontSize: 24,
  },
  dropdown: {
    position: 'absolute',
    top: 96,
    right: 15,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
    elevation: 5,
    zIndex: 99,
  },
  item: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    backgroundColor: '#fae3d9',
  },
});