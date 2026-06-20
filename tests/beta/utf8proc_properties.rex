/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

--------------------------------------------------------------------------------
-- This program is part of the automated test suite. See tests/test.all.rex   --
--------------------------------------------------------------------------------

-- utf8proc_properties.rex - Consistency check for the per-codepoint properties
-- served by properties/UTF8Proc.cls over the utf8proc binding:
--
--   utf8proc_Char_Width              <- codepointCharWidth    (integer)
--
-- ORACLE: the utf8proc binding itself (.RexxUnicodeServices), NOT a UCD file.
-- The facade just reshapes what the binding returns; the test re-derives the
-- expected shape from the same binding call and checks the facade matches.
-- The whole BMP is swept, plus a sample of astral codepoints.
--
-- Requires a utf8proc binding (any Unicode version: these checks compare the
-- facade against the live binding, so they are version-agnostic).

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "utf8proc_properties.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  self = .Unicode.UTF8Proc

  Call Time "R"
  Say "Running consistency check for utf8proc_Char_Width..."
  Say "Oracle: utf8proc binding, Unicode" .RexxUnicodeServices~unicodeVersion
  Say

  count = 0

  Do i = 0 To X2D("FFFF")
    If i >= X2D("D800"), i <= X2D("DFFF") Then Iterate
    If CheckCodepoint(i, self) Then count += 1
    Else Exit 1
  End

  astral = "10000 1D11E 1F600 1EE00 2F800 E0001 10FFFF 1F100 1FBF0 10330"
  Do code Over astral~makeArray(" ")
    If CheckCodepoint(X2D(code), self) Then count += 1
    Else Exit 1
  End

  Say "Checked" count "codepoints, 0 failures."
  Say "Elapsed:" Time("E")"s."

Exit 0

--------------------------------------------------------------------------------

CheckCodepoint: Procedure
  Use Strict Arg n, self

  code = D2X(n)
  If Length(code) < 4 Then code = Right(code, 4, 0)

  -- utf8proc_Char_Width: integer, passed through unchanged.
  oracle = .RexxUnicodeServices~codepointCharWidth(n)
  got = self~utf8proc_Char_Width(code)
  If got \== oracle Then Return Fail("utf8proc_Char_Width", code, got, oracle)

Return 1

Fail: Procedure
  Use Strict Arg property, code, got, expected
  Say property "for U+"code": got '"got"', expected '"expected"'."
Return 0
