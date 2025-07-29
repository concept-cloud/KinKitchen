// app/profile.jsx
import React from 'react';
import { View, StyleSheet } from 'react-native';
import EditableProfileSheet from '../components/EditableProfileSheet';
import CustomHeader from '../components/CustomHeader';

export default function ProfileScreen() {
  const userData = {
    photo: 'https://i.pravatar.cc/150?img=12',
    firstName: 'Gregory',
    lastName: 'Hudler',
    email: 'greg@example.com',
    location: 'Baltimore, MD',
  };

  return (
    <View style={{ flex: 1 }}>
             <CustomHeader />
    <View style={styles.container}>
      <EditableProfileSheet initialUser={userData} />
    </View>
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
