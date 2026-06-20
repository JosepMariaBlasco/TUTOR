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

-- c2u_dualpath.rex - Equivalence check for the C2U dual path. When the Unicode
-- binding is active, Bytes~C2U decodes strict UTF-8 via the native iterator
-- utf8DecodeCodepoint (method C2UViaUTF8Proc); without it, via the in-tree FSM
-- (::Routine UTF8). This test asserts the two paths agree for every well-formed
-- codepoint AND that ill-formed input still raises the same Syntax contract.
--
-- ORACLE: unusually, NOT the binding alone -- it is the in-tree FSM itself.
-- The point of the dual path is that the Unicode route reproduces the historical
-- TUTOR route verbatim, so the FSM (UTF8(...,"UTF-32","Syntax")) is the
-- reference and C2U (which now takes the Unicode route under the binding) is the
-- subject. With no binding both sides are the FSM and the test is a tautology
-- that still guards the formatting; with the binding it exercises Unicode vs FSM.
--
-- A divergence here would be a real finding (Unicode strict-UTF-8 validation
-- differing from TUTOR's on some codepoint or ill-formed sequence), exactly the
-- kind of observation the prototype is meant to surface.
--
-- COVERAGE: the BMP is always swept per-codepoint. The astral plane is swept in
-- full only when the test is called with argument "full" or "1"; otherwise a
-- curated sample of 4-byte astral codepoints is probed (default, fast -- this is
-- how the runner calls it). The multi-codepoint and ill-formed sections run in
-- both modes.

  Call "Unicode.cls"

  If \ .RexxUnicodeServices~isA(.Class) Then Do
    Say "c2u_dualpath.rex: no utf8proc binding present; skipping."
    Exit 0
  End

  -- Optional argument selects the astral coverage of the well-formed sweep.
  -- Default (no argument, as the runner calls it) is a curated astral SAMPLE
  -- exercising the 4-byte decode path -- fast, enough for the suite. Pass "full"
  -- or "1" for the exhaustive astral sweep (10000..10FFFF). The BMP is ALWAYS
  -- swept in full, and the multi-codepoint and ill-formed sections below run in
  -- both modes. Parse Arg (not Arg(1)) so an omitted argument under Call is "".
  Parse Arg rawArg
  mode      = Lower( Strip(rawArg) )
  fullSweep = ( mode == "1" | mode == "full" )

  Call Time "R"
  Say "Running equivalence checks for the C2U dual path (Unicode iterator vs FSM)..."
  Say "Reference: in-tree FSM. Subject: C2U via utf8DecodeCodepoint, Unicode" .RexxUnicodeServices~unicodeVersion
  Say

  -- 1. Well-formed sweep: both paths must agree on the UTF-32 buffer (and hence
  --    on every codepoint-based format). The BMP is always swept in full; the
  --    astral plane is swept in full only with the "full"/"1" argument,
  --    otherwise a curated sample exercising the 4-byte decode path is used.
  count = 0

  -- BMP: always exhaustive.
  Do i = 0 To X2D("FFFF")
    If i >= X2D("D800"), i <= X2D("DFFF") Then Iterate
    If \ CheckCP(i) Then Exit 1
    count += 1
  End

  If fullSweep Then Do
    Say "Astral: full sweep (10000..10FFFF)."
    Do i = X2D("10000") To X2D("10FFFF")
      If \ CheckCP(i) Then Exit 1
      count += 1
    End
  End
  Else Do
    Say "Astral: curated sample (pass 'full' or '1' for the exhaustive sweep)."
    -- A spread of astral codepoints (all 4-byte sequences): plane-1 letters and
    -- symbols, a plane-2 CJK, a plane-14 tag, and the U+10FFFF boundary.
    astral = "10000 10330 1040D 1D11E 1E900 1F600 20000 2F800 E0001 10FFFF"
    Do code Over astral~makeArray(" ")
      If \ CheckCP(X2D(code)) Then Exit 1
      count += 1
    End
  End

  If count == 0 Then Do
    Say "c2u_dualpath.rex: 0 codepoints checked -- aborting as a false green."
    Exit 1
  End
  Say "Well-formed sweep:" count "codepoints, paths agree."

  -- 2. Multi-codepoint strings: agreement on real text, not just lone points.
  samples = "41C3A9E282ACF09F9880" ,         -- A é € grinning-face
            "F09F87AAF09F87B8" ,             -- regional indicators (flag ES)
            "65CC81" ,                        -- e + combining acute
            "EFBBBF41"                        -- BOM + A
  Do hex Over samples~makeArray(" ")
    bytes   = X2C(hex)
    If Bytes(bytes)~C2U("UTF32") \== UTF8(bytes, "UTF-8", "UTF32", "Syntax") Then Do
      Say "C2U dual path diverges on multi-codepoint sample '"hex"'."
      Exit 1
    End
  End
  Say "Multi-codepoint samples: paths agree."

  -- 3. Ill-formed input: the Syntax contract must hold on the Unicode path.
  bad = "C080" ,           -- overlong NUL
        "EDA080" ,         -- UTF-8-encoded surrogate D800
        "F4908080" ,       -- > U+10FFFF
        "80" ,             -- lone continuation byte
        "C3"               -- truncated 2-byte sequence
  nbad = 0
  Do hex Over bad~makeArray(" ")
    If \ RaisesSyntax(X2C(hex)) Then Do
      Say "C2U on ill-formed '"hex"' did NOT raise Syntax (contract broken)."
      Exit 1
    End
    nbad += 1
  End
  Say "Ill-formed inputs:" nbad "sequences, all raised Syntax as expected."

  Say "Checked" count "codepoints +" nbad "ill-formed sequences, 0 failures."
  Say "Elapsed:" Time("E")"s."

Exit 0

--------------------------------------------------------------------------------

-- Encode one codepoint to UTF-8 and assert the two C2U paths (Unicode iterator
-- under the binding vs in-tree FSM) produce the same UTF-32 buffer. Returns 1
-- on agreement, 0 (after reporting) on divergence.
CheckCP: Procedure
  Use Strict Arg i
  bytes   = .RexxUnicodeServices~utf8EncodeCodepoint(i, .MutableBuffer~new, >w)~string
  subject = Bytes(bytes)~C2U("UTF32")
  refer   = UTF8(bytes, "UTF-8", "UTF32", "Syntax")
  If subject == refer Then Return 1
  Say "C2U dual path diverges at U+"D2X(i)":"
  Say "  subject (Unicode): "C2X(subject)
  Say "  reference(FSM): "C2X(refer)
  Return 0

-- Does C2U raise Syntax on this byte string? (handler out of the loop body:
-- ooRexx forbids labels inside DO/LOOP.)
RaisesSyntax: Procedure
  Use Strict Arg bytes
  Signal On Syntax Name Caught
  call_result = Bytes(bytes)~C2U
  Return 0
Caught:
  Return 1
