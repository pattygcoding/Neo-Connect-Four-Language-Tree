<script setup>
import {
    BAlert,
    BBadge,
    BButton,
    BButtonGroup,
    BCard,
    BCardBody,
    BContainer,
    BTable,
} from "bootstrap-vue-next";

import { useConnectFour } from "./composables/useConnectFour";

const { moves, status, rows, columns, alertVariant, play, reset } = useConnectFour();

const discBg = { X: "danger", O: "warning", ".": "secondary" };
</script>

<template>
    <BContainer style="max-width: 640px" class="py-4">
        <BAlert
            :variant="alertVariant"
            role="status"
            class="d-flex justify-content-between align-items-center"
        >
            <span>{{ status }}</span>
            <BBadge variant="primary">{{ moves }} {{ moves === 1 ? "move" : "moves" }}</BBadge>
        </BAlert>

        <BCard>
            <BCardBody class="text-center">
                <BTable borderless class="w-auto mx-auto mb-0">
                    <tbody>
                        <tr v-for="(row, rowIndex) in rows" :key="rowIndex">
                            <td v-for="(cell, columnIndex) in row" :key="columnIndex" class="p-1">
                                <span
                                    class="d-inline-flex align-items-center justify-content-center rounded-circle"
                                    :class="`text-bg-${discBg[cell]}`"
                                    style="width: 2.5rem; height: 2.5rem"
                                >
                                    {{ cell === "." ? "" : cell }}
                                </span>
                            </td>
                        </tr>
                    </tbody>
                </BTable>
            </BCardBody>
        </BCard>

        <BButtonGroup class="w-100 mt-3">
            <BButton
                v-for="column in columns"
                :key="column.index"
                variant="outline-primary"
                :disabled="column.disabled"
                @click="play(column.index)"
            >
                {{ column.label }}
            </BButton>
        </BButtonGroup>

        <div class="d-grid mt-3">
            <BButton variant="outline-light" @click="reset">New game</BButton>
        </div>
    </BContainer>
</template>
