package tsacinv::location;
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
use kernel::Field::OSMap;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   sub AddressBuild{
      my $self=shift;
      my $current=shift;
      my $a="";
      $a.=" ".$current->{country};
      $a.=" ".$current->{zipcode};
      $a.=" ".$current->{location};
      $a.=" ".$current->{address1};
      return($a);
   }

   
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                  label      =>'No.'),


      new kernel::Field::Id(      name       =>'code',
                                  label      =>'Code',
                                  dataobjattr  =>'amlocation.barcode'),

      new kernel::Field::Id(      name       =>'locationid',
                                  label      =>'LocationID',
                                  dataobjattr  =>'amlocation.llocaid'),

      new kernel::Field::Text(    name       =>'fullname',
                                  label      =>'Fullname',
                                  ignorecase =>1,
                                  dataobjattr     =>'amlocation.fullname'),

      new kernel::Field::Text(    name       =>'address1',
                                  label      =>'Street',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.address1'),

      new kernel::Field::Text(    name       =>'zipcode',
                                  label      =>'ZIP',
                                  dataobjattr=>'amlocation.zip'),

      new kernel::Field::Text(    name       =>'country',
                                  label      =>'Country',
                                  ignorecase =>1,
                                  dataobjattr=>'amcountry.isocode'),

      new kernel::Field::Text(    name       =>'location',
                                  label      =>'Location',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.city'),

      new kernel::Field::Text(    name       =>'locationtype',
                                  label      =>'Location Type',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.locationtype'),

      new kernel::Field::Text(    name       =>'name',
                                  label      =>'Name',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.name'),

      new kernel::Field::OSMap(
                name          =>'osmap',
                uploadable    =>0,
                searchable    =>0,
                group         =>'map',
                htmlwidth     =>'500px',
                label         =>'OpenStreetMap',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location']),


      new kernel::Field::Text(
                name          =>'w5locid',
                label         =>'W5Base Location ID',
                group         =>'w5baselocation',
                searchable    =>0,
                depend        =>[qw(location address1 country zipcode)],
                onRawValue    =>\&findW5LocID),

      new kernel::Field::TextDrop(
                name          =>'w5location',
                group         =>'w5baselocation',
                label         =>'W5Base Location',
                vjointo       =>'base::location',
                vjoindisp     =>'name',
                vjoinon       =>['w5locid'=>'id'],
                searchable    =>0),

   );
   $self->setDefaultView(qw(linenumber code locationid fullname 
                             zipcode location address1));
   $self->{MainSearchFieldLines}=4;
   return($self);
}

sub findW5LocID
{
   my $self=shift;
   my $current=shift;

   my $loc=getModuleObject($self->getParent->Config,"base::location");
   my $address1=$self->getParent->getField("address1")->RawValue($current);
   my $location=$self->getParent->getField("location")->RawValue($current);
   my $zipcode=$self->getParent->getField("zipcode")->RawValue($current);
   my $country=$self->getParent->getField("country")->RawValue($current);
   my $newrec;
   $newrec->{country}=$country;
   $newrec->{location}=$location;
   $newrec->{address1}=$address1;
   $newrec->{zipcode}=$zipcode;
   $newrec->{cistatusid}="4";

   $loc->Normalize($newrec);

   foreach my $k (keys(%$newrec)){
      delete($newrec->{$k}) if (!defined($newrec->{$k}));
   }
   #printf STDERR ("fifi newrec=%s\n",Dumper($newrec));
   my $d;
   my @locid=$loc->getIdByHashIOMapped($self->getParent->Self,$newrec,
                                       DEBUG=>\$d,
                                       ForceLikeSearch=>1);

   if ($#locid!=-1){
      return(\@locid);
   }
   else{
      return($d);
   }
   return(undef);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="amlocation, amcountry";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amlocation.lcountryid=amcountry.lcountryid(+) ";
   return($where);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/location.jpg?".$cgi->query_string());
}
         

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("amlocation");
   return(1) if (defined($self->{DB}));
   return(0);
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
