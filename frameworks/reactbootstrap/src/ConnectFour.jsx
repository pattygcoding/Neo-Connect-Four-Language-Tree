import { useState } from "react";
import { Alert, Badge, Button, ButtonGroup, Card, Container, Table } from "react-bootstrap";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

const DISC_BG = {
    X: "danger",
    O: "warning",
    ".": "secondary",
};

export default function ConnectFour() {
    const [board, setBoard] = useState(createBoard);
    const [moves, setMoves] = useState(0);

    const champion = winner(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;
    const alertVariant = champion ? "success" : over ? "warning" : "info";

    function play(column) {
        if (over || isColumnFull(board, column)) {
            return;
        }
        setBoard(drop(board, column, currentPlayer(moves)));
        setMoves(moves + 1);
    }

    function reset() {
        setBoard(createBoard());
        setMoves(0);
    }

    return (
        <Container style={{ maxWidth: 640 }} className="py-4">
            <Alert
                variant={alertVariant}
                role="status"
                className="d-flex justify-content-between align-items-center"
            >
                <span>
                    {champion
                        ? `Player ${champion} wins!`
                        : over
                        ? "It's a tie!"
                        : `Player ${currentPlayer(moves)}, choose a column.`}
                </span>
                <Badge bg="primary">
                    {moves} {moves === 1 ? "move" : "moves"}
                </Badge>
            </Alert>

            <Card>
                <Card.Body className="text-center">
                    <Table borderless className="w-auto mx-auto mb-0">
                        <tbody>
                            {[...board].reverse().map((cells, rowIndex) => (
                                <tr key={rowIndex}>
                                    {cells.map((cell, columnIndex) => (
                                        <td key={columnIndex} className="p-1">
                                            <span
                                                className={`d-inline-flex align-items-center justify-content-center rounded-circle text-bg-${
                                                    DISC_BG[cell]
                                                }`}
                                                style={{ width: "2.5rem", height: "2.5rem" }}
                                            >
                                                {cell === "." ? "" : cell}
                                            </span>
                                        </td>
                                    ))}
                                </tr>
                            ))}
                        </tbody>
                    </Table>
                </Card.Body>
            </Card>

            <ButtonGroup className="w-100 mt-3">
                {Array.from({ length: COLUMNS }, (_, column) => (
                    <Button
                        key={column}
                        variant="outline-primary"
                        disabled={over || isColumnFull(board, column)}
                        onClick={() => play(column)}
                    >
                        {column + 1}
                    </Button>
                ))}
            </ButtonGroup>

            <div className="d-grid mt-3">
                <Button variant="outline-light" onClick={reset}>
                    New game
                </Button>
            </div>
        </Container>
    );
}
