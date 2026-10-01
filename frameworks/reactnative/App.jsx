import { StatusBar } from "expo-status-bar";
import { SafeAreaView, StyleSheet } from "react-native";

import ConnectFour from "./src/ConnectFour";

export default function App() {
    return (
        <SafeAreaView style={styles.container}>
            <ConnectFour />
            <StatusBar style="auto" />
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1 },
});
