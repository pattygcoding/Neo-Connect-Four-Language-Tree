from pathlib import Path

from graphql import build_schema, graphql_sync

from board import COLUMNS, EMPTY, ROWS, Board

HERE = Path(__file__).resolve().parent
SCHEMA = build_schema(HERE.joinpath("schema.graphql").read_text(encoding="utf-8"))

GAME = {"game": Board()}


def snapshot(board):
    """The plain dict the default field resolver maps onto the Board type."""
    return {
        "rows": ROWS,
        "columns": COLUMNS,
        "moves": board.moves,
        "empty": EMPTY,
        "player": board.current_player,
        "winner": board.winner(),
        "isOver": board.is_over(),
        "cells": [row[:] for row in reversed(board.cells)],
    }


def game_of(info):
    return info.context["game"]


def resolve_board(root, info):
    return snapshot(game_of(info))


def resolve_current_player(root, info):
    return game_of(info).current_player


def resolve_column_heights(root, info):
    board = game_of(info)
    return [board.column_height(column) for column in range(COLUMNS)]


def resolve_drop(root, info, column):
    board = game_of(info)
    if 1 <= column <= COLUMNS and not board.is_over() and not board.is_full(column - 1):
        board.drop(column - 1)
    return snapshot(board)


def resolve_reset(root, info):
    info.context["game"] = Board()
    return snapshot(info.context["game"])


def resolve_replay(root, info, columns):
    board = Board()
    for column in columns:
        if board.is_over():
            break
        if 1 <= column <= COLUMNS and not board.is_full(column - 1):
            board.drop(column - 1)
    info.context["game"] = board
    return snapshot(board)


def wire():
    """Attach the resolvers to the schema loaded from schema.graphql."""
    query = SCHEMA.get_type("Query")
    query.fields["board"].resolve = resolve_board
    query.fields["currentPlayer"].resolve = resolve_current_player
    query.fields["columnHeights"].resolve = resolve_column_heights

    mutation = SCHEMA.get_type("Mutation")
    mutation.fields["drop"].resolve = resolve_drop
    mutation.fields["reset"].resolve = resolve_reset
    mutation.fields["replay"].resolve = resolve_replay


wire()


def run(source, variables=None):
    """Execute an operation and return its data, printing any GraphQL errors."""
    result = graphql_sync(SCHEMA, source, context_value=GAME, variable_values=variables)
    if result.errors:
        for error in result.errors:
            print("error:", error.message)
    return result.data


def main():
    print("query  board        ->", run("{ board { rows columns player } }"))
    print("query  heights      ->", run("{ columnHeights }"))
    print("mutation drop(4)    ->", run("mutation { drop(column: 4) { player moves } }"))
    print("mutation replay     ->", run("mutation { replay(columns: [1,1,2,2,3,3,4]) { winner isOver } }"))
    print("query  winner       ->", run("{ board { winner cells } }"))
    print("mutation reset      ->", run("mutation { reset { moves player } }"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
