set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER procedure [dbo].[sp_CalcTrades_Diff]
(
	@s_dt datetime = null
)

as
begin

set nocount on
if @s_dt is null set @s_dt = '1-1-2005'

declare @e_dt datetime
select @e_dt = getdate()

declare @SPID int
set @SPID = 538 -- S&P Index ticker id

declare @trades table (iid int identity, ticker_id int, strTicker nvarchar(50), bdate datetime, bprice dec(9,2), brank int, bBuy tinyint, sdate datetime null, sprice dec(9,2) null, srank int null, gain dec(9,2) null)
declare @tops table (strTicker nvarchar(50), ticker_id int, p2rank int, p1rank int, p2close dec(9,2), p1close dec(9,2), diff int, dt1 smalldatetime, dt2 smalldatetime)

declare @sp_dt datetime
declare @sp_close dec(9,2)

declare cDSSS scroll cursor for
select db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
and db_dt between @s_dt and @e_dt
order by db_dt asc

declare @tid int

BEGIN TRY

Open cDSSS
Fetch next from cDSSS
into @sp_dt, @sp_close

while @@FETCH_STATUS = 0
begin
	print @sp_dt
	
	insert @tops
	exec csp_Calc_Diff @dt = @sp_dt

	declare cTop25 cursor for
	select ticker_id from @tops

	open cTop25
	Fetch next from cTop25
	into @tid

	while @@FETCH_STATUS = 0
	begin

		if not exists (select * from @trades where ticker_id = @tid and sdate is null)
		begin
			insert @trades
			select A.ticker_id, A.strTicker, A.dt2, A.p2close, A.p2rank, 1, null, null, null, null
			from @tops A
			--where ticker_id not in (select ticker_id from @trades where sdate is null and ticker_id = A.ticker_id)
			where A.ticker_id = @tid
		end

		Fetch next from cTop25
		into @tid
	end
	close cTop25
	Deallocate cTop25
	

	update @trades
	set bBuy=0, 
	sprice = db_close,
	sdate = db_dt,
	srank = db_rank,
	gain = db_close - bprice
	from tbl_Prices
	where ticker_id not in (select ticker_id from @tops)
	and tbl_Prices.db_dt = @sp_dt
	and ticker_id = tbl_Prices.db_ticker_id
	and sdate is null
	
	delete from @tops

	Fetch next from cDSSS
	into @sp_dt, @sp_close

end
close cDSSS
Deallocate cDSSS


select count(*) as NumTrades, sum(gain) as Gain from @trades 
select count(*) as cnt, sum(gain) as Gain from @trades where gain > 0.0
select count(*) as cnt, sum(gain) as Loss from @trades where gain <= 0.0
update @trades
set sprice=db_close, srank=db_rank, gain=db_close-bprice
from tbl_Prices
where ticker_id = tbl_Prices.db_ticker_id
and tbl_Prices.db_dt = @sp_dt
and sdate is null

select * from @trades where bBuy=1 and sdate is null  order by ticker_id, bdate
select * from @trades where bBuy=1 and sdate is null  and year(bdate) = year(getdate()) order by ticker_id, bdate


update @trades
set sprice=db_close, sdate =  db_dt, srank=db_rank, gain=db_close-bprice
from tbl_Prices
where ticker_id = tbl_Prices.db_ticker_id
and tbl_Prices.db_dt = @sp_dt
and sdate is null

select * from @trades where bBuy=0 order by ticker_id, bdate

select count(*) as NumTrades, sum(gain) as Gain from @trades 
select count(*) as cnt, sum(gain) as Gain from @trades where gain > 0.0
select count(*) as cnt, sum(gain) as Loss from @trades where gain <= 0.0


end try


BEGIN CATCH
close cDSSS
Deallocate cDSSS

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












