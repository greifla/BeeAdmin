-- Die W5XAUTOM_HPSA_* Objekte sind als Eingangs-Interface anzusehen, �ber
-- das die X-Automation der Market-Unit die Scan-Script Daten aus HPSA in
-- die W5Warehouse Datenbank �bertr�gt.

-- drop table "W5XAUTOM_HPSA_UC128";
-- drop sequence "W5XAUTOM_HPSA_UC128_SEQ";

CREATE TABLE "W5XAUTOM_HPSA_UC128" (  
   "ID" NUMBER NOT NULL,
   "ITEM_ID" NUMBER NOT NULL,
   "AGENT" VARCHAR2(1024 BYTE),
   "HOSTNAME" VARCHAR2(1024 BYTE) NOT NULL,
   "SYSTEMID" VARCHAR2(40 BYTE),
   "PIP" VARCHAR2(80 BYTE),
   "SWCLASS" VARCHAR2(255 BYTE),
   "SWVERS" VARCHAR2(40 BYTE),
   "SCANDATE" VARCHAR2(40 BYTE),
   "SWPATH" VARCHAR2(1024 BYTE),
   "INAME" VARCHAR2(40 BYTE),
   "MDATE" DATE,
   "CREATED_BY" VARCHAR2(100 BYTE),
   "UDATE" DATE,
   "UPDATED_BY" VARCHAR2(100 BYTE),
   "ISDELETED" NUMBER NOT NULL,
   CONSTRAINT "PKID" PRIMARY KEY ("ID")
);    
CREATE SEQUENCE  "W5XAUTOM_HPSA_UC128_SEQ" MINVALUE 1 
   INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

CREATE OR REPLACE TRIGGER "W5XAUTOM_HPSA_UC128_INC"
BEFORE INSERT ON "W5XAUTOM_HPSA_UC128"
FOR EACH ROW
ENABLE

BEGIN
  SELECT "W5XAUTOM_HPSA_UC128_SEQ".NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
grant select on "W5XAUTOM_HPSA_UC128" to W5I;
grant select,insert,update,delete on "W5XAUTOM_HPSA_UC128" to W5XAUTOM;
create or replace synonym W5XAUTOM.UC128_1_MW_REPORT for "W5XAUTOM_HPSA_UC128";


