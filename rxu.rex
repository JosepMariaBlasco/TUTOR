/******************************************************************************/
/*                                                                            */
/* rxu.rex - Rexx Preprocessor for Unicode                                    */
/* =======================================                                    */
/*                                                                            */
/* This program is part of the The Unicode Tools Of Rexx (TUTOR) package      */
/*                                                                            */
/* See https://rexx.epbcn.com/tutor/                                          */
/*     and https://github.com/JosepMariaBlasco/tutor                          */
/*                                                                            */
/* Copyright (c) 2023-2025 Josep Maria Blasco <josep.maria.blasco@epbcn.com>  */
/*                                                                            */
/* License: Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)  */
/*                                                                            */
/* Version history:                                                           */
/*                                                                            */
/* Date     Version Details                                                   */
/* -------- ------- --------------------------------------------------------- */
/* 20250114    0.6  Complete rewrite for the 0.6 version. First version to    */
/*                  use the Rexx Parser.                                      */
/*                                                                            */
/******************************************************************************/

  package = .context~package

  local   =  package~local

--------------------------------------------------------------------------------
-- Recognized standard BIFs                                                   --
--------------------------------------------------------------------------------

  BIFs   = "C2X CHARIN CHAROUT CHARS CENTER CENTRE CHANGESTR COPIES DATATYPE "
  BIFs ||= "LEFT LENGTH LINEIN LINEOUT LINES LOWER POS REVERSE RIGHT STREAM "
  BIFs ||= "SUBSTR UPPER "

  local~BIFs = BIFs

--------------------------------------------------------------------------------
-- Special variables                                                          --
--------------------------------------------------------------------------------

  Special = "RC RESULT SELF SIGL SUPER"
  local~Special = Special

--------------------------------------------------------------------------------
-- Options DefaultString will apply to the following tokens                   --
--------------------------------------------------------------------------------

  local~ALL.DEFAULT_STRING = -
    .TK.STRING || .ALL.NUMBERS || .TK.PERIOD || .TK.SYMBOL_LITERAL

--------------------------------------------------------------------------------
-- Main program                                                               --
--------------------------------------------------------------------------------

  Use Arg arguments

  interactive = 0
  If arguments~isA(.Array) Then Do
    interactive = 1
    outIndex = 1
    outArray = .Array~new(arguments~items)
    outArray[1] = ""
    options. = 0
    options.namespace = "U"
    Call Transform arguments, outArray, options.
    If result == .Nil Then Return .nil
    Return outArray
  End

  options.       = 0

  keepOutputFile = 0
  warnbif        = 1

  arguments = Strip( arguments )

  Do While arguments[1] == "-"
    Parse Var arguments option arguments
    Select Case Lower(option)
      When "-h", "-help" Then Do
        Say .Resources~Help
        Exit 1
      End
      When "-k", "-keep" Then keepOutputFile  = 1
      When "-nokeep"     Then keepOutputFile  = 0
      When "-warnbif"    Then options.warnbif = 1
      When "-nowarnbif"  Then options.warnbif = 0
      When "-n", "-namespace" Then Do
        options.namespace = Word(arguments,1)
        arguments = SubWord(arguments,2)
      End
      Otherwise
        Say "Invalid option '"option"'."
        Exit 1
    End
  End

  filename = arguments

  If fileName == "" Then Do
    Say .Resources~Help
    Exit 1
  End

  q = fileName[1]
  If q = "'" | q = '"' Then
    Parse Var fileName (q)fileName(q) arguments
  Else
    Parse Var fileName    fileName    arguments

  arguments = Strip(arguments)

--------------------------------------------------------------------------------
-- Construct input and output file names                                      --
--------------------------------------------------------------------------------

  inFile  = filename
  Select
    When Pos(".",filename) == 0 Then Do
      inFile  = filename".rxu"
      outFile = filename".rex"
    End
    When filename~caselessEndsWith(".rxu") Then
      outFile = Left(filename,Length(filename)-3)"rex"
    Otherwise
      outFile = filename".rex"
  End

