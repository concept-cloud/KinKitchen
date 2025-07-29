import React from 'react';
import { View, Text, StyleSheet, Image } from 'react-native';

const ProfileSheet = ({ user }) => {
  return (
    <View style={styles.container}>
      <Image source={{ uri: user.photo }} style={styles.photo} />

      <Text style={styles.name}>
        {user.firstName} {user.lastName}
      </Text>

      <Text style={styles.info}>📧 {user.email}</Text>
      <Text style={styles.info}>📍 {user.location}</Text>
    </View>
  );
};

export default ProfileSheet;

const styles = StyleSheet.create({
  container: {
    padding: 24,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    elevation: 4,
    margin: 20,
  },
  photo: {
    width: 120,
    height: 120,
    borderRadius: 60,
    marginBottom: 16,
    borderWidth: 2,
    borderColor: '#fae3d9',
  },
  name: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  info: {
    fontSize: 16,
    color: '#555',
    marginBottom: 4,
  },
});
