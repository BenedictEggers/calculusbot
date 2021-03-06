module Calculusbot.Parse(
    parseExpr
) where

import Calculusbot.LanguageDef
import Calculusbot.Simplify

import Control.Monad
import Text.Parsec
import Text.Parsec.Expr
import Text.Parsec.Language
import qualified Text.Parsec.Token as Token


parseExpr :: String -> CBExpr
parseExpr str = case parse expParser "" str of
    Left e -> error $ show e
    Right r -> simplify r

languageDef = 
    emptyDef { Token.identStart         = letter
             , Token.identLetter        = letter
             , Token.reservedOpNames    = ["+", "-", "*", "-", "^", "**"]
             , Token.reservedNames      = ["sin", "cos", "tan", "sinh", "cosh", "tanh", "log", "logBase", "e", "pi"]
             }

lexer = Token.makeTokenParser languageDef

identifier = Token.identifier   lexer
reserved = Token.reserved       lexer
reservedOp = Token.reservedOp   lexer
parens = Token.parens           lexer
integer = Token.integer         lexer

expParser = buildExpressionParser ops terms

ops = [ [Prefix (reservedOp "-"      >> return (UnExpr Neg   ))           ]
      , [Infix (reservedOp "^"      >> return (BinExpr Power )) AssocRight]
      , [Infix (reservedOp "**"     >> return (BinExpr Power )) AssocRight]
      , [Infix (reservedOp "*"      >> return (BinExpr Times )) AssocLeft]
      , [Infix (reservedOp "/"      >> return (BinExpr Divide)) AssocLeft]
      , [Infix (reservedOp "+"      >> return (BinExpr Plus  )) AssocLeft]
      , [Infix (reservedOp "-"      >> return (BinExpr Minus )) AssocLeft]
      ]

terms = parens expParser
      <|> do { space
             ; e <- expParser
             ; return e
             }
      <|> do { reserved "e"
             ; return (Const E)
             }
      <|> do { reserved "pi"
             ; return (Const Pi)
             }
      <|> do { reserved "log"
             ; e <- parens expParser
             ; return (UnExpr Log e)
             }
      <|> do { reserved "logBase"
             ; char '('
             ; e1 <- expParser
             ; char ','
             ; e2 <- expParser
             ; spaces
             ; char ')'
             ; return (BinExpr Divide (UnExpr Log e2) (UnExpr Log e1))
             }
      <|> do { reserved "sinh"
             ; e <- parens expParser
             ; return (UnExpr Sinh e)
             }
      <|> do { reserved "cosh"
             ; e <- parens expParser
             ; return (UnExpr Cosh e)
             }
      <|> do { reserved "tanh"
             ; e <- parens expParser
             ; return (UnExpr Tanh e)
             }
      <|> do { reserved "sin"
             ; e <- parens expParser
             ; return (UnExpr Sin e)
             }
      <|> do { reserved "cos"
             ; e <- parens expParser
             ; return (UnExpr Cos e)
             }
      <|> do { reserved "tan"
             ; e <- parens expParser
             ; return (UnExpr Tan e)
             }
      <|> liftM Var identifier
      <|> do { i <- integer
             ; return (Const (IntLit i))
             }

