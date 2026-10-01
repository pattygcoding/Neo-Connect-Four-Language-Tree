import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

export default function ConnectFour() {
    const [board, setBoard] = useState(createBoard);
    const [moves, setMoves] = useState(0);

    const champion = winner(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    function play(column) {
        if (over || isColumnFull(board, column)) {
            return;
        }
        setBoard(drop(board, column, currentPlayer(moves)));
        setMoves(moves + 1);
    }

    function reset() {
        setBoard(createBoard());
        setMoves(0);
    }

    return (
        <View style={styles.game}>
            <Text style={styles.title}>Connect Four</Text>

            <Text style={styles.status}>
                {champion
                    ? `Player ${champion} wins!`
                    : over
                    ? "It's a tie!"
                    : `Player ${currentPlayer(moves)}, choose a column.`}
            </Text>

            <View style={styles.board}>
                {[...board].reverse().map((cells, rowIndex) => (
                    <View key={rowIndex} style={styles.row}>
                        {cells.map((cell, columnIndex) => (
                            <Text key={columnIndex} style={styles.cell}>
                                {cell}
                            </Text>
                        ))}
                    </View>
                ))}
            </View>

            <View style={styles.columns}>
                {Array.from({ length: COLUMNS }, (_, index) => (
                    <Pressable
                        key={index}
                        style={styles.button}
                        disabled={over || isColumnFull(board, index)}
                        onPress={() => play(index)}
                    >
                        <Text style={styles.buttonLabel}>{index + 1}</Text>
                    </Pressable>
                ))}
            </View>

            <Pressable style={styles.button} onPress={reset}>
                <Text style={styles.buttonLabel}>New game</Text>
            </Pressable>
        </View>
    );
}

const styles = StyleSheet.create({
    game: { alignItems: "center", flex: 1, justifyContent: "center" },
    title: { fontSize: 24, fontWeight: "bold" },
    status: { marginVertical: 8 },
    board: { borderColor: "#cbd3d0", borderWidth: 1 },
    row: { flexDirection: "row" },
    cell: { fontSize: 20, padding: 4, textAlign: "center", width: 32 },
    columns: { flexDirection: "row", marginVertical: 8 },
    button: {
        alignItems: "center",
        backgroundColor: "#eef1f0",
        borderRadius: 4,
        marginHorizontal: 2,
        paddingHorizontal: 12,
        paddingVertical: 8,
    },
    buttonLabel: { fontSize: 16 },
});
