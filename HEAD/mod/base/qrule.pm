package base::qrule;
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
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

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
                align         =>'left',
                label         =>'QRule ID'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full QRule Name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return("(".$id.") ".
                          $self->getParent->{qrule}->{$id}->getName());
                }),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'QRule Name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getName());
                }),

      new kernel::Field::Text(
                name          =>'target',
                label         =>'posible Target'),

      new kernel::Field::Htmlarea(
                name          =>'longdescription',
                label         =>'Description',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getDescription());
                }),

      new kernel::Field::Textarea(
                name          =>'code',
                label         =>'Programmcode',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $instdir=$self->getParent->Config->Param("INSTDIR");
                   $id=~s/::/\//g;
                   my $d="?";
                   my $file="$instdir/mod/$id.pm";
                   if (-f $file){
                      if (open(F,"<$file")){
                         $d=join("",<F>);
                         close(F);
                      }
                   }
                   return($d);
                }),

   );
   $self->LoadSubObjs("qrule","qrule");
   $self->{'data'}=[];
   my @dl=$self->getInstalledDataObjNames();
  
   foreach my $obj (values(%{$self->{qrule}})){
      my $ctrl=$obj->getPosibleTargets();
      my $name=$obj->Self();
      $ctrl=[$ctrl] if (ref($ctrl) ne "ARRAY");
      my %t;
      foreach my $ct (@$ctrl){
         if ($ct=~m/[\.\^\*]/){
            foreach my $m (@dl){
               if ($m=~m/$ct/){
                  $t{$m}++;
               }
            }
         }
         else{
            $t{$ct}++;
         }
      }
      my $r={id=>$obj->Self,target=>[keys(%t)]};
      push(@{$self->{'data'}},$r);
   }
   $self->setDefaultView(qw(linenumber id name target));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/qmgmt.jpg?".$cgi->query_string());
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

sub isQruleApplicable
{
   my $self=shift;
   my $do=shift;
   my $objlist=shift;
   my $lnkrec=shift;
   my $rec=shift;

   my $dataobjparent=$do->SelfAsParentObject();
   if (defined($self->{qrule}->{$lnkrec->{qruleid}})){
      my $qrule=$self->{qrule}->{$lnkrec->{qruleid}};
      my $postargets=$qrule->getPosibleTargets();
      $postargets=[$postargets] if (ref($postargets) ne "ARRAY");
      my $found=0;
      if (ref($postargets) eq "ARRAY"){
         foreach my $target (@$postargets){
            if (grep(/^$target$/,@$objlist)){
               my $qdataobj=quotemeta($lnkrec->{dataobj});
               my $qdataobjparent=quotemeta($dataobjparent);
               if (grep(/^$qdataobj$/,@$objlist) ||
                   grep(/^$dataobjparent$/,@$objlist)){
                  $found=1;
                  last;
               }
            }
         }
      }
      if (($lnkrec->{dataobj}=~m/::workflow::/) &&
          $lnkrec->{dataobj} ne $rec->{class}){
         $found=0;
      }
      return($qrule) if ($found);
   }
   return;
}




