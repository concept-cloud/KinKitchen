import { StyleSheet, Text, View, Image, FlatList, Dimensions, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

const recipes = [
  { id: '1', title: 'Spaghetti Bolognese', image: { uri: 'https://via.placeholder.com/160x100?text=Spaghetti' } },
  { id: '2', title: 'Chicken Alfredo', image: { uri: 'https://via.placeholder.com/160x100?text=Alfredo' } },
  { id: '3', title: 'Beef Stroganoff', image: { uri: 'https://via.placeholder.com/160x100?text=Beef' } },
];

export default function TabsHome() {
  const router = useRouter();

  const renderItem = ({ item }) => (
    <View style={styles.card}>
      <Image source={item.image} style={styles.image} />
      <Text style={styles.title}>{item.title}</Text>
    </View>
  );

  return (
    <View style={{ flex: 1, backgroundColor: '#fff' }}>
      {/* Top Half: Recipe Cards */}
      <View style={styles.topHalf}>
        <FlatList
          data={recipes}
          horizontal
          showsHorizontalScrollIndicator={false}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
        />
      </View>

      {/* Bottom Half: Button */}
      <View style={styles.bottomHalf}>
        <TouchableOpacity
          style={styles.button}
          onPress={() => router.navigate('/create')}
        >
          <Text style={styles.buttonText}>Create New Recipe</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const { height } = Dimensions.get('window');

const styles = StyleSheet.create({
  topHalf: {
    height: height * 0.5,
    justifyContent: 'center',
  },
  bottomHalf: {
    height: height * 0.5,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fae3d9',
  },
  list: {
    paddingHorizontal: 16,
  },
  card: {
    marginRight: 16,
    width: 160,
    backgroundColor: '#fff',
    borderRadius: 10,
    overflow: 'hidden',
    elevation: 3,
  },
  image: {
    width: '100%',
    height: 100,
  },
  title: {
    padding: 10,
    fontSize: 16,
    fontWeight: '500',
  },
  button: {
    backgroundColor: '#c8dbbe',
    paddingVertical: 14,
    paddingHorizontal: 30,
    borderRadius: 8,
    elevation: 2,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#000',
  },
});
