package tscape::qrule::compareProjectManager;
#######################################################################
=pod

=head3 PURPOSE

This quality rule compares the Project Manager specified in 
the ICTO Object on CapeTS to the ApplicationManager entry in
a BusinessApplication.

=head3 IMPORTS

- name of cluster

=head3 HINTS

Der Project Manager IT-System soll federf�hrend in CapeTS �ber
das ICTO Objekt gepflegt werdeni (zumindest f�r die Produktionsanwendungen
eines ICTO Obejktes).


Ansprechpartner f�r CapeTS ist Hr. Krohn ...

https://darwin.telekom.de/darwin/auth/base/user/ById/13627534400001


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["TS::appl","AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if (!($rec->{cistatusid}==3 || 
                         $rec->{cistatusid}==4));

   my %pm_soll;
   my @notifymsg;

   if ($rec->{opmode} eq "prod" && $rec->{ictono} ne ""){
      $dataobj->NotifyWriteAuthorizedContacts($rec,undef,{
         emailcc=>['11634953080001'],
      },{
         autosubject=>1,
         autotext=>1,
         mode=>'QualityCheck',
         datasource=>'CapeTS'
      },sub {
         my $par=getModuleObject($self->getParent->Config(),"tscape::archappl");
         $par->SetFilter({archapplid=>\$rec->{ictono}});
         my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
         return(undef,undef) if (!$par->Ping());
         if (defined($parrec)){
            my $tswiw=getModuleObject($self->getParent->Config,"tswiw::user");
            foreach my $r (@{$parrec->{roles}}){
               if ($r->{role} eq "Project Manager IT-System" &&
                   $r->{email} ne ""){
                  my $pmid=$tswiw->GetW5BaseUserID($r->{email});
                  if ($pmid ne ""){
                     $pm_soll{$pmid}++;
                  }
               }
            }
         }
         my @pm_soll=sort(keys(%pm_soll));
         my $lnkcontact;
         if ($#pm_soll!=-1){
            $lnkcontact=getModuleObject($self->getParent->Config,
                                                 "base::lnkcontact");
         }
         foreach my $pmid (@pm_soll){
            my $pmfound=0;
            foreach my $crec (@{$rec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::user" &&
                   $crec->{targetid} eq $pmid){
                  $pmfound=1;
                  if (!in_array($roles,"projectmanager")){
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('update roles of contact %s with '.
                                      'projectmanager',$self->Self),
                             $crec->{targetname}));
                        ####################################################
                        $lnkcontact->ValidatedUpdateRecord(
                                     {%$crec,
                                      refid=>$rec->{id},
                                      parentobj=>'itil::appl'},
                                     {roles=>[@$roles,'projectmanager']},
                                     {id=>\$crec->{id}});
                        ####################################################
                     }
                     else{
                        push(@dataissue,"projectmanager: ".
                             $crec->{targetname});
                     }
                  }
               }
               else{
                  if (in_array($roles,"projectmanager")){
                     my @newroles=grep(!/^projectmanager$/,@{$roles});
                     if ($#newroles==-1){
                        if ($autocorrect){
                           push(@notifymsg,sprintf(
                                $self->T('removing projectmanager '.
                                         'contact %s',$self->Self),
                                $crec->{targetname}));
                           #################################################
                           $lnkcontact->ValidatedDeleteRecord($crec,{
                              id=>$crec->{id}
                           });

                           #################################################
                        }
                        else{
                           push(@dataissue,"no projectmanager role for: ".
                                $crec->{targetname});
                        }
                     }
                     else{
                        if ($autocorrect){
                           push(@notifymsg,sprintf(
                                $self->T('removing projectmanager role '.
                                         'from contact %s',$self->Self),
                                $crec->{targetname}));
                           #################################################
                           $lnkcontact->ValidatedUpdateRecord(
                                        {%$crec,
                                         refid=>$rec->{id},
                                         parentobj=>'itil::appl'},
                                        {roles=>\@newroles},
                                        {id=>\$crec->{id}});
                           #################################################
                        }
                        else{
                           push(@dataissue,"no projectmanager role for: ".
                                $crec->{targetname});
                        }
                     }
                  }
               }
            }
            if (!$pmfound){
               my $user=getModuleObject($self->getParent->Config,"base::user");
               $user->SetFilter({userid=>\$pmid});
               my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
               if (defined($urec)){
                  if ($autocorrect){
                     push(@notifymsg,sprintf(
                          $self->T('adding projectmanager '.
                                   'contact %s',$self->Self),
                          $urec->{fullname}));
                     #######################################################
                     $lnkcontact->ValidatedInsertRecord({
                        srcsys=>$self->Self,
                        target=>'base::user',
                        targetid=>$urec->{userid},
                        roles=>['projectmanager'],
                        refid=>$rec->{id},
                        parentobj=>'itil::appl'
                     });
                     #######################################################
                  }
                  else{
                     push(@dataissue,"projectmanager: ".
                          $urec->{fullname});
                  }
               }
            }
         }
         if ($#notifymsg!=-1){
            @qmsg=@notifymsg;
            return($rec->{name},join("\n\n",map({"- ".$_} @notifymsg)));
         }
         return(undef,undef);
      });
   }
   if ($#dataissue!=-1){
      $errorlevel=3;
      unshift(@dataissue,"different values stored in CapeTS:");
      push(@qmsg,@dataissue);
   }

   return($errorlevel,{qmsg=>\@qmsg});
}

sub qenrichRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;



}



1;
