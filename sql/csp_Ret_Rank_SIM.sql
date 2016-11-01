set nocount on;
SET IDENTITY_INSERT dbo.tbl_Ticker ON
delete tbl_Prices where db_ticker_id in (select db_ticker_id from tbl_Ticker  where db_type = 99)
delete tbl_Ticker where db_type = 99

declare @tAS table (db_ticker_id int, db_strTicker nvarchar(50), yr int, a real, sd real, rPrice real)

declare @tPrices TABLE (
	[db_row_id] [int] IDENTITY(1,1) NOT NULL,
	[db_ticker_id] [int] NOT NULL,
	[db_strTicker] nvarchar(50),
	[db_dt] [smalldatetime] NULL,
	[db_close] [real] NULL,
	[db_rand_close] [real] )


insert @tPrices 
select 
	case
		when T.db_strTicker = 'VTI' then 9990
		when T.db_strTicker = 'VEU' then 9991
		when T.db_strTicker = 'EEM' then 9992
		when T.db_strTicker = 'ONEQ' then 9993
		when T.db_strTicker = 'TLT' then 9994
		when T.db_strTicker = 'AGG' then 9995
	end as db_ticker_id,
	case
		when T.db_strTicker = 'VTI' then 'sVTI'
		when T.db_strTicker = 'VEU' then 'sVEU'
		when T.db_strTicker = 'EEM' then 'sEEM'
		when T.db_strTicker = 'ONEQ' then 'sONEQ'
		when T.db_strTicker = 'TLT' then 'sTLT'
		when T.db_strTicker = 'AGG' then 'sAGG'
	end as db_strTicker , P.db_dt, P.db_close,
	db_close	--(db_close * 1.25 * RAND() + db_close * 0.75)
from tbl_Prices P, tbl_Ticker T
where T.db_ticker_id = P.db_ticker_id 
and T.db_strTicker in ('VTI', 'VEU', 'EEM', 'ONEQ', 'TLT', 'AGG')
and P.db_dt > '12-30-2004'


insert tbl_Ticker (db_ticker_id, db_strTicker, db_type) 
select distinct(db_ticker_id), db_strTicker, 99 from @tPrices 

insert tbl_Prices 
(db_ticker_id, db_dt, db_close, db_type) 
select db_ticker_id, db_dt, db_rand_close, 99 from @tPrices 

if (1=1)
begin
	insert @tAS
	select  distinct T.db_ticker_id, T.db_strTicker, year(db_dt), 
	convert(dec(9,2),AVG(db_close)) as average, convert(dec(9,2),STDEV(db_close)) as SD,0
	from tbl_Prices P, tbl_Ticker T
	where T.db_type = 99
	group by T.db_ticker_id, T.db_strTicker, YEAR(db_dt)
	order by T.db_ticker_id 

	update @tAS 
	set rPrice = a + RAND(db_ticker_id)*S
	from ( select db_ticker_id as TID, a as AVE, yr as Y, sd as S from @tAS) as A
	where TID = db_ticker_id 
	and Y = yr
