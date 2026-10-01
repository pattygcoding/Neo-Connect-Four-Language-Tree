<?php

use App\Http\Controllers\GameController;
use Illuminate\Support\Facades\Route;

Route::get('/', [GameController::class, 'show'])->name('game.board');
Route::post('/move', [GameController::class, 'move'])->name('game.move');
Route::delete('/reset', [GameController::class, 'reset'])->name('game.reset');
