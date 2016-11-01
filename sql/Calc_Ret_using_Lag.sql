-- calc r1,r3,r6,r12 for tickers already in tbl_Return_Rank and then update rRank

--EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Ret_Monthly] @tick='TLT'

--set nocount on

declare @tick varchar(10)
set @tick = 'TLT'

declare @sdt datetime
set @sdt = '4-1-2015'

declare @tickID int
select @tickID = db_ticker_id from tbl_Ticker where db_strTicker = @tick

declare @tbl_Prices table (idx int identity, tick varchar(10), pdt datetime, eom datetime, eomPrice dec(9,3), pPrice dec(9,3), p1 dec(9,3), p3 dec(9,3), p6 dec(9,3), p12 dec(9,3)
, r1 dec(9,3), r3 dec(9,3), r6 dec(9,3), r12 dec(9,3), rRank int )

if exists (select dt from tbl_Return_Rank where dt=@sdt and strTicker = @tick)
	insert @tbl_Prices
	select @tick, dt, EOMONTH(dt,-1),  0, price, lag(price, 1,0) over (order by dt) as p1,
	lag(price, 3,0) over (order by dt)  as p3, lag(price, 6,0) over (order by dt)  as p6, lag(price,12,0) over (order by dt) as p12
	,0,0,0,0,0
	from tbl_Return_Rank
	where strTicker = @tick
	and dt between EOMONTH(@sdt,-13) and @sdt
	order by dt
else
  begin
	insert @tbl_Prices
	select @tick, dt, EOMONTH(dt,-1),  0, price, lag(price, 1,0) over (order by dt) as p1,
	lag(price, 3,0) over (order by dt)  as p3, lag(price, 6,0) over (order by dt)  as p6, lag(price,12,0) over (order by dt) as p12
	,0,0,0,0,0
	from tbl_Return_Rank
	where strTicker = @tick
	and dt between EOMONTH(@sdt,-13) and @sdt
	union
	select @tick, db_dt, EOMONTH(@sdt,-1),  0, db_close, 0,
	0,0,0
	,0,0,0,0,0
	from tbl_Prices where db_dt = @sdt and db_ticker_id = @tickID
	order by dt

	update @tbl_Prices
	set p1 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-2) and  EOMONTH(@sdt, -1)
		) as A
	where pdt = @sdt

	update @tbl_Prices
	set p3 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-4) and  EOMONTH(@sdt, -3)
		) as A
	where pdt = @sdt


	update @tbl_Prices
	set p6 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-7) and  EOMONTH(@sdt, -6)
		) as A
	where pdt = @sdt


	update @tbl_Prices
	set p12 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-13) and  EOMONTH(@sdt, -12)
		) as A
	where pdt = @sdt



  end
/*
select @tick, db_dt, EOMONTH(db_dt,-1),  0, db_close, lag(db_close, 1,0) over (order by db_dt) as p1,
lag(db_close, 3,0) over (order by db_dt)  as p3, lag(db_close, 6,0) over (order by db_dt)  as p6, lag(db_close,12,0) over (order by db_dt) as p12
,0,0,0,0,0
from tbl_Return_Rank RR, tbl_Prices P
where RR.tid = P.db_ticker_id
and RR.dt = P.db_dt
and strTicker = @tick
order by db_dt
*/

update @tbl_Prices
set eomPrice = A.Price
from (select db_dt as ADTE, db_close as Price from tbl_Prices where db_ticker_id = @tickID) as A
where (eom = ADTE)

-- get prices where eomPrice=0 due to eom falling on a non-trading day
declare @idx int
declare @midx int
declare @dt datetime

select top 1 @idx = idx from @tbl_Prices where pdt >= @sdt and eomPrice = 0
select top 1 @midx = idx from @tbl_Prices where pdt >= @sdt and eomPrice = 0 order by pdt desc
--print 'idx=' + convert(varchar, @idx)
--print 'midx=' + convert(varchar, @midx)
while exists (select * from @tbl_Prices where idx=@idx and idx <= @midx)
  begin
	print 'idx=' + convert(varchar, @idx)
	select @dt = pdt from @tbl_Prices where idx=@idx
	update @tbl_Prices
	set eomPrice = A.Price, eom = ADTE
	from (	select top 1 db_dt as ADTE, db_close as Price from tbl_Prices
			where db_ticker_id = @tickID
			and db_dt < @dt
			order by db_dt desc) as A
	where idx = @idx

	select top 1 @idx = idx from @tbl_Prices where idx > @idx and eomPrice = 0
	if @@ROWCOUNT=0 set @idx=@midx+1
  end

--pN = BOM price and return calc using EOM price
update @tbl_Prices
set r1 = case when p1 > 0 then 100*(eomPrice/p1 - 1.0) else 0 end,
r3 = case when p3 > 0 then 100*(eomPrice/p3 - 1.0) else 0 end,
r6 = case when p6 > 0 then 100*(eomPrice/p6 - 1.0) else 0 end,
r12 = case when p12 > 0 then 100*(eomPrice/p12 - 1.0) else 0 end

update @tbl_Prices
set rRank = case when coalesce(CEILING(.5*r1+.3*r3+.15*r6+.05*r12),0) < 0 then 0 else coalesce(CEILING(.5*r1+.3*r3+.15*r6+.05*r12),0) end


--declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

-- calc VIX
declare @vix dec(9,2)
declare @eom datetime
select @eom = eom from @tbl_Prices where pdt = @sdt
SELECT @vix =  dbo.fn_CalcVIX(@eom
				,@sdt
				,@tickID
			)

select @tickID, @tick, @sdt, pPrice, r1, r3, r6, r12, @vix as VIX, rRank
from @tbl_Prices
where pdt = @sdt

select * from @tbl_Prices
where pdt > '12-31-2006'

