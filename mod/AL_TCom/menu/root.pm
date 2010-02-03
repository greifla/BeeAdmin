package AL_TCom::menu::root;
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
use kernel;
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

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

   $self->RegisterObj('AL_TCom::workflow::diary$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=AL_TCom::workflow::diary',
                      defaultacl=>['admin']);

   $self->RegisterObj('AL_TCom::workflow::fastdiary$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=AL_TCom::workflow::fastdiary',
                      defaultacl=>['admin']);

   $self->RegisterObj('base::MyW5Base::myP800$',  # virtureller Eintrag f�r
                      'base::MyW5Base::myP800$',  # MyW5Base
                      func=>'Main',
                      defaultacl=>['DTAG.TSI.ICTO.CSS.AO.DTAG',
                                   'DTAG.TSI.SSM']);

   $self->RegisterObj('AL_TCom::MyW5Base::ChangeFuture$',
                      'AL_TCom::MyW5Base::ChangeFuture$',
                      func=>'Main',
                      defaultacl=>['admin','DTAG.TSI.ICTO.CSS.AO.DTAG']);

   $self->RegisterObj("AL_TCom",
                      "tmpl/welcome",
                      defaultacl=>['admin','DTAG.TSI.ICTO.CSS.AO.DTAG']);
   
   $self->RegisterObj("AL_TCom.custcontract",
                      "AL_TCom::custcontract",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.custcontract.new",
                      "AL_TCom::custcontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.custcontract.lnkappl",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.custcontract.lnkappl.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl",
                      "AL_TCom::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.appl.new",
                      "AL_TCom::appl",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplappl",
                      "itil::lnkapplappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplappl.new",
                      "itil::lnkapplappl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnkcustcontract",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnkcustcontract.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.prio",
                      "TS::topappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplinteranswer",
                      "itil::lnkapplinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust",
                      "AL_TCom::itclust",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.itclust.new",
                      "AL_TCom::itclust",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system",
                      "AL_TCom::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.system.new",
                      "AL_TCom::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.system.systemnfsnas",
                      "itil::systemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.systemnfsnas.new",
                      "itil::systemnfsnas",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.systemnfsnas.clients",
                      "itil::lnksystemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.systemnfsnas.ipclients",
                      "itil::lnknfsnasipnet",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.software",
                      "itil::lnksoftwaresystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.lnksysteminteranswer",
                      "itil::lnksysteminteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset",
                      "AL_TCom::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.asset.new",
                      "AL_TCom::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance",
                      "itil::swinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.new",
                      "itil::swinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.lnksystem",
                      "itil::lnkswinstancesystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.lnkswinstancecontact",
                      "itil::lnkswinstancecontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("AL_TCom.kern.network",
                      "itil::network",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.network.new",
                      "itil::network",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.platform",
                      "itil::platform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.platform.new",
                      "itil::platform",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.costcenter",
                      "itil::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.costcenter.new",
                      "itil::costcenter",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.hwmodel.new",
                      "itil::hwmodel",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.servicesupport",
                      "itil::servicesupport",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.servicesupport.new",
                      "itil::servicesupport",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.location",
                      "base::location",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.bp",
                      "itil::businessprocess",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.bp.new",
                      "itil::businessprocess",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc",
                      "tmpl/welcome",
                      prio=>20000);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement",
                      "TS::chmmgmt",
                      defaultacl=>['admin']);

   $self->RegisterObj('AL_TCom::workflow::eventnotify$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=AL_TCom::workflow::eventnotify',
                      defaultacl=>['admin']);

   $self->RegisterObj('AL_TCom::workflow::businesreq$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=AL_TCom::workflow::businesreq',
                      defaultacl=>['DTAG.TSI']);

   return(1);
}



1;