--select * from @tAS order by db_ticker_id, yr

	declare @t int
	declare @d datetime
	declare @c real
	declare @rand real
	set @rand = RAND(0)
	
	declare cAS scroll cursor for
	select db_ticker_id, db_dt, db_close
	from tbl_Prices
	where db_type=99
	order by db_ticker_id, db_dt

	declare @av dec(9,3), @sd dec(9,3), @y int
	declare @fact dec(9,3)
	declare @prev_close dec(9,3)
	declare @i int
	declare @prev_t int
	set @i=0
	
		Open cAS
		Fetch next from cAS
		into @t, @d, @c
		set @prev_close = 100
		set @prev_t = @t
		while @@FETCH_STATUS = 0
		begin
			print 'Prev Close=[' + convert(varchar, @prev_close) + ']'
			set @i=@i+1
			select @rand = X from udf_sampleNormal(rand(),rand())
			select @av = a, @sd = sd, @y = yr from @tAS where db_ticker_id = @t and yr = YEAR(@d)
			set @fact = (SQRT(1.0/365.0)*@sd*@rand + @av/365.0)
			print 'Tid=' + convert(varchar, @t) + ' Rand=[' + convert(varchar, @rand) + '], Fact=[' + convert(varchar, (1+(SQRT(1.0/52.0)*@sd*@rand + @av/52.0))) + '], tid=[' + convert(varchar, @t) + '], av=[' + convert(varchar, @av) + '], sd=[' + convert(varchar, @sd) + ']'
			
			update tbl_Prices
			set db_close = db_close * (1+@fact/100.0)
			where db_ticker_id = @t and db_dt = @d

			set @prev_close = @prev_close * (1 + @fact/100.0)

			Fetch next from cAS
			into @t, @d, @c
			if (@t <> @prev_t) 
				begin
					set @prev_close=100
					set @i=0
				end
			set @prev_t = @t
		end
		close cAS
		Deallocate cAS
	--select * from tbl_Prices where db_type = 99 order by db_ticker_id, db_dt
end

if (1=1)
begin
declare	@sdt smalldatetime = null
declare	@tick varchar(10) = null

	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '1-1-2007' else set @start_dt = @sdt

declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), rRank int)
DECLARE	@r1 decimal(9, 2),
		@r3 decimal(9, 2),
		@r6 decimal(9, 2),
		@r12 decimal(9, 2),
		@prev_price decimal(9,2),
		@prev_dt datetime,
		@o_price dec(9,2),
		@price dec(9,2)
		
	declare @tid int
	declare @strTicker varchar(50)
	declare @rRank int
	declare @tmp int
	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where (db_type=99 or db_strTicker = 'sSPY' or db_strTicker = 'sTLT')
		and db_inactive_dt is null
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @strTick
		order by db_ticker_id

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @s_yr int
			set @s_yr = YEAR(@start_dt)

			declare @e_yr int
			set @e_yr = year(GETDATE())
--			print @e_yr
			print @strTicker

			declare @iMonth int
			if @sdt is null
				set @iMonth = 1
			else
				set @iMonth = Month(@sdt)
				
			declare @dt datetime
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					--set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					select @dt = MIN(db_dt) from tbl_Prices where YEAR(db_dt)=@s_yr and MONTH(db_dt)=@iMonth and db_ticker_id = 538
					insert @tbl
					exec csp_Calc_Ret @dt, @strTicker

					delete tbl_Return_Rank
					where tid = @tid and dt = @dt
					
					insert tbl_Return_Rank
					select * from @tbl
					where tid = @tid and dt = @dt

					set @iMonth = @iMonth+1
				  end
				set @s_yr = @s_yr+1
				set @iMonth = 1
			  end

			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS
--if @tick is null
--	select * from @tbl
--	where rRank is not NULL
--	order by rRank desc, strTickers
--else
--	select * from @tbl
--	where rRank is not NULL
--	order by dt

--Pivot {
--- SIM Ret Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [sVTI], [sVEU], [sEEM], [sTLT],  'SIM' as DataSet
from (
select T.db_strTicker , FN.dt as dt, coalesce(FN.rRank ,0) as rRank
from IDToDSN_DKC.dbo.tbl_Return_Rank FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('sVTI', 'sVEU', 'sEEM', 'sTLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([sVTI], [sVEU], [sEEM],[sTLT])
) as Pvt
--- SIM Ret Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([sVTI],2) as sVTI, round([sVEU],2) as sVEU,round([sEEM],2) as sEEM, round([sTLT],2) as sTLT, 'SIM' as DataSet
from (
select T.db_strTicker , FN.dt as dt, coalesce(FN.price,0) as price 
from IDToDSN_DKC.dbo.tbl_Return_Rank FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('sVTI', 'sVEU', 'sEEM', 'sTLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([sVTI], [sVEU], [sEEM], [sTLT])
) as Pvt
--- End Pivot }
		  
	END TRY

	BEGIN CATCH
	close cDSS
	Deallocate cDSS

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