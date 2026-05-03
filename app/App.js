import { NavigationContainer } from '@react-navigation/native'
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import { Text } from 'react-native'

import MapaScreen      from './src/screens/MapaScreen'
import AlertasScreen   from './src/screens/AlertasScreen'
import ReportesScreen  from './src/screens/ReportesScreen'
import PerfilScreen    from './src/screens/PerfilScreen'

const Tab = createBottomTabNavigator()

export default function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          tabBarActiveTintColor  : '#16a34a',
          tabBarInactiveTintColor: '#6b7280',
          tabBarStyle: {
            backgroundColor: '#ffffff',
            borderTopWidth : 1,
            borderTopColor : '#e5e7eb',
            paddingBottom  : 5,
            height         : 60,
          },
          headerStyle           : { backgroundColor: '#16a34a' },
          headerTintColor       : '#ffffff',
          headerTitleStyle      : { fontWeight: 'bold' },
        }}
      >
        <Tab.Screen
          name="Mapa"
          component={MapaScreen}
          options={{ tabBarIcon: () => <Text>🗺️</Text>, title: 'CargApp' }}
        />
        <Tab.Screen
          name="Alertas"
          component={AlertasScreen}
          options={{ tabBarIcon: () => <Text>🔔</Text> }}
        />
        <Tab.Screen
          name="Reportes"
          component={ReportesScreen}
          options={{ tabBarIcon: () => <Text>📢</Text> }}
        />
        <Tab.Screen
          name="Perfil"
          component={PerfilScreen}
          options={{ tabBarIcon: () => <Text>👤</Text> }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  )
}