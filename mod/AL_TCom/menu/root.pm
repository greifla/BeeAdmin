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
                      defaultacl=>['admin']);

   $self->RegisterObj('base::MyW5Base::P800rawdata$',  # virtureller Eintrag f�r
                      'base::MyW5Base::P800rawdata$',  # MyW5Base
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj('AL_TCom::MyW5Base::ChangeFuture$',
                      'AL_TCom::MyW5Base::ChangeFuture$',
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj('AL_TCom::MyW5Base::MIReport$',
                      'AL_TCom::MyW5Base::MIReport$',
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("AL_TCom.custcontract",
                      "AL_TCom::custcontract",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.custcontract.new",
                      "AL_TCom::custcontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.custcontract.crono",
                      "itil::custcontractcrono",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.custcontract.lnkappl",
                      "itil::lnkapplcustcontract",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.custcontract.lnkappl.new",
                      "itil::lnkapplcustcontract",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.applgrp",
                      "AL_TCom::applgrp",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.applgrp.new",
                      "AL_TCom::applgrp",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.adv",
                      "TS::appladv",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.nor",
                      "TS::applnor",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl",
                      "AL_TCom::appl",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.appl.new",
                      "AL_TCom::appl",
                      func=>'New',
                      prio=>1,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplurl",
                      "itil::lnkapplurl",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplurl.new",
                      "itil::lnkapplurl",
                      prio=>1,
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.applwallet",
                      "itil::applwallet",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.applwallet.new",
                      "itil::applwallet",
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

   $self->RegisterObj("AL_TCom.appl.aegmgmt",
                      "AL_TCom::aegmgmt",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnksystem.new",
                      "itil::lnkapplsystem",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.appl.lnkapplcontact",
                      "itil::lnkapplcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.lnkapplinteranswer",
                      "itil::lnkapplinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.bs",
                      "itil::businessservice",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.bs.new",
                      "AL_TCom::businessservice",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.appl.bs.lnkcontact",
                      "itil::lnkbscontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust",
                      "AL_TCom::itclust",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.itclust.new",
                      "AL_TCom::itclust",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust.lnkitclustsvc",
                      "itil::lnkitclustsvc",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust.lnkitclustsvc.appl",
                      "itil::lnkitclustsvcappl",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust.lnkitclustsvc.sw",
                      "itil::lnksoftwareitclustsvc",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.itclust.lnkitclustcontact",
                      "itil::lnkitclustcontact",
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

   $self->RegisterObj("AL_TCom.system.dnsalias",
                      "itil::dnsalias",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

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

   $self->RegisterObj("AL_TCom.system.software.new",
                      "itil::lnksoftwaresystem",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.software.matrix",
                      "itil::systemsoftwarematrix",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.system.lnksysteminteranswer",
                      "itil::lnksysteminteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.signedfile",
                      "AL_TCom::signedfilesystem",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.system.monipoint",
                      "itil::systemmonipoint",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset",
                      "AL_TCom::asset",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.asset.new",
                      "AL_TCom::asset",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.core",
                      "itil::assetphyscore",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.cpu",
                      "itil::assetphyscpu",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.lnkassetcontact",
                      "itil::lnkassetcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.itfarm",
                      "AL_TCom::itfarm",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.itfarm.new",
                      "AL_TCom::itfarm",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.asset.itfarm.lnkitfarmasset",
                      "AL_TCom::lnkitfarmasset",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract",
                      "itil::liccontract",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract.new",
                      "itil::liccontract",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract.sys",
                      "itil::lnklicsystem",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.liccontract.appl",
                      "itil::lnklicappl",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance",
                      "TS::swinstance",
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

   $self->RegisterObj("AL_TCom.swinstance.param",
                      "itil::lnkswinstanceparam",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.lnkswinstance",
                      "itil::lnkswinstanceswinstance",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.lnkswinstance.new",
                      "itil::lnkswinstanceswinstance",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.swinstance.rule",
                      "itil::swinstancerule",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.swinstance.rule.new",
                      "itil::swinstancerule",
                      func=>'New',
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

   $self->RegisterObj("AL_TCom.kern.network.ipnet",
                      "itil::ipnet",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.network.ipnet.new",
                      "itil::ipnet",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
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

   $self->RegisterObj("AL_TCom.kern.software.lnkcontact",
                      "itil::lnksoftwarecontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.licproduct",
                      "itil::licproduct",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.licproduct.new",
                      "itil::licproduct",
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
                      "TS::costcenter",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.kern.costcenter.new",
                      "TS::costcenter",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.costcenter.contacts",
                      "finance::lnkcostcentercontact",
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
                      "AL_TCom::businessprocess",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.bp.new",
                      "AL_TCom::businessprocess",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.complexinfoabo",
                      "itil::complexinfoabo",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.interview",
                      "TS::interview",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.kern.autodisce",
                      "itil::autodiscengine",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.autodisce.map",
                      "itil::autodiscmap",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.autodisce.rec",
                      "itil::autodiscrec",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.kern.autodisce.virt",
                      "itil::autodiscvirt",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc",
                      "tmpl/welcome",
                      prio=>20000);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement",
                      "TS::chmmgmt",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement.mplan",
                      "AL_TCom::measureplan",
                      prio=>3,
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement.mplan.tspan",
                      "temporal::tspan",
                      prio=>3,
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement.mplan.tspan.new",
                      "temporal::tspan",
                      func=>'New',
                      prio=>10,
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement.Campus",
                      "TS::campus",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.ChangeManagement.Campus.new",
                      "TS::campus",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.softmgmt",
                      "itil::softwareset",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.softmgmt.analyse",
                      "itil::softwaresetanalyse",
                      defaultacl=>['admin']);

   $self->RegisterObj("AL_TCom.proc.softmgmt.software",
                      "itil::lnksoftwaresoftwareset",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.proc.mgmtitemgroup",
                      "itil::mgmtitemgroup",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.proc.licman",
                      "tmpl/welcome",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("AL_TCom.proc.licman.amtelitsys",
                      "AL_TCom::amtelitsys",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("AL_TCom.proc.mgmtitemgroup.new",
                      "itil::mgmtitemgroup",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.proc.mgmtitemgroup.lnkcigroup",
                      "itil::lnkmgmtitemgroup",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("AL_TCom.proc.mgmtitemgroup.lnkcontact",
                      "itil::lnkmgmtitemgroupcontact",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices",
                      "AL_TCom::itschain",
                      defaultacl=>['valid_user']);  # mu� noch admin  werden!
   
   $self->RegisterObj("itservices.bps",
                      "itil::businessprocess",
                      prio=>50,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.bps.acl",
                      "crm::businessprocessacl",
                      prio=>40,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.bps.lnkbs",
                      "itil::lnkbprocessbservice",
                      prio=>45,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.bps.new",
                      "itil::businessprocess",
                      func=>'New',
                      prio=>50,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.its",
                      "AL_TCom::businessserviceITS",
                      prio=>100,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.its.bscomp",
                      "itil::lnkbscomp");

   $self->RegisterObj("itservices.its.contact",
                      "itil::lnkbscontact");

   $self->RegisterObj("itservices.its.lnkgrp",
                      "itil::lnkbusinessservicegrp");

   $self->RegisterObj("itservices.ens",
                      "AL_TCom::businessserviceES",
                      prio=>150,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.ens.bscomp",
                      "itil::lnkbscomp");

   $self->RegisterObj("itservices.ens.contact",
                      "itil::lnkbscontact");

   $self->RegisterObj("itservices.ens.lnkgrp",
                      "itil::lnkbusinessservicegrp");

   $self->RegisterObj("itservices.ta",
                      "AL_TCom::businessserviceTA",
                      prio=>200,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("itservices.ta.bscomp",
                      "itil::lnkbscomp");

   $self->RegisterObj("itservices.ta.contact",
                      "itil::lnkbscontact");

   $self->RegisterObj("itservices.ta.lnkgrp",
                      "itil::lnkbusinessservicegrp");

   $self->RegisterObj("itservices.new",
                      "AL_TCom::businessservice",
                      prio=>1000,
                      func=>'New',
                      defaultacl=>['valid_user']);

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
