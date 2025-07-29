import { SafeAreaView, StatusBar, ScrollView, View, Text, Image, TouchableOpacity, StyleSheet } from 'react-native'

export default function RecipeCardScreen() {
  const categories = ['Special Diets']
  const ingredients = [
    '1 cup all-purpose flour',
    '2 tbsp sugar',
    '1 tsp baking powder',
    'Pinch of salt',
    '1 cup milk',
    '1 egg',
    '2 tbsp melted butter',
  ]
  const directions = [
    'Preheat oven to 350°F (175°C).',
    'In a bowl, whisk together flour, sugar, baking powder, and salt.',
    'In another bowl, beat egg with milk and melted butter.',
    'Pour wet ingredients into dry and stir until just combined.',
    'Pour batter into greased muffin tin.',
    'Bake for 18–20 minutes, or until golden brown.',
    'Let cool before serving.',
  ]

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" />
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.headerButton} onPress={() => {}}>
          <Text style={styles.headerButtonText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Recipe Title</Text>
        <TouchableOpacity style={styles.headerButton} onPress={() => {}}>
          <Text style={styles.headerButtonText}>Edit</Text>
        </TouchableOpacity>
      </View>

      {/* Content */}
      <ScrollView contentContainerStyle={styles.container}>
        <Image
          source={{ uri: 'https://source.unsplash.com/featured/?recipe' }}
          style={styles.image}
          resizeMode="cover"
        />

        {/* Categories Scroll */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.categoryScroll}
        >
          {categories.map((cat, i) => (
            <TouchableOpacity key={i} style={styles.categoryItem} onPress={() => {}}>
              <View style={styles.categoryIcon} />
              <Text style={styles.categoryText}>{cat} →</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Ingredients */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Ingredients</Text>
          <View style={styles.content}>
            {ingredients.map((item, idx) => (
              <Text key={idx} style={styles.itemText}>• {item}</Text>
            ))}
          </View>
        </View>

        {/* Instructions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Instructions</Text>
          <View style={styles.content}>
            {directions.map((step, idx) => (
              <Text key={idx} style={styles.itemText}>{idx + 1}. {step}</Text>
            ))}
          </View>
        </View>
      </ScrollView>

      {/* Handle Indicator */}
      <View style={styles.handle} />

      {/* Footer Actions */}
      <View style={styles.footer}>
        <TouchableOpacity style={styles.footerButton} onPress={() => {}}>
          <View style={styles.footerIcon} />
          <Text style={styles.footerText}>Share</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.footerButton} onPress={() => {}}>
          <View style={styles.footerIcon} />
          <Text style={styles.footerText}>Add to Project</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.footerButton} onPress={() => {}}>
          <View style={styles.footerIcon} />
          <Text style={styles.footerText}>Print</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
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
