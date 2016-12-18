declare @ticks table (idx int identity, tid int)
insert @ticks
select distinct(tid) from tbl_Return_Rank where dt = '9-1-2016' 
and tid in (select db_ticker_id from tbl_Ticker where db_type = 2)
select * from @ticks

declare @mxid int = @@ROWCOUNT

declare @idx int=1

IF OBJECT_ID('tempdb..#TBL_EMA10_RT') IS NOT NULL BEGIN
	DROP TABLE #TBL_EMA10_RT
END

while @idx < @mxid
  begin
	IF OBJECT_ID('tempdb..#tblA') IS NOT NULL BEGIN
		DROP TABLE #tblA
	END
	create table #tblA (QuoteId int identity, StockId int, QuoteDay datetime, QuoteClose dec(9,3) )

	insert #tblA
	select db_ticker_id, db_dt, db_close
	from tbl_Prices
	where db_ticker_id in (select tid from @ticks where idx = @idx)
	and db_dt between '12-1-2006' and '9-30-2016'

	SELECT *, CAST(NULL AS FLOAT) AS EMA10 INTO #TBL_EMA10_RT FROM #tblA

	CREATE UNIQUE CLUSTERED INDEX EMA10_IDX_RT ON #TBL_EMA10_RT (StockId, QuoteId)

	IF OBJECT_ID('tempdb..#TBL_START_AVG') IS NOT NULL BEGIN
		DROP TABLE #TBL_START_AVG
	END

	SELECT StockId, AVG(QuoteClose) AS Start_Avg INTO #TBL_START_AVG FROM #tblA WHERE QuoteId <= 6 GROUP BY StockId

	DECLARE @C FLOAT = 2.0 / (1 + 6), @EMA10 FLOAT

	UPDATE
		T1
	SET
		@EMA10 =
			CASE
				WHEN QuoteId = 6 then T2.Start_Avg
				WHEN QuoteId > 6 then T1.QuoteClose * @C + @EMA10 * (1 - @C)
			END
		,EMA10 = @EMA10 
	FROM
		#TBL_EMA10_RT T1
	JOIN
		#TBL_START_AVG T2
	ON
		T1.StockId = T2.StockId
	OPTION (MAXDOP 1)


	update tbl_Prices
	set db_avg = A.EMA10
	from (
		select StockId, QuoteId, QuoteDay, QuoteClose, CAST(EMA10 AS NUMERIC(10,2)) AS EMA10
		from #TBL_EMA10_RT X, tbl_Prices P
		where X.StockID = P.db_ticker_id
		and X.QuoteDay = P.db_dt) as A
	where db_dt = A.QuoteDay
	and db_ticker_id = A.StockID

	
	set @idx=@idx+1
	IF OBJECT_ID('tempdb..#TBL_EMA10_RT') IS NOT NULL BEGIN
		DROP TABLE #TBL_EMA10_RT
	END
  end

	IF OBJECT_ID('tempdb..#TBL_EMA10_RT') IS NOT NULL BEGIN
		DROP TABLE #TBL_EMA10_RT
	END


-- =================
IF OBJECT_ID('tempdb..#TBL_EMA25_RT') IS NOT NULL BEGIN
	DROP TABLE #TBL_EMA25_RT
END

declare @tblA table (QuoteId int identity, StockID int, QuoteDay datetime, QuoteClose dec(9,3) )

insert @tblA
select db_ticker_id, db_dt, db_close
from tbl_Prices
where db_ticker_id = 989
and db_dt between '1-1-2014' and '12-16-2016'
order by db_dt

SELECT *, CAST(NULL AS FLOAT) AS EMA25 INTO #TBL_EMA25_RT FROM @tblA

CREATE UNIQUE CLUSTERED INDEX EMA25_IDX_RT ON #TBL_EMA25_RT (StockId, QuoteId)

IF OBJECT_ID('tempdb..#TBL_START_AVG') IS NOT NULL BEGIN
	DROP TABLE #TBL_START_AVG
END

SELECT StockId, AVG(QuoteClose) AS Start_Avg INTO #TBL_START_AVG FROM @tblA WHERE QuoteId <= 25 GROUP BY StockId

DECLARE @C FLOAT = 2.0 / (1 + 25), @EMA25 FLOAT

UPDATE
	T1
SET
	@EMA25 =
		CASE
			WHEN QuoteId = 25 then T2.Start_Avg
			WHEN QuoteId > 25 then T1.QuoteClose * @C + @EMA25 * (1 - @C)
		END
	,EMA25 = @EMA25 
FROM
	#TBL_EMA25_RT T1
JOIN
	#TBL_START_AVG T2
ON
	T1.StockId = T2.StockId
OPTION (MAXDOP 1)

