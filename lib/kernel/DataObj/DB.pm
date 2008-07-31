package kernel::DataObj::DB;
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
use Scalar::Util qw(weaken);
use kernel;
use kernel::DataObj;
use kernel::database;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;
use UNIVERSAL;
@ISA    = qw(kernel::DataObj UNIVERSAL);


sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}

sub AddDatabase
{
   my $self=shift;
   my $db=shift;
   my $obj=shift;

   my ($dbh,$msg)=$obj->Connect();
   if (!$dbh){
      if ($msg ne ""){
         return("InitERROR",$msg);
      }
      return("InitERROR",msg(ERROR,"can't connect to database '%s'",$db));
   }
   $self->{$db}=$obj;
   return($dbh);
}  

sub Rows 
{
    my $self=shift;

    if (defined($self->{DB})){
       return($self->{DB}->rows());
    }
    return(undef);
}


sub getSqlFields
{
   my $self=shift;
   my @view=$self->getCurrentView();
   my @flist=();
   my $distinct;
   if ($view[0] eq "DISTINCT"){
      $distinct="distinct";
      shift(@view);
   }
   if (!$distinct){
      my $idfield=$self->IdField();
      my $idfieldname;
      $idfieldname=$idfield->Name() if (defined($idfield));
      if (!($#view==0 && ($view[0] eq $idfieldname || 
                          $view[0] eq "srcload" || 
                          $view[0] eq "srcsys" || 
                          $view[0] eq "srcid" || 
                          $view[0] eq "mdate" || 
                          $view[0] eq "cdate"))){
         my @selectfix=();
         foreach my $fname (@{$self->{'FieldOrder'}}){
            my $fobj=$self->{'Field'}->{$fname};
            if ($fobj->selectfix()){
               push(@selectfix,$fname);
            }
         }
         foreach my $selectfix (@selectfix){
            push(@view,$selectfix) if (!grep(/^$selectfix$/,@view));
         }
      }
   }
   $distinct=" distinct " if ($self->{use_distinct}==1);
   foreach my $fullfieldname (@view){
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/^\S+\.\S+$/){
         ($container,$fieldname)=split(/\./,$fullfieldname);
      }
      my $field=$self->getField($fieldname);
      if (defined($field->{depend})){
         if (ref($field->{depend}) ne "ARRAY"){
            $field->{depend}=[$field->{depend}];
         }
         foreach my $field (@{$field->{depend}}){
            push(@view,$field) if (!grep(/^$field$/,@view));
         }
      }
   }
   foreach my $fullfieldname (@view){
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/^\S+\.\S+$/){
         ($container,$fieldname)=split(/\./,$fullfieldname);
      }
      my $field=$self->getField($fieldname);
      next if (!defined($field));
      next if (!$field->selectable());
      my $selectfield=$field->getSelectField("select",$self->{DB});
      if (defined($selectfield)){
         push(@flist,"$selectfield $fieldname");
      }
      #
      # dependencies solution on vjoins
      #
      if (defined($field->{alias})){
         my $alias=$self->getField($field->{alias});
         $field=$alias if (defined($alias)); 
      }
      if (defined($field->{vjoinon})){
         my $joinon=$field->{vjoinon}->[0];
         my $joinonfield=$self->getField($joinon);
         if (!defined($joinonfield)){
            die("vjoinon not corret in field $field->{name}");
         }
         my $selectfield=$joinonfield->getSelectField("select",$self->{DB});
         if (defined($selectfield)){
            $selectfield.=" ".$joinon;
            if (!grep(/^$selectfield$/,@flist)){
               push(@flist,$selectfield);
            }
         }
      }
      #
      # dependencies solution on container
      #
      elsif (defined($field->{container})){
         my $contfield=$self->getField($field->{container});
         if (defined($contfield->{dataobjattr})){
            my $newfield=$contfield->{dataobjattr}." ".$field->{container}; 
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
   }
   return($distinct,@flist);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return($worktable);
}

