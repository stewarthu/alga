-----------------------------------------------------------------------------
-- |
-- Module     : Algebra.Graph.Test.Graph
-- Copyright  : (c) Andrey Mokhov 2016-2018
-- License    : MIT (see the file LICENSE)
-- Maintainer : andrey.mokhov@gmail.com
-- Stability  : experimental
--
-- Testsuite for "Algebra.Graph" and polymorphic functions defined in
-- "Algebra.Graph.HigherKinded.Class".
-----------------------------------------------------------------------------
module Algebra.Graph.Test.Graph (
    -- * Testsuite
    testGraph
  ) where

import Prelude ()
import Prelude.Compat

import Data.Either

import Algebra.Graph
import Algebra.Graph.Test
import Algebra.Graph.Test.Generic
import Algebra.Graph.ToGraph (reachable)

import qualified Data.Graph as KL

t :: Testsuite
t = testsuite "Graph." empty

type G = Graph Int

testGraph :: IO ()
testGraph = do
    putStrLn "\n============ Graph ============"
    test "Axioms of graphs"   (axioms   :: GraphTestsuite G)
    test "Theorems of graphs" (theorems :: GraphTestsuite G)

    testBasicPrimitives t
    testIsSubgraphOf    t
    testToGraph         t
    testSize            t
    testGraphFamilies   t
    testTransformations t

    ----------------------------------------------------------------
    -- Generic relational composition tests, plus an additional one
    testCompose         t
    test "size (compose x y)                        <= edgeCount x + edgeCount y + 1" $ \(x :: G) y ->
          size (compose x y)                        <= edgeCount x + edgeCount y + 1
    ----------------------------------------------------------------

    putStrLn "\n============ Graph.(===) ============"
    test "    x === x         == True" $ \(x :: G) ->
             (x === x)        == True

    test "    x === x + empty == False" $ \(x :: G) ->
             (x === x + empty)== False

    test "x + y === x + y     == True" $ \(x :: G) y ->
         (x + y === x + y)    == True

    test "1 + 2 === 2 + 1     == False" $
         (1 + 2 === 2 + (1 :: G)) == False

    test "x + y === x * y     == False" $ \(x :: G) y ->
         (x + y === x * y)    == False

    putStrLn "\n============ Graph.mesh ============"
    test "mesh xs     []    == empty" $ \xs ->
          mesh xs     []    == (empty :: Graph (Int, Int))

    test "mesh []     ys    == empty" $ \ys ->
          mesh []     ys    == (empty :: Graph (Int, Int))

    test "mesh [x]    [y]   == vertex (x, y)" $ \(x :: Int) (y :: Int) ->
          mesh [x]    [y]   == vertex (x, y)

    test "mesh xs     ys    == box (path xs) (path ys)" $ \(xs :: [Int]) (ys :: [Int]) ->
          mesh xs     ys    == box (path xs) (path ys)

    test "mesh [1..3] \"ab\"  == <correct result>" $
          mesh [1..3]  "ab"   == edges [ ((1,'a'),(1,'b')), ((1,'a'),(2,'a')), ((1,'b'),(2,'b')), ((2,'a'),(2,'b'))
                                    , ((2,'a'),(3,'a')), ((2,'b'),(3,'b')), ((3,'a'),(3 :: Int,'b')) ]
    test "size (mesh xs ys) == max 1 (3 * length xs * length ys - length xs - length ys -1)" $ \(xs :: [Int]) (ys :: [Int]) ->
          size (mesh xs ys) == max 1 (3 * length xs * length ys - length xs - length ys -1)

    putStrLn "\n============ Graph.torus ============"
    test "torus xs     []    == empty" $ \xs ->
          torus xs     []    == (empty :: Graph (Int, Int))

    test "torus []     ys    == empty" $ \ys ->
          torus []     ys    == (empty :: Graph (Int, Int))

    test "torus [x]    [y]   == edge (x,y) (x,y)" $ \(x :: Int) (y :: Int) ->
          torus [x]    [y]   == edge (x,y) (x,y)

    test "torus xs     ys    == box (circuit xs) (circuit ys)" $ \(xs :: [Int]) (ys :: [Int]) ->
          torus xs     ys    == box (circuit xs) (circuit ys)

    test "torus [1,2]  \"ab\"  == <correct result>" $
          torus [1,2]   "ab"   == edges [ ((1,'a'),(1,'b')), ((1,'a'),(2,'a')), ((1,'b'),(1,'a')), ((1,'b'),(2,'b'))
                                      , ((2,'a'),(1,'a')), ((2,'a'),(2,'b')), ((2,'b'),(1,'b')), ((2,'b'),(2 :: Int,'a')) ]

    test "size (torus xs ys) == max 1 (3 * length xs * length ys)" $ \(xs :: [Int]) (ys :: [Int]) ->
          size (torus xs ys) == max 1 (3 * length xs * length ys)


    putStrLn "\n============ Graph.deBruijn ============"
    test "          deBruijn 0 xs               == edge [] []" $ \(xs :: [Int]) ->
                    deBruijn 0 xs               ==(edge [] [] :: Graph [Int])

    test "n > 0 ==> deBruijn n []               == empty" $ \n ->
          n > 0 ==> deBruijn n []               == (empty :: Graph [Int])

    test "          deBruijn 1 [0,1]            == edges [ ([0],[0]), ([0],[1]), ([1],[0]), ([1],[1]) ]" $
                    deBruijn 1 [0,1::Int]       == edges [ ([0],[0]), ([0],[1]), ([1],[0]), ([1],[1]) ]

    test "          deBruijn 2 \"0\"              == edge \"00\" \"00\"" $
                    deBruijn 2 "0"              == edge "00" "00"

    test "          deBruijn 2 \"01\"             == <correct result>" $
                    deBruijn 2 "01"             == edges [ ("00","00"), ("00","01"), ("01","10"), ("01","11")
                                                         , ("10","00"), ("10","01"), ("11","10"), ("11","11") ]

    test "          transpose   (deBruijn n xs) == fmap reverse $ deBruijn n xs" $ mapSize (min 5) $ \(NonNegative n) (xs :: [Int]) ->
                    transpose   (deBruijn n xs) == fmap reverse (deBruijn n xs)

    test "          vertexCount (deBruijn n xs) == (length $ nub xs)^n" $ mapSize (min 5) $ \(NonNegative n) (xs :: [Int]) ->
                    vertexCount (deBruijn n xs) == (length $ nubOrd xs)^n

    test "n > 0 ==> edgeCount   (deBruijn n xs) == (length $ nub xs)^(n + 1)" $ mapSize (min 5) $ \(NonNegative n) (xs :: [Int]) ->
          n > 0 ==> edgeCount   (deBruijn n xs) == (length $ nubOrd xs)^(n + 1)

    testSplitVertex t
    testBind        t
    testSimplify    t

    putStrLn "\n============ Graph.box ============"
    let unit = fmap $ \(a, ()) -> a
        comm = fmap $ \(a,  b) -> (b, a)
    test "box x y               ~~ box y x" $ mapSize (min 10) $ \(x :: G) (y :: G) ->
          comm (box x y)        == box y x

    test "box x (overlay y z)   == overlay (box x y) (box x z)" $ mapSize (min 10) $ \(x :: G) (y :: G) z ->
          box x (overlay y z)   == overlay (box x y) (box x z)

    test "box x (vertex ())     ~~ x" $ mapSize (min 10) $ \(x :: G) ->
     unit(box x (vertex ()))    == x

    test "box x empty           ~~ empty" $ mapSize (min 10) $ \(x :: G) ->
     unit(box x empty)          == empty

    let assoc = fmap $ \(a, (b, c)) -> ((a, b), c)
    test "box x (box y z)       ~~ box (box x y) z" $ mapSize (min 10) $ \(x :: G) (y :: G) (z :: G) ->
      assoc (box x (box y z))   == box (box x y) z

    test "transpose   (box x y) == box (transpose x) (transpose y)" $ mapSize (min 10) $ \(x :: G) (y :: G) ->
          transpose   (box x y) == box (transpose x) (transpose y)

    test "vertexCount (box x y) == vertexCount x * vertexCount y" $ mapSize (min 10) $ \(x :: G) (y :: G) ->
          vertexCount (box x y) == vertexCount x * vertexCount y

    test "edgeCount   (box x y) <= vertexCount x * edgeCount y + edgeCount x * vertexCount y" $ mapSize (min 10) $ \(x :: G) (y :: G) ->
          edgeCount   (box x y) <= vertexCount x * edgeCount y + edgeCount x * vertexCount y

    putStrLn "\n============ Graph.sparsify ============"
    test "sort . reachable x       == sort . rights . reachable (Right x) . sparsify" $ \x (y :: G) ->
         (sort . reachable x) y    == (sort . rights . reachable (Right x) . sparsify) y

    test "vertexCount (sparsify x) <= vertexCount x + size x + 1" $ \(x :: G) ->
          vertexCount (sparsify x) <= vertexCount x + size x + 1

    test "edgeCount   (sparsify x) <= 3 * size x" $ \(x :: G) ->
          edgeCount   (sparsify x) <= 3 * size x

    test "size        (sparsify x) <= 3 * size x" $ \(x :: G) ->
          size        (sparsify x) <= 3 * size x

    putStrLn "\n============ Graph.sparsifyKL ============"
    test "sort . reachable k                 == sort . filter (<= n) . flip reachable k . sparsifyKL n" $ \(Positive n) -> do
        let pairs = (,) <$> choose (1, n) <*> choose (1, n)
        k  <- choose (1, n)
        es <- listOf pairs
        let x = vertices [1..n] `overlay` edges es
        return $ (sort . reachable k) x == (sort . filter (<= n) . flip KL.reachable k . sparsifyKL n) x

    test "length (vertices $ sparsifyKL n x) <= vertexCount x + size x + 1" $ \(Positive n) -> do
        let pairs = (,) <$> choose (1, n) <*> choose (1, n)
        es <- listOf pairs
        let x = vertices [1..n] `overlay` edges es
        return $ length (KL.vertices $ sparsifyKL n x) <= vertexCount x + size x + 1

    test "length (edges    $ sparsifyKL n x) <= 3 * size x" $ \(Positive n) -> do
        let pairs = (,) <$> choose (1, n) <*> choose (1, n)
        es <- listOf pairs
        let x = vertices [1..n] `overlay` edges es
        return $ length (KL.edges $ sparsifyKL n x) <= 3 * size x

    putStrLn "\n============ Labelled.Graph.context ============"
    test "context (const False) x                   == Nothing" $ \x ->
          context (const False) (x :: G)            == Nothing

    test "context (== 1)        (edge 1 2)          == Just (Context [   ] [2  ])" $
          context (== 1)        (edge 1 2 :: G)     == Just (Context [   ] [2  ])

    test "context (== 2)        (edge 1 2)          == Just (Context [1  ] [   ])" $
          context (== 2)        (edge 1 2 :: G)     == Just (Context [1  ] [   ])

    test "context (const True ) (edge 1 2)          == Just (Context [1  ] [2  ])" $
          context (const True ) (edge 1 2 :: G)     == Just (Context [1  ] [2  ])

    test "context (== 4)        (3 * 1 * 4 * 1 * 5) == Just (Context [3,1] [1,5])" $
          context (== 4)        (3 * 1 * 4 * 1 * 5 :: G) == Just (Context [3,1] [1,5])
