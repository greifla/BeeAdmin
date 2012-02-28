package itil::lnksysteminteranswer;
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
use vars qw(@ISA $VERSION $DESCRIPTION);
use kernel;
use base::interanswer;
@ISA=qw(base::interanswer);

           

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'systemidname',
                htmlwidth     =>'100px',
                readonly      =>1,
                label         =>'SystemID',
                vjointo       =>'itil::system',
                vjoinon       =>['parentid'=>'id'],
                uploadable    =>0,
                vjoindisp     =>'name',
                dataobjattr   =>'system.systemid'),
      insertafter=>'id'
   );
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'parentname',
                htmlwidth     =>'100px',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),
      insertafter=>'id'
   );
   $self->AddFields(
      new kernel::Field::Import( $self,
                vjointo       =>'itil::system',
                group         =>'relation',
                dontrename    =>1,
                fields        =>[qw(adminteam adminteamid 
                                    mandator mandatorid
                                    )]),
      insertafter=>'parentname'
   );

   $self->getField("parentobj")->{searchable}=0;
   $self->getField("parentid")->{searchable}=0;
   $self->{secparentobj}='itil::system';
   $self->setDefaultView(qw(parentname mandator relevant 
                            name answer mdate editor));
   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
                          "RMember")){
      my %g=$self->getGroupsOf($ENV{REMOTE_USER},
                               [qw(RCFManager RCFManager2 RAuditor RQManager)],
                               'down');
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my @secflt=({mandatorid=>\@mandators});
      if (keys(%g)){
         push(@secflt,{mandatorid=>[keys(%g)]});
      }
      push(@flt,\@secflt);
   }
   return($self->SetFilter(@flt));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL"); 
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $secobj=$self->{secparentobj};

   return("system left outer join $worktable ".
          "on $worktable.parentobj='$secobj' and ".
          "$worktable.parentid=system.id ".
          "left outer join interview ".
          "on $worktable.interviewid=interview.id ");
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="(system.cistatus<=5 and system.cistatus>=3)";
   return($where);
}




1;
