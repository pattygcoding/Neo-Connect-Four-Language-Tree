import type { Page } from "@playwright/test";

export async function dropDiscs(page: Page, columns: number[]): Promise<void> {
    for (const column of columns) {
        await page.getByRole("button", { name: String(column + 1), exact: true }).click();
    }
}

export function columnName(column: number): string {
    return String(column + 1);
}
