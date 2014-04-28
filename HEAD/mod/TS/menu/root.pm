package TS::menu::root;
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

   $self->RegisterObj("itts",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("itts.custcontract",
                      "itil::custcontract",
                      defaultacl=>['admin','valid_user']);
   
   $self->RegisterObj("itts.custcontract.new",
                      "itil::custcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.adv",
                      "TS::appladv",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.appl.nor",
                      "TS::applnor",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.custcontract.lnkappl",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.custcontract.lnkappl.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl",
                      "TS::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.appl.new",
                      "TS::appl",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.appl.lnksystem",
                      "itil::lnkapplsystem",
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.lnkapplappl",
                      "itil::lnkapplappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.appl.lnkapplappl.new",
                      "itil::lnkapplappl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.lnkcustcontract",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.appl.lnkcustcontract.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system",
                      "OSY::system",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.system.new",
                      "itil::system",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.software",
                      "itil::lnksoftwaresystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.ipaddress",
                      "itil::ipaddress",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.system.ipaddress.new",
                      "itil::ipaddress",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.system.dnsalias",
                      "itil::dnsalias",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.monipoint",
                      "itil::systemmonipoint",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.systemnfsnas",
                      "itil::systemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.systemnfsnas.new",
                      "itil::systemnfsnas",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.systemnfsnas.clients",
                      "itil::lnksystemnfsnas",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.system.lnksystemcontact",
                      "itil::lnksystemcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.asset",
                      "itil::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.asset.new",
                      "itil::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.itclust",
                      "itil::itclust",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.itclust.new",
                      "itil::itclust",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.itclust.lnkitclustsvc",
                      "itil::lnkitclustsvc",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.itclust.lnkitclustsvc.new",
                      "itil::lnkitclustsvc",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.itclust.lnkitclustsvc.appl",
                      "itil::lnkitclustsvcappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.swinstance",
                      "itil::swinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.swinstance.new",
                      "itil::swinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.swinstance.lnksystem",
                      "itil::lnkswinstancesystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.swinstance.lnkswinstancecontact",
                      "itil::lnkswinstancecontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern",
                      "tmpl/welcome");
   
   $self->RegisterObj("itts.kern.network",
                      "itil::network",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.network.new",
                      "itil::network",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.kern.osrelease",
                      "itil::osrelease",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.osrelease.new",
                      "itil::osrelease",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.platform",
                      "itil::platform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.platform.new",
                      "itil::platform",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.software",
                      "itil::software",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.software.new",
                      "itil::software",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.producer",
                      "itil::producer",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.producer.new",
                      "itil::producer",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.hwmodel",
                      "itil::hwmodel",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.hwmodel.new",
                      "itil::hwmodel",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.location",
                      "base::location",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("itts.kern.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.costcenter",
                      "TS::costcenter",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.costcenter.new",
                      "itil::costcenter",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.projectroom",
                      "OSY::projectroom",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.servicesupport",
                      "itil::servicesupport",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.kern.servicesupport.new",
                      "itil::servicesupport",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.proc",
                      "tmpl/welcome",
                      prio=>20000);

   $self->RegisterObj("itts.proc.ChangeManagement",
                      "TS::chmmgmt",
                      defaultacl=>['admin']);

   $self->RegisterObj("itts.kern.projectroom.new",
                      "OSY::projectroom",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itts.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.qmgmt.tsinterview",
                      "TS::interview",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.qmgmt.tsinterview.new",
                      "TS::interview",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.qmgmt.tsinterview.cat",
                      "base::interviewcat",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj('TS::MyW5Base::send2Miles$',
                      'TS::MyW5Base::send2Miles$',
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj("customerportal.cfmts",
                      "tmpl/welcome",
                      prio=>200,
                      defaultacl=>['admin']);

   $self->RegisterObj("customerportal.cfmts.appl",
                      "TS::custappl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("customerportal.cfmts.system",
                      "itcrm::custsystem",
                      defaultacl=>['valid_user']);

   return($self);
}



1;