module Main (main) where

import Control.Exception (IOException, try)
import Data.Char (isSpace)
import Data.List (intercalate)
import System.IO (BufferMode (NoBuffering), hSetBuffering, stdout)
import System.IO.Error (isEOFError)

rows :: Int
rows = 6

cols :: Int
cols = 7

empty :: Char
empty = '.'

players :: String
players = "XO"

header :: String
header =
    "=== Connect Four ===\n"
        ++ "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

type Board = [[Char]]

newBoard :: Board
newBoard = replicate rows (replicate cols empty)

lowestEmptyRow :: Board -> Int -> Int
lowestEmptyRow board column = scan 0
    where
        scan row
            | row >= rows = -1
            | board !! row !! column == empty = row
            | otherwise = scan (row + 1)

replaceAt :: Int -> a -> [a] -> [a]
replaceAt index value items = take index items ++ [value] ++ drop (index + 1) items

setCell :: Board -> Int -> Int -> Char -> Board
setCell board targetRow targetColumn player = replaceAt targetRow updatedRow board
    where
        updatedRow = replaceAt targetColumn player (board !! targetRow)

hasFour :: Board -> Char -> Bool
hasFour board player = any wins starts
    where
        starts = [(row, column) | row <- [0 .. rows - 1], column <- [0 .. cols - 1]]
        at row column =
            row >= 0
                && row < rows
                && column >= 0
                && column < cols
                && board !! row !! column == player
        run row column rowStep columnStep =
            all (\step -> at (row + step * rowStep) (column + step * columnStep)) [0 .. 3]
        wins (row, column) =
            run row column 0 1
                || run row column 1 0
                || run row column 1 1
                || run row column 1 (-1)

printBorder :: IO ()
printBorder = putStrLn ('+' : replicate (cols * 2 - 1) '-' ++ "+")

rowText :: Board -> Int -> String
rowText board row = "|" ++ intercalate " " (map (: []) (board !! row)) ++ "|"

printBoard :: Board -> IO ()
printBoard board = do
    putStr (" " ++ unwords (map show [1 .. cols]) ++ "\n")
    printBorder
    mapM_ (putStrLn . rowText board) (reverse [0 .. rows - 1])
    printBorder

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

isWholeNumber :: String -> Bool
isWholeNumber token = not (null body) && all isDigitChar body
    where
        body = case token of
            ('+' : rest) -> rest
            ('-' : rest) -> rest
            _ -> token
        isDigitChar c = c >= '0' && c <= '9'

digitValue :: Char -> Int
digitValue c = fromEnum c - fromEnum '0'

parseValue :: String -> Int
parseValue token = applySign (accumulate 0 body)
    where
        (negative, body) = case token of
            ('-' : rest) -> (True, rest)
            ('+' : rest) -> (False, rest)
            _ -> (False, token)
        applySign value
            | negative = negate value
            | otherwise = value
        accumulate value [] = value
        accumulate value (c : rest)
            | value > (maxBound - digitValue c) `div` 10 = maxBound
            | otherwise = accumulate (value * 10 + digitValue c) rest

readLineOrEof :: IO (Maybe String)
readLineOrEof = do
    result <- try getLine :: IO (Either IOException String)
    case result of
        Right line -> return (Just line)
        Left err
            | isEOFError err -> return Nothing
            | otherwise -> ioError err

askColumn :: Board -> Char -> IO Int
askColumn board player = do
    putStr ("Player " ++ [player] ++ ", choose a column (1-7): ")
    line <- readLineOrEof
    case line of
        Nothing -> do
            putStrLn "\nInput closed. Goodbye."
            return (-1)
        Just text -> handleInput board player (trim text)

rejectInput :: Board -> Char -> String -> IO Int
rejectInput board player message = do
    putStrLn ("\n" ++ message)
    askColumn board player

handleInput :: Board -> Char -> String -> IO Int
handleInput board player token = do
    if null token
        then rejectInput board player "Invalid input: no column entered."
        else
            if not (isWholeNumber token)
                then
                    rejectInput
                        board
                        player
                        ("Invalid input: \"" ++ token ++ "\" is not a whole number.")
                else
                    let value = parseValue token
                    in if value < 1 || value > cols
                        then
                            rejectInput
                                board
                                player
                                ("Invalid input: \"" ++ token ++ "\" is out of range (1-7).")
                        else
                            if lowestEmptyRow board (value - 1) < 0
                                then rejectInput board player ("Column " ++ show value ++ " is full.")
                                else return (value - 1)

play :: Board -> Int -> Int -> IO ()
play board moves playerIndex = do
    let player = players !! playerIndex
    column <- askColumn board player
    if column < 0
        then return ()
        else do
            let row = lowestEmptyRow board column
            let board' = setCell board row column player
            let moves' = moves + 1
            putStr "\n"
            printBoard board'
            if hasFour board' player
                then putStrLn ("Player " ++ [player] ++ " wins!")
                else
                    if moves' == rows * cols
                        then putStrLn "It's a tie!"
                        else play board' moves' (1 - playerIndex)

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    putStr (header ++ "\n")
    printBoard newBoard
    play newBoard 0 0
