use w5base;
CREATE TABLE wfattach (
  wfattachid bigint(20) NOT NULL default '0',
  wfdataid bigint(20) default NULL,
  wfheadid bigint(20) default NULL,
  data blob,
  createuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (wfattachid),
  KEY createdate (createdate),
  KEY wfheadid (wfheadid),
  KEY wfdataid (wfdataid)
);
CREATE TABLE wfkey (
  id bigint(20) NOT NULL,
  name varchar(30) NOT NULL default '',
  fval varchar(128) NOT NULL default '',
     wfstate    tinyint(3) default NULL,
     opendate   datetime   default NULL,
     closedate  datetime   default NULL,
     eventstart datetime   default NULL,
     eventend   datetime   default NULL,
     wfclass varchar(30)   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) default NULL,
  realeditor varchar(100) default NULL,
  UNIQUE KEY nameval (fval,name,id),
  KEY name (name,id), key id(id),
  KEY nameeventstart (name,eventstart,wfclass,fval),
  KEY nameeventend (name,eventend,wfclass,fval),
  KEY nameopendate (name,opendate,wfclass,fval),
  KEY nameclosedate (name,closedate,wfclass,fval),
  KEY wfstate (name,wfstate,wfclass,fval),KEY eventend (eventend,wfclass)
);
CREATE TABLE wfaction (
  wfactionid bigint(20) NOT NULL default '0',
  wfheadid bigint(20) NOT NULL default '0',
  name        varchar(30) NOT NULL,
  translation varchar(40) NOT NULL,
  actionref   longtext NOT NULL,
  additional  longtext NOT NULL,
  comments    longtext default NULL,effort int(14),
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys varchar(40) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (wfactionid),
  KEY action (wfheadid,name),key(createuser,createdate),
  KEY modifydate (modifydate),key srcsys(srcid,srcsys),
  KEY wfheadid (wfheadid)
);
CREATE TABLE wfhead (
  wfheadid bigint(20) NOT NULL default '0',
  shortdescription varchar(128) NOT NULL default '',
  description text NOT NULL,
  wfstate tinyint(3) unsigned default NULL,prio int(1) default '5',
  wfclass varchar(30) NOT NULL default '',
  wfstep varchar(40) NOT NULL default '',
  fwdtarget varchar(20) default NULL,
  fwdtargetid bigint(20) default NULL,
  fwddebtarget varchar(20) default NULL,
  fwddebtargetid bigint(20) default NULL,
  opendate datetime NOT NULL default '0000-00-00 00:00:00',
  closedate datetime default NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  openuser bigint(20) default NULL,
  openusername varchar(255) default NULL,
  closeuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  eventstart datetime default NULL,
  eventend datetime default NULL,
  headref longtext NOT NULL,
  initiallang   varchar(5) NOT NULL,
  initialsite   varchar(128) NOT NULL,
  initialconfig varchar(20) NOT NULL,
  initialclient varchar(20) NOT NULL,
  srcsys varchar(100) default NULL,
  srcid varchar(40) default NULL,
  srcload datetime default NULL,
  additional longtext default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (wfheadid),
  KEY openuser (openuser,wfstate),KEY modifyuser (modifyuser,wfstate),
  unique srcsys(srcsys,srcid),key srcid(srcid),
  key srcload(srcsys,srcload),key modifydate(modifydate,wfstate),
  key fwd(fwdtarget,fwdtargetid,wfstate),
  key wfclass(wfclass,wfstep),
  key wfstep(wfstep)
);
CREATE TABLE joblog (
  id bigint(20) NOT NULL default '0',
  method    varchar(128) NOT NULL default '',
  event     varchar(40)  NOT NULL default '',
  exitcode  int(20)      default NULL,srcsys varchar(10) default 'w5base',
  pid       int(20)      default NULL,srcid varchar(20) default NULL,
  exitstate varchar(20)  default NULL,srcload datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),
  KEY method (method),key srcload(srcload),
  KEY event  (event,method),key(pid),
  KEY createdate  (createdate),
  KEY modifydate  (modifydate,method,exitcode)
);
alter table wfaction add privatestate int(2) default '0';
CREATE TABLE wfrelation (
  wfrelationid bigint(20) NOT NULL default '0',
  srcwfid bigint(20) NOT NULL default '0',
  dstwfid bigint(20) NOT NULL default '0',
  name        varchar(30) NOT NULL,
  translation varchar(40) NOT NULL,
  additional  longtext NOT NULL,
  comments    longtext default NULL,
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys varchar(40) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (wfrelationid),
  key srcid (srcwfid),key dstid (dstwfid)
);
CREATE TABLE wfworkspace (
  id          bigint(20) NOT NULL default '0',
  wfheadid    bigint(20) default NULL,
  fwdtarget   varchar(20) default NULL,
  fwdtargetid bigint(20) default NULL,
  additional  longtext NOT NULL,
  createuser  bigint(20) NOT NULL default '0',
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY (id),key fwd(fwdtarget,fwdtargetid)
);
alter table wfhead add directlnktype varchar(40) default NULL, add directlnkid bigint(20) default NULL,add directlnkmode varchar(20) default NULL,add key directlnk(directlnktype,directlnkid,wfstate,directlnkmode),add key directlnkev(directlnktype,directlnkid,eventend);
CREATE TABLE wfrepjob (
  id          bigint(20) NOT NULL default '0',
  targetfile  varchar(255) default NULL,
  reportname  varchar(20)  default NULL,
  mday        int default '1',
  runmday     varchar(20) default NULL,
  flt_name    text default NULL,
  flt_state   text default NULL,
  flt_class   text default NULL,
  flt_desc    text default NULL,
  flt_step    text default NULL,
  flt1_name   varchar(20) default NULL,
  flt1_value  text default NULL,
  flt2_name   varchar(20) default NULL,
  flt2_value  text default NULL,
  flt3_name   varchar(20) default NULL,
  flt3_value  text default NULL,
  flt4_name   varchar(20) default NULL,
  flt4_value  text default NULL,
  flt_code    text default NULL,
  repfields   text default NULL,
  sumcount1on varchar(20) default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(10) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY (id)
);
alter table wfrepjob add cistatus int(2) NOT NULL;
alter table wfrepjob add timezone varchar(20) NOT NULL;
alter table wfrepjob add funccode text NOT NULL;
