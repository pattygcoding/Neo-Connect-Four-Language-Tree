CREATE KEYSPACE IF NOT EXISTS connect_four
    WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': 1}
    AND durable_writes = true;

CREATE TABLE IF NOT EXISTS connect_four.games (
    game_id    uuid PRIMARY KEY,
    player     text,
    next_turn  int,
    status     text,
    created_at timestamp
) WITH default_time_to_live = 86400;

CREATE TABLE IF NOT EXISTS connect_four.moves_by_game (
    game_id       uuid,
    move_id       timeuuid,
    turn          int,
    player        text,
    column_number tinyint,
    PRIMARY KEY ((game_id), move_id)
) WITH CLUSTERING ORDER BY (move_id ASC)
  AND default_time_to_live = 86400;

CREATE TABLE IF NOT EXISTS connect_four.board_by_game (
    game_id       uuid,
    column_number tinyint,
    discs         list<text>,
    PRIMARY KEY ((game_id), column_number)
) WITH default_time_to_live = 86400;

CREATE MATERIALIZED VIEW IF NOT EXISTS connect_four.games_by_status AS
    SELECT status, created_at, game_id, next_turn, player
    FROM connect_four.games
    WHERE status IS NOT NULL AND game_id IS NOT NULL
    PRIMARY KEY (status, created_at, game_id);

CREATE INDEX IF NOT EXISTS games_by_player ON connect_four.games (player);
