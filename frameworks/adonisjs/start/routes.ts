import router from "@adonisjs/core/services/router";

const GamesController = () => import("#controllers/games_controller");

router.get("/", [GamesController, "show"]);
router.post("/move", [GamesController, "move"]);
router.post("/reset", [GamesController, "reset"]);
