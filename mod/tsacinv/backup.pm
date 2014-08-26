package tsacinv::backup;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'BackupID',
                htmldetail    =>0,
                align         =>'left',
                dataobjattr   =>'amtsibackup.lbackupid'),

      new kernel::Field::Text(
                name          =>'backupid',
                label         =>'BackupID',
                dataobjattr   =>'amtsibackup.code'),

      new kernel::Field::Select(
                name          =>'stype',
                htmldetail    =>0,
                label         =>'Typ',
                transprefix   =>'SBACKTYP.', 
                dataobjattr   =>'amtsibackup.setype'),

      new kernel::Field::Select(
                name          =>'type',
                label         =>'Type',
                transprefix   =>'BACKTYP.', 
                dataobjattr   =>'amtsibackup.setype'),

      new kernel::Field::Interface(
                name          =>'typeid',
                label         =>'TypeID',
                dataobjattr   =>'amtsibackup.setype'),

      new kernel::Field::Text(
                name          =>'subtype',
                label         =>'Subtype',
                dataobjattr   =>'amtsibackup.subtype'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'amtsibackup.backupservice'),

      new kernel::Field::Text(
                name          =>'bgroup',
                label         =>'Group',
                dataobjattr   =>'amtsibackup.groupname'),

      new kernel::Field::Text(
                name          =>'hexpectedquantity',
                label         =>'expectedquantity',
                dataobjattr   =>"concat(amtsibackup.expectedquantity,".
                                "concat(' ',amtsibackup.quantityunit))"),

      new kernel::Field::Text(
                name          =>'tfrom',
                group         =>'timeframe',
                label         =>'from',
                dataobjattr   =>'amtsibackup.savetimeframefrom'),

      new kernel::Field::Text(
                name          =>'tto',
                group         =>'timeframe',
                label         =>'to',
                dataobjattr   =>'amtsibackup.savetimeframeto'),


      new kernel::Field::Text(
                name          =>'dbtype',
                group         =>'dbbackup',
                label         =>'DBType',
                dataobjattr   =>'amtsibackup.dbtype'),

      new kernel::Field::Text(
                name          =>'policy',
                group         =>'dbbackup',
                label         =>'Policy',
                dataobjattr   =>'amtsibackup.policy'),

      new kernel::Field::Text(
                name          =>'dbinstance',
                group         =>'dbbackup',
                label         =>'Instance',
                dataobjattr   =>'amtsibackup.dbinstance'),


      new kernel::Field::Boolean(
                name          =>'isactive',
                label         =>'Active',
                dataobjattr   =>'amtsibackup.bactive'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'Computerid',
                dataobjattr   =>'amtsibackup.lcomputerid'),

   );
   $self->setDefaultView(qw(linenumber backupid type
                            subtype name bgroup));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/service.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsibackup";
 #           "(select amitemlistval.value,".
 #           "amitemlistval.litemlistvalid from amitemizedlist,amitemlistval ".
 #           "where amitemizedlist.litemlistid=amitemlistval.litemlistid and ".
 #           "amitemizedlist.identifier='TSI_amTsiBackup_DBType') dbtypelist";


   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
             #"amtsibackup.dbtype=dbtypelist.litemlistvalid and ".
             "amtsibackup.bdelete=0 ";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @all=qw(default header source);
   push(@all,"dbbackup") if ($rec->{type} eq "1");
   push(@all,"timeframe") if ( ($rec->{tfrom} ne "NA" && $rec->{tfrom} ne "") 
                              || ($rec->{tto} ne "NA" && $rec->{tto} ne ""));
   return(@all);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
