use w5base;
create table interface_tssapp01_01 (
  id           bigint(20)  NOT NULL,
  name         varchar(30) NOT NULL,etype char(20) NOT NULL,
  description  longtext    default NULL, accarea varchar(20) default NULL,
  status       varchar(20) default NULL,
  isdeleted    int(1)      default '0',
  databosswiw  varchar(8)  default NULL,
  smwiw        varchar(8)  default NULL,
  dmwiw        varchar(8)  default NULL,
  sapcustomer  varchar(80) default NULL,
  saphier1     varchar(20) default NULL,
  saphier2     varchar(20) default NULL,
  saphier3     varchar(20) default NULL,
  saphier4     varchar(20) default NULL,
  saphier5     varchar(20) default NULL,
  saphier6     varchar(20) default NULL,
  saphier7     varchar(20) default NULL,
  saphier8     varchar(20) default NULL,
  saphier9     varchar(20) default NULL,
  saphier10    varchar(20) default NULL,
  pconumber    varchar(20) default NULL,
  normodel     varchar(5)  default NULL,
  norn         varchar(5)  default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(30) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY `name` (name,srcsys),
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=MyISAM DEFAULT CHARSET=latin1;
create table interface_tssapp01_02 (
  id           bigint(20)  NOT NULL,
  name         varchar(30) NOT NULL,
  etype char(20) NOT NULL, accarea varchar(20) default NULL,
  description  longtext    default NULL,
  isdeleted    int(1)      default '0',
  responsiblewiw  varchar(8)  default NULL,
  saphier1     varchar(20) default NULL,
  saphier2     varchar(20) default NULL,
  saphier3     varchar(20) default NULL,
  saphier4     varchar(20) default NULL,
  saphier5     varchar(20) default NULL,
  saphier6     varchar(20) default NULL,
  saphier7     varchar(20) default NULL,
  saphier8     varchar(20) default NULL,
  saphier9     varchar(20) default NULL,
  saphier10    varchar(20) default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(30) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY `name` (name,srcsys),
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=MyISAM DEFAULT CHARSET=latin1;
alter table interface_tssapp01_01 add bpmark varchar(20);
alter table interface_tssapp01_01 add ictono varchar(20);
create table interface_tssapp01_gpk (
  id           bigint(20)  NOT NULL,
  name         varchar(10) NOT NULL,
  description  longtext    default NULL,
  phase        varchar(20) NOT NULL,
  response     varchar(40) NOT NULL,
  allocation   varchar(40) default NULL,
  comments     longtext    default NULL,
  perftype     varchar(20) NOT NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(30) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY `name` (name,srcsys),
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=MyISAM DEFAULT CHARSET=latin1;