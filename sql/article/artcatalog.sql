use w5base;
create table artcatalog (
  id         bigint(20)  NOT NULL,
  name       varchar(40) NOT NULL, 
  frontlabel longtext, 
  mandator   bigint(20)  NOT NULL,
  databoss   bigint(20)  NOT NULL,
  cistatus   int(2)      NOT NULL,
  description longtext,
  comments    longtext,
  additional  longtext,
  logo_small  blob,
  logo_large  blob,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key name(name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artcategory (
  id           bigint(20)  NOT NULL,
  artcatalog   bigint(20)  NOT NULL, 
  partcategory bigint(20), 
  chkpartcategory bigint(20) NOT NULL,
  posno          int(7)      NOT NULL,
  frontlabel     longtext, 
  sublabel       longtext, 
  description longtext,
  comments    longtext,
  additional  longtext,
  logo_small  blob,
  logo_large  blob,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY parentcategory (partcategory)
          REFERENCES artcategory (id) ON DELETE CASCADE,
  FOREIGN KEY articlecatalog (artcatalog)
          REFERENCES artcatalog (id) ON DELETE RESTRICT,
  UNIQUE KEY `positionnumber` (artcatalog,posno,chkpartcategory),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artproduct (
  id           bigint(20)  NOT NULL,
  artcategory1 bigint(20) NOT NULL,
  artcategory2 bigint(20),artcategory3 bigint(20),
  posno1       int(7),     
  posno2       int(7),    posno3       int(7),
  pclass       char(20) default 'simple',variantof    bigint(20),
  variant      varchar(40) default 'standard',variantdesc longtext,
  frontlabel   longtext, 
  pstatus      int(2)      NOT NULL,
  productmgr   bigint(20)  NOT NULL, delivprovider bigint(20)  NOT NULL,
  orderable_from datetime default NULL,
  orderable_to   datetime default NULL,
  cost_once           double(36,2) default NULL,
  cost_day            double(36,2) default NULL,
  cost_month          double(36,2) default NULL,
  cost_year           double(36,2) default NULL,
  cost_peruse         double(36,2) default NULL,
  cost_produnit       varchar(30)  default NULL,
  cost_currency       varchar(10)  default 'EUR',
  cost_billinterval   varchar(30)  default NULL,
  cost_stepping  longtext default NULL,cost_rulesmodals longtext default NULL,
  price_once          double(36,2) default NULL,
  price_day           double(36,2) default NULL,
  price_month         double(36,2) default NULL,
  price_year          double(36,2) default NULL,
  price_peruse        double(36,2) default NULL,
  price_produnit      varchar(30)  default NULL,
  price_currency      varchar(10)  default 'EUR',
  price_billinterval  varchar(30)  default NULL,
  price_stepping longtext default NULL,price_rulesmodals longtext default NULL,
  description longtext, comments    longtext,
  additional  longtext,
  logo_small  blob, logo_large  blob,
  custoblig    longtext, premises     longtext, rest         longtext, 
  exclusions   longtext, pod          longtext, specialarr   longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY articlecategory (artcategory1)
          REFERENCES artcategory (id) ON DELETE CASCADE,
  UNIQUE KEY `positionnumber1` (artcategory1,posno1),
  UNIQUE KEY `positionnumber2` (artcategory2,posno2),
  UNIQUE KEY `positionnumber3` (artcategory3,posno3),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artdelivprovider (
  id         bigint(20)  NOT NULL,
  name       varchar(40) NOT NULL, 
  frontlabel longtext, 
  mandator   bigint(20)  NOT NULL,
  databoss   bigint(20)  NOT NULL,
  cistatus   int(2)      NOT NULL,
  description longtext,
  comments    longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key name(name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artprodopttoken (
  id         bigint(20)  NOT NULL,
  artproduct bigint(20)  NOT NULL,
  optionclass  char(10), name varchar(40),
  description longtext,  
  comments    longtext, 
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY artproduct (artproduct)
          REFERENCES artproduct (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkartelementprod (
  id         bigint(20)  NOT NULL,
  artdelivelement  bigint(20)  NOT NULL,
  artproduct       bigint(20)  NOT NULL,
  comments    longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),           
  FOREIGN KEY deliveryelement (artdelivelement)
          REFERENCES artdelivelement (id) ON DELETE CASCADE,
  FOREIGN KEY product (artproduct)
          REFERENCES artproduct (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkartprodprod (
  id         bigint(20)  NOT NULL,
  partproduct      bigint(20)  NOT NULL,
  artproduct       bigint(20)  NOT NULL,
  comments    longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),           
  FOREIGN KEY pproduct (partproduct)
          REFERENCES  artproduct (id) ON DELETE CASCADE,
  FOREIGN KEY product (artproduct)
          REFERENCES  artproduct (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artkernkpi (
  id          bigint(20)   NOT NULL,
  cistatus    int(2)       default '4',
  name        char(20) NOT NULL,
  labeldata longtext,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY (id),unique(name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artprodoptkpi (
  id         varchar(40)  NOT NULL,
  artproduct bigint(20)  NOT NULL,partproduct bigint(20)  NOT NULL,
  token      varchar(40) NOT NULL,
  description longtext,  
  comments    longtext, 
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),unique(artproduct,token),key(partproduct),
  FOREIGN KEY artproduct (artproduct)
          REFERENCES artproduct (id) ON DELETE CASCADE,
  FOREIGN KEY token (token)
          REFERENCES artkernkpi (name) ON DELETE RESTRICT,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artkernmodal (
  id          bigint(20)   NOT NULL,
  cistatus    int(2)       default '4',
  name        char(20) NOT NULL,
  labeldata longtext,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY (id),unique(name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table artprodoptmodal (
  id         varchar(40)  NOT NULL,
  artproduct bigint(20)  NOT NULL,partproduct bigint(20)  NOT NULL,
  token      varchar(40) NOT NULL,
  description longtext,  
  comments    longtext, 
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),unique(artproduct,token),key(partproduct),
  FOREIGN KEY artproduct (artproduct)
          REFERENCES artproduct (id) ON DELETE CASCADE,
  FOREIGN KEY token (token)
          REFERENCES artkernmodal (name) ON DELETE RESTRICT,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
