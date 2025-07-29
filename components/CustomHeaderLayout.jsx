import { View, StyleSheet } from 'react-native';
import CustomHeader from './CustomHeader';

 const CustomHeaderLayout = ({ children }) => {
  return (
    <View style={styles.container}>
      <CustomHeader />
      <View style={styles.content}>{children}</View>
    </View>
  );
}
export default CustomHeaderLayout

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
});