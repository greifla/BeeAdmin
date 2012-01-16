package base::qrule::InvalidRefChk;
#######################################################################
=pod

=head3 PURPOSE

Checks if there contact or group referenzes in the current
record, witch are marked as "disposed of waste".
This qrule can check field with type ...
kernel::Field::ContactLnk
kernel::Field::Contact
kernel::Field::Group
kernel::Field::Databoss

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if (!exists($rec->{cistatusid}) || $rec->{cistatusid}>5);

   my @chkfieldtypes=qw(ContactLnk Contact Group Databoss);
   my $chkfieldtypes=join("|",@chkfieldtypes);
   my @fobjlst;
   foreach my $fieldname ($dataobj->getFieldList(current=>$rec)){
      my $fobj=$dataobj->getField($fieldname);
      my $t=$fobj->Type();
      if (defined($fobj) && $fobj->Type()=~m/^($chkfieldtypes)$/){
         push(@fobjlst,$fobj);
      }
   }
   my $user=$dataobj->ModuleObject("base::user");
   my $grp=$dataobj->ModuleObject("base::grp");
   my @failmsg;
   my @dataissue;
   foreach my $fobj (@fobjlst){
      my $label=$fobj->Label();
      my @checkids=();
      if ($fobj->Type() ne "ContactLnk"){
         my $idfobj=$dataobj->getField($fobj->{vjoinon}->[0]);
         if (defined($idfobj)){
            my $id=$idfobj->RawValue($rec);
            if ($id ne ""){
               push(@checkids,$fobj->{vjointo});
               push(@checkids,$id);
            }

         }
      #   printf STDERR ("vjointo=%s",$fobj->{vjointo});
      #   printf STDERR ("vjoinon=%s",$fobj->{vjoinon}->[0]);
      }
      else{
         my $val=$fobj->RawValue($rec);
         if (ref($val) eq "ARRAY"){
            foreach my $r (@$val){
               if ($r->{target} eq "base::user"){
                  push(@checkids,$r->{target},$r->{targetid});
               }
               if ($r->{target} eq "base::grp"){
                  push(@checkids,$r->{target},$r->{targetid});
               }
            }
         } 
      }
      while(my $target=shift(@checkids)){
         my $targetid=shift(@checkids);
         if ($target eq "base::grp"){
            $grp->ResetFilter();
            $grp->SetFilter({grpid=>\$targetid});
            my ($chkrec)=$grp->getOnlyFirst(qw(cistatusid fullname));
            if (!defined($chkrec)){
               push(@failmsg,"'".$label."' ".
                             $self->T("points to non existing record"));
            }
            else{
               if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
                  push(@failmsg,$label.": ".$chkrec->{fullname}." ".
                                $self->T("is invalid"));
                  push(@dataissue,$chkrec->{fullname});
               }
            }
         }
         if ($target eq "base::user"){
            $user->ResetFilter();
            $user->SetFilter({userid=>\$targetid});
            my ($chkrec)=$user->getOnlyFirst(qw(cistatusid fullname));
            if (!defined($chkrec)){
               push(@failmsg,"'".$label."' ".
                             $self->T("points to non existing record"));
            }
            else{
               if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
                  push(@failmsg,$label.": ".$chkrec->{fullname}." ".
                                $self->T("is invalid"));
                  push(@dataissue,$chkrec->{fullname});
               }
            }
         }
      }
   }
   if ($#failmsg!=-1){
     # printf STDERR ("check fail:%s\n",Dumper(\@failmsg));
      return(3,{qmsg=>['There are invalid contact references!',@failmsg],
                dataissue=>['There are invalid contact references!',@dataissue]});
   }
   
   return(0,undef);
}



1;
