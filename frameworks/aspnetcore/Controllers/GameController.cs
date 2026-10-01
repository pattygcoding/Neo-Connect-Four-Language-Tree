using ConnectFour.Models;

using Microsoft.AspNetCore.Mvc;

namespace ConnectFour.Controllers;

public class GameController : Controller
{
    private const string SessionKey = "board";

    public IActionResult Board()
    {
        var board = CurrentBoard();
        ViewData["Status"] = Status(board);
        return View(board);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Move(int column)
    {
        var board = CurrentBoard();

        if (column >= 1 && column <= ConnectFourBoard.Columns && !board.IsOver
            && !board.IsFull(column - 1))
        {
            board.Drop(column - 1);
        }

        Store(board);
        return RedirectToAction(nameof(Board));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Reset()
    {
        HttpContext.Session.Remove(SessionKey);
        return RedirectToAction(nameof(Board));
    }

    private ConnectFourBoard CurrentBoard()
    {
        var state = HttpContext.Session.GetString(SessionKey);
        return state is null ? new ConnectFourBoard() : ConnectFourBoard.Deserialize(state);
    }

    private void Store(ConnectFourBoard board) =>
        HttpContext.Session.SetString(SessionKey, board.Serialize());

    private static string Status(ConnectFourBoard board) =>
        board.Winner() != '.' ? $"Player {board.Winner()} wins!"
        : board.IsOver ? "It's a tie!"
        : $"Player {board.CurrentPlayer}, choose a column.";
}
