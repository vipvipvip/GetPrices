set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go







ALTER procedure [dbo].[sp_GenSignals]
as
begin

set nocount on

declare @s_dt datetime
declare @e_dt datetime


-- To gen signals starting 1-1-2004, set the 
-- s_dt = 1-1-2003. This is because we need
-- 200 data points for 200 day MA.
set @s_dt = '1-1-2003'
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
declare @tbl_SP_MA table (db_dt datetime, price dec(9,2), MA1 dec(9,2), MA2 dec(9,2) )

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
declare @id int
declare @MA1_dt datetime, @MA2_dt datetime
declare @t_strTicker nvarchar(50)
declare @cnt int

BEGIN TRY

Open cDSS
Fetch next from cDSS
into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

while @@FETCH_STATUS = 0
begin
print '--------'
	print @sp_dt
if year(@sp_dt) < year(@s_dt)+1 goto Skip
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
	insert @tbl_SP_MA
	select @sp_dt, @sp_close, @MA1, @MA2

	print 'SPY=[' + convert(varchar, @sp_close) + '], MA1=[' + convert(varchar, @MA1) + ']'
print '--------'
	-- SPY MA check - SPY closing below 65 Day MA.
	if @sp_close < @MA1 
		begin

/*			update @trades
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
*/
			-- get dates for indiv trades MA
			Fetch relative -40 from cDSS
			into @MA1_dt, @sp_close, @sp_rank,@spy_tlt_ratio
		
			Fetch relative 40 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio


			Fetch relative -60 from cDSS
			into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative 60 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			if not exists (select * from @trades where ticker_id = @TLTID and sdate is null)
				begin
					select @MA1 = avg(db_close)
					from tbl_Prices
					where db_ticker_id = @TLTID
					and db_dt between @MA1_dt and @sp_dt

					select @MA2 = avg(db_close)
					from tbl_Prices
					where db_ticker_id = @TLTID
					and db_dt between @MA2_dt and @sp_dt
					
					if @MA1 > @MA2
					begin
						print '---- Insert a TLT Buy  based on SPY MA1 & MA2 -----'
						-- Set typ=0
						insert @trades
						select P.db_ticker_id, P.db_ticker_id, T.db_strTicker, P.db_dt, P.db_close, P.db_rank, 1, null, null, null, null,db_mult_avg_ratio,0,0,0,@sp_rank, @mean_rank,0,0
						from tbl_Prices P, tbl_Ticker T
						where P.db_ticker_id = T.db_ticker_id
						and P.db_ticker_id = @TLTID
						and db_dt = @sp_dt
					end
				end
print '******************************************'
select @cnt = count(*) from @trades where sdate is null and bdate <= @sp_dt
print 'Num Holdings:[' + convert(varchar, @cnt) + ']'

			-- Step thru each open trade to see if MA1 < MA2
			declare cTrades scroll cursor for
			select id, ticker_id, strTicker from @trades where sdate is null and bdate <= @sp_dt

			Open cTrades
			Fetch next from cTrades
			into @id, @tid,@t_strTicker
			while @@FETCH_STATUS = 0
			begin
				-- each indiv open trade MA check
				select @MA1 = avg(db_close)
				from tbl_Prices
				where db_ticker_id = @tid
				and db_dt between @MA1_dt and @sp_dt

				select @MA2 = avg(db_close)
				from tbl_Prices
				where db_ticker_id = @tid
				and db_dt between @MA2_dt and @sp_dt
				
				if @MA1 < @MA2
					begin
						print '--- SELL A - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
						update @trades
						set bBuy=0, 
						sprice = db_close,
						sdate = db_dt,
						srank = db_rank,
						gain = db_close - bprice,
						sratio = db_mult / db_avg
						from tbl_Prices
						where ticker_id = @tid
						and sdate is null
						and tbl_Prices.db_dt = @sp_dt
						and tbl_Prices.db_ticker_id = @tid
						and tbl_Prices.db_ticker_id = ticker_id
					end
				else
					print '--- HOLD A - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'

				Fetch next from cTrades
				into @id, @tid, @t_strTicker
			end
			close cTrades
			Deallocate cTrades