sub getSqlOrder
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my @order=$self->initSqlOrder;
   my @view=$self->getFieldObjsByView([$self->getCurrentView()]);


   my @o=$self->GetCurrentOrder();
   if (!($#o==0 && $o[0] eq "NONE")){
      if ($#o==-1 || ($#o==0 && $o[0] eq "")){
         foreach my $field (@view){
            my $orderstring=$field->getSelectField("order",$self->{DB});
            next if (!defined($orderstring));
            push(@order,$orderstring);
         }
         return(join(", ",@order));
      }
      else{
         foreach my $fieldname (@o){
            my $field=$self->getField($fieldname);
            next if (!defined($field));
            my $orderstring=$field->getSelectField("order",$self->{DB});
            next if (!defined($orderstring));
            push(@order,$orderstring);
         }
         return(join(", ",@order));
      }
      return("");
   }
   return("");
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $filter=shift;

   return("");
}


sub initSqlOrder
{
   my $self=shift;
   return;
}


sub processFilterHash
{
   my $self=shift;
   my $wheremode=shift;
   my $where=shift;
   my $filter=shift;

   foreach my $fieldname (keys(%{$filter})){
      my $fo=$self->getField($fieldname);
      if (!defined($fo)){
         msg(ERROR,"invalid filter request on unknown field '$fieldname'");
         next;
      }
      my $fotype=$fo->Type();
      my %sqlparam=();
      my $preparedFilter=$fo->prepareToSearch($filter->{$fieldname});
      if (defined($preparedFilter)){
         if ($fotype eq "Fulltext"){
            $sqlparam{datatype}="FULLTEXT";
            $sqlparam{listmode}=0;
            $sqlparam{wildcards}=0;
            $sqlparam{logicalop}=0;
         }
         if ($fotype=~m/Date$/){
            $sqlparam{datatype}="DATE";
            $sqlparam{timezone}=$fo->timezone();
         }
         if (defined($fo->{container})){
            $sqlparam{containermode}=$fo->{container};
         }
         if (defined($fo->{uppersearch})){
            $sqlparam{uppersearch}=1;
         }
         if (defined($fo->{lowersearch})){
            $sqlparam{lowersearch}=1;
         }
         if (defined($fo->{ignorecase})){
            $sqlparam{ignorecase}=1;
         }
         $sqlparam{sqldbh}=$self->{DB};
         my $sqlfieldname=$fo->getSelectField("where.$wheremode",$self->{DB});
         next if (!defined($sqlfieldname));
         my $bk=$self->Data2SQLwhere($where,$sqlfieldname,$preparedFilter,
                                     %sqlparam);
         return(undef) if (!$bk);
      }
   }
   return(1);
}



sub getSqlWhere
{
   my $self=shift;
   my $wheremode=shift;
   my @filter=@_;
   my $where=$self->initSqlWhere($wheremode,\@filter);

   foreach my $filter (@filter){
      if (ref($filter) eq "HASH"){
         my $bk=$self->processFilterHash($wheremode,\$where,$filter);
         return(undef) if (!$bk);
      }
      if (ref($filter) eq "ARRAY"){
         my $orwhere="";
         foreach my $flt (@{$filter}){
            my $subwhere="";
            my $bk=$self->processFilterHash($wheremode,\$subwhere,$flt);
            return(undef) if (!$bk);
            if ($subwhere ne ""){
               if ($orwhere ne ""){
                  $orwhere="($orwhere) or ($subwhere)";
               }
               else{
                  $orwhere="($subwhere)";
               }
            }
         }
         if ($orwhere ne ""){
            if ($where eq ""){
               $where="($orwhere)";
            }
            else{
               $where="($where) and ($orwhere)";
            }
         }
      }
   } 
   #printf STDERR ("DUMP:filter:%s\n",Dumper(\@filter));
   #printf STDERR ("DUMP:where:%s\n",$where);
   return($where);
}

sub addLimit
{
   my $self=shift;
   my $where=shift;
   my $order=shift;
   my $limit=shift;
   my $limitnum=shift;

   if (!$self->{_UseSoftLimit}){
      if (defined($self->{DB}->{db}) &&
          lc($self->{DB}->{db}->{Driver}->{Name}) eq "mysql"){
         $$limit="$limitnum";
      }
      if (defined($self->{DB}->{db}) &&
          lc($self->{DB}->{db}->{Driver}->{Name}) eq "oracle"){
         $$where="(".$$where.") and ROWNUM<=$limitnum";
      }
   }
}

sub getSqlGroup
{
   my $self=shift;
   return(undef);
}

