create procedure csp_Calc_Freq_Weekly
(
	@tick_id int
)
as
begin

declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int)

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @str_ticker varchar(10)
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int

declare cDSSS scroll cursor for
select T.db_ticker_id, db_dt, datepart(wk,db_dt)
from tbl_Ticker T, tbl_Prices P
where YEAR(db_dt) >= 2007
and T.db_ticker_id = @tick_id
and T.db_ticker_id = P.db_ticker_id 
BEGIN TRY

Open cDSSS
Fetch next from cDSSS
into @ticker_id, @dt, @wk
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin

	if @wk > @prev_wk or @prev_wk - @wk > 51
	begin
		EXECUTE @RC = [csp_Calc_Freq_Rank] 
		   @dt
		  ,@ticker_id
		  ,@str_ticker
		  ,@ret_price OUTPUT

		insert @tbl
		select @ticker_id, @dt, @RC
	end
	set @prev_wk = @wk
	Fetch next from cDSSS
	into @ticker_id, @dt, @wk

end
close cDSSS
Deallocate cDSSS
select * from @tbl
end try

BEGIN CATCH
close cDSSS
Deallocate cDSSS

    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE() + ', ' + convert(varchar, @dt),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
end