print '******************************************'			
			goto Skip
		end	 
	else
		-- SPY close > 65 Day MA - mkt moving up - so sell TLT
		begin
			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices
			where ticker_id = @TLTID
			and sdate is null
			and typ = 0 -- sell TLT
			and tbl_Prices.db_dt = @sp_dt
			and tbl_Prices.db_ticker_id = @TLTID
			and tbl_Prices.db_ticker_id = @TLTID
		end


	if @t1=1
		begin
			insert @tops
			select T.db_ticker_id, T.db_strticker, db_dt, db_close, db_rank, 1,db_mult_avg_ratio, @sp_rank, @mean_rank
			from tbl_Prices P, tbl_Ticker T
			where P.db_ticker_id = T.db_ticker_id
			and db_dt = @sp_dt
			--and ( db_rank between 1 and 50 or (db_rank < 75 and db_rank  < (select top 1 0.5*db_rank from tbl_Prices A where A.db_ticker_id = P.db_ticker_id and db_dt < @sp_dt order by db_dt desc) ))
			and ( db_rank between 1 and 50 or (db_rank < 75 and P.db_change_rank <= 10) )
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
	select ticker_id, rank, strTicker from @tops

	open cTop25
	Fetch next from cTop25
	into @tid, @r, @t_strTicker

	Fetch relative -15 from cDSS
	into @MA1_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative 15 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative -30 from cDSS
	into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative 30 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	while @@FETCH_STATUS = 0
	begin

		if not exists (select * from @trades where ticker_id = @tid and sdate is null)
		begin

			select @MA1 = avg(db_close)
			from tbl_Prices
			where db_ticker_id = @tid
			and db_dt between @MA1_dt and @sp_dt

			select @MA2 = avg(db_close)
			from tbl_Prices
			where db_ticker_id = @tid
			and db_dt between @MA2_dt and @sp_dt

			if @MA1 > @MA2
					begin
						print '--- BUY - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
						insert @trades
						select A.id, A.ticker_id, A.strTicker, A.dt, A.price, A.rank, 1, null, null, null, null,ratio,0,typ,0,sp_rank, mean_sp_rank,0,0
						from @tops A
						where ticker_id not in (select ticker_id from @trades where sdate is null and ticker_id = A.ticker_id)
						and ticker_id = @tid
					end
			else
				print '--- NO BUY - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'

		end

		Fetch next from cTop25
		into @tid, @r, @t_strTicker
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
			--and ((db_rank > 100) or (cnt > 30 and db_rank > 25) )
			and ((db_rank > 100) or (cnt > 30 and db_rank > 25) or (db_rank > 50 and db_rank  > (select top 1 1.5*db_rank from tbl_Prices A where A.db_ticker_id = tbl_Prices.db_ticker_id and db_dt < @sp_dt order by db_dt desc) ) )
			and tbl_Prices.db_dt = @sp_dt

if 1=0
 begin -- {
			Fetch relative -65 from cDSS
			into @MA1_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative 65 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative -200 from cDSS
			into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative 200 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			-- Step thru each open trade to see if MA1 < MA2
			declare cTrades scroll cursor for
			select id, ticker_id, strTicker from @trades where sdate is null and bdate <= @sp_dt

			Open cTrades
			Fetch next from cTrades
			into @id, @tid,@t_strTicker
			while @@FETCH_STATUS = 0
			begin
				-- each indiv open trade MA check
				select @MA1 = avg(db_close)
				from tbl_Prices
				where db_ticker_id = @tid
				and db_dt between @MA1_dt and @sp_dt

				select @MA2 = avg(db_close)
				from tbl_Prices
				where db_ticker_id = @tid
				and db_dt between @MA2_dt and @sp_dt
				
				if @MA1 < @MA2
					begin
						print '--- SELL B - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
						update @trades
						set bBuy=0, 
						sprice = db_close,
						sdate = db_dt,
						srank = db_rank,
						gain = db_close - bprice,
						sratio = db_mult / db_avg
						from tbl_Prices
						where ticker_id = @tid
						and sdate is null
						and tbl_Prices.db_dt = @sp_dt
						and tbl_Prices.db_ticker_id = @tid
						and tbl_Prices.db_ticker_id = ticker_id
					end
				else
					print '--- HOLD B - Ticker=[' + @t_strTicker + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'

				Fetch next from cTrades
				into @id, @tid, @t_strTicker
			end
			close cTrades
			Deallocate cTrades
end --}
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
select strTicker, convert(varchar,month(bdate)) + '-' + convert(varchar,day(bdate)) + '-' + convert(varchar,year(bdate)) as bdt, convert(varchar,month(sdate)) + '-' + convert(varchar,day(sdate)) + '-' + convert(varchar,year(sdate)) as sdt, bprice, sprice, brank, srank 
from @trades 
order by strTicker, bdate, sdate

-- open trades only - most recent at top
--select * from @trades where bBuy=1 order by bdate desc, ticker_id 

--sales in current year
--select * from @trades where bBuy=0 and year(sdate) = year(getdate()) order by sdate desc, ticker_id 

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

select convert(char(2),month(db_dt)) + '-' + convert(char(2),day(db_dt)) + '-' + convert(char(4),year(db_dt)) as dte, MA2 as '200MA', MA1 as '65MA', price
from @tbl_SP_MA order by db_dt 

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






