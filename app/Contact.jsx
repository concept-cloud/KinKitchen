import { StyleSheet, Text, View } from 'react-native'



const Contact = () => {
  return (
    <View style={styles.container}>
        <Text style={styles.title}>Contact US</Text>
        <Text style={{textAlign: 'center'}}>We are currently working on building a customer service team.  Please check back later for information on how to contact us.</Text>
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