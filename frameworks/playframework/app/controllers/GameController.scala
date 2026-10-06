package controllers

import javax.inject._
import models.Board
import models.ConnectFourBoard
import play.api.mvc._

@Singleton
class GameController @Inject() (val controllerComponents: ControllerComponents)
    extends BaseController {

    def index: Action[AnyContent] = Action { implicit request =>
        val board = currentBoard
        Ok(views.html.board(board, 1 to Board.Columns))
    }

    def move: Action[AnyContent] = Action { implicit request =>
        val board = currentBoard
        val column = request.body.asFormUrlEncoded
            .flatMap(_.get("column").flatMap(_.headOption))
            .flatMap(_.toIntOption)
            .getOrElse(0)

        val next =
            if (!board.isOver && column >= 1 && column <= Board.Columns && !board.isFull(column - 1)) {
                board.drop(column - 1)
            } else {
                board
            }

        Redirect(routes.GameController.index).withSession("board" -> next.encode)
    }

    def reset: Action[AnyContent] = Action {
        Redirect(routes.GameController.index).withNewSession
    }

    private def currentBoard(implicit request: RequestHeader): ConnectFourBoard =
        request.session.get("board").map(ConnectFourBoard.decode).getOrElse(ConnectFourBoard())
}
