package base::lnkgrpuserrole;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(       name   =>'roleid',
                                   label  =>'RoleId',
                                   size   =>'10',
                                   dataobjattr=>
                                         'lnkgrpuserrole.lnkgrpuserroleid'),

      new kernel::Field::Text(     name       =>'userfullname',
                                   label      =>'UserFullname',
                                   readonly   =>1,
                                   dataobjattr=>'user.fullname'),

      new kernel::Field::Link(     name       =>'userid',
                                   label      =>'UserID',
                                   readonly   =>1,
                                   dataobjattr=>'user.userid'),

      new kernel::Field::Text(     name       =>'grpfullname',
                                   label      =>'GrpFullname',
                                   weblinkto  =>'base::grp',
                                   weblinkon  =>['grpid'=>'grpid'],
                                   readonly   =>1,
                                   dataobjattr=>'grp.fullname'),

      new kernel::Field::Link(     name       =>'grpid',
                                   dataobjattr=>'grp.grpid'),

      new kernel::Field::Text(     name       =>'lnkgrpuserid',
                                   label      =>'LinkId',
                                   weblinkto  =>'base::lnkgrpuser',
                                   weblinkon  =>['lnkgrpuserid'=>
                                                 'lnkgrpuserid'],
                                   dataobjattr=>'lnkgrpuserrole.lnkgrpuserid'),

      new kernel::Field::Select(   name       =>'role',
                                   label      =>'Role',
                                   value      =>['RMember','REmployee',
                                                 'RAdmin','RDataAdmin', 
                                                 'RReportReceive','RBoss',
                                                 'RBoss2','RQManager',
                                                 'RINManager','RCHManager',
                                                 'RCFManager','RTimeManager'],
                                   dataobjattr=>'lnkgrpuserrole.role'),
      new kernel::Field::CDate(    name       =>'cdate',
                                   label      =>'Creation-Date',
                                   dataobjattr=>'lnkgrpuserrole.createdate'),
                                  
      new kernel::Field::Editor(   name       =>'editor',
                                   label      =>'Editor',
                                   dataobjattr=>'lnkgrpuserrole.editor'),

      new kernel::Field::RealEditor(name      =>'realeditor',
                                   label      =>'RealEditor',
                                   dataobjattr=>'lnkgrpuserrole.realeditor'),

   );
   $self->setDefaultView(qw(roleid userfullname grpfullname role editor cdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("lnkgrpuserrole");
   return(1);
}




sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join lnkgrpuser ".
          "on $worktable.lnkgrpuserid=lnkgrpuser.lnkgrpuserid ".
          "left outer join user ".
          "on lnkgrpuser.userid=user.userid ".
          "left outer join grp ".
          "on lnkgrpuser.grpid=grp.grpid ");
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{lnkgrpuserid})) ||
       (defined($newrec->{lnkgrpuserid}) && $newrec->{lnkgrpuserid}==0)){
      $self->LastMsg(ERROR,"invalid lnkid specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{role})) ||
       (defined($newrec->{role}) && $newrec->{role} eq "")){
      $self->LastMsg(ERROR,"invalid role specified");
      return(undef);
   }
   return(1);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateUserCache();
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);
   $self->InvalidateUserCache();
   return($bak);
}
   


1;
