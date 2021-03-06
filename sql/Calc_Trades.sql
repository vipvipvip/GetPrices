set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go





ALTER procedure [dbo].[sp_CalcTrades]
as
begin

set nocount on

declare @s_dt datetime
declare @e_dt datetime
declare @prev_dt datetime

set @s_dt = '1-1-2001'
select @e_dt = getdate()

declare @SPID int
set @SPID = 538 -- S&P Index ticker id
declare @SPYID int
set @SPYID = 442
declare @TLTID int
set @TLTID = 471

declare @t1 smallint, @t2 smallint, @t3 smallint
set @t1=1
set @t2=0
set @t3=0

declare @trades table (iid int identity, id int, ticker_id int, strTicker nvarchar(50), bdate datetime, bprice dec(9,2), brank int, bBuy tinyint, sdate datetime null, sprice dec(9,2) null, srank int null, gain dec(9,2) null, ratio dec(9,2), sratio dec(9,2),typ smallint, cnt int, sp_rank int, mean_sp_rank int, nshares int, buy_amount dec(9,2))
declare @tops table (					 id int identity, ticker_id int, strTicker nvarchar(50), dt datetime, price dec(9,2), rank int, typ smallint, ratio dec(9,2), sp_rank int, mean_sp_rank int)

/*
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Trades]') AND type in (N'U'))
DROP TABLE [dbo].[tbl_Trades]

CREATE TABLE [dbo].[tbl_Trades](
iid int, id int, ticker_id int, strTicker nvarchar(50), bdate datetime, bprice dec(9,2), brank int, bBuy tinyint, sdate datetime null, sprice dec(9,2) null, srank int null, gain dec(9,2) null, ratio dec(9,2), sratio dec(9,2),typ smallint, cnt int, sp_rank int, mean_sp_rank int, nshares int, buy_amount dec(9,2)
 CONSTRAINT [PK_tbl_Trades] PRIMARY KEY CLUSTERED 
(
	[iid] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
*/


declare @sp_dt datetime
declare @sp_close dec(9,2)
declare @sp_rank int
declare @spy_tlt_ratio dec(9,2)
declare @sp_dt_prev datetime
/*
declare cDSS scroll cursor for
select db_dt, db_close, db_rank
from tbl_Prices
where db_ticker_id = @SPID
and db_dt between @s_dt and @e_dt
order by db_dt asc
*/
declare cDSS scroll cursor for
select A.db_dt, A.db_close, A.db_rank, convert(dec(9,3), A.db_close) / convert(dec(9,3), B.db_close) as SPYTLTRatio
from tbl_Prices A, tbl_Prices B
where A.db_ticker_id = @SPYID
and B.db_ticker_id = @TLTID
and A.db_dt between @s_dt and @e_dt
and A.db_dt = B.db_dt
order by A.db_dt asc

declare @tid int
declare @r int
declare @mean_rank int
set @mean_rank=0
declare @MA1 dec(9,2), @MA2 dec(9,2)

BEGIN TRY

Open cDSS
Fetch next from cDSS
into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

while @@FETCH_STATUS = 0
begin
print '--------'
	print @sp_dt
if @sp_dt < '1-1-2004' goto Skip
	if 1=0
	  begin
		select @mean_rank = avg(db_rank)
		from tbl_Prices
		where db_ticker_id = @SPYID
		and db_dt between dateadd(d, -90,@sp_dt) and @sp_dt
		print 'SPRank=' + convert(varchar, @sp_rank) + ', MR=' + convert(varchar, @mean_rank)
	  end

	Fetch relative -65 from cDSS
	into @sp_dt_prev, @sp_close, @sp_rank,@spy_tlt_ratio
	--print @sp_dt_prev

	select @MA1 = avg(db_close)
	from tbl_Prices
	where db_ticker_id = @SPYID
	and db_dt between @sp_dt_prev and @sp_dt
	
	Fetch relative 65 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio
	--print @sp_dt


	Fetch relative -200 from cDSS
	into @sp_dt_prev, @sp_close, @sp_rank,@spy_tlt_ratio
	--print @sp_dt_prev

	select @MA2 = avg(db_close)
	from tbl_Prices
	where db_ticker_id = @SPYID
	and db_dt between @sp_dt_prev and @sp_dt

	Fetch relative 200 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio
	--print @sp_dt
	print 'MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
print '--------'
	--if @sp_dt between '5-19-2008' and '3-9-2009'
	if @MA1 < @MA2
		begin
			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and tbl_Prices.db_dt = @sp_dt
			
			goto Skip
		end	 
	
	if @t1=1
		begin
			insert @tops
			select T.db_ticker_id, T.db_strticker, db_dt, db_close, db_rank, 1,db_mult_avg_ratio, @sp_rank, @mean_rank
			from tbl_Prices P, tbl_Ticker T
			where P.db_ticker_id = T.db_ticker_id
			and db_dt = @sp_dt
			and db_rank between 1 and 50
			--and @sp_rank > @mean_rank
			order by db_rank asc
		end

	if @t2=1
		begin
			insert @tops
			select T.db_ticker_id, T.db_strticker, db_dt, db_close, db_rank, 2,db_mult_avg_ratio, @sp_rank, @mean_rank
			from tbl_Prices P, tbl_Ticker T
			where P.db_ticker_id = T.db_ticker_id
			and db_dt = @sp_dt
			and db_rank between 0 and 50
			and (db_mult_avg_ratio between 1.5 and 2.0)
			order by db_rank asc
		end

	if @t3=1
		begin
			insert @tops
			select T.db_ticker_id, T.db_strticker, db_dt, db_close, db_rank, 3,db_mult_avg_ratio, @sp_rank, @mean_rank
			from tbl_Prices P, tbl_Ticker T
			where P.db_ticker_id = T.db_ticker_id
			and db_dt = @sp_dt
			and (db_mult_avg_ratio between 1.25 and 1.75)
			and @sp_rank > @mean_rank

		end

	declare cTop25 cursor for
	select ticker_id, rank from @tops

	open cTop25
	Fetch next from cTop25
	into @tid, @r

	while @@FETCH_STATUS = 0
	begin

		if not exists (select * from @trades where ticker_id = @tid and sdate is null)
		begin
			insert @trades
			select A.id, A.ticker_id, A.strTicker, A.dt, A.price, A.rank, 1, null, null, null, null,ratio,0,typ,0,sp_rank, mean_sp_rank,0,0
			from @tops A
			where ticker_id not in (select ticker_id from @trades where sdate is null and ticker_id = A.ticker_id)
		end

		Fetch next from cTop25
		into @tid, @r
	end
	close cTop25
	Deallocate cTop25
	delete from @tops
	--if @sp_dt between '5-19-2008' and '3-10-2009' goto Skip
