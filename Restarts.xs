#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/*
 * COPYRIGHT AND LICENCE
 *
 * Copyright (C) 2008 WhitePages.com, Inc. with primary development by
 * Joshua ben Jore.
 *
 * This program is distributed WITHOUT ANY WARRANTY, including but not
 * limited to the implied warranties of merchantability or fitness for
 * a particular purpose.
 *
 * The program is free software.  You may distribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation (either version 2 or any later
 * version) and the Perl Artistic License as published by O’Reilly
 * Media, Inc.  Please open the files named gpl-2.0.txt and Artistic
 * for a copy of these licenses.
 */



/**
 ** Debugging diagnostics.
 **/

/*
 * Enable various diagnostics.
 */
#define DEBUG (!!RestartsDebugMode)
I32 RestartsDebugMode = 0;


/*
 * The RESTARTS_DEBUG environment variable toggles debugging.
 */
static void
set_debug_from_environment()
{
  HV *env;
  SV **sv;

  env = get_hv("main::ENV",0);
  if ( ! env ) {
    croak("Couldn't fetch %ENV hash");
  }

  sv = hv_fetch(env,"RESTARTS_DEBUG",0,0);
  if ( ! ( sv && *sv )) {
    RestartsDebugMode = 0;
    return;
  }
  
  RestartsDebugMode = SvTRUE( *sv );
}






void
setOp( PERL_CONTEXT *cx, OP *op )
{
  /*
   * This function is pure violence.
   */
  
  /* TODO: use the proper macros. */
  switch(CxTYPE(cx)) {
  case CXt_SUB:
    (*cx).cx_u.cx_blk.blk_u.blku_sub.retop = op;
    break;
  case CXt_EVAL:
    (*cx).cx_u.cx_blk.blk_u.blku_eval.retop = op;
    break;
  case CXt_LOOP:
    (*cx).cx_u.cx_blk.blk_u.blku_loop.my_op = (LOOP*)op;
#ifdef USE_THREADS
    
#else
    (*cx).cx_u.cx_blk.blk_u.blku_loop.next_op = op;
#endif
    break;
  case CXt_GIVEN:
  case CXt_WHEN:
    (*cx).cx_u.cx_blk.blk_u.blku_givwhen.leave_op = op;
    break;
  }
}

extern void dumpStacks(); /* From Devel::StackBlech */





/*
 * Advances N caller() frames through the stack. If there are not
 * enough frames in this stack, return -1. Accepts a pointer to N so
 * it can communicate how much of N is left to go.
 */
/* TODO: I32 */
dopoptonth( I32 *nth )
{
  I32 i;
  /* TODO: I32 in_debugger = 0; */
  
  for ( i = cxstack_ix; i >= 0; --i ) {
    register const PERL_CONTEXT *const cx = &cxstack[i];
    
    switch (CxTYPE(cx)) {
      /* TODO: comment out this default block. Also, shouldn't I be
	 using break instead of continue? */
    default:
      continue;
      
    case CXt_SUB:
      if ( DEBUG ) {
	PerlIO_printf(Perl_debug_log,"cv=0x%x PL_DBcv=0x%x\n", cx->blk_sub.cv, PL_DBcv);
      }
      /*
       * Skip past &DB::sub.
       */
      if ( cx->blk_sub.cv == PL_DBcv ) {
	continue;
      }
    case CXt_EVAL:
    case CXt_FORMAT:
      -- *nth;
      if ( 0 == *nth ) {
	/* TODO: when there are DB::sub frames, I may need to return
	   i+1. */
	return i;
      }
    }
  }
  
  return -1;
}





MODULE = Enbugger::Restarts	       PACKAGE = Enbugger::Restarts	    PREFIX = Restarts_




=pod

Enable XS debugging.

=cut

void
Restarts_debug( state )
    I32 state
  CODE:
    RestartsDebugMode = state;




MODULE = Enbugger::Restarts PACKAGE = DB PREFIX = Restarts_


=pod

restart_at(N) is an experimental function designed to get at some of
the functionality provided in the Smalltalk debugger. It attempts to
provide a way to continue executing from some higher scope.

=cut