SELECT StockId, QuoteId, QuoteDay, QuoteClose, CAST(EMA25 AS NUMERIC(10,2)) AS EMA25 FROM #TBL_EMA25_RT

select StockId, QuoteId, QuoteDay, QuoteClose, P.db_MA50 as EMA6, CAST(EMA25 AS NUMERIC(10,2)) as EMA25, 
case when P.db_avg > X.EMA25 then 1 else 0 end as BUY
from #TBL_EMA25_RT X
--, tbl_Return_Rank RR
, tbl_Prices P
where X.StockID = P.db_ticker_id
and X.QuoteDay = P.db_dt
--and RR.tid = P.db_ticker_id
--and RR.dt = P.db_dt
--and RR.tid = X.StockID
--and RR.dt = X.QuoteDay
order by P.db_dt

--===================

IF OBJECT_ID('tempdb..#TBL_EMA_LOOP') IS NOT NULL BEGIN
    DROP TABLE #TBL_EMA_LOOP
END

--declare @tblA table (QuoteId int identity, StockID int, QuoteDay datetime, QuoteClose dec(9,3) )
 
SELECT *, CAST(NULL AS FLOAT) AS EMA12, CAST(NULL AS FLOAT) AS EMA26 INTO #TBL_EMA_LOOP FROM @tblA

CREATE UNIQUE CLUSTERED INDEX EMA_IDX ON #TBL_EMA_LOOP (StockId, QuoteId)
 
DECLARE @StockId INT = 827, @QuoteId INT, @QuoteIdMax INT, @StartAvgEMA12 FLOAT, @StartAvgEMA26 FLOAT, @C_EMA12 FLOAT = 2.0 / (1 + 12), @C_EMA26 FLOAT = 2.0 / (1 + 26), @EMA12 FLOAT, @EMA26 FLOAT
declare @maxID int = @StockId+1
 
WHILE @StockId <= @maxID BEGIN
    SELECT @QuoteId = 1, @QuoteIdMax = MAX(QuoteId) FROM @tblA WHERE StockId = @StockId
    SELECT @StartAvgEMA12 = AVG(QuoteClose) FROM @tblA WHERE StockId = @StockId AND QuoteId <= 12
    SELECT @StartAvgEMA26 = AVG(QuoteClose) FROM @tblA WHERE StockId = @StockId AND QuoteId <= 26
 
    WHILE @QuoteId <= @QuoteIdMax BEGIN
        UPDATE
            T0
        SET
            EMA12 =
                CASE
                    WHEN @QuoteId = 12 THEN @StartAvgEMA12
                    WHEN @QuoteId > 12 THEN (T0.QuoteClose * @C_EMA12) + T1.EMA12 * (1.0 - @C_EMA12)
                END
            ,EMA26 =
                CASE
                    WHEN @QuoteId = 26 THEN @StartAvgEMA26
                    WHEN @QuoteId > 26 THEN (T0.QuoteClose * @C_EMA26) + T1.EMA26 * (1.0 - @C_EMA26)
                END
        FROM
            #TBL_EMA_LOOP T0
        JOIN
            #TBL_EMA_LOOP T1
        ON
            T0.StockId = T1.StockId
        AND
            T0.QuoteId - 1 = T1.QuoteId
        WHERE
            T0.StockId = @StockId
        AND
            T0.QuoteId = @QuoteId
 
        SELECT @QuoteId = @QuoteId + 1
    END
 
    SELECT @StockId = @StockId + 1
END
 
SELECT
    Y.StockId
    ,Y.QuoteId
    ,Y.QuoteDay
    ,Y.QuoteClose
	,CAST(X.EMA10 AS NUMERIC(10,2)) AS EMA10
    ,CAST(Y.EMA12 AS NUMERIC(10,2)) AS EMA12
    ,CAST(Y.EMA26 AS NUMERIC(10,2)) AS EMA26
    ,CAST(Y.EMA12 - Y.EMA26 AS NUMERIC(10,2)) AS MACD
	,case when (CAST(Y.EMA12 - Y.EMA26 AS NUMERIC(10,2)) > 0 and P.db_avg > X.EMA10 ) then 1 else 0 end as BUY
FROM
    #TBL_EMA_LOOP as Y, #TBL_EMA10_RT X, tbl_Return_Rank RR, tbl_Prices P
where Y.StockID = RR.tid
and Y.QuoteDay = RR.dt
and RR.tid = P.db_ticker_id
and RR.dt = P.db_dt
and RR.tid = Y.StockID
and RR.dt = Y.QuoteDay
and X.StockID = RR.tid
and X.QuoteDay = RR.dt
and RR.tid = P.db_ticker_id
and RR.dt = P.db_dt
and RR.tid = X.StockID
and RR.dt = X.QuoteDay
order by RR.dt
