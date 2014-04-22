package AL_TCom::itschain;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}=[qw(insert modify delete)];

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'its_name',
                readonly      =>1,
                label         =>'IT-Service Name',
                dataobjattr   =>"its.name",
                depend        =>['its_id'],
                onClick       =>\&multiDestLinkHandler,
                weblinkto     =>'AL_TCom::businessserviceITS',
                weblinkon     =>['its_id']),

      new kernel::Field::Text(
                name          =>'es_name',
                readonly      =>1,
                label         =>'Enabling-Service Name',
                dataobjattr   =>"es.name",
                depend        =>['es_id'],
                onClick       =>\&multiDestLinkHandler,
                weblinkto     =>'AL_TCom::businessserviceES',
                weblinkon     =>['es_id']),

      new kernel::Field::Text(
                name          =>'ta_name',
                readonly      =>1,
                label         =>'Transaction Name',
                dataobjattr   =>"ta.name",
                depend        =>['ta_id'],
                onClick       =>\&multiDestLinkHandler,
                weblinkto     =>'AL_TCom::businessserviceTA',
                weblinkon     =>['ta_id']),

      new kernel::Field::Text(
                name          =>'appl_name',
                readonly      =>1,
                label         =>'Application Name',
                dataobjattr   =>"appl.name",
                depend        =>['appl_id'],
                onClick       =>\&multiDestLinkHandler,
                weblinkto     =>'AL_TCom::appl',
                weblinkon     =>['appl_id']),

      new kernel::Field::Text(
                name          =>'its_id',
                readonly      =>1,
                label         =>'IT-Service W5BaseID',
                dataobjattr   =>"its.id"),

      new kernel::Field::Text(
                name          =>'es_id',
                readonly      =>1,
                label         =>'Enabling-Service W5BaseID',
                dataobjattr   =>"es.id"),

      new kernel::Field::Text(
                name          =>'ta_id',
                readonly      =>1,
                label         =>'Transaction W5BaseID',
                dataobjattr   =>"ta.id"),

      new kernel::Field::Text(
                name          =>'appl_id',
                readonly      =>1,
                label         =>'Application W5BaseID',
                dataobjattr   =>"appl.id"),


   );
   $self->setDefaultView(qw(linenumber
                            its_name 
                            es_name 
                            ta_name 
                            appl_name));
   return($self);
}

sub multiDestLinkHandler
{
   my $self=shift;
   my $output=shift;
   my $app=shift;
   my $current=shift;
   my $id=$current->{$self->{weblinkon}->[0]};
   my $lineonclick;

   if ($id ne ""){
      my $detailx=$app->DetailX();
      my $detaily=$app->DetailY();
      my $UserCache=$self->getParent->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      my $winsize="normal";
      if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
         $winsize=$UserCache->{winsize};
      }
      my $dest="../../".$self->{weblinkto}."/ById/".$id;
      $dest=~s/::/\//g;
      if ($dest ne ""){
         $lineonclick="custopenwin(\"$dest\",\"$winsize\",".
                      "$detailx,$detaily)";
      }
   }
   return($lineonclick);
}




#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_applcistatus"))){
#     Query->Param("search_applcistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#   if (!defined(Query->Param("search_managed"))){
#     Query->Param("search_managed"=>$self->T("yes"));
#   }
#}







sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   my @view=$self->getCurrentView();
   print STDERR Dumper(\@view);

   $from.="businessservice as its ";

   if (grep(/^(es_|ta_|appl_)/,@view)){
      $from.="left outer join lnkbscomp as lnkits ".
             "  on its.id=lnkits.businessservice ".
             "     and lnkits.objtype='itil::businessservice' ".
             "left outer join businessservice as es ".
             "  on lnkits.obj1id=es.id ";
      if (grep(/^(ta_|appl_)/,@view)){
         $from.="left outer join lnkbscomp as lnkes ".
                "  on es.id=lnkes.businessservice ".
                "     and lnkes.objtype='itil::businessservice' ".
                "left outer join businessservice as ta ".
                "  on lnkes.obj1id=ta.id ";
         if (grep(/^(appl_)/,@view)){
            $from.="left outer join lnkbscomp as lnkta ".
                   "  on ta.id=lnkta.businessservice ".
                   "     and lnkes.objtype='itil::businessservice' ".
                   "left outer join appl".
                   "  on lnkta.obj1id=appl.id ";
         }
      }
   }




   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $where="its.nature='IT-S'";
   return($where);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

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
   my @l=$self->SUPER::isWriteValid($rec);
   return("default","meetings","processcheck","addcontacts",
          "checklist") if (in_array(\@l,"ALL"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default aeg addcontacts 
             meetings processcheck checklist source));
}




1;
