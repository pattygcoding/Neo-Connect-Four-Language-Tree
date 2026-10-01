<?php

namespace App\Support;

class ConnectFourBoard
{
    public const ROWS = 6;
    public const COLUMNS = 7;
    public const EMPTY = '.';

    private const PLAYERS = ['X', 'O'];
    private const DIRECTIONS = [[0, 1], [1, 0], [1, 1], [1, -1]];

    public function __construct(
        public array $cells = [],
        public int $moves = 0,
    ) {
        if ($this->cells === []) {
            $this->cells = array_fill(0, self::ROWS, array_fill(0, self::COLUMNS, self::EMPTY));
        }
    }

    public static function fromSession(?array $data): self
    {
        if ($data === null) {
            return new self();
        }

        return new self($data['cells'], $data['moves']);
    }

    public function toSession(): array
    {
        return ['cells' => $this->cells, 'moves' => $this->moves];
    }

    public function currentPlayer(): string
    {
        return self::PLAYERS[$this->moves % count(self::PLAYERS)];
    }

    public function winner(): ?string
    {
        foreach (self::PLAYERS as $player) {
            if ($this->hasLine($player)) {
                return $player;
            }
        }

        return null;
    }

    public function isOver(): bool
    {
        return $this->winner() !== null || $this->moves === self::ROWS * self::COLUMNS;
    }

    public function isFull(int $column): bool
    {
        return $this->lowestEmptyRow($column) === null;
    }

    public function drop(int $column): bool
    {
        $row = $this->lowestEmptyRow($column);

        if ($row === null) {
            return false;
        }

        $this->cells[$row][$column] = $this->currentPlayer();
        $this->moves++;

        return true;
    }

    private function lowestEmptyRow(int $column): ?int
    {
        for ($row = 0; $row < self::ROWS; $row++) {
            if ($this->cells[$row][$column] === self::EMPTY) {
                return $row;
            }
        }

        return null;
    }

    private function hasLine(string $player): bool
    {
        foreach (self::DIRECTIONS as [$rowStep, $columnStep]) {
            for ($row = 0; $row < self::ROWS; $row++) {
                for ($column = 0; $column < self::COLUMNS; $column++) {
                    if ($this->matches($row, $column, $player)
                        && $this->matches($row + $rowStep, $column + $columnStep, $player)
                        && $this->matches($row + $rowStep * 2, $column + $columnStep * 2, $player)
                        && $this->matches($row + $rowStep * 3, $column + $columnStep * 3, $player)) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    private function matches(int $row, int $column, string $player): bool
    {
        return $row >= 0 && $row < self::ROWS
            && $column >= 0 && $column < self::COLUMNS
            && $this->cells[$row][$column] === $player;
    }
}
