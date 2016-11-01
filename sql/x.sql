SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE sp_Calc_Portfolio
AS
BEGIN
	SET NOCOUNT ON;
/*
EXEC	IDToDSN_DKC.[dbo].[sp_Calc_Portfolio]
*/

declare @s_dt datetime
declare @e_dt datetime

set @s_dt = '1-1-2005'
select @e_dt = getdate()

-- Portfolio calc vars
declare @start_$ dec(12,2)
set @start_$ = 100000.00

declare @s_nNewBuys int
set @s_nNewBuys=0

declare @s_nNewSells int
set @s_nNewSells=0

declare @s_nNewBuys$ dec(12,2)
set @s_nNewBuys$=0

declare @s_nNewSells$ dec(12,2)
set @s_nNewSells$=0

declare @cash_$ dec(12,2)
set @cash_$ = @start_$

declare @cash_Allocn dec(12,2)
set @cash_Allocn=.1

declare @nshares int
set @nshares = 7

declare @pv$ dec(12,2)
set @pv$=0

declare @s_CurrentHoldings$ dec(12,2)
set @s_CurrentHoldings$=0
-- End Portfolio calc vars

declare @SPID int
set @SPID = 442 --538 -- S&P Index ticker id

declare @sp_dt datetime
declare @sp_close dec(12,2)
declare @prev_sp_close dec(12,2)
set @prev_sp_close=0
declare @spbh dec(12,2)
set @spbh = @start_$

--Bond related
declare @TLTID int
set @TLTID = 471
declare @tlt_close dec(12,2)
declare @prev_tlt_close dec(12,2)
set @prev_tlt_close=0
declare @Cash_TLT_Portfolio dec(12,2)
set @Cash_TLT_Portfolio=0

declare cDSS scroll cursor for
select db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
and db_dt between @s_dt and @e_dt
order by db_dt asc

--declare @port table (dt datetime, OpenTrades int, OpenProfitTrades int, Gain dec(12,2), OpenLossTrades int, Loss dec(12,2), OpenPurch$ dec(12,2), OpenSales$ dec(12,2), PortFolioValue dec(12,2))
declare @port table (dt datetime, cash dec(12,2), nBuys int, nSells int, CurrentHolding$ dec(12,2), PortFolioValue dec(12,2), Cash_TLT_Portfolio dec(12,2), SPBuyandHold dec(12,2),OpenTrades int, OpenProfitTrades int, Gain dec(12,2), OpenLossTrades int, Loss dec(12,2), NetProfit$ dec(12,2) )

declare @sum_bprice dec(12,2)

Open cDSS
Fetch next from cDSS
into @sp_dt, @sp_close

while @@FETCH_STATUS = 0
begin
	--print @sp_dt

	if @prev_sp_close <=0
		set @prev_sp_close = @sp_close
	else
		set @spbh = @spbh * @sp_close/@prev_sp_close
	
	set @prev_sp_close = @sp_close
	
	select @s_nNewBuys = count(*) 
	from tbl_Trades
	where bdate = @sp_dt

	select @s_nNewSells = count(*) 
	from tbl_Trades
	where sdate = @sp_dt

	if @s_nNewBuys > 0
	  begin
		select @sum_bprice=sum(bprice)	from tbl_Trades where bdate = @sp_dt
		print 'sum price = ' + convert(varchar, @sum_bprice)
		set @nshares = (@cash_$ - @cash_Allocn * @start_$ ) / @sum_bprice 
		print 'Buy shares = ' + convert(varchar, @nshares)
		update tbl_Trades set nshares = @nshares, buy_amount = @nshares*bprice where bdate = @sp_dt
	  end

	--select @s_nNewBuys$ = coalesce(sum(bprice),0) * @nshares
	select @s_nNewBuys$ = coalesce(sum(buy_amount),0)
	from tbl_Trades
	where bdate = @sp_dt

--	select @s_nNewSells$ = convert(dec(12,2),coalesce(sum(db_close),0) * @nshares)
	select @s_nNewSells$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where sdate = @sp_dt
	and ticker_id = db_ticker_id
	and db_dt = sdate

	set @cash_$ = @cash_$ - @s_nNewBuys$ + @s_nNewSells$
	select @tlt_close = db_close from tbl_Prices where db_ticker_id = @TLTID and db_dt = @sp_dt

	if @prev_tlt_close <=0	set @prev_tlt_close =  @tlt_close
	--set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * (1-(@prev_tlt_close/@tlt_close)))
	set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * .03/365)
	set @prev_tlt_close = @tlt_close

	print convert(varchar, @sp_dt) + ', nBuys=' + convert(varchar, @s_nNewBuys) + ', nSells=' + convert(varchar, @s_nNewSells) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', Sell$=' + convert(varchar, @s_nNewSells$) + ', Cash = ' + convert(varchar, @cash_$)

	--select @s_nNewBuys$ = coalesce(sum(bprice),0) * @nshares
/*	select @s_nNewBuys$ = coalesce(sum(buy_amount),0)
	from tbl_Trades
	where bdate <= @sp_dt
*/
	--select @s_CurrentHoldings$ = convert(dec(12,2),coalesce(sum(db_close),0) * @nshares)
	select @s_CurrentHoldings$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where ticker_id = db_ticker_id
	and db_dt = @sp_dt
	and sdate > @sp_dt
	and bdate <= @sp_dt


	set @pv$ = @cash_$ + @s_CurrentHoldings$
	print 'Total --> ' + convert(varchar, @sp_dt) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', CurrentHolding=' + convert(varchar, @s_CurrentHoldings$) + ', Portfolio = ' + convert(varchar, @pv$)

	insert @port
	select @sp_dt,  @cash_$, @s_nNewBuys, @s_nNewSells, @s_CurrentHoldings$, @pv$, @Cash_TLT_Portfolio, @spbh,OpenTrades, OpenProfitTrades, Gain, OpenLossTrades, Loss
	, 0
	from
	(select count(*) as OpenTrades from tbl_Trades where bdate <= @sp_dt and sdate >= @sp_dt and nshares > 0) AS A,
	(select count(*) as OpenProfitTrades, coalesce(sum(gain*nshares),0) as Gain from tbl_Trades where gain > 0.0 and bdate <= @sp_dt and sdate >= @sp_dt and nshares > 0) as B,
	(select count(*) as OpenLossTrades, coalesce(sum(gain*nshares),0) as Loss from tbl_Trades where gain <= 0.0 and bdate <= @sp_dt and sdate >= @sp_dt and nshares > 0) as C
	--,(select coalesce(sum(nshares*(db_close - bprice)),0) as NetProfit from tbl_Trades, tbl_Prices where ticker_id = db_ticker_id and db_dt = @sp_dt and bdate <= @sp_dt) as D
	Fetch next from cDSS
	into @sp_dt, @sp_close

end
close cDSS
Deallocate cDSS

select * from @port
END
GO