sub nativQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my @param=@_;
   my $parent=$self->getParent->Clone;
   my $result;
   my %alldataissuemsg;
   my %dataupdate;
   my $mandator=[];
   my $checkStart=NowStamp("en");

   $mandator=$rec->{mandatorid} if (exists($rec->{mandatorid}));
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   $objlist=[$objlist] if (ref($objlist) ne "ARRAY");
   my $lnkr=getModuleObject($self->Config,"base::lnkqrulemandator");
   if ($self->getParent->Self() eq "base::workflow"){
      $lnkr->SetFilter({mandatorid=>$mandator,
                        dataobj=>\$rec->{class}});
   }
   else{
      $lnkr->SetFilter({mandatorid=>$mandator});
   }
   my %qruledone;

   my $parentTransformationCount=0;

   foreach my $lnkrec ($lnkr->getHashList(qw(mdate qruleid dataobj))){
      my $do=getModuleObject($self->Config,$lnkrec->{dataobj});
      if (my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$rec)){
         if ($parent->Self() ne $do->Self()){
            if ($parentTransformationCount==0){
               # rec mu� neu gelesen werden!
               $do->ResetFilter();
               my $idname=$do->IdField()->Name();
               $do->SetFilter({$idname=>\$rec->{$idname}});
               ($rec)=$do->getOnlyFirst(qw(ALL)); 
               if (!defined($rec)){
                  msg(ERROR,"parent transformation error while reread rec");
                  return;
               }
               $objlist=$do->getQualityCheckCompat($rec); # recreate compat list
               msg(INFO,"qrule parent transformation from %s to %s done",
                        $parent->Self(),$do->Self());
               $parent=$do;
            }
            else{
               msg(ERROR,"mulitple parent transformation detected");
            }
         }
      }
   }


   foreach my $lnkrec ($lnkr->getHashList(qw(mdate qruleid dataobj))){
      my $qrulename=$lnkrec->{qruleid};
      next if ($qruledone{$qrulename});
      my $do=getModuleObject($self->Config,$lnkrec->{dataobj});
      if (my $qrule=$self->isQruleApplicable($do,$objlist,$lnkrec,$rec)){
         $qruledone{$qrulename}++;
         my $oldcontext=$W5V2::OperationContext;
         $W5V2::OperationContext="QualityCheck";
         my $acorrect=0;  # vorgesehen f�r auto correct modeA
         my ($qresult,$control)=$qrule->qcheckRecord($parent,$rec,$acorrect);
         $W5V2::OperationContext=$oldcontext;
         if (defined($control) && defined($control->{dataissue})){
            my $dataissuemsg=$control->{dataissue};
            $dataissuemsg=[$dataissuemsg] if (ref($dataissuemsg) ne "ARRAY");
            if ($#{$dataissuemsg}!=-1){
               my $qrulename=$qrule->Self();
               if (!defined($alldataissuemsg{$qrulename})){
                  $alldataissuemsg{$qrulename}=[];
               }
               push(@{$alldataissuemsg{$qrulename}},@{$dataissuemsg});
            }
         }
         if (defined($control) && defined($control->{dataupdate})){
         }
         my $resulttext="OK";
         $resulttext="fail"      if ($qresult!=0);
         $resulttext="messy"     if ($qresult==1);
         $resulttext="warn"      if ($qresult==2);
         $resulttext="undefined" if (!defined($qresult));
         my $qrulelongname=$qrule->getName();
         my $res={ rulelabel=>"$qrulelongname",
                   ruleid=>$qrule->Self,
                   result=>$self->T($resulttext),
                   exitcode=>$qresult};
         if (defined($control->{qmsg})){
            $res->{qmsg}=$control->{qmsg};
            if (ref($res->{qmsg}) eq "ARRAY"){
               for(my $c=0;$c<=$#{$res->{qmsg}};$c++){
                  if (my ($pr,$po)=$res->{qmsg}->[$c]=~m/^(.*)\s*:\s+(.*)$/){
                     $res->{qmsg}->[$c]=$self->T($pr,
                                                  $qrulename).": ".$po;
                  }
                  else{
                     $res->{qmsg}->[$c]=$self->T($res->{qmsg}->[$c],
                                                  $qrulename);
                  }
               }
            }
            else{
               if (my ($pr,$po)=$res->{qmsg}=~m/^(.*)\s*:\s+(.*)$/){
                  $res->{qmsg}=$self->T($pr,$qrulename).": ".$po;
               }
               else{
                  $res->{qmsg}=$self->T($res->{qmsg},$qrulename);
               }
            }
         }
         push(@{$result->{rule}},$res);
      }
   }
   if ($parent->Self() ne "base::workflow"){ # only DataIssues for nonworkflows!
      my $wf=getModuleObject($parent->Config,"base::workflow");
      my $dataobj=$parent;
      #my $affectedobject=$dataobj->SelfAsParentObject();
      my $affectedobject=$dataobj->Self(); # new version of affected calc
      my $idfield=$dataobj->IdField();
      my $affectedobjectid=$idfield->RawValue($rec);
      #msg(INFO,"QualityRule Level1");
      if (keys(%alldataissuemsg)){
         #msg(INFO,"QualityRule Level2");
         my $directlnkmode="DataIssueMsg";
         my $detaildescription;
         foreach my $qrule (keys(%alldataissuemsg)){
            $detaildescription.="\n" if ($detaildescription ne "");
            $detaildescription.="[W5TRANSLATIONBASE=$qrule]\n";
            $detaildescription.=$qrule."\n";
            foreach my $msg (@{$alldataissuemsg{$qrule}}){
               if ($msg=~m/^\[\S+::\S+\]$/){
                  $detaildescription.=$msg."\n";
               }
               else{
                  $detaildescription.=" - ".$msg."\n";
               }
            }
         }
         #msg(INFO,"QualityRule Level3");
         my $oldforce=$ENV{HTTP_FORCE_LANGUAGE};
         $ENV{HTTP_FORCE_LANGUAGE}="en";
         my $objectname=$dataobj->getRecordHeader($rec);
         if (my $headerfield=$dataobj->getRecordHeaderField($rec)){
            $objectname=$headerfield->RawValue($rec);
         }
     
         my $name="DataIssue: ".$dataobj->T($affectedobject,$affectedobject).": ".
                  $objectname;
         $ENV{HTTP_FORCE_LANGUAGE}=$oldforce;
         delete($ENV{HTTP_FORCE_LANGUAGE}) if ($ENV{HTTP_FORCE_LANGUAGE} eq "");
         $wf->ResetFilter();
         $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                         directlnktype=>\$affectedobject,
                         directlnkid=>\$affectedobjectid});
         #msg(INFO,"QualityRule Level4");
         my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         my $oldcontext=$W5V2::OperationContext;
         $W5V2::OperationContext="QualityCheck";
         #msg(INFO,"QualityRule Level5");
         if (!defined($WfRec)){
            #msg(INFO,"QualtiyCheck: ".
            #         "an old record does not exists - so i create a new one");
            my $newrec={name=>$name,
                        detaildescription=>$detaildescription,
                        class=>"base::workflow::DataIssue",
                        step=>"base::workflow::DataIssue::dataload",
                        affectedobject=>$affectedobject,
                        affectedobjectid=>$affectedobjectid,
                        altaffectedobjectname=>$objectname,
                        directlnkmode=>$directlnkmode,
                        eventend=>undef,
                        eventstart=>NowStamp("en"),
                        srcload=>NowStamp("en"),
                        srcsys=>$affectedobject,
                        dataissuemetric=>[sort(keys(%alldataissuemsg))],
                        DATAISSUEOPERATIONSRC=>$directlnkmode};
            my $bk=$wf->Store(undef,$newrec);
            $result->{wfheadid}=$bk;
         }
         else{
            msg(INFO,"QualtiyCheck: ".
                     "an old record exists - so i update the record");
            my $newrec={name=>$name,
                        mdate=>$WfRec->{mdate},
                        owner=>$WfRec->{owner},
                        editor=>$WfRec->{editor},
                        realeditor=>$WfRec->{realeditor},
                        srcload=>NowStamp("en"),
                        dataissuemetric=>[sort(keys(%alldataissuemsg))],
                        detaildescription=>$detaildescription};
            my $bk=$wf->Store($WfRec,$newrec);
            $result->{wfheadid}=$WfRec->{id};
         }
     
         $W5V2::OperationContext=$oldcontext;
      }
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="QualityCheck";
      #
      # cleanup deprecated DataIssues for current object
      #
      $wf->ResetFilter();
      $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                      srcload=>"<\"$checkStart GMT\"",
                      directlnktype=>\$affectedobject,
                      directlnkid=>\$affectedobjectid});
      $wf->SetCurrentView(qw(ALL));
      $wf->ForeachFilteredRecord(sub{
                         $wf->Store($_,{stateid=>'21',
                                        fwddebtarget=>undef,
                                        fwddebtargetid=>undef,
                                        fwdtarget=>undef,
                                        fwdtarget=>undef});
                      });
      if (my $qclast=$parent->getField("lastqcheck")){
         my $idfield=$parent->IdField();
         if (defined($idfield)){
            my $id=$idfield->RawValue($rec);
            if ($id ne ""){
               $parent->ValidatedUpdateRecord($rec,{lastqcheck=>NowStamp("en")},
                                              {$idfield->Name()=>\$id});
            }
         }
      }
      $W5V2::OperationContext=$oldcontext;
   }

   return($result);

}


