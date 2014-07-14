use w5base;
create table TCOM_appl (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  origname   varchar(40) NOT NULL, 
    wbv            bigint(20)  default NULL,
    wbv2           bigint(20)  default NULL,
    ev             bigint(20)  default NULL,
    ev2            bigint(20)  default NULL,
    itv            bigint(20)  default NULL,
    itv2           bigint(20)  default NULL,
    inm            bigint(20)  default NULL,
    inm2           bigint(20)  default NULL,
    ippl           bigint(20)  default NULL,
    ippl2          bigint(20)  default NULL,
    customerprio   int(2)      default NULL,customer bigint(20),
    description    longtext    default NULL,
    additional     longtext    default NULL,
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
  key(wbv),  key(wbv2),
  key(ev),   key(ev2),
  key(itv),  key(itv2),
  key(inm),  key(inm2),
  key(ippl), key(ippl2),key(customer),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
alter table TCOM_appl add custapplid varchar(20);
drop table TCOM_appl;