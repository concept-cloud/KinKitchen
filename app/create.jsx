// app/create.jsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import CustomHeader from '../components/CustomHeader';

export default function CreateScreen() {
  return (
    <View style={{ flex: 1 }}>
        <CustomHeader />
        <View style={styles.container}>
      <Text style={styles.text}>Recipe Creator Coming Soon!</Text>
    </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    fontSize: 18,
  },
});
