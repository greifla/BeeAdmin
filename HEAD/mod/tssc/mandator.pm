package tssc::mandator;
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
use kernel::Field;
use base::mandator;
@ISA=qw(base::mandator);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Textarea( name       =>'tsscchmfilter',
                                   label      =>'SC change base filter',
                                   group      =>'screlation',
                                   container  =>'additional'),
   );
   $self->setDefaultView(qw(id name tsscchmfilter));
   return($self);




   return($self);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec));
   my @l=$self->SUPER::isWriteValid($rec);
   if ($self->IsMemberOf("admin")){
      push(@l,"screlation");
      @l=grep(!/^default$/,@l);
      @l=grep(!/^contacts$/,@l);
   }
   return(@l);
}  
   
sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/mandator.jpg?".$cgi->query_string());
}
         



1;
