Set-StrictMode -Version Latest

$Rows = 6
$Cols = 7
$Empty = '.'
$Players = @('X', 'O')
$MaxInt = [long]::MaxValue
$MaxIntDiv10 = [long]($MaxInt / 10)
$Border = '+' + ('-' * ($Cols * 2 - 1)) + '+'
$Header = "=== Connect Four ===`n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.`n"

function New-Board {
    $cells = @($Empty) * ($Rows * $Cols)
    return $cells
}

function Get-LowestEmptyRow {
    param([string[]]$Board, [int]$Column)
    for ($row = 0; $row -lt $Rows; $row++) {
        if ($Board[$row * $Cols + $Column] -ceq $Empty) {
            return $row
        }
    }
    return -1
}

function Test-Run {
    param(
        [string[]]$Board,
        [string]$Player,
        [int]$Row,
        [int]$Column,
        [int]$RowStep,
        [int]$ColumnStep
    )
    for ($step = 0; $step -lt 4; $step++) {
        $targetRow = $Row + $step * $RowStep
        $targetColumn = $Column + $step * $ColumnStep
        if ($targetRow -lt 0 -or $targetRow -ge $Rows -or $targetColumn -lt 0 -or $targetColumn -ge $Cols) {
            return $false
        }
        if ($Board[$targetRow * $Cols + $targetColumn] -cne $Player) {
            return $false
        }
    }
    return $true
}

function Test-HasFour {
    param([string[]]$Board, [string]$Player)
    for ($row = 0; $row -lt $Rows; $row++) {
        for ($column = 0; $column -lt $Cols; $column++) {
            $across = Test-Run -Board $Board -Player $Player -Row $row -Column $column -RowStep 0 -ColumnStep 1
            $down = Test-Run -Board $Board -Player $Player -Row $row -Column $column -RowStep 1 -ColumnStep 0
            $upRight = Test-Run -Board $Board -Player $Player -Row $row -Column $column -RowStep 1 -ColumnStep 1
            $downRight = Test-Run -Board $Board -Player $Player -Row $row -Column $column -RowStep 1 -ColumnStep -1
            if ($across -or $down -or $upRight -or $downRight) {
                return $true
            }
        }
    }
    return $false
}

function Format-Board {
    param([string[]]$Board)
    $lines = @((' ' + ((1..$Cols) -join ' ')), $Border)
    for ($row = $Rows - 1; $row -ge 0; $row--) {
        $cells = @()
        for ($column = 0; $column -lt $Cols; $column++) {
            $cells += $Board[$row * $Cols + $column]
        }
        $lines += '|' + ($cells -join ' ') + '|'
    }
    $lines += $Border
    return ($lines -join "`n") + "`n"
}

function Test-IsWholeNumber {
    param([string]$Token)
    $body = $Token
    if ($body.StartsWith('+') -or $body.StartsWith('-')) {
        $body = $body.Substring(1)
    }
    if ($body.Length -eq 0) {
        return $false
    }
    foreach ($character in $body.ToCharArray()) {
        $code = [int][char]$character
        if ($code -lt 48 -or $code -gt 57) {
            return $false
        }
    }
    return $true
}

function ConvertTo-Value {
    param([string]$Token)
    $negative = $false
    $body = $Token
    if ($body.StartsWith('+') -or $body.StartsWith('-')) {
        $negative = $body.StartsWith('-')
        $body = $body.Substring(1)
    }
    $value = [long]0
    foreach ($character in $body.ToCharArray()) {
        if ($value -gt $MaxIntDiv10) {
            $value = $MaxInt
            break
        }
        $value = $value * 10 + ([int][char]$character - 48)
    }
    if ($negative) {
        return -$value
    }
    return $value
}

function Read-Column {
    param([string[]]$Board, [string]$Player)
    while ($true) {
        [Console]::Out.Write("Player $Player, choose a column (1-7): ")
        $line = [Console]::In.ReadLine()
        if ($null -eq $line) {
            [Console]::Out.Write("`nInput closed. Goodbye.`n")
            return -1
        }
        $token = $line.Trim()
        if ($token.Length -eq 0) {
            [Console]::Out.Write("`n" + 'Invalid input: no column entered.' + "`n")
            continue
        }
        if (-not (Test-IsWholeNumber -Token $token)) {
            $message = 'Invalid input: "' + $token + '" is not a whole number.'
            [Console]::Out.Write("`n" + $message + "`n")
            continue
        }
        $value = ConvertTo-Value -Token $token
        if ($value -lt 1 -or $value -gt $Cols) {
            $message = 'Invalid input: "' + $token + '" is out of range (1-7).'
            [Console]::Out.Write("`n" + $message + "`n")
            continue
        }
        if ((Get-LowestEmptyRow -Board $Board -Column ($value - 1)) -lt 0) {
            [Console]::Out.Write("`n" + "Column $value is full." + "`n")
            continue
        }
        return $value - 1
    }
}

$board = New-Board
[Console]::Out.Write($Header + "`n")
[Console]::Out.Write((Format-Board -Board $board))
$playerIndex = 0
$moves = 0
while ($true) {
    $player = $Players[$playerIndex]
    $column = Read-Column -Board $board -Player $player
    if ($column -lt 0) {
        break
    }
    $row = Get-LowestEmptyRow -Board $board -Column $column
    $board[$row * $Cols + $column] = $player
    $moves++
    [Console]::Out.Write("`n")
    [Console]::Out.Write((Format-Board -Board $board))
    if (Test-HasFour -Board $board -Player $player) {
        [Console]::Out.WriteLine("Player $player wins!")
        break
    }
    if ($moves -eq $Rows * $Cols) {
        [Console]::Out.WriteLine("It's a tie!")
        break
    }
    $playerIndex = 1 - $playerIndex
}
