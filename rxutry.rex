#!/usr/bin/env rexx
--
-- Modifications by Josep Maria Blasco to support Unicode.cls and
-- TUTOR Unicode extensions.
-- Changed and added lines are marked "JMB".
--
-- First version based on rexxtry.rex distributed with
-- Open Object Rexx Version 5.1.0 r12691.
--
-- First release, TUTOR 0.5, 20240204.
--
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 1995, 2004 IBM Corporation. All rights reserved.             */
/* Copyright (c) 2005-2023 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* https://www.oorexx.org/license.html                                        */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/****************************************************************************/
/* Name: rxuxtry.rex                                                    JMB */
/* Type: ooRexx Script                                                      */
/*                                                                          */
/*  Loosely derived from an ancient formulation of Mike Cowlishaw.          */
/*                                                                          */
/*  This procedure lets you interactively try REXX statements.              */
/*  If you run it with no parameter, or with a question mark                */
/*  as a parameter, it will briefly describe itself.                        */
/*  You may also enter a REXX statement directly on the command line        */
/*  for immediate execution and exit.  Example:  rexxtry call show          */
/*                                                                          */
/*  Enter 'call show' to see user variables provided by REXXTRY.            */
/*  Enter '=' to repeat your previous statement.                            */
/*  Enter '?' to invoke system-provided online help for REXX.               */
/*  The subroutine named 'sub' can be CALLed or invoked as 'sub()'.         */
/*  REXXTRY can be run recursively with CALL.                               */
/*                                                                          */
/*  Except for the signal instructions after a syntax error, this           */
/*  procedure is an example of structured programming.                      */
/*  The 'clear' routine illustrates system-specific SAA-portable coding.    */
/*                                                                          */
/****************************************************************************/

parse arg argrx                                /* Get user's arg string.    */
call house                                     /* Go do some housekeeping.  */
Call Unicode.Setup                             /* JMB                       */

select                                         /* 3 modes of operation...   */
  when argrx = '?' then                        /*   1.  Tell user how.      */
    call tell
  when argrx = ''  then do                     /*   2.  Interactive mode.   */
    call intro
    call main
  end
  otherwise                                    /*   3.  One-liner and exit. */
    push argrx
    call main
end

Unicode.Setup:                                 /* This whole routine by JMB */
  hand     = "F0 9F 91 89"X
  path = Value("PATH",,"ENVIRONMENT")
  sep = .File~pathSeparator
  uFile = .File~searchPath("Unicode.cls","."sep||path)
  If uFile == .nil Then Signal Unicode.cls.not.found
  dir = uFile~parent
  If abbrev(sysrx,  'Windows') Then
    present = Pos(Upper(dir) || sep, Upper(path) || sep) > 0
  Else
    present = Pos(      dir  || sep,       path  || sep) > 0
  If \present Then Do
    Say hand  " Temporarily adding" dir "to the PATH environment variable..."
    Call Value "PATH",  dir || sep || path, "ENVIRONMENT"
  End
  Drop path sep uFile dir present
 .context~package~addPackage(.Package~new("Unicode.cls"), "U")
  Return
Unicode.cls.not.found:
  Say "Could not find file 'Unicode.cls'."
  Signal done

done:
  exit                                         /* The only exit.            */

house:                                         /* Housekeeping.             */
  parse version version                        /* Fill-in 2 user variables. */
  parse source source
  sysrx = word(source, 1)                      /* Get system name.          */
  remindrx = "Enter 'exit' to end."            /* How to escape rexxtry.    */
  helprx = '   ',                              /* add extra help info       */
    "  Or '?' for online REXX help."
  promptrx = ''                                /* Null if not one-liner.    */
  procrx = .context~package~name               /* fully resolved name       */
  if argrx<>'' then
    promptrx = procrx' '                       /*   Name part of user line. */
  filerx = .File~new(procrx)                   /* get a file object for parsing */
  procrx = filerx~name                         /* Pick up the proc name.    */
  temprx = ' 'procrx' on 'sysrx                /* Make border...            */
  posrx = 69-length(temprx)                    /*   where to overlay name,  */
  bordrx = copies('.', 68)                     /*   background of periods,  */
  bordrx = overlay(temprx, bordrx, posrx)      /*   name right-adjusted.    */
  save = ''                                    /* Don't save user input.    */
  trace = 'Off'                                /* Init user trace variable. */
  return result                                /* Preserve result contents. */

