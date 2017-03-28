use w5base;
create table metagrpmgmt (
  id         bigint(20)    NOT NULL,
  name       varchar(40)   NOT NULL,
  fullname   varchar(255)  NOT NULL,
  cistatus   int(2)        NOT NULL,chkdate datetime default NULL,key(chkdate),
  is_chmmgr     bool default NULL, is_chmimpl     bool default NULL,
  is_chmassign  bool default NULL, is_chmcoord    bool default NULL,
  is_chmapprov  bool default NULL, is_resp4all    bool default NULL,
  is_chmreview  bool default NULL, 
  is_inmmgr     bool default NULL, 
  is_inmassign  bool default NULL, 
  is_prmmgr     bool default NULL, 
  is_prmassign  bool default NULL, 
  is_cfmmgr     bool default NULL, 
  is_cfmassign  bool default NULL, 
  is_org        bool default NULL, 
  is_line       bool default NULL, 
  is_depart     bool default NULL, 
  is_resort     bool default NULL, 
  is_team       bool default NULL, 
  is_orggroup   bool default NULL, 
  smid          varchar(80) default NULL,key(smid),
  smdate        datetime    default NULL,smadmgrp varchar(80) default NULL,
  w5id          varchar(80) default NULL,key(w5id),
  w5date        datetime    default NULL,
  amid          varchar(80) default NULL,key(amid),
  amdate        datetime    default NULL,
  smbbid        varchar(80) default NULL,key(smbbid),
  smbbdate      datetime    default NULL,
  scid          varchar(80) default NULL,key(scid),
  scdate        datetime    default NULL,
  description longtext     default NULL,contactemail varchar(255) default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY fullname (fullname),
  UNIQUE KEY `srcsys` (srcsys,srcid),key `srcload` (srcsys,srcload)
) ENGINE=INNODB;
CREATE TABLE lnkmetagrp (
  id             bigint(20) NOT NULL,
  targetid       bigint(20) NOT NULL,
  refid          bigint(20) NOT NULL,
  parentobj      varchar(40) NOT NULL,
  responsibility varchar(20) default '',
  createdate     datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate     datetime NOT NULL default '0000-00-00 00:00:00',
  createuser     bigint(20) NOT NULL default '0',
  modifyuser     bigint(20) NOT NULL default '0',
  editor         varchar(100) NOT NULL default '',
  realeditor     varchar(100) NOT NULL default '',
  PRIMARY KEY (id),
  KEY parent (parentobj,refid),
  UNIQUE KEY grp (targetid,parentobj,refid,responsibility),
  FOREIGN KEY fk_metagrp (targetid) REFERENCES metagrpmgmt (id) ON DELETE CASCADE
) ENGINE=INNODB;
