package kernel::ldapdriver;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use Net::LDAP;
use Unicode::Map8;
use Data::Dumper;
use Unicode::String qw(utf8 latin1);

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $name=shift;
   my $self=bless({},$type);

   $self->setParent($parent);
   $self->{ldapname}=$name;
   $self->{isConnected}=0;
   

   return($self);
}


sub Connect
{
   my $self=shift;
   my $ldapname=$self->{ldapname};
   my %p=();
  
  # if ($self->{isConnected}){
  #    return($self->{'ldap'});
  # }
   $p{ldapuser}=$self->getParent->Config->Param('DATAOBJUSER');
   $p{ldappass}=$self->getParent->Config->Param('DATAOBJPASS');
   $p{ldapserv}=$self->getParent->Config->Param('DATAOBJSERV');

   foreach my $v (qw(ldapuser ldappass ldapserv)){
      if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$ldapname}))){
         return(undef,
                msg(ERROR,"Connect(%s): essential information '%s' missing",
                    $ldapname,$v));
      }
      if (defined($p{$v}->{$ldapname}) && $p{$v}->{$ldapname} ne ""){
         $self->{$v}=$p{$v}->{$ldapname};
      }
   }
   if (!($self->{ldap}=Net::LDAP->new($self->{ldapserv},
                                      version=>'3',async=>0))){
      return(undef,msg(ERROR,"ldapbind '%s' while connect '%s'",
             $@,$self->{ldapserv}));
   }
   $self->{ldap}->bind($self->{ldapuser},password =>$self->{ldappass});


   if (!$self->{'ldap'}){
      return(undef,msg(ERROR,"Connect(%s): LDAP '%s'",$ldapname,
                       "can't connect"));
   }
   else{
      $self->{isConnected}=1;
   }

   return($self->{'ldap'});
}

sub getErrorMsg
{
   return("getErrorMsg:ldap errorstring");
}

sub execute
{
   my $self=shift;
   my @p=@_;

   $self->checksoftlimit(\$p[0]);
   #printf STDERR ("execute: %s\n",$p[0]);
   return($self->SUPER::execute(@p)); 
}

sub checksoftlimit
{
   my $self=shift;
   my $cmd=shift;
   delete($self->{softlimit});

   if ($self->getDriverName() eq "ODBC"){
      if (my ($n)=$$cmd=~m/\s+limit\s+(\d+)/){
         $self->{softlimit}=$n;
         $$cmd=~s/\s+limit\s+(\d+)//;
      }
   }
}


sub execute 
{
   my $self=shift;
   my @param=@_;

   if ($self->{ldap}){
       my $c=$self->getParent->Context;
       #printf STDERR ("ldapdriver->execute:%s\n",Dumper(\@param));
       $c->{$self->{ldapname}}->{sth}=$self->{'ldap'}->search(@param);
       if (!($c->{$self->{ldapname}}->{sth})){
          return(undef,msg(ERROR,"problem while LDAP search"));
       }
       if ($c->{$self->{ldapname}}->{sth}->code()){
          return(undef,msg(ERROR,"ldap-search:%s",
                           $c->{$self->{ldapname}}->{sth}->error));
       }
                      
       $c->{$self->{ldapname}}->{sthdata}=
                   [$c->{$self->{ldapname}}->{sth}->all_entries()];
       $c->{$self->{ldapname}}->{sthcount}=$#{$c->{$self->{ldapname}}->{sthdata}}+1;
       #printf STDERR ("fifi kernel::ldapdriver found %d entries\n",
       #               $#{$c->{$self->{ldapname}}->{sthdata}}+1);
       return($c->{$self->{ldapname}}->{sth});
   }
   return(undef);
}

sub rows
{
   my $self=shift;
   my $c=$self->getParent->Context;
   if (defined($c->{$self->{ldapname}}->{sthcount})){
      return($c->{$self->{ldapname}}->{sthcount}-
             $#{$c->{$self->{ldapname}}->{sthdata}}-1);
   }
   return(undef);
}

sub finish
{
   my $self=shift;
   my $c=$self->getParent->Context;
   delete($c->{$self->{ldapname}}->{sth});
   delete($c->{$self->{ldapname}}->{sthdata});
   delete($c->{$self->{ldapname}}->{sthcount});
}

   
sub fetchrow
{
   my $self=shift;
   my $c=$self->getParent->Context;

   my $entry=shift(@{$c->{$self->{ldapname}}->{sthdata}});
   if ($entry){
      my %rec=();
      foreach my $attr ($entry->attributes) {
         my @val=$entry->get_value($attr);
         for(my $c=0;$c<=$#val;$c++){
            $val[$c]=utf8($val[$c])->latin1();
         }
         my $val=join(", ",@val);
         if ($#val>0){
            $rec{$attr}=\@val;
         }
         else{
            $rec{$attr}=$val[0];
         }
      }
#   printf STDERR ("fifi data=%s\n",Dumper(\%rec));
      return(\%rec);
   }

   return(undef);
}

sub getCurrent
{
   my $self=shift;
   my $c=$self->getParent->Context;
   return($c->{$self->{dbname}}->{'current'});
}

sub do
{
   my $self=shift;
   my $cmd=shift;

   $cmd.=" /* W5BaseUser: $ENV{REMOTE_USER} */" if ($ENV{REMOTE_USER} ne "");
   if ($self->{'db'}){
      if ($self->{'db'}->do($cmd,{},@_)){
         return($self->{'db'});
      }
      else{
         msg(ERROR,"do('%s')",$cmd);
      }
   }
   return(undef);
}



1;

