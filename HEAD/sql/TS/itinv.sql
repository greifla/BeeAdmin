use w5base;
#
alter table appl add ictoid varchar(20), add key(ictoid), add ictono varchar(20),add key(ictono);
alter table appl add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20), add scapprgroupid2 bigint(20);
alter table swinstance add acinmassignmentgroupid bigint(20), add scapprgroupid bigint(20);
