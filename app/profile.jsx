// app/profile.jsx
import React from 'react';
import { View, StyleSheet } from 'react-native';
import EditableProfileSheet from '../components/EditableProfileSheet';

export default function ProfileScreen() {
  const userData = {
    photo: 'https://i.pravatar.cc/150?img=12',
    firstName: 'Gregory',
    lastName: 'Hudler',
    email: 'greg@example.com',
    location: 'Baltimore, MD',
  };

  return (
    <View style={styles.container}>
      <EditableProfileSheet initialUser={userData} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fdf6f2',
    justifyContent: 'center',
  },
});
