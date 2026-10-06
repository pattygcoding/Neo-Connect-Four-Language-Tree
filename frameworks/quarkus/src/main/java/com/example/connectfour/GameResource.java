package com.example.connectfour;

import io.quarkus.qute.Template;
import io.quarkus.qute.TemplateInstance;
import jakarta.enterprise.context.SessionScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.Serializable;
import java.net.URI;

@Path("/")
public class GameResource {

    @SessionScoped
    public static class Game implements Serializable {
        private ConnectFourBoard board = new ConnectFourBoard();

        public ConnectFourBoard getBoard() {
            return board;
        }

        public void play(int column) {
            if (!board.isOver()
                    && column >= 1
                    && column <= ConnectFourBoard.COLUMNS
                    && !board.isFull(column - 1)) {
                board.drop(column - 1);
            }
        }

        public void reset() {
            board = new ConnectFourBoard();
        }
    }

    @Inject
    Game game;

    @Inject
    Template board;

    @GET
    @Produces(MediaType.TEXT_HTML)
    public TemplateInstance page() {
        return board.data("board", game.getBoard());
    }

    @POST
    @Path("/move")
    public Response move(@FormParam("column") int column) {
        game.play(column);
        return Response.seeOther(URI.create("/")).build();
    }

    @POST
    @Path("/reset")
    public Response reset() {
        game.reset();
        return Response.seeOther(URI.create("/")).build();
    }
}
