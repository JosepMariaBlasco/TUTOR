/******************************************************************************
 * This file is part of The Unicode Tools Of Rexx (TUTOR)                     *
 * See https://rexx.epbcn.com/TUTOR/                                          *
 *     and https://github.com/JosepMariaBlasco/TUTOR                          *
 * Copyright © 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>    *
 * License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  *
 ******************************************************************************/

/*****************************************************************************/
/*                                                                           */
/*  The UNICODE.ICU plug-in                                                  */
/*  =========================                                                */
/*                                                                           */
/*  OPTIONAL back-end, sibling of the UTF8Proc plug-in. This is the ICU      */
/*  layer: it covers properties that utf8proc does NOT expose. Per           */
/*  executor5 release notes, the bundled ICU4ooRexx is a MINIMAL wrapping    */
/*  of ICU4C: codepoint<->Name only (plus versions and a loose-name helper). */
/*  Verified against the .so exported symbols: the only UCD property ICU     */
/*  adds over utf8proc is Name (Na).                                         */
/*                                                                           */
/*  STATUS: ACTIVE. When the ICU layer is available, this plug-in owns the   */
/*  Name/Na property (registered via RegisterPreferredProperties in          */
/*  Activate). When the layer is NOT available it stays inert and the        */
/*  default U15 table class Unicode.Name remains in charge. Known effects of */
/*  letting ICU own Name, vs the table class:                                */
/*    (a) Name moves to the ICU/Unicode version (U17 here);                  */
/*    (b) control chars: ICU returns "" for U_UNICODE_CHAR_NAME and only     */
/*        yields <control-XXXX> via U_EXTENDED_CHAR_NAME, so the Name method */
/*        replicates the UNICODE -> EXTENDED -> ALIAS cascade that           */
/*        rxunicode.cls's codepointName uses, to match what TUTOR returns.   */
/*                                                                           */
/*  DEPENDENCIES (loaded lazily, see LoadICULayer below):                    */
/*    rxunicode.cls   -> defines .RexxUnicode (registration host for ICU)    */
/*    ICU4ooRexx.cls  -> defines .ICU4ooRexx, self-registers into            */
/*    .RexxUnicode                                                           */
/*                                                                           */
/*  Version history                                                          */
/*  ===============                                                          */
/*                                                                           */
/*  Vers. Aut Date     Comments                                              */
/*  ----- --- -------- ----------------------------------------------------- */
/*   0.7  JMB 20260617 First version                                         */
/*                                                                           */
/*****************************************************************************/

.local~Unicode.ICU = .Unicode.ICU

::Class Unicode.ICU Public SubClass Unicode.Property

::Method Activate Class
  Expose icuAvailable

  -- Try to bring up the ICU layer. Never fatal: on any failure the plug-in
  -- stays inert and the default table classes remain in charge.
  icuAvailable = self~LoadICULayer

  -- ICU now owns Name/Na when the layer is available. The label nomenclature
  -- for unassigned code points was aligned to ICU's form (<unassigned-XXXX>)
  -- in gc.cls, so table and ICU agree on every codepoint; activating this only
  -- adds U17 character names (and the algorithmic Hangul, already fixed).
  If icuAvailable Then
    super~RegisterPreferredProperties( "Name Na", self )

-------------------------------------------------------------------------------
-- Lazy loader / validator for the ICU layer.                                --
-- Returns 1 if .RexxUnicode reports ICU registered and .ICU4ooRexx answers; --
-- 0 otherwise. Quiet about failures (POC: this is optional infrastructure). --
-------------------------------------------------------------------------------

::Method LoadICULayer Class
  Signal On Syntax Name LoadFailed

  -- Already up? (e.g. user loaded the layer by hand.)
  If self~ICURegistered Then Return 1

  -- Locate the executor's bin directory from the running interpreter itself.
  -- .RexxInfo~executable is a File for the rexx binary; its parent directory
  -- holds the Unicode .cls (rxunicode.cls, ICU4ooRexx.cls) and libICU4ooRexx.so.
  -- No external configuration needed -> travels with the code.
  exe = .RexxInfo~executable
  bin = exe~parent                      -- directory holding rexx + the .cls/.so
  sep = .File~separator
  bin ||= sep

 .context~package~loadPackage(bin"rxunicode.cls")  -- defines .RexxUnicode + registration host
 .context~package~loadPackage(bin"ICU4ooRexx.cls") -- defines .ICU4ooRexx, self-registers

  Return self~ICURegistered

LoadFailed:
  Return 0

-- True iff .RexxUnicode exists and reports ICU4ooRexx as registered.

::Method ICURegistered Class
  Signal On Syntax Name notReg
  If \ .environment~hasIndex("REXXUNICODE") Then Return 0
  Return (.RexxUnicode~ICU4ooRexxIsRegistered == 1)
notReg:
  Return 0

-------------------------------------------------------------------------------
-- Property method (READY, but only reached once registered).                --
-- Facade identical to Unicode.Name: same input normalization, same return.  --
-- Replicates the UNICODE -> EXTENDED -> ALIAS name-choice cascade so that    --
-- control chars, etc., match what the table class returns.                  --
-------------------------------------------------------------------------------

::Method Na   Class
  Forward Message "Name"
::Method Name Class
  Use Strict Arg code

  If \DataType(code,"X") Then Return ""

  -- Normalize "code" exactly like Unicode.Name does.
  If Length(code) < 4 Then code = Right(code,4,0)
  Do While code[1] == "0", Length(code) > 4
    code = SubStr(code,2)
  End
  code = Upper(code)

  cp = X2D(code)

  name = .ICU4ooRexx~u_charName(cp, .ICU4ooRexx~U_UNICODE_CHAR_NAME)
  If name \== "" Then Return name
  name = .ICU4ooRexx~u_charName(cp, .ICU4ooRexx~U_EXTENDED_CHAR_NAME)
  If name \== "" Then Return name
  Return .ICU4ooRexx~u_charName(cp, .ICU4ooRexx~U_CHAR_NAME_ALIAS)