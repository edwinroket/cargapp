import { View, Text, StyleSheet } from 'react-native'

export default function PerfilScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.texto}>👤 Perfil — próximamente</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#f9fafb' },
  texto    : { fontSize: 18, color: '#374151' }
})