--------------------------------------------------------------------------------
-- Check that the input file exists and is not a directory                    --
--------------------------------------------------------------------------------

  If Stream(inFile,"c","query exists") == "" Then Do
    Call LineOut .StdOut, "File '"inFile"' does not exist."
    Exit
  End

  If .File~new(inFile)~isDirectory Then Do
    Call LineOut .StdOut, "'"inFile"' is a directory."
    Exit
  End

--------------------------------------------------------------------------------
-- Close and re-open outfile (avoid hangs from previous runs)                 --
--------------------------------------------------------------------------------

  Call Stream outFile,"c","close"
  Call Stream outFile,"c","open write replace"

--------------------------------------------------------------------------------
-- Translate the file                                                         --
--------------------------------------------------------------------------------

  Call Transform inFile, outFile, options.

  saveRC = result

  Call Stream inFile,  "C", "Close"
  Call Stream outFile, "C", "Close"

--------------------------------------------------------------------------------
-- Translation error?                                                         --
--------------------------------------------------------------------------------

  If saveRC \== 0 Then Exit saveRC

--------------------------------------------------------------------------------
-- Translation was OK. Run the translated .rex file                           --
--------------------------------------------------------------------------------

  Address COMMAND "rexx" outFile arguments

  saveRC = rc

  If \keepOutputFile Then .File~new(outFile)~delete

Exit saveRC

--------------------------------------------------------------------------------
-- Dependencies                                                               --
--------------------------------------------------------------------------------

::Requires "Rexx.Parser.cls"
::Requires "modules/print/print.cls" -- Helps in debugging

--------------------------------------------------------------------------------
-- Translate RXU -> REX                                                       --
--------------------------------------------------------------------------------