tell:
  call clear
  /* the following loop start and end may need to be modified should the    */
  /* comment at the top of the program be changed.                          */
  do irx = 44 to 58                            /* Tell about rexxtry by     */
    say substr(sourceline(irx), 4, 73)         /*   displaying the prolog.  */
  end
  return result                                /* Preserve result contents. */

clear:
  select                                       /* SAA-portable code.        */
    when abbrev(sysrx,  'Windows') then
      'CLS'                                    /* system to clear screen    */
    when sysrx = 'LINUX' | sysrx = 'AIX' | sysrx = 'SUNOS' | sysrx = 'DARWIN' then
      'clear'                                  /* system to clear screen    */
    otherwise nop                              /* No such command available */
  end; say
  return result                                /* Preserve result contents. */

intro:                                         /* Display brief             */
  say version                                  /*   introductory            */
  say hand''procrx' lets you',                 /*   about rxutry and  *JMB* */
    'interactively try Unicode-REXX',          /*   remarks for       *JMB* */
    'statements.'                              /*   interactive mode.       */
  say '    Each string is executed when you hit Enter.'
  say "    Enter 'call tell' for",             /* How to see description.   */
    "a description of the features."
  say hand"  Options DefaultString is" .Unicode.DefaultString /*        JMB */
  say hand"  Options Coercions     is" .Unicode.Coercions     /*        JMB */
  say '  Go on - try a few...            'remindrx
  return result                                /* Preserve result contents. */

sub:
  say '  ...test subroutine',                  /* User can CALL this        */
  "'sub'  ...returning 1234..."                /*   subroutine or           */
  return 1234                                  /*   invoke with 'sub()'.    */

main:
  signal on syntax                             /* Enable syntax trap.       */
  do forever                                   /* Loop forever.             */
    prev = inputrx                             /* User can repeat previous. */
    parse pull inputrx                         /* Input keyboard or queue.  */
    current = inputrx                          /* Current line for 'show'.  */
    if save <> '' then call save               /* Save before interpreting. */
    if inputrx = '=' then inputrx=prev         /* '=' means repeat previous */
    select
      when inputrx = '' then say ' ',          /* If null line, remind      */
        procrx':  'remindrx helprx             /*   user how to escape.     */
      when inputrx='?' then call help          /* Request for online help.  */
      otherwise
        rxuinputrx = rxu2rexx()                /* Run RXU on user input JMB */
        If rxuinputrx = .Nil Then Do           /* Error handled in rxu  JMB */
          If argrx <> '' & queued() = 0 Then   /* One-liner and queue   JMB */
            Leave                              /* isempty? We are done  JMB */
          Iterate                              /* Get more input        JMB */
        End                                    /*                       JMB */
        rc = 'X'                               /* Make rc change visible.   */
        call set2; trace (trace)               /* Need these on same line.  */
        interpret rxuinputrx                   /* Try the user's input. JMB */
        trace 'Off'                            /* Don't trace rexxtry.      */
        call border                            /* Go write the border.      */
    end
    if argrx <> '' & queued() = 0              /* For one-liner, loop until */
      then leave                               /*   queue is empty.         */
  end
  return result                                /* Preserve result contents. */

rxu2rexx:                                      /* Whole routine by JMB      */
  Signal On Syntax Name rxu.rex.not.found
  Call "rxu.rex" .Array~of(inputrx)
  If result~isA(.Array) Then Return result[1]
  Return result
rxu.rex.not.found:
  Say "The rxu.rex preprocessor was not found."
  Call done

set1:  siglrx1 = sigl                          /* Save pointer to lineout.  */
  return result                                /* Preserve result contents. */

set2:  siglrx2 = sigl                          /* Save pointer to trace.    */
  return result                                /* Preserve result contents. */

