// components/Buttons/PlusButton.jsx

import { TouchableOpacity, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export default function PlusButton({ onPress, size = 64, style, ...rest }) {
  const incoming = Array.isArray(style) ? Object.assign({}, ...style) : style || {};
  const { backgroundColor, ...safeStyle } = incoming;

  return (
    <TouchableOpacity
      onPress={onPress}
      style={styles.button}
      activeOpacity={0.85}
    >
      <Ionicons name="add" size={30} color="#fff" />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    position: 'absolute',
    top: -20,
    left: "50%",
    transform:[{translateX: -40}],
    backgroundColor: '#4CAF50',
    borderRadius: 24,
    width: 80,
    height: 80,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