::Routine Transform

  Signal On Syntax

  Use Strict Arg inFile, outFile, options.

  interactive = 0
  If outFile~isA(.Array) Then Do
    interactive = 1
    outIndex = 1
    outArray = outFile
    outArray[1] = ""
  End

  options = .Array~new
  options~append( (Unicode, 1) )
  If inFile~isA(.Array) Then
    parser = .Rexx.Parser~new( "Array", inFile, options )
  Else Do
    inFile =  Qualify(infile)
    source =  CharIn(inFile,,Chars(inFile))~makeArray
    parser = .Rexx.Parser~new( inFile, source, options )
  End

  tokens = .Array~new                   -- To collect all non-inserted tokens
  namespaces = .Set~new                 -- To collect all namespaces

  -- First pass. Collect tokens and all namespaces
  token  = parser~firstElement
  Do While token \== .Nil
    tokens~append( token )
    If token << .NAMESPACE.NAME Then namespaces[] = token~value
    token = token~next
  End

  -- If we were not given a namespace, pick one
  If options.nameSpace == 0 Then
    options.nameSpace = PickANewNamespace( nameSpaces )
  namespace = options.namespace

  -- Second pass. Emit the new program, with the appropriate substitutions
  lastLine = 1
  currentInstruction = ""
  optionsInstruction = 0
  tokenNo = 0
  parseVarContext = 0 -- PARSE VAR found -> change to PARSE VALUE var WITH
  Do token Over tokens
    If \token~isIgnorable Then tokenNo += 1
    Parse Value token~from token~to With startLine . endLine .
    Do While lastLine < startLine
      Call Say ""
      lastLine += 1
    End

    prev = token~prev
    If prev \== .Nil, prev < (.ALL.SYMBOLS_AND_STRINGS||.TK.OP.ABUTTAL) Then prefix = "||"
    Else prefix = ""

    source = token~source
    nosuffix = Left( source, Length(source) - 1)

    -- Since we are substituting tokens on a token-by-token basis, we
    -- will enclose substitutions between parenthesis, because determining
    -- whether these parentheses are really needed might be too expensive.
    -- The same might not be true if we were using the Tree API.

    Select

      -- Calls to built-in functions and procedures.
      --
      -- We use token~value instead of token~source here because we want
      -- to substitute CALL "POS" by CALL U:POS, i.e., we want to remove
      -- quotes, if present.
      When token << .BUILTIN.NAME, WordPos(token~value,.BIFS) > 0 Then Do
        If WordPos(token~value,.BIFS) > 0 Then
          Call Out namespace":"token~value
        Else If Options.warnbif Then
          Say "WARNING: Unsupported BIF '"token~value"'",
            "used in line" Word(token~from,1)
      End

      -- Sanitize taken constants
      When token < .TK.TAKEN_CONSTANT Then Do
        source = token~source
        c = source[1]
        -- Symbols are emitted as-is
        If c \== "'", c \== '"' Then
          Call Out token~source
        -- Strings are a little more involved
        Else Do
          Select Case source[ source~length ]~lower
            -- Translate U strings. See the comments about U strings below
            When "u" Then
              Call Out '"'ChangeStr('"',token~value,'""')'"'
            -- For all other Unicode strings, simply delete the new suffix
            When "y","p","g","t" Then
              Call Out Left(source, Length(source) - 1)
            Otherwise
              Call Out source
          End
        End
      End

      -- Unicode U-strings
      --
      -- For demo purposes, using token~value is much better for legibility.
      -- For portability and storage, however, a C2X version of the string
      -- should be used (Unicode characters can degrade, depending on the
      -- editor).
      When token < .TK.UNICODE_STRING Then
        Call Out prefix'('namespace':Bytes("'ChangeStr('"',token~value,'""')'"))'

      -- The four new Unicode string types
      When token < .TK.TEXT_STRING Then
        Call Out prefix'('namespace':Text('nosuffix'))'
      When token < .TK.GRAPHEMES_STRING Then
        Call Out prefix'('namespace':Graphemes('nosuffix'))'
      When token < .TK.CODEPOINTS_STRING Then
        Call Out prefix'('namespace':Codepoints('nosuffix'))'
      When token < .TK.BYTES_STRING Then
        Call Out prefix'('namespace':Bytes('nosuffix'))'

      -- Hexadecimal and binary strings are low-level, hence BYTES strings
      When token < (.TK.HEX_STRING || .TK.BINARY_STRING) Then
        Call Out prefix'('namespace':Bytes('source'))'

      -- Standard strings, numbers and pure constant symbols.
      When token < .ALL.DEFAULT_STRING Then
        Call Out prefix'('namespace':Default('source'))'

      -- We apply the default string method only to variables which are
      -- not the direct or indirect targets of an assignment. In this sense,
      -- a variable that is to receive a value in a PARSE, ARG, USE ARG, etc.,
      -- instruction is an indirect target of an assignment.
      -- We leave special variables alone too.
      When token < .ALL.VAR_SYMBOLS Then Do
        If parseVarContext Then Do
          Call Out token~source "With"
          parseVarContext = 0
        End
        Else If \token~isAssigned, -
          WordPos(token~value, .Special) == 0, -
          WordPos(currentInstruction, "PROCEDURE") == 0 Then
          Call Out prefix'('namespace':Default('source'))'
        Else
          Call Out prefix||token~source
      End

      -- Keep track of the current instruction
      When token < .TK.KEYWORD Then Do
        currentInstruction = token~value
        -- OPTIONS instruction support
        If currentInstruction == "OPTIONS" Then
          Call Out "Do; !Options ="
        -- Standard case
        Else
          Call Out token~source
      End

      -- Process subkeywords (special for PARSE VAR)
      When token < .TK.SUBKEYWORD Then Do
        If token~value == "VAR", currentInstruction == "PARSE" Then Do
          -- Emit "Value" instead of "Var"
          Call Out "Value"
          -- And note the fact. This will allow us to emit "With" after
          -- the variable name... and this will allow us to use the default
          -- BIF against the variable.
          parseVarContext = 1
        End
        Else
          Call Out token~source
      End

      -- Process end of clause markers (inserted or not)
      When token < .TK.END_OF_CLAUSE Then Do
        Select Case currentInstruction
          When "OPTIONS" Then Do
            optionsInstruction = 0
            Call Out "; Call !Options !Options; Options !Options; End"
          End
          Otherwise Nop
        End
        currentInstruction = ""
        tokenNo = 0
        If token~from \== token~to Then Call Out ";"
      End

      -- We do not print inserted tokens
      When token~from == token~to Then Nop

      -- Standard case
      Otherwise Call Out token~source
    End
    lastLine = endLine
  End

  If \interactive Then Do
    Call Say ""
    Call Say "::Requires 'Unicode.cls' Namespace" namespace
  End