sub getSqlSelect
{
   my $self=shift;

   my ($distinct,@fields)=$self->getSqlFields();
   my @filter=$self->getFilterSet();
   my $where=$self->getSqlWhere("select",@filter);
   my @from=$self->getSqlFrom("select",@filter);
   my $group=$self->getSqlGroup("select",@filter);
   my $order=$self->getSqlOrder("select",@filter);
   my $limit;
   my $limitnum=$self->{_Limit};
   if ($limitnum){
      $self->addLimit(\$where,\$order,\$limit,$limitnum);
   }
   my @cmd;
   foreach my $from (@from){
      my $cmd="select ".$distinct.join(",",@fields)." from $from";
      $cmd.=" where ".$where if ($where ne "");
      $cmd.=" group by ".$group if ($group ne "");
      $cmd.=" order by ".$order if ($order ne "");
      $cmd.=" limit ".$limit if ($limit ne "");
      my $disp=$cmd;
      $disp=~tr/\n/ /;
      if (!defined($where)){
         msg(ERROR,"ilegal filter for '%s'\n%s",$cmd,Dumper(\@filter));
         return(undef);
      }
      push(@cmd,$cmd);
   }
   if ($#cmd>0){
      map({$_="(".$_.")"} @cmd);
   }

   return(join(" UNION ",@cmd));
}

sub QuoteHashData
{
   my $self=shift;
   my $workdb=shift;
   my %param=@_;
   my $newdata=$param{current};
   my %raw;

   foreach my $fobj ($self->getFieldObjsByView(["ALL"],%param)){
      my $field=$fobj->Name();
      next if (!exists($newdata->{$field}));
      if (defined($fobj->{alias})){
         $fobj=$self->getField($fobj->{alias});
      }
      if (!defined($fobj)){
         printf STDERR ("ERROR: can't getField $field in $self\n");
   #      exit(1);
   #      return(undef);
      }
      if (defined($fobj->{dataobjattr})){
         if (!defined($newdata->{$field})){
            $raw{$fobj->{dataobjattr}}="NULL";
         }elsif (ref($newdata->{$field}) eq "SCALAR"){
            $raw{$fobj->{dataobjattr}}=${$newdata->{$field}};
         }
         else{
            $raw{$fobj->{dataobjattr}}=$workdb->quotemeta($newdata->{$field});
         }
      }
      else{
         if (!defined($fobj->{container}) && !defined($fobj->{onFinishWrite})
             && $fobj->Type() ne "KeyText" 
             && $fobj->Type() ne "KeyHandler" &&
                $fobj->Type() ne "File"){
            msg(ERROR,"can't QuoteHashData field '$field' in $self - ".
                      "no dataobjattr");
         }
      }
   }
   return(%raw);
}