void
Restarts_restart_at( n )
    I32 n
  PREINIT:
    const I32 orig_n = n;
    const PERL_CONTEXT *ccstack = cxstack;
    const PERL_CONTEXT *cx;
    I32 cxix;
    const PERL_SI *orig_top_si = PL_curstackinfo;
          PERL_SI *top_si      = PL_curstackinfo;
    
    OP *retop;
    CV *cv;
  CODE:

    if ( DEBUG ) {
      PerlIO_printf(Perl_debug_log,"PL_DBcv=0x%x\n",PL_DBcv);
      dumpStacks();
    }

    /*
     * Validate that N is possibly valid.
     *
     * 0 < N <= max
     *   where
     *     only interesting stack frames count towards max.
     */
    if ( 0 == n ) {
      if ( DEBUG ) {
	PerlIO_printf(Perl_debug_log,"restart_at(%d) has no work\n",n);
      }
      return;
    }
    else if ( n < 0 ) {
      croak( "Cannot return %d frames", n );
    }
    if ( DEBUG ) {
      PerlIO_printf(Perl_debug_log,"restart_at(%d)\n",n);
    }



    /*
     * Pop up to a higher JMPENV level if needed. This also advances
     * cxix and N as possible. Possible additional JMPENV levels are:
     * 
     *
     * There is only a place to longjmp() to when there exists a
     * top_env->je_prev.
     * 
     * TODO: understand je_mustcatch. Whatever that is, there is some
     * magic WRT some things that can be traversed into and not others.
     *
     * Block types:
     *   SUB
     *   SUB_DB
     *   FORMAT
     *
     * PUSHSTACKi(PERLSI_*)
     *  +UNKNOWN: not used
     *  +UNDEF: not used
     *   MAIN:
     *   MAGIC
     *     When servicing tied things
     *     When loading a module to satisfiy a tie() calls.
     *     Implicated by a bunch of places that examine
     *       PERL_MAGIC_tiedscalar.
     *     During utf::SWASHNEW. Is that a form of tie() magic?
     *  +SORT
     *  +SIGNAL:
     *  +OVERLOAD
     *  +DESTROY
     *  +WARNHOOK
     *  +DIEHOOK
     *  +REQUIRE
     */
    if ( DEBUG ) {
      PerlIO_printf(Perl_debug_log,"dopoptonth(&%d)=%d PL_curstackinfo=0x%x PL_curstackinfo->si_prev=0x%x\n",
		    n,cxix,PL_curstackinfo,PL_curstackinfo->si_prev);
    }
    while (0 < n
	   && (cxix = dopoptonth(&n))
	   && PL_curstackinfo->si_prev) {

      /*
       * Unwind a JMPENV stack.
       *
       * TODO: do *not* do this unwinding until I know I'm doing to
       * succeed. There are still opportunities to croak(). If I
       * croak, having popped PERLSI contexts and unwound any
       * contexts, there is no safe recovery.
       */
      dounwind(-1);
      POPSTACK;
      
      if ( DEBUG ) {
	PerlIO_printf(Perl_debug_log,"dopoptonth(&%d)=%d PL_curstackinfo=0x%x PL_curstackinfo->si_prev=0x%x\n",
		      cxix, PL_curstackinfo, PL_curstackinfo->si_prev);
      }
    }


    /*
     * Validate that our # of stacks to unwind is still proper. This
     * may be 0 if the current stack has been completely exhausted. I
     * think this ought to be popping the JMPENV if the context is
     * empty. TODO.
     */
    if ( 2 <= n ) {
      croak( "TODO: Can't pop to frame %d. I piddled on the stack. Lucky you", orig_n );
    }
    else if ( 1 == n ) {
      /*
       * Returning into PL_main.
       */
      croak( "TODO: Can't restart main. I piddled on the stack. Lucky you" );
      /* TODO: retop = PL_main_start; */
    }
    else {
      
      /*
       * Fetch the context we're returning into.
       */
      cx = &cxstack[cxix];
      switch (CxTYPE(cx)) {
      default:
	croak( "Unexpected CxTYPE 0x%x(cxstack[%d])=%d", cxix, CxTYPE(cx) );
	
	/*
	 * Fetch the CV and OP out of the proper struct.
	 */
      case CXt_EVAL:
	cv    = cx->blk_eval.cv;
	retop = CvSTART( cv );
	if ( DEBUG ) {
	  PerlIO_printf(Perl_debug_log,"CXtEVAL\n");
	}
	break;
      case CXt_SUB:
      case CXt_FORMAT:
	cv    = cx->blk_sub.cv;
	retop = CvSTART( cv );
	if ( DEBUG ) {
	  PerlIO_printf(Perl_debug_log,"CXtSUB CXtFORMAT retop=0x%x\n", retop );
	}
	break;
      }
      
      if ( DEBUG ) {
	/*
	 * Some tests are going to use this debug output to make
	 * assertions about the proper things being returned into.
	 */
	PerlIO_printf(Perl_debug_log,"cxstack_ix=%d cxix=%d cv=0x%x retop=%s(0x%x)\n",
		      cxstack_ix,cxix,cv, (retop ? OP_NAME(retop) : "" ),retop);
      }

      /*
       * Unwind the last part required.
       */
      dounwind(cxix);
    }




    /*
     * Have I passed upward into a different JMPENV context?
     */
    if ( orig_top_si == PL_curstackinfo ) {
      /*
       * Continue from the proper location. We're still in the same
       * JMPENV/PERLSI context. We just unwound some CXt* frames on
       * the current stack and are going to tell the interpreter where
       * to resume execution.
       */
      if ( DEBUG ) {
	PerlIO_printf(Perl_debug_log,"PL_op=0x%x\n",retop);
      }

      /* TODO: Consider calling setOp. */
      PL_op = retop;
    }

    else {
      /*
       * longjmp() up to the proper level. This is only relevant if I
       * popped up a JMPENV level. That is how perl undoes the C
       * stack. Normal stackless perl doesn't need longjmp() to fix up
       * the C stack.
       */
      if ( DEBUG ) {
	PerlIO_printf(Perl_debug_log,"JMPENV_JUMP\nPL_restartop=0x%x\n",retop);
      }

      /*
       * Run the current runloop to the end.
       *
       * If I don't do this, an interesting thing happens. The
       * function I'm in *right* *now* (whatever is calling this bit
       * of XS) is going to run to it's end like normal even though
       * the function may have been popped off the stack and in theory
       * "isn't running" anymore.
       *
       * What isn't clear to me in retrospect is why this was
       * necessary. I had to write this because I observed that I was
       * returning from my calling function more than once.
       */
      while ( PL_op->op_next ) {
	PL_op = PL_op->op_next;
      }

      
      /*
       * longjmp(). We're going to return from one of the
       * JMPENV_PUSH(ret) calls. There is no accounting for any
       * longjmp targets set by XS code.
       *
       * Places Perl 5.10 uses JMPENV_PUSH to push new C longjmp() targs at:
       *   op.c:
       *     - constant folding
       *   pp_ctl.c:
       *     - S_docatch which is likely eval() and eval{}
       *   perl.c:
       *     - perl_destruct while processing END{} blocks
       *       all return values ignored.
       *     - perl_parse prior to UNITCHECK{} and CHECK{}
       *       1: start context stack again
       *       2: exit
       *       3: resume from PL_restartop and pop the stack.
       *     - perl_run
       *       1: STATUS_ALL_FAILURE?
       *       2: STATUS_EXIT
       *       3: panic: top_env
       *     - Perl_call_sv when not in an eval.
       *       1: STATUS_ALL_FAILURE
       *       2: exit
       *       3: resume from PL_restartop and pop the stack.
       *     - Perl_evla_sv
       *       1: STATUS_ALL_FAILURE
       *       2: exit
       *       3: resume from PL_restartop and pop the stack.
       *     - Perl_call_list for each block when calling a list of END blocks
       *       1: STATUS_ALL_FAILURE
       *       2: exit
       *       3: resume from PL_restartop and pop the stack.
       */
      PL_restartop = retop;
      JMPENV_JUMP(3);
    }


BOOT:
    /*
     * Are we in debugging mode?
     */
    set_debug_from_environment();


## Local Variables:
## mode: c
## mode: auto-fill
## End:
