package com.example.connectfour;

import jakarta.servlet.http.HttpSession;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class GameController {
    private static final String SESSION_KEY = "board";

    @GetMapping("/")
    public String board(HttpSession session, Model model) {
        ConnectFourBoard board = currentBoard(session);
        model.addAttribute("board", board);
        model.addAttribute("status", status(board));
        return "board";
    }

    @PostMapping("/move")
    public String move(@RequestParam int column, HttpSession session) {
        ConnectFourBoard board = currentBoard(session);

        if (column >= 1 && column <= ConnectFourBoard.COLUMNS && !board.isOver()
                && !board.isFull(column - 1)) {
            board.drop(column - 1);
        }

        session.setAttribute(SESSION_KEY, board);
        return "redirect:/";
    }

    @PostMapping("/reset")
    public String reset(HttpSession session) {
        session.removeAttribute(SESSION_KEY);
        return "redirect:/";
    }

    private String status(ConnectFourBoard board) {
        if (board.winner() != '.') {
            return "Player " + board.winner() + " wins!";
        }
        if (board.isOver()) {
            return "It's a tie!";
        }
        return "Player " + board.currentPlayer() + ", choose a column.";
    }

    private ConnectFourBoard currentBoard(HttpSession session) {
        Object stored = session.getAttribute(SESSION_KEY);
        if (stored instanceof ConnectFourBoard board) {
            return board;
        }
        return new ConnectFourBoard();
    }
}
