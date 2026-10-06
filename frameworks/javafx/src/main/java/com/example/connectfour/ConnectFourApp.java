package com.example.connectfour;

import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Circle;
import javafx.stage.Stage;

public class ConnectFourApp extends Application {

    private final ConnectFourBoard board = new ConnectFourBoard();
    private final GridPane boardGrid = new GridPane();
    private final GridPane columnGrid = new GridPane();
    private final Label status = new Label();

    @Override
    public void start(Stage stage) {
        boardGrid.setHgap(4);
        boardGrid.setVgap(4);
        columnGrid.setHgap(4);
        boardGrid.setAlignment(Pos.CENTER);
        columnGrid.setAlignment(Pos.CENTER);

        Label title = new Label("Connect Four");
        title.setStyle("-fx-font-size: 24px; -fx-font-weight: bold;");

        VBox root = new VBox(12, title, status, boardGrid, columnGrid);
        root.setPadding(new Insets(16));
        root.setAlignment(Pos.CENTER);

        render();

        stage.setTitle("Connect Four");
        stage.setScene(new Scene(root, 480, 580));
        stage.show();
    }

    private void render() {
        String champion = board.winner();
        status.setText(
                champion != null
                        ? "Player " + champion + " wins!"
                        : board.isOver()
                                ? "It's a tie!"
                                : "Player " + board.currentPlayer() + ", choose a column.");

        boardGrid.getChildren().clear();
        for (int displayRow = 0; displayRow < ConnectFourBoard.ROWS; displayRow++) {
            int row = ConnectFourBoard.ROWS - 1 - displayRow;
            for (int column = 0; column < ConnectFourBoard.COLUMNS; column++) {
                Circle disc = new Circle(20, discColor(board.cell(row, column)));
                boardGrid.add(disc, column, displayRow);
            }
        }

        columnGrid.getChildren().clear();
        for (int column = 0; column < ConnectFourBoard.COLUMNS; column++) {
            int target = column;
            Button button = new Button(String.valueOf(column + 1));
            button.setDisable(board.isOver() || board.isFull(column));
            button.setOnAction(event -> {
                board.drop(target);
                render();
            });
            columnGrid.add(button, column, 0);
        }
    }

    private Color discColor(String cell) {
        return switch (cell) {
            case "X" -> Color.CRIMSON;
            case "O" -> Color.GOLD;
            default -> Color.DARKSLATEGRAY;
        };
    }

    public static void main(String[] args) {
        launch(args);
    }
}
