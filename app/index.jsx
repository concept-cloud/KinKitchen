// app/index.jsx
import { StyleSheet, Text, View, Image } from 'react-native';
import { Link } from 'expo-router'; // ✅ Required for navigation
import CustomHeaderLayout from '../components/CustomHeaderLayout';
import Logo from '../assets/images/Kin-Kitchen.png';

const Home = () => {
  return (
    <CustomHeaderLayout>
      <View style={styles.container}>
        <Image source={Logo} style={styles.img} />
        <Text style={styles.title}>Where Family Recipes live forever.</Text>

        <Link href="/about" style={styles.link}>About</Link>
        <Link href="/Contact" style={styles.link}>Contact Us</Link>
        <Link href="/recipie" style={styles.link}>Recipe Card</Link>
      </View>
    </CustomHeaderLayout>
  );
};

export default Home;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: 10,
  },
  img: {
    marginVertical: 20,
    width: 200,
    height: 200,
    resizeMode: 'contain',
  },
  title: {
    fontWeight: 'bold',
    fontSize: 18,
    marginBottom: 20,
    textAlign: 'center',
  },
  link: {
    marginVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#999',
    padding: 5,
  },
});