Return 0

Say:
  If interactive Then Do
    outArray[outIndex] ||= Arg(1)
    outIndex += 1
    outArray[outIndex] = ""
  End
  Else Call LineOut outFile, Arg(1)
Return

Out:
  If interactive Then outArray[outIndex] ||= Arg(1)
  Else Call CharOut outFile, Arg(1)
Return

--------------------------------------------------------------------------------
-- SYNTAX handler                                                             --
--------------------------------------------------------------------------------

Syntax:
  co = condition("O")

  ------------------------------------------------------------------------------
  -- Support for rxutry                                                       --
  ------------------------------------------------------------------------------

  If \interactive Then Signal NotRXUTry

  Signal On Syntax Name RXUTry
  additional = Condition("A")~lastItem
  Raise Syntax (additional~code) Additional (additional~additional)

RXUTry:
  co = Condition("O")
  Say "  Oooops ! ... try again.    " co~errorText
  Say "                             " co~message
  Parse Source source
  Say Left("  rc =" co~code" ",46,".") "rxutry.rex on" Word(source,1)
  Return .nil

  ------------------------------------------------------------------------------
  -- Standard Rexx Parser error handler                                       --
  ------------------------------------------------------------------------------

NotRXUTry:
  If co~code \== 98.900 Then Do
    Say "Error" co~code "in" co~program", line" co~position":"
    Raise Propagate
  End

  additional = Condition("A")
  Say additional[1]":"
  line = Additional~lastItem~position
  Say Right(line,6) "*-*" source[line]
  Say Copies("-",80)
  Say co~stackFrames~makeArray
  additional = additional~lastItem

  Raise Syntax (additional~code) Additional (additional~additional)

--------------------------------------------------------------------------------
-- PickANewNamespace                                                          --
--   No namespace has been specified, but we need one to qualify the calls    --
--   to old/new BIFs contained in Unicode.cls.                                --
--------------------------------------------------------------------------------

::Routine PickANewNamespace

  Use Strict Arg UsedNamespaces

  -- Try with "U", "UN", ..., "UNICODE" first.
  name = "UNICODE"
  Do i = 1 To Length(name)
    nam = Left(name, i)
    If \InUse( nam ) Then Return nam
  End

  -- Then try with "UC", ... , "UCODE".
  name = "UCODE"
  Do i = 2 To Length(name)
    nam = Left(name, i)
    If \InUse( nam ) Then Return nam
  End

  -- If not successful, try "U" with a four-digit random number
  Do Forever
    nam = "U"Random(1000,9999)
    If \InUse( nam ) Then Return nam
  End

InUse: Return UsedNamespaces~hasItem( Arg(1) )

--------------------------------------------------------------------------------
-- Helpfile                                                                   --
--------------------------------------------------------------------------------

::Resource Help
rxu: Rexx Preprocessor for Unicode

Syntax:
  rxu [options] filename [arguments]

Default extension is ".rxu". A ".rex" file with the same name
will be created, replacing an existing one, if any.

Options (case insensitive):

  -help, -h       : display help for the RXU command
  -keep, -k       : do not delete the generated .rex file
  -namespace NAME : prefix to identify TUTOR-defined BIFs and routines
  -n NAME         :
  -nokeep         : delete the generated .rex file (the default)
  -warnbif        : warn when using not-yet-migrated to Unicode BIFs
  -nowarnbif      : do not warn when using not-yet-migrated-to-Unicode
                    BIFs (the default)
::END