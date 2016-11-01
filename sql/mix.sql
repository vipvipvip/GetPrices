declare @tbl table (idx int identity, fn varchar(100) )
declare @tbl2 table (idx int identity, fn varchar(100) )
declare @tbl3 table (idx int identity, fn varchar(100) )
declare @tbl4 table (idx int identity, fn varchar(100) )
declare @tbl5 table (idx int identity, fn varchar(100) )
declare @dir varchar(50)
set @dir = 'c:\stockmon'


	insert @tbl
	EXEC	[dbo].[csp_ReadCSV]
			@filename = 'all_stocks.csv',
			@dbDir = @dir,
			@cols='Ticker',
			@whereclause = N'1=1'

	insert @tbl2
	EXEC	[dbo].[csp_ReadCSV]
			@filename = 'ivv.csv',
			@dbDir = @dir,
			@cols='Ticker',
			@whereclause = N'1=1'

	insert @tbl
	select fn from @tbl2 where fn not in (select fn from @tbl)


	insert @tbl3
	EXEC	[dbo].[csp_ReadCSV]
			@filename = 'ijh.csv',
			@dbDir = @dir,
			@cols='Ticker',
			@whereclause = N'1=1'

	insert @tbl
	select fn from @tbl3 where fn not in (select fn from @tbl)


	--insert @tbl4
	--EXEC	[dbo].[csp_ReadCSV]
	--		@filename = 'ijr.csv',
	--		@dbDir = @dir,
	--		@cols='Ticker',
	--		@whereclause = N'1=1'

	--insert @tbl
	--select fn from @tbl4 where fn not in (select fn from @tbl)

	insert @tbl5
	EXEC	[dbo].[csp_ReadCSV]
			@filename = 'nasdaq100.csv',
			@dbDir = @dir,
			@cols='Ticker',
			@whereclause = N'1=1'

	insert @tbl
	select fn from @tbl5 where fn not in (select fn from @tbl)

	select A.* from @tbl A, tbl_Ticker T
	where A.fn = T.db_strTicker
	order by fn

	--select A.* 
	--from @tbl A
	--left outer join tbl_Ticker T on T.db_strTicker = A.fn
	--where T.db_strTicker is null
	--order by fn

	--select T.db_strTicker 
	--from tbl_Ticker T
	--left outer join @tbl A on T.db_strTicker = A.fn
	--where A.fn is null
	--order by fn
