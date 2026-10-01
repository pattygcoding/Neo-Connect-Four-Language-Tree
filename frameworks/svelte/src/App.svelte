<script>
    import { board, columns, over, status, play, reset } from "./lib/store.js";
</script>

<section class="game">
    <h1>Connect Four</h1>

    <p role="status">{$status}</p>

    <table class="board">
        <tbody>
            {#each [...$board].reverse() as cells}
                <tr>
                    {#each cells as cell}
                        <td class="cell cell--{cell.toLowerCase()}">{cell}</td>
                    {/each}
                </tr>
            {/each}
        </tbody>
    </table>

    <div class="columns">
        {#each columns as column}
            <button type="button" disabled={$over} on:click={() => play(column)}>
                {column + 1}
            </button>
        {/each}
    </div>

    <button type="button" on:click={reset}>New game</button>
</section>