sub WinHandleQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my $dataobj=$self->getParent();
   my $CurrentIdToEdit=Query->Param("CurrentIdToEdit");
   my $mode=Query->Param("Mode");
   if (defined($mode) && $mode eq "process" && $CurrentIdToEdit ne ""){
      #printf STDERR ("fifi env=%s\n",Dumper(\%ENV));
      #printf STDERR ("fifi query=%s\n",Query->Dumper());
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({},{header=>1});
      print $res."<document>";
      my $checkresult=$self->nativQualityCheck($objlist,$rec);
      #print STDERR Dumper($checkresult);
      foreach my $ruleres (@{$checkresult->{rule}}){
         my $res=hash2xml({rule=>$ruleres},{});
         print $res;
         #printf STDERR ($res."\n");
      }
      if ($checkresult->{wfheadid} ne ""){
         my $res=hash2xml({wfheadid=>$checkresult->{wfheadid}},{});
         print $res;
         #printf STDERR ($res."\n");
      }
      print "</document>";
      return();
   }
   my $d=$self->HttpHeader("text/html");
   my $winlabel;
   $winlabel=$rec->{name}     if (defined($rec->{name}));
   $winlabel=$rec->{fullname} if (defined($rec->{fullname}));
   $d.=$self->HtmlHeader(style=>['default.css','qrule.css'],
                         form=>1,body=>1,
                         js=>['toolbox.js'],
                         title=>$self->T("QC:").$winlabel);
   my $handlermask=$self->getParsedTemplate("tmpl/base.qualitycheck",
                          {static=>{winlabel=>$winlabel}});
   my $msg=$self->findtemplvar({},"LASTMSG"); 
   my $DetailClose=$self->T("DetailClose","kernel::App::Web::Listedit");
   my $DetailPrint=$self->T("DetailPrint","kernel::App::Web::Listedit");
   $d.=<<EOF;
