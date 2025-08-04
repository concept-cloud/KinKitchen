import { View, Text, StyleSheet } from 'react-native'
import CustomHeader from '../../components/CustomHeader';

export default function RecipeCardScreen() {


  return (
   <View style={{ flex: 1 }}>
         <CustomHeader />
         <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
           <Text style={styles.title}>Currently Under Construction</Text>
         </View>
         </View>
  )
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderColor: '#ccc',
  },
  headerButton: {
    padding: 6,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
  },
  headerButtonText: {
    fontSize: 16,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
  },
  container: {
    padding: 16,
  },
  image: {
    width: '100%',
    height: 200,
    borderRadius: 8,
    marginBottom: 12,
  },
  categoryScroll: {
    marginBottom: 12,
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 8,
    backgroundColor: '#f0f0f0',
    borderRadius: 20,
  },
  categoryIcon: {
    width: 20,
    height: 20,
    backgroundColor: '#a0a0a0',
    marginRight: 6,
    borderRadius: 4,
  },
  categoryText: {
    fontSize: 14,
  },
  section: {
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
  },
  content: {
    backgroundColor: '#fafafa',
    padding: 12,
    borderRadius: 6,
  },
  itemText: {
    fontSize: 16,
    marginVertical: 4,
    lineHeight: 22,
  },
  handle: {
    height: 4,
    width: 60,
    backgroundColor: '#e0e0e0',
    alignSelf: 'center',
    borderRadius: 2,
    marginVertical: 8,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 12,
    borderTopWidth: 1,
    borderColor: '#ccc',
  },
  footerButton: {
    alignItems: 'center',
  },
  footerIcon: {
    width: 24,
    height: 24,
    backgroundColor: '#a0a0a0',
    borderRadius: 4,
    marginBottom: 4,
  },
  footerText: {
    fontSize: 12,
  },
})
