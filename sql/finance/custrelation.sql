use w5base;
create table custcontract (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  cistatus   int(2)      NOT NULL,
    fullname       varchar(80) default NULL,
    contractid     varchar(20) default NULL,
    custorderno    varchar(20) default NULL,
    contractclass  varchar(20) default NULL,
    databoss       bigint(20)  default NULL,
    sem            bigint(20)  default NULL,
    sem2           bigint(20)  default NULL,
    mandator       bigint(20)  default NULL,
    responseteam   bigint(20)  default NULL,
    durationstart  datetime NOT NULL default '0000-00-00 00:00:00',
    durationend    datetime    default NULL,
    autoexpansion  int(20)     default NULL,
    cancelperiod   int(20)     default NULL,
    customer       bigint(20)  default NULL,
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
  UNIQUE KEY contractid (contractid),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
alter table custcontract add conumber varchar(20) default NULL;
alter table custcontract add lastqcheck datetime default NULL,add key(lastqcheck);
alter table custcontract add databoss2 bigint(20)  default NULL;
