import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

 const CustomHeader = () => {
  const [open, setOpen] = useState(false);

  return (
    <View style={styles.header}>
      <Text style={styles.logo}>KinKitchen</Text>
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
    paddingTop: 40,
    paddingBottom: 10,
    paddingHorizontal: 15,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logo: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  menu: {
    fontSize: 24,
  },
  dropdown: {
    position: 'absolute',
    top: 70,
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