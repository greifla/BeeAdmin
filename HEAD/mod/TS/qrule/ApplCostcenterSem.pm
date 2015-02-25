package TS::qrule::ApplCostcenterSem;
#######################################################################
=pod

=head3 PURPOSE

Checks if the given costcenter is valid in AssetManager.
If not, an error will be procceded.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The given costcenter has no servicemanager entry in AssetManager.

This can result in "marking as delete" the application in AssetManager, involving
that the application is no more selectable in the process supporting tools.

Please check if the given costcenter is correct.
If so, the entry in SAP P01 should be checked.

Responsible to maintenance this record in SAP P01 is the databoss of the costcenter.

[de:]

Das angegebene Kontierungsobjekt enth�lt keinen 
Servicemanager-Eintrag in AssetManager.

Das kann dazu f�hren, dass die Anwendung in AssetManager als "deleted" markiert 
wird, was z.B. zur Folge hat, dass sie in prozessunterst�tzenden Tools nicht 
mehr als ConfigItem ausw�hlbar ist.

Bitte pr�fen, ob das Kontierungsobjekt korrekt angegeben wurde.
Wenn ja, sollte der Eintrag in SAP P01 �berpr�ft werden.

Zust�ndig f�r die Pflege dieses Datensatzes in SAP P01 ist der
Datenverantwortliche des Kontierungsobjektes.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=3 && 
                       $rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=5);

   my $amcoc=getModuleObject($self->getParent->Config,"tsacinv::costcenter");
   $amcoc->SetFilter({name=>$rec->{conodenumber}});
  
   if ($amcoc->getVal('sem') eq '') {
      return(3,{qmsg     =>['no servicemanager entry in AssetManager'],
                dataissue=>['no servicemanager entry in AssetManager']});
   }

   return(0,undef);
}



1;
