set nocount on;

declare @tbl_Dates table (idx int identity, dte datetime, stkCnt int, i1 int, i2 int, totrR int, Port_ret dec(9,4), nCommon int, nNew int, TradeDate datetime, [$avail] dec(9,4), nShares int, [$invested] dec(9,4), [$cash] dec(9,4) )

declare @tbl_Selections table (idx int identity, dte datetime, tid int, price dec(9,3)
		,tick varchar(10), ePrice dec(9,3), rR int, r1 int, Q dec(9,3) )

declare @tbl_Final table (idx int identity, dte datetime, tid int,  price dec(9,3)
		,tick varchar(10), ePrice dec(9,3), rR int, Q dec(9,3), allocn dec(9,3), WtdEquityret dec(9,5) )

declare @tbl_Common table (tick varchar(10), allocn dec(9,2) )
declare @tbl_New table (tick varchar(10), allocn dec(9,2) )

insert @tbl_Dates
select distinct(dt),0,0,0,0,0,0,0,0,0,0,0,0
from tbl_Return_Rank
where dt > '12-29-2006'
--where dt > '1-1-2015'
order by dt asc


declare @id int
set @id=1
declare @aDt datetime
declare @tDt datetime

-- acquire second trading date of the month
while exists (select * from @tbl_Dates where idx=@id)
  begin
	select @aDt = dte from @tbl_Dates where idx = @id
	select top 1 @tDt = db_dt
	from tbl_Prices
	where db_dt  > @aDt
	and db_ticker_id = 538
	
	print 'For idx ' + convert(varchar, @id) + ' dates: ' + convert(varchar,@aDt) + ' found ' + convert(varchar,@tDt)

	update @tbl_Dates
	set TradeDate = @tDt
	where idx = @id

	set @id=@id+1
  end

-- collect tickers of interest
declare @dir varchar(50)
set @dir = 'c:\stockmon'

declare @srcFN varchar (100)
set @srcFN=NULL
--set @srcFN = 'qqq.csv'
--set @srcFN = 'IYW.csv'
--set @srcFN = 'Tech_Horses.csv'
--set @srcFN = 'td_sym.csv'
--set @srcFN = 'global.csv'
--set @srcFN = 'tda.csv'
--set @srcFN = 'tda_cap.csv'
--set @srcFN = 'SP_Div_Aristocrats.csv'
--set @srcFN = 'Top_10.csv'
--set @srcFN = 'BrandNames.csv'
--set @srcFN = 'VG_ETF.csv'
--set @srcFN = 'ALL_ETFs.csv'
--set @srcFN = 'ALL_STOCKS.csv'
--set @srcFN = '1747.csv'
--set @srcFN = 'iTOT.csv'
set @srcFN = 'ivv.csv'
--set @srcFN = 'iwr.csv'
--set @srcFN = 'ijh.csv'
--set @srcFN = 'ijr.csv'
--set @srcFN = 'DIA.csv'
--set @srcFN = 'mix.csv'

--set @srcFN = 'TD_Comm_Free.csv'
--set @srcFN = 'TD_Comm_Free_Equities.csv'
--set @srcFN = 'AOX.csv'
--set @srcFN = 'VG_MF.csv'
--set @srcFN = 'VG_MF_AOX.csv'

declare @tbl table (idx int identity, fn varchar(100) )
declare @tbl2 table (idx int identity, fn varchar(100) )

if @srcFN is not null
  begin
	insert @tbl
	EXEC	[dbo].[csp_ReadCSV]
			@filename = @srcFN,
			@dbDir = @dir,
			@cols='Ticker',
			@whereclause = N'1=1'

	--insert @tbl2
	--EXEC	[dbo].[csp_ReadCSV]
	--		@filename = 'nasdaq100.csv',
	--		@dbDir = @dir,
	--		@cols='Ticker',
	--		@whereclause = N'1=1'

	--insert @tbl
	--select fn from @tbl2 where fn not in (select fn from @tbl)

	insert @tbl
	select distinct(RR.strTicker)
	from tbl_Return_Rank RR
	where RR.strTicker in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY'  )
	and RR.strTicker not in (select fn from @tbl)
  end
