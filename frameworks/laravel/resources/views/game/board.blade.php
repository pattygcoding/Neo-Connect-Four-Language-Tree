<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Connect Four</title>
</head>
<body>
    <h1>Connect Four</h1>

    @if ($board->winner())
        <p>Player {{ $board->winner() }} wins!</p>
    @elseif ($board->isOver())
        <p>It's a tie!</p>
    @else
        <p>Player {{ $board->currentPlayer() }}, choose a column.</p>
    @endif

    <table class="board">
        @foreach (array_reverse($board->cells) as $row)
            <tr>
                @foreach ($row as $cell)
                    <td class="cell cell--{{ strtolower($cell) }}">{{ $cell }}</td>
                @endforeach
            </tr>
        @endforeach
    </table>

    <form method="post" action="{{ route('game.move') }}">
        @csrf
        @foreach ($columns as $column)
            <button type="submit" name="column" value="{{ $column }}"
                    @if ($board->isOver()) disabled @endif>{{ $column }}</button>
        @endforeach
    </form>

    <form method="post" action="{{ route('game.reset') }}">
        @csrf
        @method('DELETE')
        <button type="submit">New game</button>
    </form>
</body>
</html>
