// app/drawer/_layout.jsx
import { Drawer } from 'expo-router/drawer';

export default function DrawerLayout() {
  // “index” here will load /drawer/index.jsx
  return <Drawer initialRouteName="index" />;
}