sub UpdateRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my @updfilter=@_;   # update filter
   my $where=$self->getSqlWhere("update",@updfilter);
   my %raw=();

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no Worktable");
      return(undef);
   }
   if (!defined($workdb)){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no workdb");
      return(undef);
   }
   my %raw=$self->QuoteHashData($workdb,oldrec=>undef,current=>$newdata);
   my $cmd;
   my $logcmd;
   if ($self->{UseSqlReplace}==1){
      my @flist=keys(%raw);
      $cmd="replace into $worktable (".
           join(",",@flist).") ".
           "values(".join(",",map({$raw{$_}} @flist)).")";
      $logcmd=$cmd;
   }
   else{
      $cmd="update $worktable set ".
           join(",",map({
                           $_."=".$raw{$_};
	                } keys(%raw)));
      $cmd.=" where ".$where if ($where ne "");
      $logcmd="update $worktable set ".
           join(",",map({
                           my $d=$raw{$_};
                           $d=substr($d,0,100)."...(BIN)'" if ($d=~m/\E/);
                           $d=~s/[^a-zA-Z 0-9\.'\-,\(\)]/_/g;
                           $_."=".$d;
	                } keys(%raw)));
      $logcmd.=" where ".$where if ($where ne "");
   }
   #msg(INFO,"fifi UpdateRecord data=%s\n",Dumper($newdata));
   msg(INFO,"updcmd=%s",$logcmd);
   if ($workdb->do($cmd)){
      return(1);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $idname=$self->IdField->Name();
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $dropid=$oldrec->{$idname};
   if (!defined($dropid)){
      $self->LastMsg(ERROR,"can't delete record without unique id in $idname");
      return(undef);
   }
   my @flt=({$self->IdField->Name()=>$dropid});
   my $where=$self->getSqlWhere("delete",@flt);

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no Worktable");
      return(undef);
   }
   my $cmd="delete from $worktable";
   $cmd.=" where ".$where if ($where ne "");
   #my $cmd="delete from ta_application_data where ta_application_data.id=13";
   msg(INFO,"delcmd=%s",$cmd);
   if ($workdb->do($cmd)){
      msg(INFO,"delete seems to be ok");
      return(1);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub InsertRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $idobj=$self->IdField();
   my $idfield=$idobj->Name();
   my $id;

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't InsertRecord in $self - no Worktable");
      return(undef);
   }
   if (!defined($workdb)){
      $self->LastMsg(ERROR,"can't InsertRecord in $self - no workdb");
      return(undef);
   }
   if (!defined($newdata->{$idfield})){
      if ($idobj->autogen==1){
         my $res=$self->W5ServerCall("rpcGetUniqueId");
         my $retry=15;
         while(!defined($res=$self->W5ServerCall("rpcGetUniqueId"))){
            sleep(1);
            last if ($retry--<=0);
            msg(WARN,"W5Server problem for user $ENV{REMOTE_USER} ($retry)");
         }
         if (defined($res) && $res->{exitcode}==0){
            $id=$res->{id};
         }
         else{
            msg(ERROR,"InsertRecord: W5ServerCall returend %s",Dumper($res));
            $self->LastMsg(ERROR,"W5Server unavailable ".
                          "- can't get unique id - ".
                          "please try later or contact the admin");
            return(undef);
         }
         $newdata->{$idfield}=$id;
      }
   }
   else{
      $id=$newdata->{$idfield};
   }
   my %raw=$self->QuoteHashData($workdb,oldrec=>undef,current=>$newdata);
   my $cmd;
   if ($self->{UseSqlReplace}==1){

   }
   else{
      my @flist=keys(%raw);
      $cmd="insert into $worktable (".
           join(",",@flist).") ".
           "values(".join(",",map({$raw{$_}} @flist)).")";
   }
   #msg(INFO,"fifi InsertRecord data=%s into '$worktable'\n",Dumper($newdata));
   msg(INFO,"insert=%s",$cmd);
   if ($workdb->do($cmd)){
      if (!defined($id)){
         # id was not created by w5base, soo we need to read it from the
         # table
         # getHashList
         my %q=();
         my @fieldlist=$self->getFieldList();
         foreach my $field (@fieldlist){
            my $fo=$self->getField($field);
            if ($fo->{id} && defined($fo->{dataobjattr})){
               if (defined($newdata->{$fo->{name}})){
                  $q{$fo->{dataobjattr}}=$workdb->quotemeta(
                                      $newdata->{$fo->{name}});
               }
               else{
                  $q{$fo->{dataobjattr}}="NULL";
               }
            }
         }
         my $cmd;
         if (defined($idobj->{dataobjattr}) &&          # id is automatic gen
             ref($idobj->{dataobjattr}) ne "ARRAY"){    # by the database 
            $cmd="select $idobj->{dataobjattr} from $worktable ".
                 "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
            msg(INFO,"reading id by=%s",$cmd);

            my @l=$workdb->getArrayList($cmd);
            my $rec=pop(@l);
            if (defined($rec)){
               $id=$rec->[0];
            }
         }
         if (defined($idobj->{dataobjattr}) &&          # no one simple unique
             ref($idobj->{dataobjattr}) eq "ARRAY"){    # ... id more fields
          #  $cmd="select $idobj->{dataobjattr} from $worktable ".
          #       "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
          #  msg(INFO,"reading id by=%s",$cmd);
#
#            my @l=$workdb->getArrayList($cmd);
#            my $rec=pop(@l);
#            if (defined($rec)){
#               $id=$rec->[0];
#            }
         }
         if (!defined($id)){
            $self->LastMsg(ERROR,"no record identifier returned by insert");
         }
      }
      return($id);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub preProcessDBmsg
{
   my $self=shift;
   my $msg=shift;

   if (my ($fld,$key)=$msg=~m/^Duplicate entry '(.+)' for key (\d+)\s*$/){
      return(sprintf($self->T("Duplicate entry '%s'"),$fld));
   }

   return($msg);
}



sub tieRec
{
   my $self=shift;
   my $rec=shift;
   
   my %rec;
   my $view=[$self->getFieldObjsByView([$self->getCurrentView()],
                                       current=>$rec)];
   tie(%rec,'kernel::DataObj::DB::rec',$self,$rec,$view);
   return(\%rec);
   return(undef);
   
}  

sub getFirst
{
   my $self=shift;

   if (!defined($self->{DB})){
      $self->{isInitalized}=0;
      return(undef,
             msg(ERROR,
             $self->T("no database connection or invalid database handle")));
   }
   $self->{DB}->finish();
   my @sqlcmd=($self->getSqlSelect());
   if (!defined($sqlcmd[0])){
      return(undef,join("\n",$self->LastMsg()));
   }
   my $baselimit=$self->Limit();
   $self->Context->{CurrentLimit}=$baselimit if ($baselimit>0);
   my $t0=[gettimeofday()];
   if ($self->{DB}->execute($sqlcmd[0])){
      my $t=tv_interval($t0,[gettimeofday()]);
      my $p=$self->Self();
      my $msg=sprintf("%s:time=%0.4fsec;mod=$p",NowStamp(),$t);
      $msg.=";user=$ENV{REMOTE_USER}" if ($ENV{REMOTE_USER} ne "");
      msg(INFO,"sqlcmd=%s (%s)",$sqlcmd[0],$msg);
      if ($self->{_LimitStart}>0){
         for(my $c=0;$c<$self->{_LimitStart}-1;$c++){
            my ($temprec,$error)=$self->{DB}->fetchrow();
            last if (!defined($temprec));
         }
      }
      my ($temprec,$error)=$self->{DB}->fetchrow();
      if ($error){
         return(undef,$self->{DB}->getErrorMsg());
      }
      if ($temprec){
         $temprec=$self->tieRec($temprec);
      }
      return($temprec);
   }
   return(undef,$self->{DB}->getErrorMsg());
}

sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   $self->{DB}->finish();
   return(@res);
}

sub getNext
{
   my $self=shift;
   if (defined($self->Context->{CurrentLimit})){
      $self->Context->{CurrentLimit}--;
      if ($self->Context->{CurrentLimit}<=0){
         if (lc($self->{DB}->{db}->{Driver}->{Name}) ne "mysql"){
            while(my $temprec=$self->{DB}->fetchrow()){  # on oracle DBD
            }                                     # we must read to the end
         }                                        # of request to count rows
         return(undef,"Limit reached");
      }
   }
   my $temprec=$self->{DB}->fetchrow();
   if (defined($temprec)){
      $temprec=$self->tieRec($temprec);
      return($temprec);
   }
   return(undef,undef);
}

sub ResolvFieldValue
{
   my $self=shift;
   my $name=shift;

   my $current=$self->{'DB'}->getCurrent();
   return($current->{$name});
}

sub setWorktable
{
   my $self=shift;
   $self->{Worktable}=$_[0];
   delete($self->{WorkDB});
   $self->{WorkDB}=$_[1] if (defined($self->{WorkDB}));
   return($self->{Worktable},$self->{WorkDB});
}

sub getWorktable
{
   my $self=shift;
   return($self->{Worktable},$self->{WorkDB});
}




package kernel::DataObj::DB::rec;
use strict;
use kernel;
use kernel::Universal;
use vars qw(@ISA);
use Tie::Hash;
use Data::Dumper;

@ISA=qw(Tie::Hash kernel::Universal);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   my $view=shift;
   my %HashView;
   map({$HashView{$_->Name()}=$_} @{$view});
   my $self=bless({Rec=>$rec,View=>\%HashView},$type);
   $self->setParent($parent);
   return($self);
}

sub FIRSTKEY
{
   my $self=shift;

   my %k=();
   map({$k{$_}=1;} keys(%{$self->{View}}));
   $self->{'keylist'}=[keys(%k)];
 
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;

   return(grep(/^$key$/,keys(%{$self->{View}}),keys(%{$self->{Rec}})) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{
   my $self=shift;
   my $key=shift;

   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $p=$self->getParent();
   if (defined($p)){
      my $fobj;
      if (!defined($self->{View}->{$key})){
         $fobj=$p->getField($key,$self->{Rec});
      }
      else{
         $fobj=$self->{View}->{$key};
      }
      return($p->RawValue($key,$self->{Rec},$fobj));
   }
   return("- unknown parent for '$key' - DataObj isn't valid at now -");
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{View}->{$key}=undef if (!exists($self->{View}->{$key}));
   $self->{Rec}->{$key}=$val; 
}
1;
