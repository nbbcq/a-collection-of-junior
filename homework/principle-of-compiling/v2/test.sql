--! 测试 create / use / drop
create database test;
use test;
create table test(i int);
drop table test;
drop database test;
create database data;
use data;
create table tb(i int, f float, s string);
--! 测试 insert / expr
insert into tb values (1, 2.0);
insert into tb values(2, 2.0, "st");
insert into tb values(3, 3, "str");
insert into tb values(4.0, 4.0, "stri"); --! error
insert into tb values('s', 2, 'strin');  --! error
insert into tb (i) values (5);
insert into tb (i) values (5+1);
insert into tb (i) values (1.0+6);
insert into tb (i) values (6+1.0);
insert into tb (f) values (7-1.0);
insert into tb (f) values (8*1.0);
insert into tb (f) values (9/1.0);
insert into tb (f) values (2^4);
insert into tb (f) values (100);
select * from tb;
select i, f from tb;
--! 测试 bool expr
delete from tb where f==5;
delete from tb where i==5;
select * from tb;
delete from tb where i==2 && i==3 && i==6;
delete from tb where i==2 || i==3 || i==6;
select * from tb;
update tb set s="string"  where f==(8);
update tb set i=8,f=9.0,s="string" where i==1;
update tb set s="string" where s!="string";
update tb set i=20 where i!=10;
update tb set i=10 where s=="string";
update tb set i=80  where f==6.0;
update tb set f=30.0 where f!=30.0;
select * from tb;