SELL:
	if @t1=1
		begin
			update @trades
			set cnt = cnt+1,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and (tbl_Prices.db_rank <= 10 and typ=1)
			and tbl_Prices.db_dt = @sp_dt

			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and typ=1
			and ((db_rank > 100) or (cnt > 30 and db_rank > 25) )
			and tbl_Prices.db_dt = @sp_dt
		end		

	if @t2=1
		begin
			update @trades
			set cnt = cnt+1,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and (tbl_Prices.db_rank < 10 and typ=2)
			and tbl_Prices.db_dt = @sp_dt
			
			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			--and ((tbl_Prices.db_rank > 10 and cnt > 30 and typ = 2) or ((tbl_Prices.db_rank > 10 and cnt2 > 10 and typ = 2)) )
			--and (tbl_Prices.db_rank > 25 and cnt > 30 and typ = 2)
			and ( (tbl_Prices.db_rank between 1 and 15 and cnt > 30 and typ = 2) or (tbl_Prices.db_rank > 75 and typ = 2) )
			and ((tbl_Prices.db_mult_avg_ratio > 2.5 and tbl_Prices.db_rank > 10 ))
			and tbl_Prices.db_dt = @sp_dt
		end

		
	if @t3=1
		begin
			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and typ=3
			and ((tbl_Prices.db_mult_avg_ratio > 1.5*ratio and tbl_Prices.db_rank > 25))
			and tbl_Prices.db_dt = @sp_dt
			and @sp_rank < @mean_rank

			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = tbl_Prices.db_ticker_id
			and sdate is null
			and typ=3
			and (tbl_Prices.db_mult_avg_ratio < .85*ratio and tbl_Prices.db_rank > 25 and tbl_Prices.db_rank > brank and tbl_Prices.db_close > bprice )
			and tbl_Prices.db_dt = @sp_dt
			and @sp_rank < @mean_rank

		end
Skip:
	Fetch next from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

end
close cDSS
Deallocate cDSS

-- calc portfolio value based on closed trades
-- close open trades (leave bBuy=1)
update @trades
set sprice=db_close, sdate=@sp_dt, srank=db_rank, gain=db_close-bprice
from tbl_Prices
where ticker_id = tbl_Prices.db_ticker_id
and tbl_Prices.db_dt = @sp_dt
and sdate is null

truncate table tbl_Trades
insert tbl_Trades
select * from @trades

-- all trades (open and closed)
select * from @trades order by strTicker, bdate 

-- open trades only - most recent at top
select * from @trades where bBuy=1 order by bdate desc, ticker_id 

--sales in current year
select * from @trades where bBuy=0 and year(sdate) = year(getdate()) order by sdate desc, ticker_id 

select *
from (select count(*) as TotTrades from @trades) AS A,
(select count(*) as ClosedProfitTrades, sum(gain) as Gain from @trades where gain > 0.0 and bBuy=0) as B,
(select count(*) as ClosedLossTrades, sum(gain) as Loss from @trades where gain <= 0.0 and bBuy=0) as C,
(select sum(bprice) as ClosedPurchaes$, sum(sprice) as ClosedSales$ from @trades where bBuy=0) as D


update @trades
set sprice=db_close, sdate=@sp_dt, srank=db_rank, gain=db_close-bprice
from tbl_Prices
where ticker_id = tbl_Prices.db_ticker_id
and tbl_Prices.db_dt = @sp_dt
and sdate is null
and bBuy=1


select *
from (select count(*) as OpenTrades from @trades where bBuy=1) AS A,
(select count(*) as OpenProfitTrades, sum(gain) as Gain from @trades where gain > 0.0 and bBuy=1) as B,
(select count(*) as OpenLossTrades, sum(gain) as Loss from @trades where gain <= 0.0 and bBuy=1) as C,
(select sum(bprice) as OpenPurchaes$, sum(sprice) as OpenSales$ from @trades where bBuy=1) as D

-- Note: TotTrades = ClosedProfitTrades + ClosedLossTrades + OpenTrades
-- OpenTrades = OpenProfitTrades + OpenLossTrades

-- If above #s do not reconcile, then uncomment line below - it
-- will show records that problematic. Mostly it will be
-- that latest prices have not been downloaded.
--select * from @trades where sdate is null

--EXEC	[dbo].[sp_Calc_Portfolio]
 
end try


BEGIN CATCH

    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE() + ', ' + convert(varchar, @sp_dt),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
end




