import { StyleSheet, Text, View } from 'react-native'
import CustomHeader from '../components/CustomHeader';


const About = () => {
  return (
    <View style={{ flex: 1 }}>
      <CustomHeader />
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text style={styles.title}>About Kin-Kitchen</Text>
      <Text style={{textAlign: 'center'}}>How may times have you wished you could remember your grandmothers special recipie?  How many of you have children about to set off on their own for the first time and you want to give them the taste of home?  How many friends do you have that always ask how you made this dish?
      </Text>
      <Text style={{textAlign: 'center'}}>Kin-Kitchen is a mobile application platform desinged to help chefs from all walks of life preserve their delicious recipies to share with the world.</Text>
      <Text style={{textAlign: 'center'}}>A key feature of our application is the ability to create personalized cook books that can be ordered directly from a POD service so that you can easily create a beautiful and professional cook book with all your family recipies.</Text>
    </View>
    </View>
  )
}
export default About

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