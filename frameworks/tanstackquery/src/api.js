async function request(path, options) {
    const response = await fetch(path, options);
    if (!response.ok) {
        throw new Error(`Request failed: ${response.status}`);
    }
    return response.json();
}

export function fetchGame() {
    return request("/api/game");
}

export function sendMove(column) {
    return request(`/api/move?column=${column}`, { method: "POST" });
}

export function resetGame() {
    return request("/api/reset", { method: "POST" });
}
