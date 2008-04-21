package base::menu::default;
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

   $self->RegisterObj("",
                      "base::start");

   $self->RegisterObj("MyW5Base",
                      "base::MyW5Base",
                      prio=>'1',
                      func=>'Main',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm",
                      "tmpl/sysadm.welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv",
                      "base::user",
                      func=>'MyDetail',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.userenv.userview",
                      "base::userview",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.infoabo",
                      "base::infoabo",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.bookmarks",
                      "base::userbookmark",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.bookmarks.new",
                      "base::userbookmark",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.note",
                      "base::note",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user",
                      "base::user");
   
   $self->RegisterObj("sysadm.user.new",
                      "base::user",
                      func=>'New');
   
   $self->RegisterObj("sysadm.user.subst",
                      "base::usersubst",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.user.mailsig",
                      "base::mailsignatur",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.user.mailsig.new",
                      "base::mailsignatur",
                      defaultacl=>['admin'],
                      func=>'New');
   
   $self->RegisterObj("sysadm.user.userview",
                      "base::userview",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.infoabo",
                      "base::infoabo",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.infoabo.new",
                      "base::infoabo",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.lnkcontact",
                      "base::lnkcontact",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.useraccount",
                      "base::useraccount",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.useraccount.new",
                      "base::useraccount",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.useraccount.logon",
                      "base::userlogon",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.grp",
                      "base::grp");
   
   $self->RegisterObj("sysadm.grp.new",
                      "base::grp",
                      func=>'New');
   
   $self->RegisterObj("sysadm.grp.treecreate",
                      "base::grp",
                      func=>'TreeCreate');
   
   $self->RegisterObj("sysadm.grp.rel",
                      "base::lnkgrpuser",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.grp.rel.role",
                      "base::lnkgrpuserrole",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu",
                      "base::menu",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu.new",
                      "base::menu",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu.acl",
                      "base::menuacl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.mandator",
                      "base::mandator");
   
   $self->RegisterObj("sysadm.mandator.new",
                      "base::mandator",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location",
                      "base::location");
   
   $self->RegisterObj("sysadm.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.location.googlekeys",
                      "base::googlekeys",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.googlekeys.new",
                      "base::googlekeys",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools",
                      "tmpl/welcome",
                      param=>'MSG=Hallo%20dies%20ist%20die%20Nachricht',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.analytics",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.workflow",
                      "base::workflow",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.action",
                      "base::workflowaction",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.relation",
                      "base::workflowrelation",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.relation.new",
                      "base::workflowrelation",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.key",
                      "base::workflowkey",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.ws",
                      "base::workflowws",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.ws.new",
                      "base::workflowws",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflownew",
                      "base::workflow",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.projectroom",
                      "base::projectroom",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.projectroom.new",
                      "base::projectroom",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.filemgmt",
                      "base::filemgmt",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.filemgmt.new",
                      "base::filemgmt",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.filebrowser",
                      "base::filemgmt",
                      func=>'browser');
   
   $self->RegisterObj("sysadm.qmgmt",
                      "tmpl/welcome.qmgmt",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.qmgmt.qrule",
                      "base::qrule",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.qmgmt.qrule.lnkmandator",
                      "base::lnkqrulemandator",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.qmgmt.qrule.lnkmandator.new",
                      "base::lnkqrulemandator",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.reflexion",
                      "tmpl/welcome.reflexion",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.reflexion.w5stat",
                      "base::w5stat",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.reflexion.fields",
                      "base::reflexion_fields",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.reflexion.translation",
                      "base::reflexion_translation",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.XLSExpand",
                      "base::XLSExpand",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.joblog",
                      "base::joblog",
                      defaultacl=>['admin']);
   
   $self->RegisterObj('base::workflow::interflow$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=base::workflow::interflow',
                      defaultacl=>['admin']);

   $self->RegisterObj('base::workflow::diary$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=base::workflow::diary',
                      defaultacl=>['admin']);

   return(1);
}



1;
