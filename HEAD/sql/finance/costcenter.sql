use w5base;
create table costcenter (
  id         bigint(20) NOT NULL,
  name       varchar(20) NOT NULL,
  cistatus   int(2)      NOT NULL,
    mandator       bigint(20)  default NULL,
    fullname       varchar(40) default NULL,
    delmgr         bigint(20)  default NULL,
    delmgr2        bigint(20)  default NULL,
    delmgrteam     bigint(20)  default NULL,
    description    longtext    default NULL,
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),KEY(fullname),KEY(mandator),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
alter table costcenter add databoss bigint(20) default NULL,add key(databoss);
alter table costcenter add is_directwfuse int(2) default '0';
alter table costcenter add ldelmgr  bigint(20) default NULL,add key(ldelmgr);
alter table costcenter add ldelmgr2 bigint(20) default NULL,add key(ldelmgr2);
