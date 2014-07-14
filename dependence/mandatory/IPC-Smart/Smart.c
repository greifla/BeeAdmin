/*
 * This file was generated automatically by ExtUtils::ParseXS version 2.15 from the
 * contents of Smart.xs. Do not edit this file, edit Smart.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST! 
 *
 */

#line 1 "Smart.xs"
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/ipc.h> 
#include "smart.h"

/*
 * Some perl version compatibility stuff.
 * Taken from HTML::Parser
 */
#include "patchlevel.h"
#if PATCHLEVEL <= 4 /* perl5.004_XX */

#ifndef PL_sv_undef
   #define PL_sv_undef sv_undef
   #define PL_sv_yes   sv_yes
#endif

#ifndef PL_hexdigit
   #define PL_hexdigit hexdigit
#endif
                                                              
#if (PATCHLEVEL == 4 && SUBVERSION <= 4)
/* The newSVpvn function was introduced in perl5.004_05 */
static SV *
newSVpvn(char *s, STRLEN len)
{
    register SV *sv = newSV(0);
    sv_setpvn(sv,s,len);
    return sv;
}
#endif /* not perl5.004_05 */
#endif /* perl5.004_XX */            

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
     char *name;
     int arg;
{
  errno = 0;
  switch (*name) {
  case 'A':
    break;
  case 'B':
    break;
  case 'C':
    break;
  case 'D':
    break;
  case 'E':
    break;
  case 'F':
    break;
  case 'G':
    if (strEQ(name, "GETALL"))
#ifdef GETALL
      return GETALL;
#else
    goto not_there;
#endif
    if (strEQ(name, "GETNCNT"))
#ifdef GETNCNT
      return GETNCNT;
#else
    goto not_there;
#endif
    if (strEQ(name, "GETPID"))
#ifdef GETPID
      return GETPID;
#else
    goto not_there;
#endif
    if (strEQ(name, "GETVAL"))
#ifdef GETVAL
      return GETVAL;
#else
    goto not_there;
#endif
    if (strEQ(name, "GETZCNT"))
#ifdef GETZCNT
      return GETZCNT;
#else
    goto not_there;
#endif
    break;
  case 'H':
    break;
  case 'I':
    if (strEQ(name, "IPC_ALLOC"))
#ifdef IPC_ALLOC
      return IPC_ALLOC;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_CREAT"))
#ifdef IPC_CREAT
      return IPC_CREAT;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_EXCL"))
#ifdef IPC_EXCL
      return IPC_EXCL;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_NOWAIT"))
#ifdef IPC_NOWAIT
      return IPC_NOWAIT;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_O_RMID"))
#ifdef IPC_O_RMID
      return IPC_O_RMID;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_O_SET"))
#ifdef IPC_O_SET
      return IPC_O_SET;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_O_STAT"))
#ifdef IPC_O_STAT
      return IPC_O_STAT;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_PRIVATE"))
#ifdef IPC_PRIVATE
      return IPC_PRIVATE;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_RMID"))
#ifdef IPC_RMID
      return IPC_RMID;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_SET"))
#ifdef IPC_SET
      return IPC_SET;
#else
    goto not_there;
#endif
    if (strEQ(name, "IPC_STAT"))
#ifdef IPC_STAT
      return IPC_STAT;
#else
    goto not_there;
#endif
    break;
  case 'J':
    break;
  case 'K':
    break;
  case 'L':
    if (strEQ(name, "LOCK_EX"))
#ifdef LOCK_EX 
      return LOCK_EX;
#else
    goto not_there;
#endif              
    if (strEQ(name, "LOCK_SH"))
#ifdef LOCK_SH 
      return LOCK_SH;
#else
    goto not_there;
#endif        
    if (strEQ(name, "LOCK_NB"))
#ifdef LOCK_NB
      return LOCK_NB;
#else
    goto not_there;
#endif             
    if (strEQ(name, "LOCK_UN"))
#ifdef LOCK_UN
      return LOCK_UN;
#else
    goto not_there;
#endif                      
    break;
  case 'M':
    break;
  case 'N':
    break;
  case 'O':
    break;
  case 'P':
    break;
  case 'Q':
    break;
  case 'R':
    break;
  case 'S':
    if (strEQ(name, "SEM_A"))
#ifdef SEM_A
      return SEM_A;
#else
    goto not_there;
#endif
    if (strEQ(name, "SEM_R"))
#ifdef SEM_R
      return SEM_R;
#else
    goto not_there;
#endif
    if (strEQ(name, "SEM_UNDO"))
#ifdef SEM_UNDO
      return SEM_UNDO;
#else
    goto not_there;
#endif
    if (strEQ(name, "SETALL"))
#ifdef SETALL
      return SETALL;
#else
    goto not_there;
#endif
    if (strEQ(name, "SETVAL"))
#ifdef SETVAL
      return SETVAL;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_LOCK"))
#ifdef SHM_LOCK
      return SHM_LOCK;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_R"))
#ifdef SHM_R
      return SHM_R;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_RDONLY"))
#ifdef SHM_RDONLY
      return SHM_RDONLY;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_RND"))
#ifdef SHM_RND
      return SHM_RND;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_SHARE_MMU"))
#ifdef SHM_SHARE_MMU
      return SHM_SHARE_MMU;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_UNLOCK"))
#ifdef SHM_UNLOCK
      return SHM_UNLOCK;
#else
    goto not_there;
#endif
    if (strEQ(name, "SHM_W"))
#ifdef SHM_W
      return SHM_W;
#else
    goto not_there;
#endif
    break;
  case 'T':
    break;
  case 'U':
    break;
  case 'V':
    break;
  case 'W':
    break;
  case 'X':
    break;
  case 'Y':
    break;
  case 'Z':
    break;
  }
  errno = EINVAL;
  return 0;
  
 not_there:
  errno = ENOENT;
  return 0;
}

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#line 326 "Smart.c"

