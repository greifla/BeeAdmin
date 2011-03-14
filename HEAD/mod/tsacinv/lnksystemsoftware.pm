package tsacinv::lnksystemsoftware;

#
# Diese Module ist noch nicht fertig - ich begreife da einfach nicht
# die Strukturen von AC
#
#
#

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
                htmlwidth     =>'60px',
                label         =>'SW-Install-ID',
                dataobjattr   =>"amportfolio.assettag"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Software',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'ammodel.name'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                uppersearch   =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lparentid'=>'lportfolioitemid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::TextDrop(
                name          =>'systemid',
                label         =>'SystemID',
                uppersearch   =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lparentid'=>'lportfolioitemid'],
                vjoindisp     =>'systemid'),

      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                label         =>'Quantity',
                dataobjattr   =>'amsoftinstall.lusecount'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                dataobjattr   =>'amsoftinstall.versionlevel'),

      new kernel::Field::Text(
                name          =>'instpath',
                label         =>'Folder',
                dataobjattr   =>'amsoftinstall.folder'),

      new kernel::Field::TextDrop(
                name          =>'license',
                label         =>'License',
                uppersearch   =>1,
                vjointo       =>'tsacinv::license',
                vjoinon       =>['llicense'=>'lportfolioitemid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lparentid',
                label         =>'ParentID',
                dataobjattr   =>'amportfolio.lparentid'),

      new kernel::Field::Text(
                name          =>'llicense',
                label         =>'LicenseID',
                dataobjattr   =>'amsoftinstall.llicenseid'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'amportfolio.dtcreation'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amsoftinstall.dtlastmodif'),
   );
   $self->setDefaultView(qw(id model system license quantity));
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
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from="amportfolio,ammodel,amnature,amsoftinstall";
   return($from);
}  

sub initSqlWhere
{  
   my $self=shift;
   my $where=
      "amportfolio.lportfolioitemid=amsoftinstall.litemid ".
      "and amportfolio.lmodelid=ammodel.lmodelid ".
      "and ammodel.lnatureid=amnature.lnatureid(+) ".
      "and amnature.name='SW-INSTALLATION' ".
      "and amportfolio.bdelete=0 ";
   return($where);
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
   return(undef);
}


1;
