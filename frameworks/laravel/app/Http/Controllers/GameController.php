<?php

namespace App\Http\Controllers;

use App\Support\ConnectFourBoard;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class GameController extends Controller
{
    public function show(): View
    {
        return view('game.board', [
            'board' => $this->board(),
            'columns' => range(1, ConnectFourBoard::COLUMNS),
        ]);
    }

    public function move(Request $request): RedirectResponse
    {
        $board = $this->board();
        $column = (int) $request->input('column') - 1;

        if ($column >= 0 && $column < ConnectFourBoard::COLUMNS
            && ! $board->isOver() && ! $board->isFull($column)) {
            $board->drop($column);
        }

        session(['board' => $board->toSession()]);

        return redirect()->route('game.board');
    }

    public function reset(): RedirectResponse
    {
        session()->forget('board');

        return redirect()->route('game.board');
    }

    private function board(): ConnectFourBoard
    {
        return ConnectFourBoard::fromSession(session('board'));
    }
}
