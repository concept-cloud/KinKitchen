import { StyleSheet, Text, View, Image } from 'react-native'
import Logo from '../assets/images/Kin-Kitchen.png'
import { Link } from 'expo-router'

const Home = () => {
  return (
    <View style={styles.container}>
      <Image source={Logo} style={styles.img}/>
      <Text style={styles.title}>Where Family Recipies live forever.</Text>
      <Link href="/about" style={styles.link}>About</Link>
      <Link href="/Contact" style={styles.link}>Contact Us</Link>
    </View>
  )
}

export default Home

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  img:
  {
    marginVertical: 20,
  },
  link: 
  {
    marginVertical: 10,
    borderBottomWidth: 1,
  },
  title: {
    fontWeight: 'bold',
    fontSize: 18,
  }
})