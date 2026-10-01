<script setup>
import { useConnectFour } from "../composables/useConnectFour";

const { board, over, status, columns, play, reset, isColumnFull } = useConnectFour();
</script>

<template>
    <section class="game">
        <h1>Connect Four</h1>

        <p role="status">{{ status }}</p>

        <table class="board">
            <tbody>
                <tr v-for="(cells, rowIndex) in [...board].reverse()" :key="rowIndex">
                    <td
                        v-for="(cell, columnIndex) in cells"
                        :key="columnIndex"
                        class="cell"
                        :class="`cell--${cell.toLowerCase()}`">
                        {{ cell }}
                    </td>
                </tr>
            </tbody>
        </table>

        <div class="columns">
            <button
                v-for="column in columns"
                :key="column"
                type="button"
                :disabled="over || isColumnFull(board, column)"
                @click="play(column)">
                {{ column + 1 }}
            </button>
        </div>

        <button type="button" @click="reset">New game</button>
    </section>
</template>
