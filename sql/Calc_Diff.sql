use IDToDSN_DKC
go

alter procedure csp_Calc_Diff
as

set nocount on

declare @t table (idx int identity, ticker varchar(50), id int, r2 int, r1 int, c2 dec(9,2), c1 dec(9,2), diff int, d1 varchar(12), d2 varchar(12), cnt int null)

declare @SPID int
set @SPID = 538 -- S&P Index ticker id



declare @sp_dt varchar(12)
declare @sp_close float
declare @sp_prev float

declare cDSS scroll cursor for
select top 30 db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
order by db_dt desc

declare @dt2 varchar(12)
BEGIN TRY

Open cDSS
Fetch next from cDSS
into @sp_dt, @sp_close
declare @today varchar(12)
declare @yday varchar(12)
declare @last varchar(12)

set @today = @sp_dt
fetch next from cDSS
into @yday, @sp_prev

Fetch prior from cDSS
into @sp_dt, @sp_close

while @@FETCH_STATUS = 0
begin
	--print @sp_dt
	fetch next from cDSS
	into @dt2, @sp_prev
	--print @dt2

	Fetch prior from cDSS
	into @sp_dt, @sp_close

	if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

	insert @t
	select top 10 T.db_strticker, T.db_ticker_id, P2.db_rank as P2Rank, P1.db_rank as P1Rank, P2.db_close as P2Close, P1.db_close as P1Close, P2.db_rank - P1.db_rank as Diff, @sp_dt, @dt2, 0
	from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
	where P1.db_ticker_id = T.db_ticker_id
	and P1.db_ticker_id = P2.db_ticker_id
	and P1.db_dt = @dt2 and P2.db_dt = @sp_dt
	order by Diff asc

	print convert(varchar,@sp_dt) + ', ' + convert(varchar, @dt2) + ', ' + convert(varchar, @sp_close)

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

update @t
set cnt = c
from (select ticker as tick, count(*) as c from @t group by ticker) as A
where A.tick = ticker

--Most diff and count in past 30 days
select ticker, id, sum(diff) as diff, cnt
from @t
group by ticker, id, cnt
order by diff, cnt

-- Detail of Most diff and count in past 30 days
select * from @t order by cnt, d1 desc, ticker

-- Diff as of today
select top 10 T.db_strticker, T.db_ticker_id, P2.db_rank as P2Rank, P1.db_rank as P1Rank, P2.db_close as P2Close, P1.db_close as P1Close, P2.db_rank - P1.db_rank as Diff, @today, @yday
from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
where P1.db_ticker_id = T.db_ticker_id
and P1.db_ticker_id = P2.db_ticker_id
and P1.db_dt = @yday and P2.db_dt = @today
order by Diff asc

-- Diff over last today and 30 days ago
select top 10 T.db_strticker, T.db_ticker_id, P2.db_rank as P2Rank, P1.db_rank as P1Rank, P2.db_close as P2Close, P1.db_close as P1Close, P2.db_rank - P1.db_rank as Diff, @today, @sp_dt
from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
where P1.db_ticker_id = T.db_ticker_id
and P1.db_ticker_id = P2.db_ticker_id
and P1.db_dt = @sp_dt and P2.db_dt = @today
order by Diff asc
