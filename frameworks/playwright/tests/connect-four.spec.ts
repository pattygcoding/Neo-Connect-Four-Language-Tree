import { expect, test } from "@playwright/test";

import { columnName, dropDiscs } from "./support/board";

test.beforeEach(async ({ page }) => {
    await page.goto("/");
});

test("announces the opening player", async ({ page }) => {
    await expect(page.getByRole("status")).toHaveText("Player X, choose a column.");
});

test("X wins with a horizontal line across the bottom", async ({ page }) => {
    await dropDiscs(page, [0, 0, 1, 1, 2, 2, 3]);
    await expect(page.getByRole("status")).toHaveText("Player X wins!");
});

test("O wins with a vertical line", async ({ page }) => {
    await dropDiscs(page, [0, 1, 0, 1, 6, 1, 6, 1]);
    await expect(page.getByRole("status")).toHaveText("Player O wins!");
});

test("a full column can no longer be played", async ({ page }) => {
    for (let move = 0; move < 6; move += 1) {
        await dropDiscs(page, [0]);
    }
    await expect(page.getByRole("button", { name: columnName(0), exact: true })).toBeDisabled();
});

test("the reset button clears the board", async ({ page }) => {
    await dropDiscs(page, [0, 1, 2]);
    await page.getByRole("button", { name: "New game" }).click();
    await expect(page.getByRole("status")).toHaveText("Player X, choose a column.");
});
