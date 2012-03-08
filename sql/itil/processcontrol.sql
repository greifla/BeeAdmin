use w5base;
create table softwareset (
  id          bigint(20)  NOT NULL,
  name        varchar(80) NOT NULL,
  cistatus    int(2)      NOT NULL,
    mandator       bigint(20)  default NULL,
    databoss       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
create table lnksoftwaresoftwareset (
  id           bigint(20) NOT NULL,
  softwareset  bigint(20) NOT NULL,
  software     bigint(20) NOT NULL,
  version      varchar(30),
  releasekey   char(20) default '00000000000000000000',
  comparator   char(1)  default '0', 
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id), KEY software (software),key(releasekey),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
