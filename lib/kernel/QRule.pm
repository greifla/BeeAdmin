package kernel::QRule;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Init                  # at this method, the registration must be done
{
   my $self=shift;
   return(1);
}

sub getPosibleTargets
{
   my $self=shift;
   return;
}

sub getName
{
   my $self=shift;
   return($self->getParent->T($self->Self,$self->Self));
}

sub getDescription
{
   my $self=shift;

   return("This is long");
}

sub qcheckRecord
{
   my $self=shift;
   my $rec=shift;

   my $result=3;       # undef = rule not useable
                       #     1 = rule failed, but no big problem
                       #     2 = rule failed
                       #     3 = rule failed - k.o. criterium
   my $desc={
               qmsg=>'this is a rule with no defined qcheckRecord method',
               dataissue=>'this could be an array of text to DataIssue Wf',
            };


   return($result,$desc);
}

sub priority           # priority in witch order the rules should be processed
{
   my $self=shift;
   return(1000);
}

sub T
{
   my $self=shift;
   my $t=shift;
   my $tr=(caller())[0];
   return($self->getParent->T($t,$tr,@_));
}


sub IfaceCompare
{
   my $self=shift;
   my $obj=shift;
   my $origrec=shift;
   my $origfieldname=shift;
   my $comprec=shift;
   my $compfieldname=shift;
   my $forcedupd=shift;
   my $wfrequest=shift;
   my $qmsg=shift;
   my $errorlevel=shift;
   my %param=@_;

   $param{mode}="native" if (!defined($param{mode}));

   my $takeremote=0;
   my $ask=1;
   if ($param{mode} eq "native"){           # like nativ string compares
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          (!defined($origrec->{$origfieldname}) ||
           $comprec->{$compfieldname} ne $origrec->{$origfieldname})){
         $takeremote++;
      }
   }
   elsif ($param{mode} eq "leftouterlinkcreate"){  # like servicesupprt links
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          (!defined($origrec->{$origfieldname}) ||
           $comprec->{$compfieldname} ne $origrec->{$origfieldname})){
         my $lnkfield=$obj->getField($origfieldname);
         my $lnkobj=$lnkfield->{vjointo};
         my $chkobj=getModuleObject($self->getParent->Config,$lnkobj);
         if (defined($chkobj)){
            $chkobj->SetFilter($lnkfield->{vjoindisp}=>
                               $comprec->{$compfieldname});
            my ($chkrec,$msg)=$chkobj->getOnlyFirst($lnkfield->{vjoinon}->[1]);
            if (!defined($chkrec)){
               my $newrec={};
               if (ref($param{onCreate}) eq "HASH"){
                  foreach my $k (keys(%{$param{onCreate}})){
                     $newrec->{$k}=$param{onCreate}->{$k};
                  }
               }
               $chkobj->ValidatedInsertRecord($newrec);
            }
         }
         $takeremote++;
      }
   }
   elsif ($param{mode} eq "integer"){  # like amounth of memory
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          $comprec->{$compfieldname}!=0 &&
          (!defined($origrec->{$origfieldname}) ||
           $origrec->{$origfieldname} ==0 ||
           $comprec->{$compfieldname} != $origrec->{$origfieldname})){
         if (defined($param{tolerance})){
            if ( ($comprec->{$compfieldname}*((100+$param{tolerance})/100.0)<
                  $origrec->{$origfieldname}) ||
                 ($comprec->{$compfieldname}*((100-$param{tolerance})/100.0)>
                  $origrec->{$origfieldname})){
               $takeremote++;
            }
         }
         else{
            $takeremote++;
         }
      }
   }
   if ($takeremote){
      if ((exists($origrec->{allowifupdate}) && $origrec->{allowifupdate}) ||
          !defined($origrec->{$origfieldname}) ||
          $origrec->{$origfieldname}=~m/^\s*$/){
         $forcedupd->{$origfieldname}=$comprec->{$compfieldname};
      }
      else{
         $wfrequest->{$origfieldname}=$comprec->{$compfieldname};
      }
   }
   

}

1;

