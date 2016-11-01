declare @tblA table (s varchar(50))
declare @tblB table (s varchar(50))
declare @tblC table (s varchar(50))
declare @tblD table (s varchar(50))
declare @tblE table (s varchar(50))
declare @tblF table (s varchar(50))
declare @tblG table (s varchar(50))

insert @tblA
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'All_stocks.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblA where s like '%.%'
delete from @tblA where s like '%--%'
delete from @tblA where s like '%/%'


insert @tblB
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'ivv.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblB where s like '%.%'
delete from @tblB where s like '%--%'
delete from @tblB where s like '%/%'


insert @tblC
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'ijh.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblC where s like '%.%'
delete from @tblC where s like '%--%'
delete from @tblC where s like '%/%'


insert @tblD
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'ijr.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblD where s like '%.%'
delete from @tblD where s like '%--%'
delete from @tblD where s like '%/%'



insert @tblE
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'brandnames.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblE where s like '%.%'
delete from @tblE where s like '%--%'
delete from @tblE where s like '%/%'


insert @tblF
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'Nasdaq100.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblF where s like '%.%'
delete from @tblF where s like '%--%'
delete from @tblF where s like '%/%'


insert @tblG
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'iwr.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tblG where s like '%.%'
delete from @tblG where s like '%--%'
delete from @tblG where s like '%/%'

delete from @tblA
where s in (
select * from @tblA
where s not in (select db_strTicker from tbl_Ticker)
)

select * from @tblA 
where s not in ( select * from @tblB) 
and s not in (select * from @tblC)
and s not in (select * from @tblD)
and s not in (select * from @tblE)
and s not in (select * from @tblF)
and s not in (select * from @tblG)

select * from @tblA
where s in (
select distinct(s) from 
(
select *, 'B' as SRC from @tblB
--where s in (select * from @tblA)
union
select *, 'C' as SRC  from @tblC
--where s in (select * from @tblA)
union
select *, 'D' as SRC  from @tblD
--where s in (select * from @tblA)
union
select *, 'E' as SRC  from @tblE
--where s in (select * from @tblA)
union
select *, 'F' as SRC  from @tblF
--where s in (select * from @tblA)
union
select *, 'G' as SRC from @tblG
--where s in (select * from @tblA)
) as A
)

