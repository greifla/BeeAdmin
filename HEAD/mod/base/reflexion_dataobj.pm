package base::reflexion_dataobj;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

$VERSION="1.0";
$DESCRIPTION=<<EOF;
Represend all existing dataobject in current
running W5Base application.

To see VERSION and DESCRIPTION, there are need to be the
variables \$VERSION and \$DESCRIPTION in the programmcode.
If not, VERSION=UNKNOWN and DESCRIPTION="??? Beta Module ???".

In the description can be also informations about access
rules and other security informations as documention from
the developer.
EOF


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
                name          =>'fullname',
                align         =>'left',
                label         =>'fullqualified object'),

      new kernel::Field::Text(
                name          =>'modnamelabel',
                label         =>'Dataobject Label'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description'),

   );
   $self->{'data'}=\&getData;



   $self->setDefaultView(qw(linenumber fullname  modnamelabel));
   return($self);
}

sub getData
{
   my $self=shift;
   my $c=$self->Context;
   if (!defined($c->{data})){
      my $instdir=$self->Config->Param("INSTDIR");
      msg(INFO,"recreate data on dir '%s'",$instdir);
      my $pat="$instdir/mod/*/*.pm";
      my @sublist=glob($pat);
      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$instdir//;
                    $_=~s/\/mod\///; $_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my @data=();
      foreach my $modname (@sublist){
         my $o=getModuleObject($self->Config,$modname);
         if (defined($o)){
            my %rec=();
            $rec{fullname}=$modname;
            $rec{modnamelabel}=$o->T($modname,$modname);
            if ($modname->can("VERSION")){
               $rec{version}=$modname->VERSION;
            }
            $rec{description}="\$${modname}::DESCRIPTION";
            $rec{description}=eval($rec{description});
            if ($rec{version} eq ""){
               $rec{version}="UNKNOWN";
            }
            if ($rec{description} eq ""){
               $rec{description}="??? Beta Module ???";
            }
            push(@data,\%rec);
         }
      }
      $c->{data}=\@data;
   }
   return($c->{data});
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
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