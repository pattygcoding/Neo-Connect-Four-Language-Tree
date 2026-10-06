DEFINE TABLE game SCHEMAFULL;
DEFINE FIELD player ON game TYPE string;
DEFINE FIELD status ON game TYPE string DEFAULT 'in_progress'
    ASSERT $value INSIDE ['in_progress', 'finished'];
DEFINE FIELD created_at ON game TYPE datetime DEFAULT time::now();

DEFINE TABLE move SCHEMAFULL;
DEFINE FIELD game ON move TYPE record<game>;
DEFINE FIELD turn_no ON move TYPE int ASSERT $value > 0;
DEFINE FIELD player ON move TYPE string ASSERT $value INSIDE ['X', 'O'];
DEFINE FIELD column_number ON move TYPE int ASSERT $value >= 1 AND $value <= 7;
DEFINE FIELD played_at ON move TYPE datetime DEFAULT time::now();

DEFINE INDEX move_by_game ON move FIELDS game, turn_no UNIQUE;
