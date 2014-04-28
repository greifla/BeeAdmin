package AL_TCom::businessservice;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use itil::businessservice;
@ISA=qw(itil::businessservice);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->getField("application")->{weblinkto}="AL_TCom::appl";
   $self->getField("srcapplication")->{vjointo}="AL_TCom::appl";

   $self->AddFields(
      new kernel::Field::Contact(
                name          =>'requestor',
                group         =>'contactpersons',
                label         =>'Requestor',
                readonly      =>1,
                vjoinon       =>'requestorid'),
      new kernel::Field::Link(
                name          =>'requestorid',
                group         =>'contactpersons',
                label         =>'Requestor',
                readonly      =>1,
                dataobjattr   =>"(select targetid from lnkcontact where ".
                   " lnkcontact.refid=businessservice.id and ".
                   " lnkcontact.target='base::user' and ".
                   " lnkcontact.parentobj='itil::businessservice' and ".
                   " croles like '%roles=\\'requestor\\'=roles%'".
                   " limit 1)"),
      new kernel::Field::Contact(
                name          =>'itsowner',
                group         =>'contactpersons',
                label         =>'IT-Service Owner',
                readonly      =>1,
                vjoinon       =>'funcmgrid'),
   );
   $self->AddGroup("contactpersons",translation=>'AL_TCom::businessservice');

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'sdbid',
                searchable    =>0,
                group         =>'desc',
                label         =>'SDB-ID',
                container     =>'additional'),
      insertafter=>['description']
   );





   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   if (exists($newrec->{sdbid})){
      if ($newrec->{sdbid} ne ""){
         $newrec->{srcsys}="SDB";
         $newrec->{srcid}=$newrec->{sdbid};
         $newrec->{srcload}=NowStamp("en");
      }
      else{
         $newrec->{srcsys}="w5base";
         $newrec->{srcid}=undef;
         $newrec->{srcload}=undef;
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));

}



sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "desc");
   }
   splice(@l,$inserti,$#l-$inserti,("contactpersons",@l[$inserti..($#l+-1)]));
   return(@l);

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,["desc","ALL"])){
      push(@l,"contactpersons");
   }

   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isWriteValid($rec);

   #if (in_array(\@l,["desc","ALL"])){
   #   push(@l,"contactpersons");
   #}

   return(@l);
}









1;