package tssc::event::scincident;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
use kernel;
use kernel::Event;
use tssc::lib::io;
@ISA=qw(kernel::Event tssc::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("scincident","scincident",timeout=>1200);
}

sub scincident
{
   my $self=shift;
   my %param=@_;

   $self->InitScImportEnviroment();
   my $selfname=$self->Self();
   my $inm=getModuleObject($self->Config,"tssc::inm");
   msg(DEBUG,"ServiceCenter inm is connected");
   $inm->SetCurrentView(qw(closetime incidentnumber name description status 
                           hassignment iassignment priority causecode reason
                           downtimestart downtimeend opentime 
                           workstart workend resolution custapplication
                           softwareid deviceid reportedby
                           action sysmodtime involvedassignment));
   my $focus="now";
   my %flt=(closetime=>"\">$focus-24h\"");
   if (!defined($param{incidentnumber}) && !defined($param{closetime}) &&
       !defined($param{downtimeend})){
      $self->{wf}->SetFilter(srcsys=>\$selfname,srcload=>">now-3d");
      $self->{wf}->SetCurrentView(qw(srcload));
      msg(DEBUG,"finding last srcload");
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(srcload));
      if (defined($wfrec)){
         $focus=$wfrec->{srcload};
         %flt=(closetime=>"\">$focus-4m\"");
      }
   }
   else{
      if (defined($param{downtimeend})){
         %flt=(downtimeend=>$param{downtimeend});
      }
      if (defined($param{incidentnumber})){
         %flt=(incidentnumber=>\$param{incidentnumber});
      }
      if (defined($param{closetime})){
         %flt=(closetime=>$param{closetime});
      }
   }
   msg(DEBUG,"filter=%s",Dumper(\%flt));
   $inm->SetFilter(\%flt);
   my ($rec,$msg)=$inm->getFirst();
   if (defined($rec)){
      READLOOP: do{
         if ($self->ServerGoesDown()){
            last READLOOP;
         }
         if ((!$inm->Ping()) || (!$self->{wf}->Ping())){
            my $msg="database connection aborted";
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>2,msg=>$msg});
         }
         $self->ProcessServiceCenterRecord($selfname,$rec,$inm);
         ($rec,$msg)=$inm->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec));
   }
   if (defined($msg)){
      msg(ERROR,"db init problem: %s",$msg);
      return({exitcode=>1});
   }

   return({exitcode=>0,msg=>'OK'}); 
}


1;
