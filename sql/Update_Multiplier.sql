set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go



ALTER procedure [dbo].[csp_Update_Multiplier]
(
	@step_id int=1,
	@s_date datetime  = '1-1-2001'
)
as

set nocount on
--Step 1
if @step_id=1
  begin
	update tbl_Prices
		set db_mult = convert(dec(9,2), db_close/SP_CLOSE * 100.00)
	FROM (select db_dt as SP_DATE, db_close as SP_CLOSE from tbl_Prices where db_ticker_id = 538 and db_dt >= @s_date) as TBL
	where db_dt = SP_DATE
	and db_dt >= @s_date

	goto Done
  end

--Step 3
if @step_id=3
  begin
	update tbl_Prices
		set db_index = convert(dec(9,2), db_close/db_avg * 100.00)
	goto Done
 end


--Step 4
if @step_id=4
  begin
	update tbl_Prices
	set db_mult_avg_ratio = convert(dec(9,2),db_mult / db_avg)
	goto Done
 end


declare @SPID int
set @SPID = 538 -- S&P Index ticker id
declare @start_date datetime
--select @start_date = dateadd(dd, -1, max(db_dt)) from tbl_Prices where (db_avg <= 0.0 or db_index <= 0.0 or db_mult <= 0.0 or db_avg is null or db_index is null or db_mult is null)

set @start_date = @s_date



declare @sp_dt datetime
declare @sp_close float

declare cDSS scroll cursor for
select db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
and db_dt >= @start_date
--and db_dt between '11-20-2006' and '11-29-2006'
order by db_dt desc

declare @dt2 datetime
BEGIN TRY

Open cDSS
Fetch next from cDSS
into @sp_dt, @sp_close

while @@FETCH_STATUS = 0
begin
	print @sp_dt
	set @dt2 = dateadd(dd, -1830, @sp_dt)
	if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

	--Step 1
	--if @step_id=1
	--	update tbl_Prices
	--		set db_mult = convert(dec(9,2), db_close/@sp_close * 100.00)
	--	where db_dt = @sp_dt
	
	--Step 2
	if @step_id=2
	  begin
		update tbl_Prices
		set db_avg = val
		from (select db_ticker_id, convert(dec(9,2), avg(db_mult)) as val
				from tbl_Prices
				where db_ticker_id = tbl_Prices.db_ticker_id
				and db_dt between @dt2 and @sp_dt
				group by db_ticker_id) A
		where tbl_Prices.db_ticker_id = A.db_ticker_id
		and tbl_Prices.db_dt = @sp_dt
	  end

	--Step 5
	if @step_id=5
		update tbl_Prices
		set db_rank = Rank
		from (select T.db_ticker_id, P.db_dt, rank() over (order by db_index desc) as Rank
		from tbl_Prices P, tbl_Ticker T
		where P.db_ticker_id = T.db_ticker_id
		and db_dt = @sp_dt) as X
		where tbl_Prices.db_ticker_id = X.db_ticker_id and tbl_Prices.db_dt = X.db_dt


	--Step 6
	if @step_id=6
		begin
			declare @prev_dt datetime
			fetch next from CDSS
			into @prev_dt, @sp_close
			--print 'Prev Dt = ' + convert(varchar, @prev_dt)

			update tbl_Prices
			set db_rank_change = Diff
			from (select P1.db_ticker_id, P2.db_dt, P2.db_rank - P1.db_rank as Diff
			from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
			where P1.db_ticker_id = T.db_ticker_id
			and P1.db_ticker_id = P2.db_ticker_id
			and P1.db_dt = @prev_dt --(select max(db_dt) from tbl_Prices where db_ticker_id = P1.db_ticker_id and db_dt < @sp_dt)
			and P2.db_dt = @sp_dt) as X
			where tbl_Prices.db_ticker_id = X.db_ticker_id
			and tbl_Prices.db_dt = X.db_dt

			fetch prior from CDSS
			into @sp_dt, @sp_close
		end
		
	--Step 7
	if @step_id=7
		update tbl_Prices
		set db_change_rank = Rank
		from (select T.db_ticker_id, P.db_dt, rank() over (order by db_rank_change asc) as Rank
		from tbl_Prices P, tbl_Ticker T
		where P.db_ticker_id = T.db_ticker_id
		and db_dt = @sp_dt) as X
		where tbl_Prices.db_ticker_id = X.db_ticker_id and tbl_Prices.db_dt = X.db_dt
		

	--print convert(varchar,@sp_dt) + ', ' + convert(varchar, @dt2) + ', ' + convert(varchar, @sp_close)

	Fetch next from cDSS
	into @sp_dt, @sp_close

end
close cDSS
Deallocate cDSS

end try

BEGIN CATCH
close cDSS
Deallocate cDSS
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
Done:


