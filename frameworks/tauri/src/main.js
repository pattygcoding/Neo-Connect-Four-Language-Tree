const { invoke } = window.__TAURI__.core;

const boardEl = document.getElementById("board");
const columnsEl = document.getElementById("columns");
const statusEl = document.getElementById("status");
const resetEl = document.getElementById("reset");

function render(view) {
    statusEl.textContent = view.status;

    boardEl.replaceChildren();
    for (const row of view.rows) {
        const tr = document.createElement("tr");
        for (const cell of row) {
            const td = document.createElement("td");
            td.className = `cell cell--${cell.toLowerCase()}`;
            td.textContent = cell;
            tr.append(td);
        }
        boardEl.append(tr);
    }

    columnsEl.replaceChildren();
    view.full.forEach((full, column) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = String(column + 1);
        button.disabled = view.over || full;
        button.addEventListener("click", async () => render(await invoke("play", { column })));
        columnsEl.append(button);
    });
}

resetEl.addEventListener("click", async () => render(await invoke("new_game")));

window.addEventListener("DOMContentLoaded", async () => render(await invoke("new_game")));
