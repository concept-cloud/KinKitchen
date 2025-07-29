import { StyleSheet, Text, View } from 'react-native'
import CustomHeader from '../components/CustomHeader';


const Contact = () => {
  return (
     <View style={{ flex: 1 }}>
          <CustomHeader />
          <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text style={styles.title}>Contact US</Text>
        <Text style={{textAlign: 'center'}}>We are currently working on building a customer service team.  Please check back later for information on how to contact us.</Text>
    </View>
    </View>
  )
}
export default Contact

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