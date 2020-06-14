module Main where

import Game
import TicUI
import Rules
import TreeZipper
import MCTS

import qualified Data.Tree as T
import qualified System.Random as R
import           Control.Monad
import           Data.Char (digitToInt)
import qualified Data.Vector as V
import           Data.Maybe (isNothing, fromJust)
import           System.Exit (exitSuccess)

--clear = "\ESC[2J\ESC[H"
clear = ""

emptyGrid = Grid $ V.replicate 9 em
emptyMatch = Match $ Grid $ V.replicate 9 (emptyGrid, Left True)

validInputs = replicateM 4 ['0'..'2']

isValid :: String -> Bool
isValid s = s `elem` validInputs

testInput :: String -> Move -> Match Token -> IO (Move)
testInput input move match =
  if isValid input
    then do userMove <- parseMove input (nextPlayer . _agent $ move)
            let legalMoves = V.map fst $ legalMatchMoves move match
            if not(userMove `elem` legalMoves)
              then do putStrLn $ "Please enter a legal move"
                      newInput <- getLine
                      testInput newInput move match
              else return userMove
    else do putStrLn "Please enter a move in a valid format"
            newInput <- getLine
            testInput newInput move match

testInput' :: String -> Match Token -> IO (Move)
testInput' input match =
  if isValid input
    then parseMove input x
    else do putStrLn "Please enter a move in a valid format"
            newInput <- getLine
            testInput' newInput match

parseMove :: String -> Token -> IO (Move)
parseMove raw token = do
  let rawCoord = fmap digitToInt raw
  let outer = Coord ((rawCoord !! 0),(rawCoord !! 1))
  let inner = Coord ((rawCoord !! 2),(rawCoord !! 3))
  let userMove = Move outer inner token
  return userMove

gameLoop :: R.StdGen -> (Move, Match Token) -> IO ()
gameLoop gen pair = do
  putStrLn "Thinking..."
  state@(computerMove,currentBoard) <- getBestMove gen pair
  putStrLn $ clear ++ show currentBoard
  putStrLn $ "AI's last move was"
  putStrLn $ show $ computerMove
  if smartMatchStatus state /= Left True
    then do putStrLn "Game Over"
            exitSuccess
    else return ()
  putStrLn "Please write down your move and press ENTER"
  inputMove <- getLine
  userMove <- testInput inputMove computerMove currentBoard
  putStrLn $ "Your move was " ++ (show userMove)
  let newState = setMatchEl userMove currentBoard
  if smartMatchStatus (userMove, fromJust newState) /= Left True
    then do putStrLn $ show $ fromJust newState
            putStrLn $ "Last move was"
            putStrLn $ show $ computerMove
            putStrLn "Game Over"
            exitSuccess
    else return ()
  gameLoop (snd . R.next $ gen) (userMove, fromJust $ newState)
  return ()

aiVai :: R.StdGen -> (Move, Match Token) -> IO ()
aiVai gen pair = do
  putStrLn "Thinking..."
  state@(computerMove,currentBoard) <- getBestMove gen pair
  putStrLn $ clear ++ show currentBoard
  putStrLn $ "Last move was"
  putStrLn $ show $ computerMove
  if smartMatchStatus state /= Left True
    then do putStrLn "Game Over"
            exitSuccess
    else aiVai (snd . R.next $ gen) state

selectionY :: R.StdGen -> IO ()
selectionY gen = do
  putStrLn "Please write down your move and press ENTER"
  inputMove <- getLine
  userMove <- testInput' inputMove emptyMatch
  putStrLn $ "Your move was " ++ (show userMove)
  let newState = fromJust $ setMatchEl userMove emptyMatch
  gameLoop gen (userMove, newState)

main :: IO ()
main = do
  putStr clear
  g <- R.newStdGen
  putStrLn "Welcome to Tic-Hask-Toe!"
  putStrLn "Select 0 to play as O (default),"
  putStrLn "Select 1 to play as X,"
  putStrLn "Select 2 to run an AI vs. AI match."
  putStrLn "Press Ctrl-C to quit."
  selection <- getLine
  case selection of
    "0" -> gameLoop g (Move (Coord (1,1)) (Coord (1,1)) o, emptyMatch)
    "1" -> selectionY g
    "2" -> aiVai g (Move (Coord (1,1)) (Coord (1,1)) o, emptyMatch)
    --"test" -> aiVaiParamX g (Move (Coord (1,1)) (Coord (1,1)) o, emptyMatch)
    _   -> do putStrLn "Cannot parse input. AI will play as X."
              gameLoop g (Move (Coord (1,1)) (Coord (1,1)) o, emptyMatch)
  return ()

-- Parametric versions, for parameter tuning

constX = 1 --
constO = 1 --

-- 0.7294x
-- 1.73264x

aiVaiParamX :: R.StdGen -> (Move, Match Token) -> IO ()
aiVaiParamX gen pair = do
  putStrLn "Thinking..."
  state@(computerMove,currentBoard) <- getBestMoveParam gen constX pair
  putStrLn $ clear ++ show currentBoard
  putStrLn $ "Last move was"
  putStrLn $ show $ computerMove
  if smartMatchStatus state /= Left True
    then do putStrLn "Game Over"
            exitSuccess
    else aiVaiParamO (snd . R.next $ gen) state

aiVaiParamO :: R.StdGen -> (Move, Match Token) -> IO ()
aiVaiParamO gen pair = do
  putStrLn "Thinking..."
  state@(computerMove,currentBoard) <- getBestMoveParam gen constO pair
  putStrLn $ clear ++ show currentBoard
  putStrLn $ "Last move was"
  putStrLn $ show $ computerMove
  if smartMatchStatus state /= Left True
    then do putStrLn "Game Over"
            exitSuccess
    else aiVaiParamX (snd . R.next $ gen) state