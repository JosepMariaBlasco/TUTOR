/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

--------------------------------------------------------------------------------
-- Runner for the beta test suite (utf8proc layer). Sibling of test.all.rex.  --
--                                                                            --
-- These tests exercise properties/UTF8Proc.cls, which only registers itself  --
-- when the utf8proc binding is present. The whole suite is therefore gated   --
-- on .RexxUnicodeServices being a class: with the binding we run it, without --
-- it we skip cleanly (Exit 0). Each test follows the test.all.rex contract:  --
-- it returns 0 on success, non-zero on failure, and we stop on first error.  --
--                                                                            --
-- Run from the tests/ directory:  rexx beta/test.beta.rex                    --
-- Exhaustive astral sweep:         rexx beta/test.beta.rex full              --
--------------------------------------------------------------------------------

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "No utf8proc binding (.RexxUnicodeServices is not a class); skipping beta suite."
    Exit 0
  End

  -- Optional argument: "full" or "1" requests the exhaustive astral sweep on the
  -- tests that support it (currently tocasefold, c2u_dualpath). Default sweeps the
  -- BMP in full and samples the astral plane -- fast. The flag is forwarded
  -- verbatim to every subtest; those that don't yet honour it ignore it
  -- harmlessly, so a test gaining the flag later needs no runner change. Parse
  -- Arg (not Arg(1)) so an omitted argument is "".
  Parse Arg rawArg
  mode = Lower( Strip(rawArg) )
  If mode == "1" | mode == "full" Then astralArg = "full"
  Else                                 astralArg = ""

  Call Time("R")

  Say Time("E") "Running beta tests (utf8proc layer)..."
  If astralArg == "full" Then Say Time("E") "Astral coverage: FULL (exhaustive sweep where supported)."
  Else                        Say Time("E") "Astral coverage: sample (pass 'full' for the exhaustive sweep)."
  Say Time("E") "-------------------------------------"

  Say Time("E") "Calling utf8proc_properties.rex..."
  Call "utf8proc_properties.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling tocasefold.rex..."
  Call "tocasefold.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling graphemes_utf8proc.rex..."
  Call "graphemes_utf8proc.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling c2u_dualpath.rex..."
  Call "c2u_dualpath.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling UnicodeData.rex..."
  Call "UnicodeData.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling name_icu.rex..."
  Call "name_icu.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling canonical_decomposition.rex..."
  Call "canonical_decomposition.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E") "Calling derived_properties.rex..."
  Call "derived_properties.rex" astralArg
  If result \== 0 Then Exit result

  Say Time("E")
  Say Time("E") "All beta tests PASSED!"
  Say Time("E") "----------------------"

Exit 0
