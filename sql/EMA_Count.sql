declare @tbl_Final table (idx int identity, dt datetime, cnt_A int, cnt_B int)

insert @tbl_Final
select dt,0,0 from tbl_Return_Rank
where tid = 442
and dt > '12-31-2006'
order by dt

declare @nMonths int
select @nMonths = @@ROWCOUNT

declare @tbl table (tid int)
insert @tbl
--EXEC	[dbo].[csp_ReadCSV]
--		@filename = N'ETF_Segments.csv',
--		@dbDir = N'c:\stockmon',
--		@whereclause = N'1=1'
select db_ticker_id from tbl_Ticker where db_type=2

declare @idx int
set @idx = 1

declare @curr_dt datetime
declare @cnt int

while exists (select * from @tbl_Final where idx = @idx)
  begin
	select @curr_dt = dt from @tbl_Final where idx = @idx

	SELECT @cnt = count(*)
	  FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
	  where T.db_type = 2
	  and T.db_ticker_id in (select * from @tbl)
	  and P.db_ticker_id = T.db_ticker_id
	  and P.[db_MA50] is not null
	  and P.[db_MA200] is not null
	  and P.[db_EMA25] is not null
	  and P.[db_MA15] is not null
	  and P.[db_EMA10] is not null

	  and P.db_close <= P.db_MA50
	  and P.db_close >= P.db_MA200

	  and P.db_EMA10 >= P.db_MA15
	  and P.db_EMA10 <= P.db_MA50

	  and P.db_MA50 >= P.db_MA200
	  and P.db_dt = @curr_dt

	update @tbl_Final set cnt_A = @cnt where dt = @curr_dt

	SELECT @cnt = count(*)
	FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
	where T.db_type = 2
	and T.db_ticker_id in (select * from @tbl)
	and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	and P.[db_MA200] is not null
	and P.[db_EMA25] is not null
	and P.[db_MA15] is not null
	and P.[db_EMA10] is not null

	and P.db_EMA10 >= P.db_MA15
	and P.db_MA15 >= P.db_MA50
	and P.db_EMA10 >= P.db_MA50
	and P.db_MA50 >= P.db_MA200
	and P.db_dt = @curr_dt

	update @tbl_Final set cnt_B = @cnt where dt = @curr_dt

	set @idx = @idx + 1
  end

select * from @tbl_Final