else
	insert @tbl
	select distinct(T.db_strTicker)
	from tbl_Ticker T --, tbl_Return_Rank RR
	where 1=1
	--and T.db_ticker_id = RR.tid
	--and ( T.db_type=3 )
	and ( T.db_type = 1 or T.db_strTicker in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY'  ))

declare @t_dt datetime
declare @e_dt datetime
declare @l1 int, @l2 int, @l3 int, @l4 int
declare @cnt int

set @id=1
while exists (select * from @tbl_Dates where idx = @id)
  begin
  	select @t_dt= dte from @tbl_Dates where idx = @id
	print 'processing dt= [' + convert(varchar, @t_dt) + ']'
	if exists (select * from tbl_Return_Rank where strTicker='SDS' and rRank > 0 and dt = @t_dt)
	  begin
		insert @tbl_Selections
		select @t_dt, tid, price, strTicker,0, rRank, r1, 0 --NTILE(4) OVER(order by rRank asc)
		from tbl_Return_Rank
		where strTicker in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY'  )
		--and strTicker not in (select tick from @tbl_Selections where dte = @t_dt)
		and dt = @t_dt
		and rRank > 0
		--force add 'SHY' if no bond ETFs were inserted in previous step
		if not exists (select * from @tbl_Selections where dte = @t_dt)
			insert @tbl_Selections
			select @t_dt, tid, price, strTicker,0, rRank, r1, 99 --NTILE(4) OVER(order by rRank asc)
			from tbl_Return_Rank
			where strTicker in ('SHY')
			and dt = @t_dt
	  end
	else
	  begin
		insert @tbl_Selections
		select @t_dt, RR.tid, RR.price, RR.strTicker,0, RR.rRank, RR.r1, 0 --NTILE(4) OVER(order by RR.rRank desc)
		from tbl_Return_Rank RR-- , tbl_Prices P
		where 1=1
		--and RR.tid = P.db_ticker_id
		--and RR.dt = P.db_dt 
		and dt = @t_dt
		--and P.db_avg > P.db_mult
		and price >= 10.00
		and r1 < 20 --- avoid high fliers/takeovers with 20%+ gain in a month
		and r1 > -2 --- cannot have lost more than 2%
		and r12 <> 0 -- require at least a year's worth of history
		and (r1 > r3 or r3 > r6 or r6 > r12)
		and rRank between 0 and 100
		and strTicker in (select fn from @tbl)
		and strTicker not in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY' )
		
		-- calc slope of rRank
		--print '@t_dt for slope = ' + convert(varchar, @t_dt)

		-- update @tbl_Selections
		--   set Q = (SELECT [dbo].[fn_CalcRankSlope] (
		--   DATEADD(YEAR, -1, @t_dt) -- convert(varchar, month(@t_dt)+1) + '-15-' + convert(varchar, year(@t_dt)-1)
		--  ,@t_dt
		--  ,ATID))
		--  from (select tid as ATID from @tbl_Selections where dte = @t_dt) A
		--  where tid = ATID
		--  and dte = @t_dt
		--delete from @tbl_Selections where dte = @t_dt and Q <= 0

		if not exists (select * from @tbl_Selections where dte = @t_dt)
			insert @tbl_Selections
			select @t_dt, tid, price, strTicker,0, rRank, r1, 99 --NTILE(4) OVER(order by rRank asc)
			from tbl_Return_Rank
			where strTicker in ('SHY')
			and dt = @t_dt
	  end	

	--get the prices after the second trading day of the month - since we gen signals on 1st of the 
	--month and hence earliest we can trade is on the second trading day of the month
	-- so price set to second trading of the month
	-- and ePrice set to second trading of the following month
	select @e_dt= TradeDate from @tbl_Dates where idx = @id
	print 'Updating prices ----- for idx=[' + convert(varchar, @id) + ']'
	print 'tdt ' + convert(varchar,@t_dt)
	print 'edt ' + convert(varchar,@e_dt)
	update @tbl_Selections
	--set ePrice=A.PRICE
	set price=A.PRICE
	from (select db_ticker_id, db_close as PRICE, db_dt as DT 
			from tbl_Prices
			where db_dt = @e_dt
			and db_close is not null
			and db_ticker_id in (
					select db_ticker_id 
					from tbl_Ticker 
					where db_strTicker in (select fn from @tbl)
					or db_strTicker  in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY' )
				)
		  ) as A
	where dte= @t_dt
	and tid = A.db_ticker_id

	select @e_dt= TradeDate from @tbl_Dates where idx = @id+1
	print 'edt ' + convert(varchar,@e_dt)
	print '-----'
	update @tbl_Selections
	set ePrice=A.PRICE
	from (select db_ticker_id, db_close as PRICE, db_dt as DT 
			from tbl_Prices
			where db_dt = @e_dt
			and db_close is not null
			and db_ticker_id in (
					select db_ticker_id 
					from tbl_Ticker 
					where db_strTicker in (select fn from @tbl)
					or db_strTicker  in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY'  )
				)
		  ) as A
	where dte= @t_dt
	and tid = A.db_ticker_id

	if exists (select * from tbl_Return_Rank where strTicker='SDS' and rRank > 0 and dt = @t_dt)
	  begin
		insert @tbl_Final
		select dte, tid, price, tick, ePrice, rR, Q, 0,0
		from @tbl_Selections
		where dte = @t_dt
		and tick in ('TLT','AGG', 'EMB','HYG',   'LQD', 'TIP', 'SHY'  )
	  end
	else
	  begin
		--select top 1 @l1=rR from @tbl_Selections where Q=1 and dte = @t_dt
		--order by rR desc
		--select top 1 @l2=rR from @tbl_Selections where Q=4 and dte = @t_dt
		--order by rR desc

		insert @tbl_Final
		select top 10 dte, tid, price, tick, ePrice, rR, Q, 0,0
		from @tbl_Selections
		where dte = @t_dt
		--and rR <= @l2 and rR >= @l1
		order by rR desc, r1 desc
	  end
	  
    set @id= @id+1
  end

-- not all months have 10 stocks.. so need to get a count 
  update @tbl_Dates
  set stkCnt = A.cnt
  from (
  select dte as DT, count(*) as cnt from @tbl_Final
  group by dte
  ) as A
  where dte = A.DT
  
  -- and calc return for each month based on number of stocks for each month in @tbl_Final
set @id=1
declare @c int
declare @fidx int
set @fidx=1


-- now we need to calc allocation for each selected stock for each month
-- using the i1 and 12 from @tbl_Dates and picking the rows with those
-- idx values from @tbl_Final
declare @sum dec(9,3)
while exists (select * from @tbl_Dates where idx = @id)
  begin
	select @t_dt= dte, @c = stkCnt from @tbl_Dates where idx = @id
	set @l1 = @fidx
	set @l2 = @fidx+@c-1

	update @tbl_Dates
	set i1 = @l1, i2 = @l2
	where dte = @t_dt

	select @sum = sum(rR) from @tbl_Final where idx between @l1 and @l2
	if @sum <=0 
	  begin
		set @sum = @c
		update @tbl_Final
		set allocn = 1/@sum
		where dte = @t_dt
	  end	
	else --set allocation for each selected stock
		update @tbl_Final
		set allocn = rR/@sum
		where dte = @t_dt

	-- check if 100% is allocated to one stock
	select @cnt=count(*) from @tbl_Final where allocn=1.0 and dte=@t_dt and idx=@l1
	if @cnt = 1
	 begin
		set @sum = @c
		update @tbl_Final
		set allocn = 1/@sum
		where dte = @t_dt
	 end

	-- do this to round up allocn to 100 for each month
	update @tbl_Final
	set allocn = allocn + 1-A.alloc
	from (select sum(allocn) as alloc from @tbl_Final where dte=@t_dt and idx between @l1 and @l2 ) as A
	where dte = @t_dt
	and idx = @l1

	-- then calc wtd ret using allocn
	update @tbl_Final
	set WtdEquityret = ((eprice-price)/price  * allocn)
	where dte = @t_dt

	update @tbl_Dates
	set totrR = (select sum(rR) from @tbl_Final where dte = @t_dt)
	where dte=@t_dt

	update @tbl_Dates
	set Port_ret = (select sum(WtdEquityret) from @tbl_Final where dte = @t_dt and idx between @l1 and @l2)
	where dte=@t_dt

	set @fidx=@fidx+@c
	set @id= @id+1
  end

-- Do latest date calcs {
declare @mxDte datetime
select @mxDte = max(db_dt) from tbl_Prices where db_dt > @t_dt


update @tbl_Final
set ePrice = A.APrice
from (select db_dt as ADTE, db_close as APrice, db_strTicker as ATICK from tbl_Prices P, tbl_Ticker T where T.db_ticker_id in ( select tid from @tbl_Final where dte = @t_dt) and T.db_ticker_id = P.db_ticker_id and P.db_dt=@mxDte) as A
where idx between @l1 and @l2
and Tick = ATICK

update @tbl_Final
set WtdEquityret = coalesce(((eprice-price)/price  * allocn),0)
where idx between @l1 and @l2

update @tbl_Dates
set Port_ret = (select sum(WtdEquityret) from @tbl_Final where dte = @t_dt and idx between @l1 and @l2)
where dte=@t_dt
---- }

if 1=0 
begin
  -- calc # of trades for each month based on unique tickers
set @id=2

while exists (select * from @tbl_Dates where idx = @id)
  begin
	select @t_dt= dte, @c = stkCnt, @l1=i1, @l2=i2 from @tbl_Dates where idx = @id
	select @l3=i1, @l4=i2 from @tbl_Dates where idx = @id-1

	insert @tbl_Common
	select tick, allocn from @tbl_Final where idx between @l1 and @l2
	intersect
	select tick, allocn from @tbl_Final where idx between @l3 and @l4

	insert @tbl_New
	select tick, allocn from @tbl_Final where idx between @l1 and @l2
	except
	select tick, allocn from @tbl_Final where idx between @l3 and @l4

	update @tbl_Dates
	set nCommon = A.Common, nNew = B.New
	from
			(select count(*) as Common from @tbl_Common) as A,
			(select count(*) as New from @tbl_New ) as B
		
	where dte = @t_dt
	delete from @tbl_Common
	delete from @tbl_New

	set @id=@id+1
  end
end

  select convert(char(2),month(dte)) + '-' + convert(char(2),day(dte)) + '-' + convert(char(4),year(dte)), Tick, Price, ePrice, allocn, WtdEquityret, rR 
  from @tbl_Final 
  --where rR > 0
  order by dte
  select * from @tbl_Dates order by dte
  --select convert(char(2),month(dte)) + '-' + convert(char(2),day(dte)) + '-' + convert(char(4),year(dte)), Tick, Price, ePrice, allocn, WtdEquityret, rR 
  --from @tbl_Final
  --group by Tick, dte, Price, ePrice, allocn, WtdEquityret, rR 
  --order by Tick, dte

-- the last table from this SP gives the latest top 10 tickers
--EXECUTE [csp_Calc_Ret_For_Strategy_Tickers] @fnTickers=@srcFN