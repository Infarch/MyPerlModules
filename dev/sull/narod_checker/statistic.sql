--update site set Done=0, Host=null
select
	(select count(*) from site where done=1) as done,
	(select count(*) from site where done=1 and robots=1) as robots,
	(select count(*) from site where done=1 and robothost is not null) as robothosts,
	(select count(*) from site where done=1 and host is not null) as bingo;

