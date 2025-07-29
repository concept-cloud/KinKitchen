import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Pressable,
} from 'react-native';
import { useFonts, Lobster_400Regular } from '@expo-google-fonts/lobster';
import { useRouter } from 'expo-router';

const CustomHeader = () => {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  const [fontsLoaded] = useFonts({
    Lobster_400Regular,
  });

  if (!fontsLoaded) return null;

  const navigateTo = (path) => {
    setOpen(false); // close menu first
    router.push(path);
  };

  return (
    <>
      {/* 🔘 Dropdown menu using Modal */}
      <Modal
        transparent
        visible={open}
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
        <Pressable style={styles.modalOverlay} onPress={() => setOpen(false)}>
          <View style={styles.dropdown}>
            <TouchableOpacity onPress={() => navigateTo('/profile')}>
              <Text style={styles.item}>Profile</Text>
            </TouchableOpacity>

            <TouchableOpacity onPress={() => navigateTo('/settings')}>
              <Text style={styles.item}>Settings</Text>
            </TouchableOpacity>

            <TouchableOpacity onPress={() => {
              setOpen(false);
              // Add logout logic here if needed
              alert('Logged out!');
              router.push('/'); // or /login if you have one
            }}>
              <Text style={styles.item}>Logout</Text>
            </TouchableOpacity>
          </View>
        </Pressable>
      </Modal>

      {/* 🔝 Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.push('/')}>
          <Text style={styles.logo}>Kin-Kitchen</Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={() => setOpen(!open)}>
          <Text style={styles.menu}>☰</Text>
        </TouchableOpacity>
      </View>
    </>
  );
};

export default CustomHeader;

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#fae3d9',
    paddingTop: 60,
    paddingBottom: 10,
    paddingHorizontal: 15,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    zIndex: 10,
  },
  logo: {
    fontSize: 35,
    fontFamily: 'Lobster_400Regular',
    color: '#000',
  },
  menu: {
    fontSize: 40,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'transparent',
    justifyContent: 'flex-start',
    alignItems: 'flex-end',
    paddingTop: 115,
    paddingRight: 15,
  },
  dropdown: {
    width: 160,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
    elevation: 5,
    zIndex: 20,
  },
  item: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    backgroundColor: '#fae3d9',
  },
});
