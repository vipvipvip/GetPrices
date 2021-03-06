set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER procedure [dbo].[sp_CalcHiLow]
(
	@dt datetime
)
as
begin

--set nocount on

declare @s_dt datetime
declare @e_dt datetime


set @s_dt = '1-1-2003'
select @e_dt = getdate()

declare @SPID int
set @SPID = 538 -- S&P Index ticker id

declare @sp_dt datetime
declare @sp_close dec(9,2)
declare @sp_dt_prev datetime
declare @sp_dt_begin datetime

declare @price_max dec(9,2)
declare @price_min dec(9,2)

declare @tid int

declare @dt1 datetime
declare @dt2 datetime
declare @cdt datetime


declare cSPY scroll cursor for
select db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
and db_dt between @s_dt and @e_dt
order by db_dt asc

BEGIN TRY

Open cSPY
Fetch last from cSPY
into @sp_dt, @sp_close

if @@FETCH_STATUS = 0
begin
	if year(@sp_dt) < year(@s_dt)+1 goto Done
--print '--------'
--	print @sp_dt
	
		set @cdt = @dt
		set @dt1 = dateadd(yy, -1, @cdt)
		set @dt2 = dateadd(d, -1, @cdt)

		update tbl_Prices
		set db_hi_lo = -1, db_hi_cnt=0, db_lo_cnt=0
		where db_dt = @cdt

		update tbl_Prices
		set db_hi_lo = 1
		from (select X.db_ticker_id as TID, max(X.db_close) as MAX_PRICE from tbl_Prices X where X.db_dt between @dt1 and @dt2 group by X.db_ticker_id) as A
		where db_close > MAX_PRICE
		and db_ticker_id = A.TID
		and db_dt = @cdt
		
		update tbl_Prices
		set db_hi_cnt = @@ROWCOUNT
		where db_dt = @cdt
		
--print 'Dt = [' + convert(varchar, @dt) + '], hiCount=[' + convert(varchar, @@ROWCOUNT) + ']'


		update tbl_Prices
		set db_hi_lo = 0
		from (select X.db_ticker_id as TID, min(X.db_close) as MAX_PRICE from tbl_Prices X where X.db_dt between @dt1 and @dt2 group by X.db_ticker_id) as A
		where db_close < MAX_PRICE
		and db_ticker_id = A.TID
		and db_dt = @cdt

		update tbl_Prices
		set db_lo_cnt = @@ROWCOUNT
		where db_dt = @cdt

--print 'Dt = [' + convert(varchar, @dt) + '], LowCount=[' + convert(varchar, @@ROWCOUNT) + ']'

end

Done:
close cSPY
Deallocate cSPY

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