save:                                          /* Save before interpreting. */
  call set1;rcrx=lineout(save,inputrx)         /* Need on same line.        */
  if rcrx <> 0 then                            /* Catch non-syntax error    */
    say "  Error on save="save                 /*   from lineout.           */
  return result                                /* Preserve result contents. */

help:                                          /* Request for online help.  */
  select
    when abbrev(sysrx, 'Windows') then do      /* ... for Windows           */
      /* issue the pdf as a command using quotes because the install dir may
         contain blanks */
      say '  Online Help started'
      'start "Rexx Online Documentation"' '"'||value("REXX_HOME",,"ENVIRONMENT")||"\doc\rexxref.pdf"||'"'
    end                                        /* ... for Unix              */
    when sysrx = sysrx = 'LINUX' | sysrx = 'AIX' | sysrx = 'SUNOS' | sysrx = 'DARWIN' then do
      say '  Online help is not installed on' sysrx
      rc = 'Sorry!'

      /* If you wish to install your own help, comment out the above and
       * uncomment the below, filling in the correct path to the doc and the
       * proper pdf reader.
       */
      /*
      pdfReader = 'x'
      docDir = 'dir'
      doc = docDir'/rexxref.pdf'
      say '  Online Help started using' pdfReader doc
      pdfReader doc'&'
      */
    end
    otherwise do
      say '  'sysrx' has no online help for REXX.'
      rc = 'Sorry!'
    end
  end
  call border
  return result                                /* Preserve result contents. */

border:
  if rc = 'X' then                             /* Display border.           */
    say '  'bordrx
  else say ' ',                                /* Show return code if it    */
    overlay('rc = 'rc' ', bordrx)              /*   has changed.            */
  return result                                /* Preserve result contents. */

syntax:
  trace 'Off'                                  /* Stop any tracing.         */
  select
    when sigl = siglrx1 then do                /* User's 'save' value bad.  */
      say "  Invalid 'save' value '"save"', resetting to ''."
      save = ''
    end
    when sigl = siglrx2 then do                /* User's 'trace' value bad. */
      say "  Invalid 'trace' value '"trace"', resetting to 'Off'."
      trace = 'Off'
    end
    otherwise                                  /* Some other syntax error.  */
      condition = condition('o')
                                               /* Show the error msg text.  */
      say '  Oooops ! ... try again.     'condition~errortext
      secondary = condition('o')~message
      if .nil <> secondary then              /* get a real one?           */
                                             /* display it also           */
        say '                              'secondary
      rc = condition~code                    /* use the full error code */
  end
  call border                                  /* Go write the border.      */
  if argrx <> '' & queued() = 0 then           /* One-liner not finished    */
    signal done                                /*   until queue is empty.   */
  signal main                                  /* Resume main loop.         */

show:
  trace 'Off'; call clear                      /* Display user variables    */
  say                                          /*                       JMB */
  Say hand"   Options DefaultString =" .Unicode.DefaultString  /*       JMB */
  Say hand"   Options Coercions     =" .Unicode.Coercions      /*       JMB */
  say                                          /*                       JMB */
  say '  'procrx' provides',                   /*   provided by rexxtry.    */
    'these user variables.'
  say '  The current values are...'            /* Show current values.      */
  say
  say "    'version'   = '"version"'"          /* What level of REXX.       */
  say "    'source'    = '"source"'"           /* What oper system etc.     */
  say "    'result'    = '"result"'"           /* REXX special variable.    */
  say
  say '     Previous line entered by user.  Initial value=INPUTRX.'
  say "    'prev'      = '"prev"'"             /* Previous user statement.  */
  say "    'current'   = '"current"'"          /* Compare curr with prev.   */
  say
  say "     Save your input with save=filespec. Stop saving with save=''."
  say "    'save'      = '"save"'"             /* Filespec for input keep.  */
  say
  say '     Enter trace=i, trace=o etc. to control tracing.'
  say "    'trace'     = '"trace"'"            /* Trace user statements.    */
  return result                                /* Preserve result contents. */
