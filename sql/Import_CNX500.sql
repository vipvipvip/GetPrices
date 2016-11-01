	--declare @tbl table (dt smalldatetime, price dec(9,3))


	--insert @tbl
	--EXEC	[dbo].[csp_ReadCSV]
	--		@filename = 'CNX_2015.csv',
	--		@dbDir = 'c:\temp\CNX',
	--		@cols='*',
	--		@whereclause = N' 1=1'

	--insert tbl_Prices 
	--select 6469, 0, dt, price,0,0,0,0,0,0,0,0,0,0,4,0
	--from @tbl
	--order by dt

	select * from tbl_Prices where db_ticker_id = 6469 and db_dt between '1-1-2007' and '12-31-2015'
	order by db_dt