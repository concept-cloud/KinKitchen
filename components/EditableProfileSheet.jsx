import React, { useRef, useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  Image,
  TouchableOpacity,
  KeyboardAvoidingView,
  ScrollView,
  Platform,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { findNodeHandle, UIManager } from 'react-native';

const EditableProfileSheet = ({ initialUser }) => {
  const [user, setUser] = useState(initialUser);
  const scrollRef = useRef(null);
//Keyboard avoidance with location 
const [inputLayouts, setInputLayouts] = useState({});

const handleInputLayout = (name, event) => {
  const { y } = event.nativeEvent.layout;
  setInputLayouts((prev) => ({ ...prev, [name]: y }));
};

const scrollToInput = (ref) => {
  if (ref?.current && scrollRef.current) {
    setTimeout(() => {
      const nodeHandle = findNodeHandle(ref.current);
      if (nodeHandle) {
        UIManager.measureLayout(
          nodeHandle,
          findNodeHandle(scrollRef.current),
          () => {}, // failure callback
          (x, y) => {
            scrollRef.current.scrollTo({ y: y - 80, animated: true });
          }
        );
      }
    }, 300); // Give time for keyboard to open and layout to settle
  }
};

const firstNameRef = useRef(null);
const lastNameRef = useRef(null);
const emailRef = useRef(null);
const locationRef = useRef(null);

//end keyboard avoidance

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      quality: 1,
    });

    if (!result.canceled) {
      setUser({ ...user, photo: result.assets[0].uri });
    }
  };

  const handleChange = (field, value) => {
    setUser((prev) => ({ ...prev, [field]: value }));
  };

  return (
   <KeyboardAvoidingView
  style={{ flex: 1 }}
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  keyboardVerticalOffset={Platform.OS === 'ios' ? 80 : 0}
>
  <ScrollView ref={scrollRef} contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <TouchableOpacity onPress={pickImage}>
          <Image source={{ uri: user.photo }} style={styles.photo} />
          <Text style={styles.changePhoto}>Tap to change photo</Text>
        </TouchableOpacity>

        <View style={styles.inputGroup}>
            <Text style={styles.label}>First Name</Text>
        <TextInput
          ref={firstNameRef}
          style={styles.input}
          placeholder="First Name"
          value={user.firstName}
          onLayout={(e) => handleInputLayout('firstname',e)}
          onFocus={() => scrollToInput(firstNameRef)}
          onChangeText={(text) => handleChange('firstName', text)}
        />
        </View>

        <View style={styles.inputGroup}>
            <Text style={styles.label}>Last Name</Text>
        <TextInput
          ref={lastNameRef}
          style={styles.input}
          placeholder="Last Name"
          value={user.lastName}
          onLayout={(e) => handleInputLayout('lastname',e)}
          onFocus={() => scrollToInput(lastNameRef)}
          onChangeText={(text) => handleChange('lastName', text)}
        />
        </View>

        <View style={styles.inputGroup}>
            <Text style={styles.label}>Email Address</Text>
        <TextInput
          ref={emailRef}
          style={styles.input}
          placeholder="Email"
          value={user.email}
          keyboardType="email-address"
          onLayout={(e) => handleInputLayout('email',e)}
          onFocus={() => scrollToInput(emailRef)}
          onChangeText={(text) => handleChange('email', text)}
        />
        </View>

        <View style={styles.inputGroup}>
            <Text style={styles.label}>Location</Text>
        <TextInput
          ref={locationRef}
          style={styles.input}
          placeholder="Location"
          value={user.location}
          onLayout={(e) => handleInputLayout('location',e)}
          onFocus={() => scrollToInput(locationRef)}
          onChangeText={(text) => handleChange('location', text)}
        />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

export default EditableProfileSheet;

const styles = StyleSheet.create({
  container: {
    padding: 24,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    margin: 20,
  },
  photo: {
    width: 120,
    height: 120,
    borderRadius: 60,
    marginBottom: 6,
    borderWidth: 2,
    borderColor: '#fae3d9',
  },
  changePhoto: {
    fontSize: 12,
    color: '#777',
    marginBottom: 16,
  },
  input: {
    width: '100%',
    fontSize: 16,
    padding: 12,
    marginVertical: 6,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
  },
  inputGroup: {
    width: '100%',
    marginBottom: 12,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 4,
  },
});
