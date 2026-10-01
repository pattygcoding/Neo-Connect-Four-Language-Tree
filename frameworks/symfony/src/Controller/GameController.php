<?php

namespace App\Controller;

use App\Game\ConnectFourBoard;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class GameController extends AbstractController
{
    private const SESSION_KEY = 'board';

    #[Route('/', name: 'game_board', methods: ['GET'])]
    public function board(Request $request): Response
    {
        $board = $this->currentBoard($request);

        return $this->render('game/board.html.twig', [
            'board' => $board,
            'status' => $this->status($board),
            'columns' => range(1, ConnectFourBoard::COLUMNS),
        ]);
    }

    #[Route('/move', name: 'game_move', methods: ['POST'])]
    public function move(Request $request): Response
    {
        $board = $this->currentBoard($request);
        $column = (int) $request->request->get('column');

        if ($column >= 1 && $column <= ConnectFourBoard::COLUMNS
            && ! $board->isOver() && ! $board->isFull($column - 1)) {
            $board->drop($column - 1);
        }

        $request->getSession()->set(self::SESSION_KEY, $board->toArray());

        return $this->redirectToRoute('game_board');
    }

    #[Route('/reset', name: 'game_reset', methods: ['POST'])]
    public function reset(Request $request): Response
    {
        $request->getSession()->remove(self::SESSION_KEY);

        return $this->redirectToRoute('game_board');
    }

    private function currentBoard(Request $request): ConnectFourBoard
    {
        return ConnectFourBoard::fromArray($request->getSession()->get(self::SESSION_KEY));
    }

    private function status(ConnectFourBoard $board): string
    {
        if ($board->winner() !== null) {
            return sprintf('Player %s wins!', $board->winner());
        }

        if ($board->isOver()) {
            return "It's a tie!";
        }

        return sprintf('Player %s, choose a column.', $board->currentPlayer());
    }
}
