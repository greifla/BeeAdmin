package kernel::cgi;
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
use kernel::cgi;
use Data::Dumper;
use CGI(qw(-oldstyle_urls));

sub new
{
   my $type=shift;
   my $self={};
   if ($ENV{REQUEST_METHOD} ne "GET" &&
       $ENV{REQUEST_METHOD} ne "POST"){
      $self->{'cgi'}=new CGI({});
   }
   else{
      if ( $ENV{QUERY_STRING} ne "MOD=base::interface&FUNC=SOAP" &&
           $ENV{QUERY_STRING} ne "FUNC=SOAP&MOD=base::interface"){
         if ($#_==-1 && defined($W5V2::CurrentFastCGIRequest)){
            $self->{'cgi'}=$W5V2::CurrentFastCGIRequest;
         }
         else{
            $self->{'cgi'}=new CGI(@_);
         }
      }
      else{
         $self->{'cgi'}=new CGI({MOD=>'base::interface',FUNC=>'SOAP'});
      }
   }
   $self=bless($self,$type);
   #
   # Using full QUERY_STRING in POST Request did get problems in situations
   # where forms get default values on open by passing query_strings
   #
   if ($ENV{REQUEST_METHOD} eq "POST" && $ENV{QUERY_STRING} ne "" && $#_==-1){
      my $tmpcgi=new CGI($ENV{QUERY_STRING});
      foreach my $v ($tmpcgi->param()){
         next if (!($v=~m/^(MOD|FUNC|callback)$/));
         my @val=( $tmpcgi->can('multi_param') ?
                   $tmpcgi->multi_param($v):
                   $tmpcgi->param($v));

         $#val==0 ? $self->{'cgi'}->param(-name=>$v,-value=>$val[0]):
                    $self->{'cgi'}->param(-name=>$v,-value=>\@val);
      }
   }
 
   return($self);
}

sub UploadInfo
{
   my $self=shift;
   my $name=shift;
   return($self->{cgi}->uploadInfo($name));
}

sub Param
{
   my $self=shift;
   if (defined($_[1])){
      return($self->{'cgi'}->param(-name=>$_[0],-value=>$_[1]));
   }
   if ($#_==0 && wantarray()){
      return($self->{'cgi'}->can('multi_param') ?
             $self->{'cgi'}->multi_param($_[0]):
             $self->{'cgi'}->param($_[0]));
   }
   return($self->{'cgi'}->param(@_));
}


sub QueryString
{
   my $self=shift;
   return($self->{'cgi'}->query_string());
}

sub Cookie
{
   my $self=shift;

   return($self->{'cgi'}->cookie(@_));
}

sub Header
{
   my $self=shift;

   return($self->{'cgi'}->header(@_));
}

sub Delete
{
   my $self=shift;

   return($self->{'cgi'}->delete(@_));
}

sub Reset
{
   my $self=shift;
   foreach my $v ($self->{'cgi'}->param()){
      $self->Delete($v);
   }
}


sub UrlParam
{
   my $self=shift;

   return($self->{'cgi'}->url_param(@_));
}

sub MultiVars
{
   my $self=shift;
   my %h=();

   foreach my $v ($self->{'cgi'}->param()){
      my @val=$self->{'cgi'}->can('multi_param') ?
              $self->{'cgi'}->multi_param($v):
              $self->{'cgi'}->param($v);
      if ($#val==0){
         $h{$v}=$val[0];
         $h{$v}=~s/&quote;/"/g;
      }
      else{
         map({$_=~s/&quote;/"/g;} @val);
         $h{$v}=\@val;
      }
   }

   if (wantarray()){
      return(%h);
   }
   return(\%h);
}

sub Dumper
{
   my $self=shift;
   my %q=$self->MultiVars();
   return(Data::Dumper::Dumper(\%q));
}

sub Hash2QueryString
{
   my %hash=@_;
   %hash=%{$_[0]} if (ref($_[0]) eq "HASH");
   my $q=new CGI({});
   foreach my $v (keys(%hash)){
      $q->param(-name=>$v,-value=>$hash{$v});
   }
   my $str=$q->query_string();
   $str=~s/;/&/g;
   return($str);
}




1;