XS(XS_IPC__Smart_constant); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_constant)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: IPC::Smart::constant(name, arg)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	char *	name = (char *)SvPV_nolen(ST(0));
	int	arg = (int)SvIV(ST(1));
	double	RETVAL;
	dXSTARG;

	RETVAL = constant(name, arg);
	XSprePUSH; PUSHn((double)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_new_share); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_new_share)
{
    dXSARGS;
    if (items != 4)
	Perl_croak(aTHX_ "Usage: IPC::Smart::new_share(key, segment_size, flags, nolocking)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	key_t		key = (key_t) SvIV(ST(0));
	int	segment_size = (int)SvIV(ST(1));
	int	flags = (int)SvIV(ST(2));
	int	nolocking = (int)SvIV(ST(3));
	Share *	RETVAL;
	dXSTARG;

	RETVAL = new_share(key, segment_size, flags, nolocking);
	XSprePUSH; PUSHi((I32) RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_smart_watched); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_smart_watched)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: IPC::Smart::smart_watched(share)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	int	RETVAL;
	dXSTARG;

	RETVAL = smart_watched(share);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_write_share); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_write_share)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: IPC::Smart::write_share(share, data, length)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	char*	data = (char *)SvPV_nolen(ST(1));
	int	length = (int)SvIV(ST(2));
	int	RETVAL;
	dXSTARG;

	RETVAL = write_share(share, data, length);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_read_share); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_read_share)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: IPC::Smart::read_share(share)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
#line 340 "Smart.xs"
    char*    data; 
    int      length;
#line 422 "Smart.c"
	char *	RETVAL;
	dXSTARG;
#line 343 "Smart.xs"
    share  = (Share *)SvIV(ST(0));
    length = read_share(share, &data);
    ST(0) = sv_newmortal();
    if (length >= 0) {
      sv_usepvn((SV*)ST(0), data, length);
    } else {
      sv_setsv(ST(0), &PL_sv_undef);
    }
#line 434 "Smart.c"
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_destroy_share); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_destroy_share)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: IPC::Smart::destroy_share(share, rmid)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	int	rmid = (int)SvIV(ST(1));
	int	RETVAL;
	dXSTARG;

	RETVAL = destroy_share(share, rmid);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_smart_lock); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_smart_lock)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: IPC::Smart::smart_lock(share, flags)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	int	flags = (int)SvIV(ST(1));
	int	RETVAL;
	dXSTARG;

	RETVAL = smart_lock(share, flags);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_smart_unlock); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_smart_unlock)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: IPC::Smart::smart_unlock(share)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	int	RETVAL;
	dXSTARG;

	RETVAL = smart_unlock(share);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_smart_version); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_smart_version)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: IPC::Smart::smart_version(share)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	unsigned int	RETVAL;
	dXSTARG;

	RETVAL = smart_version(share);
	XSprePUSH; PUSHu((UV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_IPC__Smart_smart_num_segments); /* prototype to pass -Wmissing-prototypes */
XS(XS_IPC__Smart_smart_num_segments)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: IPC::Smart::smart_num_segments(share)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	Share*		share = (Share *)SvIV(ST(0));
	int	RETVAL;
	dXSTARG;

	RETVAL = smart_num_segments(share);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_IPC__Smart); /* prototype to pass -Wmissing-prototypes */
XS(boot_IPC__Smart)
{
    dXSARGS;
    char* file = __FILE__;

    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(items); /* -W */
    XS_VERSION_BOOTCHECK ;

        newXS("IPC::Smart::constant", XS_IPC__Smart_constant, file);
        newXS("IPC::Smart::new_share", XS_IPC__Smart_new_share, file);
        newXS("IPC::Smart::smart_watched", XS_IPC__Smart_smart_watched, file);
        newXS("IPC::Smart::write_share", XS_IPC__Smart_write_share, file);
        newXS("IPC::Smart::read_share", XS_IPC__Smart_read_share, file);
        newXS("IPC::Smart::destroy_share", XS_IPC__Smart_destroy_share, file);
        newXS("IPC::Smart::smart_lock", XS_IPC__Smart_smart_lock, file);
        newXS("IPC::Smart::smart_unlock", XS_IPC__Smart_smart_unlock, file);
        newXS("IPC::Smart::smart_version", XS_IPC__Smart_smart_version, file);
        newXS("IPC::Smart::smart_num_segments", XS_IPC__Smart_smart_num_segments, file);
    XSRETURN_YES;
}