<table width=100% height=100% border=0>
<tr height=50><td>$handlermask</td></tr>
<tr>
<td valign=top>
<div id=reslist class=QualityCheckResultList>
</div>
</td>
</tr>
<tr height=20>
<td>
<table cellspacing=0 cellpadding=0 width=100%>
<tr><td>$msg</td><td align=right><div id=summary></div></td></tr>
</table>
</td>

</tr>
<tr height=1%>
<td align=right>
<div class=buttonline>
<input onclick="window.print();" type=button style="width:100px" value="$DetailPrint">
<input onclick="processCheck();" type=button style="width:100px" value="recheck">
<input onclick="window.close();" type=button style="width:100px" value="$DetailClose">
<input type=hidden name=CurrentIdToEdit value="$CurrentIdToEdit">
</div>
</td>
</tr>
</table>
<script language="JavaScript">

function addToResult(ruleid)
{
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST",document.location.href,true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState<4){
       var r=document.getElementById("reslist");
       if (r){
          var t="Checking ...";
          if (r.innerHTML!=t){
             r.innerHTML=t;
          }
       }
       var r=document.getElementById("summary");
       if (r){
          var t="- working -";
          if (r.innerHTML!=t){
             r.innerHTML=t;
          }
       }
    }
    if (xmlhttp.readyState==4 && (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var r=document.getElementById("reslist");
       r.innerHTML="";
       var wfheadidobj=xmlobject.getElementsByTagName("wfheadid");
       var wfheadid;
       if (wfheadidobj && wfheadidobj[0] && wfheadidobj[0].childNodes &&
           wfheadidobj[0].childNodes[0]){
          wfheadid=wfheadidobj[0].childNodes[0].nodeValue;
       }
       var results=xmlobject.getElementsByTagName("rule");
       var ok=0;
       var warn=0;
       var fail=0;
       if (results.length>0){
          for(rid=0;rid<results.length;rid++){
             var ruleres=results[rid];

             var label=ruleres.getElementsByTagName("rulelabel")[0];
             var labelChildNode=label.childNodes[0];
             var labeltext=labelChildNode.nodeValue;

             var ruleid=ruleres.getElementsByTagName("ruleid")[0];
             var ruleidChildNode=ruleid.childNodes[0];
             var ruleidtext=ruleidChildNode.nodeValue;

             var result=ruleres.getElementsByTagName("result")[0];
             var resultChildNode=result.childNodes[0];
             var resulttext=resultChildNode.nodeValue;

             var exitcode=ruleres.getElementsByTagName("exitcode")[0];
             var exitcodetext="?";
             var color="";
             if (exitcode.childNodes[0]){
                var exitcodeChildNode=exitcode.childNodes[0];
                var exitcodetext=exitcodeChildNode.nodeValue;
                color="<font color=green>";
                if (exitcodetext!=0){
                   color="<font color=red>";
                   fail++;
                }
                else{
                   ok++;
                }
                if (exitcodetext==1){
                   color="<font color=#D7AD08>";
                }
                if (exitcodetext==2){
                   warn++;
                }
             }
             r.innerHTML+="<a class=rulelink href=javascript:openwin('../../base/qrule/Detail?id="+ruleidtext+"','_blank','height=480,width=640,toolbar=no,status=no,resizeable=yes,scrollbars=no')>"+labeltext+"</a>"+": "+color+resulttext+"</font><br>";

             var qmsg=ruleres.getElementsByTagName("qmsg");

             if (qmsg.length>0){
                r.innerHTML+="<ul>";
                for(eid=0;eid<qmsg.length;eid++){
                   var qmsgChildNode=qmsg[eid].childNodes[0];
                   var qmsgtext=qmsgChildNode.nodeValue;
                   r.innerHTML+="<li>"+qmsgtext+"</li>";
                  
                }
                r.innerHTML+="</ul>";
             }
             r.innerHTML+="<div style=\\"height:4px\\"></div>";
          }
          var r=document.getElementById("summary");
          if (r){
             var t="R:";
             if (wfheadid){
                t="<a class=rulelink href=javascript:openwin('../../base/workflow/ById/"+wfheadid+"','_blank','height=480,width=640,toolbar=no,status=no,resizeable=yes,scrollbars=no')>"+t+'</a>';
             }
             t=t+results.length+"/<font color=green>"+ok+"</font>";
             if (warn>0){
                 t+="/<font color=orange>"+warn+"</font>";
             }
             if (fail>0){
                 t+="/<font color=red>"+fail+"</font>";
             }
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
       else{
          r.innerHTML="no rules defined";
          var r=document.getElementById("summary");
          if (r){
             var t="-";
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
    }
   }
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('Mode=process&CurrentIdToEdit='+'$CurrentIdToEdit');
}
function resizeOut()
{
   var r=document.getElementById("reslist");
   var h=getViewportHeight(); 
   r.style.height=(h-140)+"px";  // set height of output fix
}
function processCheck()
{
   var r=document.getElementById("reslist");
   resizeOut();
   r.innerHTML="";
   addToResult(1);
}
addEvent(window,"load",processCheck);
addEvent(window,"resize",resizeOut);

</script>
EOF

   $d.=$self->HtmlBottom(body=>1,form=>1);



   return($d);
}

   



1;
