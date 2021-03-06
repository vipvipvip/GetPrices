USE [master]
GO
/****** Object:  Database [StockDB]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE DATABASE [StockDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'IDtoDSN_Data', FILENAME = N'C:\data\Program Files\Microsoft SQL Server\SQLExpress\MSSQL\Data\StockDB.mdf' , SIZE = 1550464KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'IDtoDSN_Log', FILENAME = N'C:\data\Program Files\Microsoft SQL Server\SQLExpress\MSSQL\Data\StockDB_log.ldf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
GO
ALTER DATABASE [StockDB] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [StockDB].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [StockDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [StockDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [StockDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [StockDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [StockDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [StockDB] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [StockDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [StockDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [StockDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [StockDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [StockDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [StockDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [StockDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [StockDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [StockDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [StockDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [StockDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [StockDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [StockDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [StockDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [StockDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [StockDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [StockDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [StockDB] SET  MULTI_USER 
GO
ALTER DATABASE [StockDB] SET PAGE_VERIFY TORN_PAGE_DETECTION  
GO
ALTER DATABASE [StockDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [StockDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [StockDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [StockDB] SET DELAYED_DURABILITY = DISABLED 
GO
USE [StockDB]
GO
/****** Object:  User [NT AUTHORITY\NETWORK SERVICE]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE USER [NT AUTHORITY\NETWORK SERVICE] FOR LOGIN [NT AUTHORITY\NETWORK SERVICE] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [CenseoAdmin]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE USER [CenseoAdmin] FOR LOGIN [CenseoAdmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [BUILTIN\Administrators]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE USER [BUILTIN\Administrators] FOR LOGIN [BUILTIN\Administrators]
GO
/****** Object:  DatabaseRole [Prod]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE ROLE [Prod]
GO
ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\NETWORK SERVICE]
GO
ALTER ROLE [db_datareader] ADD MEMBER [NT AUTHORITY\NETWORK SERVICE]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [NT AUTHORITY\NETWORK SERVICE]
GO
ALTER ROLE [db_owner] ADD MEMBER [BUILTIN\Administrators]
GO
/****** Object:  Schema [NT AUTHORITY\NETWORK SERVICE]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE SCHEMA [NT AUTHORITY\NETWORK SERVICE]
GO
/****** Object:  UserDefinedTableType [dbo].[TBL_CORRELATION]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE TYPE [dbo].[TBL_CORRELATION] AS TABLE(
	[Col_A] [decimal](9, 2) NULL,
	[Col_B] [decimal](9, 2) NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[fn_CalcRankSlope]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 1/19/2014
-- Description:	Calculate VIX based on daily return
-- Need SQL2012 for the LAG() function.
-- =============================================
CREATE FUNCTION [dbo].[fn_CalcRankSlope]
(
	-- Add the parameters for the function here
	@sdt datetime,
	@edt datetime,
	@tid int
)
RETURNS dec(9,3)
AS
BEGIN
/*
USE [StockDB]
GO
declare @tid int
select @tid=db_ticker_id from tbl_Ticker where db_strTicker = 'shy'

SELECT [dbo].[fn_CalcRankSlope] (
   '6-1-2011'
  ,'6-1-2012'
  ,@tid)
GO

*/

--declare @tid int=5269
--declare @sdt datetime = '3-1-2013'
--declare @edt datetime = '2-28-2014'

declare @xbar float
declare @ybar float
declare @slp dec(9,3)
declare @rdt datetime

select @rdt = min(dt)
from tbl_Return_Rank
where year(dt) = year(@edt)
and month(dt) = month(@edt)
and tid = @tid

declare @tbl table (idx int identity, dt datetime, val dec(9,3))
insert @tbl
Select dt, rRank
from tbl_Return_Rank
where dt between @sdt and @rdt
and tid = @tid
order by dt

declare @cnt int
select @cnt = count(*) from 
(
select val
from @tbl
where dt between @sdt and @edt
group by val
) as A

if @cnt = 1 return 0

	select 
	@ybar = AVG(convert(float,idx)), @xbar = AVG(val)
	from @tbl

	select 
	-- got this formula from Excel and verified the slope matches to 3 digits.
	@slp = coalesce(sum( (convert(float,val)-@xbar)*(idx-@ybar) ) / sum( Power((convert(float,val)-@xbar),2)),0)
	from @tbl


return @slp

END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_CalcVIX]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 1/19/2014
-- Description:	Calculate VIX based on daily return
-- Need SQL2012 for the LAG() function.
-- =============================================
CREATE FUNCTION [dbo].[fn_CalcVIX]
(
	-- Add the parameters for the function here
	@sdt datetime,
	@edt datetime,
	@tid int
)
RETURNS dec(9,2)
AS
BEGIN

declare @vix dec(9,2)

declare @tbl table (idx int identity, tid int, dt datetime, sPrice dec(9,3), ePrice dec(9,3), DRet dec(9,3))

insert @tbl
select db_ticker_id, db_dt, db_close as sPrice, LAG(db_close, 1, db_close) over (order by db_dt) as ePrice, 0
from tbl_Prices
where db_dt between @sdt and @edt
and db_ticker_id = @tid

update @tbl
set DRet = (ePrice/sPrice - 1) * 100


select @vix = convert(dec(9,2), STDEV(Dret) * sqrt(252))  from @tbl

	-- Return the result of the function
	RETURN @vix

END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_getNextDate]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fn_getNextDate] 
(
	@sd datetime,
	@Freq smallint, --1=Daily,2=Weekly,3=Monthly,4=Qtrly, 5=Yearly
	@interval smallint=1
)
RETURNS datetime
AS
BEGIN
	declare @temp nvarchar(50)
	declare @dt datetime
	if		@Freq = 3 
		begin
			set @temp = convert(nvarchar(2), datepart(mm,@sd))
			set @temp = @temp +  '/'
			set @temp = @temp + '1'
			set @temp = @temp + '/'
			set @temp = @temp + convert(nvarchar(4), datepart(yyyy,@sd))
			set @sd = @temp
		end

	else if @Freq = 4 
		begin
			set @temp = convert(nvarchar(2), datepart(mm,@sd))
			set @temp = @temp +  '/'
			set @temp = @temp + '1'
			set @temp = @temp + '/'
			set @temp = @temp + convert(nvarchar(4), datepart(yyyy,@sd))
			set @sd = @temp
		end
	else if @Freq = 5 
		begin
			set @temp = convert(nvarchar(2), datepart(mm,@sd))
			set @temp = @temp +  '/'
			set @temp = @temp + '1'
			set @temp = @temp + '/'
			set @temp = @temp + convert(nvarchar(4), datepart(yyyy,@sd))
			set @sd = @temp
		end


	if		@Freq = 1 set @dt= DateAdd(dd,@interval,@sd)
	else if @Freq = 2 set @dt= DateAdd(ww,@interval,@sd)
	else if @Freq = 3 set @dt= DateAdd(mm,@interval,@sd)
	else if @Freq = 4 set @dt= DateAdd(qq,@interval,@sd)
	else if @Freq = 5 set @dt= DateAdd(yy,@interval,@sd)
return @dt
END



GO
/****** Object:  UserDefinedFunction [dbo].[fn_SplitToTable]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    function [dbo].[fn_SplitToTable]( @str varchar(max), @delim varchar(80) )
returns @tbl_Items  TABLE (val varchar(80))
as
begin
 declare @x  TABLE (val varchar(80))
 declare @iPos int
 declare @iBeg int
 declare @nItems int
 declare @aVal varchar(80)
 declare @strT varchar(100)
 set @nItems = 0
 set @iPos = 0
 set @iBeg = 0
 set @strT = @str + @delim
 while 1=1
 BEGIN
	set @iPos = charindex(@delim, @strT, @iPos+1)
	if @iPos <= 0 
	  break
	else
	 begin
	   set @aVal = substring(@strT, @iBeg, @iPos-@iBeg)
	   insert @x select @aVal as val
	   set @nItems = @nItems + 1
	   set @iBeg = @iPos+1
	 end
  if @iPos = 0 break
 END


 insert @tbl_Items
 select * from @x
 return

end


GO
/****** Object:  UserDefinedFunction [dbo].[fnMinValue]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- SQL minimum of 2 values
-- SQL UDF - scalar-valued function - user-defined function
CREATE FUNCTION [dbo].[fnMinValue] 
               (@ColumnA MONEY, 
                @ColumnB MONEY) 
RETURNS MONEY 
AS 
  BEGIN 
    RETURN (0.5 * ((@ColumnA + @ColumnB) - abs(@ColumnA - @ColumnB))) 
  END 

GO
/****** Object:  UserDefinedFunction [dbo].[GetHttp]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetHttp]
(
    @url varchar(300)      
)
--returns varchar(8000)
returns @RET table (Resp varchar(max))
as
BEGIN
    DECLARE @win int 
    DECLARE @hr  int 
    DECLARE @text varchar(max)

EXEC @hr=sp_OACreate 'WinHttp.WinHttpRequest.5.1',@win OUT 

EXEC @hr=sp_OAMethod @win, 'Open',NULL,'GET',@url,'false'
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

EXEC @hr=sp_OAMethod @win,'Send'
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

/* comment out below to use @text variable for small data */
--INSERT @RET
--EXEC @hr=sp_OAGetProperty @win,'ResponseText'
--IF @hr <> 0 EXEC sp_OAGetErrorInfo @win

EXEC @hr=sp_OAGetProperty @win,'ResponseText',@text OUTPUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win
--print @text

EXEC @hr=sp_OADestroy @win 
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

insert @RET
select @text

return
END
GO
/****** Object:  UserDefinedFunction [dbo].[udf_sampleNormal]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[udf_sampleNormal](@u real, @v real)
returns @tbl table (x real, y real)
as
begin
    declare @r real
    
    --set @u = rand(DATEPART(ms,getdate()))
    --print 'u'
    --print @u
    --set @v = rand()
    --print 'v'
    --print @v
    
    declare @x real, @y real
    set @x = SQRT(-2 * log(@u)) * COS(2 * pi() * @v)
    set @y = SQRT(-2 * log(@u)) * sin(2 * pi() * @v)
    --print 'x'
    --print @x
    --print 'y'
    --print @y
    
    insert @tbl
    select @x, @y
	return
end
GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sysdiagrams](
	[name] [nvarchar](128) NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
 CONSTRAINT [PK_sysdiagrams] PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_FiveNum]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_FiveNum](
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
 CONSTRAINT [PK_tbl_FiveNum] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_FiveNum_Daily]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_FiveNum_Daily](
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
 CONSTRAINT [PK_tbl_FiveNum_Daily] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_FiveNum_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_FiveNum_Weekly](
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
 CONSTRAINT [PK_tbl_FiveNum_Weekly] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Freq_Rank]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Freq_Rank](
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_freq_rank] [tinyint] NOT NULL,
	[db_close] [real] NOT NULL,
 CONSTRAINT [PK_tbl_Freq_Rank] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Prices]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Prices](
	[db_row_id] [int] IDENTITY(1,1) NOT NULL,
	[db_ticker_id] [int] NOT NULL,
	[db_volume] [int] NULL,
	[db_dt] [smalldatetime] NULL,
	[db_close] [real] NULL,
	[db_mult] [real] NULL,
	[db_avg] [real] NULL,
	[db_index] [real] NULL,
	[db_rank] [smallint] NULL,
	[db_mult_avg_ratio] [real] NULL,
	[db_rank_change] [smallint] NULL,
	[db_change_rank] [smallint] NULL,
	[db_hi_lo] [smallint] NULL CONSTRAINT [DF_tbl_Prices_db_hi_lo]  DEFAULT ((-1)),
	[db_hi_cnt] [int] NULL,
	[db_lo_cnt] [int] NULL,
	[db_type] [smallint] NULL,
	[db_slope] [real] NULL,
 CONSTRAINT [PK_tbl_Prices] PRIMARY KEY NONCLUSTERED 
(
	[db_row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_tbl_Prices_tickerID_dt]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE CLUSTERED INDEX [IX_tbl_Prices_tickerID_dt] ON [dbo].[tbl_Prices]
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_Return_Rank]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Return_Rank](
	[tid] [int] NOT NULL,
	[strTicker] [varchar](10) NOT NULL,
	[dt] [datetime] NOT NULL,
	[price] [decimal](9, 2) NULL,
	[r1] [decimal](9, 2) NULL,
	[r3] [decimal](9, 2) NULL,
	[r6] [decimal](9, 2) NULL,
	[r12] [decimal](9, 2) NULL,
	[vix] [decimal](9, 2) NULL,
	[rRank] [int] NULL,
 CONSTRAINT [PK_tbl_Return_Rank] PRIMARY KEY CLUSTERED 
(
	[tid] ASC,
	[strTicker] ASC,
	[dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Return_Rank_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Return_Rank_Weekly](
	[tid] [int] NULL,
	[strTicker] [varchar](10) NULL,
	[dt] [datetime] NULL,
	[price] [decimal](9, 2) NULL,
	[r1] [decimal](9, 2) NULL,
	[r3] [decimal](9, 2) NULL,
	[r6] [decimal](9, 2) NULL,
	[r12] [decimal](9, 2) NULL,
	[rRank] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Ticker]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Ticker](
	[db_ticker_id] [int] IDENTITY(1,1) NOT NULL,
	[db_strTicker] [nvarchar](50) NOT NULL,
	[db_type] [smallint] NULL,
	[db_inactive_dt] [smalldatetime] NULL,
	[db_addition_dt] [smalldatetime] NULL,
 CONSTRAINT [PK_tbl_Ticker] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbl_Trades]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Trades](
	[iid] [int] NOT NULL,
	[id] [int] NULL,
	[ticker_id] [int] NULL,
	[strTicker] [nvarchar](50) NULL,
	[bdate] [datetime] NULL,
	[bprice] [decimal](9, 2) NULL,
	[brank] [int] NULL,
	[bBuy] [tinyint] NULL,
	[sdate] [datetime] NULL,
	[sprice] [decimal](9, 2) NULL,
	[srank] [int] NULL,
	[gain] [decimal](9, 2) NULL,
	[ratio] [decimal](9, 2) NULL,
	[sratio] [decimal](9, 2) NULL,
	[typ] [smallint] NULL,
	[cnt] [int] NULL,
	[sp_rank] [int] NULL,
	[mean_sp_rank] [int] NULL,
	[nshares] [int] NULL,
	[buy_amount] [decimal](9, 2) NULL,
 CONSTRAINT [PK_tbl_Trades] PRIMARY KEY CLUSTERED 
(
	[iid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_tbl_Prices]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tbl_Prices] ON [dbo].[tbl_Prices]
(
	[db_ticker_id] ASC,
	[db_dt] ASC,
	[db_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_tbl_Prices_db_dt]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE NONCLUSTERED INDEX [IX_tbl_Prices_db_dt] ON [dbo].[tbl_Prices]
(
	[db_dt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tbl_Ticker]    Script Date: 9/25/2016 9:17:40 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tbl_Ticker] ON [dbo].[tbl_Ticker]
(
	[db_strTicker] ASC,
	[db_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tbl_Prices]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Prices_tbl_Prices_TickerID] FOREIGN KEY([db_ticker_id])
REFERENCES [dbo].[tbl_Ticker] ([db_ticker_id])
GO
ALTER TABLE [dbo].[tbl_Prices] CHECK CONSTRAINT [FK_tbl_Prices_tbl_Prices_TickerID]
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Averages_2]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[csp_Calc_Averages_2]
(
	@s_date datetime  = '1-1-2007',
	@e_date datetime = null,
	@typ smallint = 1,
	@tick_id int=0
)
as
/*
EXECUTE [csp_Calc_Averages_2] @typ=2, @s_date='7-20-2015', @e_date='8-15-2015', @tick_id=827
, @s_date='1-12-2014', @e_date='1-14-2014'
, @tick_id=3, @typ=1
GO
*/
-- use this sql to get the resulting data
/*
  select P.db_ticker_id, P.db_dt, T.db_strTicker, convert(dec(9,2),(P.db_mult-P.db_avg+P.db_avg-P.db_index)/P.db_close * 100) as IDX,
  case when P.db_index > P.db_mult_avg_ratio then 1 
	else 0 
  end
  as 'LT'
  FROM [dbo].[tbl_Prices] P, tbl_Ticker T
  where P.db_ticker_id = T.db_ticker_id
  and db_dt = (select max(db_dt)
				from dbo.tbl_Prices
				where db_ticker_id = 538)
  and P.db_mult > P.db_avg
  and P.db_avg > db_index
  and P.db_close >= 10.0
  and P.db_volume >= 100000
  order by LT desc, IDX
  
select * from tbl_Prices where db_mult_avg_ratio is null
and db_type = 1
and db_dt > '1-1-2014'

*/
set nocount on
declare @doit int
set @doit=1

declare @SPID int
set @SPID = 827 -- S&P Index ticker id
declare @start_date datetime
set @start_date = '1/1/' + convert(varchar,YEAR(@s_date)-1)
print 'Start date = ' + convert(varchar, @start_date)
print 'End date = ' + convert(varchar, @e_date)
declare @sp_dt datetime
declare @sp_close float
declare @sp_tick_id int
declare @idx int
set @idx=1
declare @dt2 datetime
declare @tbl_SPID table (idx int identity, p_tid int, p_dt datetime)

insert @tbl_SPID
select db_ticker_id, db_dt
from tbl_Prices
where db_ticker_id = @SPID
and db_dt >= @start_date and db_dt <= @e_date
order by db_dt desc
--insert @tbl_SPID
--select tid, dt
--from tbl_Return_Rank
--where tid = @SPID
--and dt >= @start_date and dt <= @e_date
--order by dt desc

print '[csp_Calc_Averages_2_WIP] nrows = ' + convert(varchar, @@ROWCOUNT)

select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt from @tbl_SPID where idx=1
print '[csp_Calc_Averages_2_WIP] sp_dt=' + convert(varchar, @sp_dt)

declare @bFound int
set @bFound=0
BEGIN TRY
while @sp_dt > @s_date
begin
 if exists (select db_dt from tbl_Prices where db_dt = @sp_dt and db_mult is null)
 begin
  set @bFound=1
---- { MA 10
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx+9
	print '[csp_Calc_Averages_2_WIP] dt2=' + convert(varchar, @dt2)
  if 1=@doit
  begin
	if @tick_id > 0
		update tbl_Prices
		set db_mult = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_ticker_id = @tick_id
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_ticker_id = @tick_id
		and db_dt = @sp_dt
		 
	else
		update tbl_Prices
		set db_mult = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_type=@typ
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_dt = @sp_dt
  end	
	
---- } MA 10
---- { EMA 10
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx+14
	print '[csp_Calc_Averages_2_WIP] dt2=' + convert(varchar, @dt2) + '-- defer to EMA10 '
  if 1=0
  begin
	if @tick_id > 0
		update tbl_Prices
		set db_avg = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_ticker_id = @tick_id
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_ticker_id = @tick_id
		and db_dt = @sp_dt
		 
	else
		update tbl_Prices
		set db_avg = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_type=@typ
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_dt = @sp_dt
  end
---- } MA 15
---- { MA 65
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx+64
	print '[csp_Calc_Averages_2_WIP] dt2=' + convert(varchar, @dt2) + ' -- skip it not used '
  if 1=0
  begin
	if @tick_id > 0
		update tbl_Prices
		set db_index = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_ticker_id = @tick_id
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_ticker_id = @tick_id
		and db_dt = @sp_dt
		 
	else
		update tbl_Prices
		set db_index = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
						and db_type=@typ
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_dt = @sp_dt
  end
---- } MA 65
---- { MA 200
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx+199
	print '[csp_Calc_Averages_2_WIP] dt2=' + convert(varchar, @dt2) + ' -- skip it not used '
  if 1=0
  begin
	if @tick_id > 0
		update tbl_Prices
		set db_mult_avg_ratio = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_ticker_id = @tick_id
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_ticker_id = @tick_id
		and db_dt = @sp_dt
		 
	else
		update tbl_Prices
		set db_mult_avg_ratio = A.AVG20
		from (
			select db_ticker_id TID, convert(dec(9,2),AVG(db_close)) as AVG20
			from tbl_Prices
			where db_dt between @dt2 and @sp_dt
			and db_type=@typ
			group by db_ticker_id
		) as A
		where db_ticker_id = A.TID
		and db_dt = @sp_dt
  end
---- } MA 200
end
else
	set @bFound=0

--do this after all MA are done to do the next date
	if @bFound = 1
		select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt 
		from @tbl_SPID 
		where idx=@idx+18
	else
		select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt 
		from @tbl_SPID 
		where idx=@idx+1
	print '[csp_Calc_Averages_2_WIP] Reset sp_dt=' + convert(varchar, @sp_dt)
end
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

/***************************************/
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Avg]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[csp_Calc_Avg]
(
	@s_date datetime,
	@e_date datetime
)
as
set nocount on
-- Step 2.1 and 2.2
declare @ticker_id int
declare @sp_close money
declare @start_date datetime
if @s_date is null
	select @start_date = dateadd(dd, -10, max(db_dt)) from tbl_Prices where db_ticker_id = 538
else
	set @start_date = @s_date

--print @start_date

declare @end_date datetime
if @e_date is null
	select @end_date = max(db_dt) from tbl_Prices where (db_avg <= 0.0 or db_index <= 0.0 or db_mult <= 0.0 or db_avg is null or db_index is null or db_mult is null)
else
	set @end_date = @e_date
--print @end_date

if @end_date is not null
begin
	declare cDSS cursor for
	select db_ticker_id
	from tbl_Ticker
	where db_ticker_id > 50
	order by db_ticker_id

	Open cDSS
	Fetch next from cDSS
	into @ticker_id

	declare @dt1 datetime
	declare @dt2 datetime
	declare @row_id int
	declare @avg float

	while @@FETCH_STATUS = 0
	begin

		select top 1 @row_id = db_row_id, @dt1 = db_dt
		from tbl_Prices
		where db_ticker_id = @ticker_id		
		and db_dt > @start_date
		order by db_dt desc

		set @dt2 = dateadd(dd, -1830, @dt1)
		if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

		select @avg = convert(dec(9,2), avg(db_mult))
		from tbl_Prices
		where db_ticker_id = @ticker_id
		and db_dt between @dt2 and @dt1

		update tbl_Prices
		set db_avg = @avg,
			db_index = convert(dec(9,2), db_close/@avg) * 100.00
		where db_ticker_id = @ticker_id
		and db_dt = @dt1
		and db_row_id = @row_id

		--print convert(varchar,@dt1) + ', ' + convert(varchar, @dt2)

		while exists (select db_dt from tbl_Prices where db_ticker_id = @ticker_id  and (db_avg <= 0.0 or db_index <= 0.0 or db_mult <= 0.0 or db_avg is null or db_index is null or db_mult is null))
		  begin
			select top 1 @dt1 = db_dt, @row_id=db_row_id
			from tbl_Prices
			where db_ticker_id = @ticker_id
			and db_dt < @dt1
			order by db_dt desc


			set @dt2 = dateadd(dd, -1830, @dt1)
			if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

			--print convert(varchar,@dt1) + ', ' + convert(varchar, @dt2)

			select @avg = convert(dec(9,2), avg(db_mult))
			from tbl_Prices
			where db_ticker_id = @ticker_id
			and db_dt between @dt2 and @dt1

			update tbl_Prices
			set db_avg = @avg,
				db_index = convert(dec(9,2), db_close/@avg) * 100.00
			where db_ticker_id = @ticker_id
			and db_dt = @dt1
			and db_row_id = @row_id

			print 'row id=' + convert(varchar, @row_id) + ', ' + 'ticker id=' + convert(varchar, @ticker_id) + ', ' + 'avg=' + convert(varchar, @avg)


		  end

		Fetch next from cDSS
		into @ticker_id

	end
	close cDSS
	Deallocate cDSS
end
else
	print 'no end date'
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Diff]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE procedure [dbo].[csp_Calc_Diff]
(
	@dt datetime= null
)
as

set nocount on

declare @t table (idx int identity, ticker varchar(50), id int, r2 int, r1 int, c2 dec(9,2), c1 dec(9,2), diff int, d1 varchar(12), d2 varchar(12), cnt int null)

declare @SPID int
set @SPID = 538 -- S&P Index ticker id



declare @sp_dt varchar(12)
declare @sp_close float
declare @sp_prev float

if @dt is null set @dt = getdate()
declare cDSS scroll cursor for
select top 30 db_dt, db_close
from tbl_Prices
where db_ticker_id = @SPID
and db_dt <= @dt
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

update @t
set cnt = c
from (select ticker as tick, count(*) as c from @t group by ticker) as A
where A.tick = ticker
/*
--Most diff and count in past 30 days
select ticker, id, sum(diff) as diff, cnt
from @t
group by ticker, id, cnt
order by diff, cnt

-- Detail of Most diff and count in past 30 days
select * from @t order by cnt, d1 desc, ticker
*/
-- Diff as of today
select top 10 T.db_strticker, T.db_ticker_id, P2.db_rank as P2Rank, P1.db_rank as P1Rank, P2.db_close as P2Close, P1.db_close as P1Close, P2.db_rank - P1.db_rank as Diff, @today, @yday
from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
where P1.db_ticker_id = T.db_ticker_id
and P1.db_ticker_id = P2.db_ticker_id
and P1.db_dt = @yday and P2.db_dt = @today
order by Diff asc

-- Diff over last today and 30 days ago
select T.db_strticker, T.db_ticker_id, P2.db_rank as P2Rank, P1.db_rank as P1Rank, P2.db_close as P2Close, P1.db_close as P1Close, P2.db_rank - P1.db_rank as Diff, @today, @sp_dt
from tbl_Ticker T, tbl_Prices P1, tbl_Prices P2
where P1.db_ticker_id = T.db_ticker_id
and P1.db_ticker_id = P2.db_ticker_id
and P1.db_dt = @sp_dt and P2.db_dt = @today
and P2.db_rank - P1.db_rank < -100
order by Diff asc








GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_EOM_Return]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 2-27-2015
-- Description:	Unlike r<1,3,6,12> in tbl_Return,
-- which are returns of previous 1,3,6 and 12
-- months, this SP calcs return by using price of 
-- month & month+1
-- So to calc return for Jan, it uses the closing
-- price of 1st Jan and 1st Feb
-- =============================================
CREATE PROCEDURE [dbo].[csp_Calc_EOM_Return] 
(
	-- Add the parameters for the function here
	@sdt datetime=null,
	@edt datetime=null,
	@tid int
)
AS
/*
DECLARE @tid int
select @tid=db_ticker_id from tbl_Ticker where db_strTicker='TLT'
EXECUTE [dbo].[csp_Calc_EOM_Return] 
   NULL
  ,NULL
  ,@tid
*/

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @tbl table (idx int identity, tid int, tick varchar(50), dt datetime, sPrice money, ePrice money, EOM_Ret money)

--insert @tbl
--select db_ticker_id, db_dt, db_close as sPrice, LAG(db_close, 1, db_close) over (order by db_dt) as ePrice, 0
--from tbl_Prices
--where db_dt between @sdt and @edt
--and db_ticker_id = @tid

if @sdt is null set @sdt = '12-31-2006'
if @edt is null set @edt = getdate()

insert @tbl
select tid, T.db_strTicker, dt, price as sPrice, lead(price, 1, price) over (order by dt) as ePrice, 0
from tbl_Ticker T, tbl_Return_Rank
where T.db_ticker_id = tbl_Return_Rank.tid
and dt between @sdt and @edt
and tid = @tid
order by dt


-- Do latest date calcs {
declare @mxDte datetime
select @mxDte = max(db_dt) from tbl_Prices where db_ticker_id = @tid

declare @mxID int
select @mxID = max(idx) from @tbl

update @tbl
set ePrice = A.APrice
from (select db_dt as ADTE, db_close as APrice from tbl_Prices P where P.db_ticker_id = @tid and P.db_dt=@mxDte) as A
where idx = @mxID

update @tbl
set EOM_Ret = (eprice-sprice)/sprice



select * from @tbl
order by idx

END

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Five_Num]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Five_Num]
(
	@nYears int=5, -- set 5=Monthly, 1=Weekly
	@i_dt datetime=null,
	@tick varchar(10),
	@o_min dec(9,2) output,
	@o_hl dec(9,2) output,
	@o_median dec(9,2) output,
	@o_hu dec(9,2) output,	
	@o_max dec(9,2) output,
	@o_price dec(9,2) output,
	@o_rank int output


)
as
set nocount on;
/*
USE [IDToDSN_DKC]
GO

DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank dec(9,2)

EXEC	[dbo].[csp_Calc_Five_Num]
		5,
		@i_dt = '3-5-2013',
		@tick = N'IVV',
		@o_min = @o_min OUTPUT,
		@o_hl = @o_hl OUTPUT,
		@o_median = @o_median OUTPUT,
		@o_hu = @o_hu OUTPUT,
		@o_max = @o_max OUTPUT,
		@o_price = @o_price OUTPUT,
		@o_rank = @o_rank OUTPUT

SELECT	@o_min as N'@o_min',
		@o_hl as N'@o_hl',
		@o_median as N'@o_median',
		@o_hu as N'@o_hu',
		@o_max as N'@o_max',
		@o_price as N'@o_price'


*/
declare @today datetime
set @today = @i_dt

declare @ticker_id int
select @ticker_id = db_ticker_id from tbl_Ticker where db_strTicker=@tick

declare @start_dt datetime

set @start_dt = DATEADD(d,-365*@nYears,@today)
print 'Start Date=' + convert(varchar, @start_dt) + ' to ' + ' End Date=' + convert(varchar, @today)

--select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @start_dt
if not exists (select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @today)
	begin
	select @o_min=0,
		@o_hl=0,
		@o_median=0, 
		@o_hu=0,
		@o_max=0,
		@o_price=0
	return		
	end

declare @MIN dec(9,2), @HL dec(9,2), @MEDIAN dec(9,2), @HU dec(9,2),@MAX dec(9,2)

--select @MIN=MIN(db_close), @MAX=MAX(db_close)
select @MAX=MAX(db_close)
from tbl_Prices 
where db_ticker_id = @ticker_id 
and db_dt between @start_dt and @today 
/*
select
    @HL=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount/4+1, (x.TickerCount+1)/4)    
group by
    x.db_ticker_id 
*/
select
    @MEDIAN=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount/2+1, (x.TickerCount+1)/2)    
group by
    x.db_ticker_id 

/*
select
    @HU=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount*3/4+1, (x.TickerCount+1)*3/4)    
group by
    x.db_ticker_id 
*/
--select @today as Dte, @MIN as MinClose, @HL as HL, @MEDIAN as MedianClose, @HU as HU, @MAX as MaxClose

/*
select @o_min=@MIN,
	@o_hl=@HL,
	@o_median=@MEDIAN, 
	@o_hu=@HU,
	@o_max=@MAX

select @o_rank = 
	      case 
			when (@o_price >= @o_max) then 4
			when (@o_price >= @o_hu) then 3
			when (@o_price >= @o_median) then 2
			when (@o_price >= @o_hl) then 1
			when (@o_price >= @o_min) then 0
			else 0
	      end	
*/
select	@o_price = db_close from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @i_dt 
declare @tbl table (idx int identity, val dec(9,3))
insert @tbl
select top 7 0 from tbl_Prices

update @tbl set val= @MEDIAN where idx = 1
update @tbl set val= @MAX where idx = 7
update @tbl set val = (select AVG(val) from @tbl where val > 0) where idx = 4 
update @tbl set val = (select AVG(val) from @tbl where idx=1 or idx = 4) where idx = 3 
update @tbl set val = (select AVG(val) from @tbl where idx=1 or idx = 3) where idx = 2
update @tbl set val = (select AVG(val) from @tbl where idx=4 or idx = 7) where idx = 5
update @tbl set val = (select AVG(val) from @tbl where idx=5 or idx = 7) where idx = 6

select @o_min=@MEDIAN,
	@o_hl=(select val from @tbl where idx = 2),
	@o_median=(select val from @tbl where idx = 4), 
	@o_hu=(select val from @tbl where idx = 5),
	@o_max=@MAX

select	@o_rank = 
	      case 
			when (@o_price >= @o_max) then 4
			when (@o_price >= @o_hu) then 3
			when (@o_price >= @o_median) then 2
			when (@o_price >= @o_hl) then 1
			when (@o_price >= @o_min) then 0
			else 0
	      end	
--select * from @tbl

--print convert(varchar, @ticker_id) + '--- =' + convert(varchar,@o_price)

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Five_Num_Trend]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Five_Num_Trend]
(
	@nYears int=5, -- set 5=Monthly, 1=Weekly
	@i_dt datetime=null,
	@tick varchar(10)=null,
	@o_min dec(9,2) output,
	@o_hl dec(9,2) output,
	@o_median dec(9,2) output,
	@o_hu dec(9,2) output,	
	@o_max dec(9,2) output,
	@o_price dec(9,2) output,
	@o_rank int output


)
as
set nocount on;
/*
--This SP is used to calc trend of the VTI only and used in XLS models to do allocation.
--It calculates the genuine Five Num Summary as per Statistics books.
USE [IDToDSN_DKC]
GO

DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
EXEC	[dbo].[csp_Calc_Five_Num_Trend]
		5
		,@i_dt ='9-30-2013'
		,@tick = N'VTI'
		,@o_min = @o_min OUTPUT
		,@o_hl = @o_hl OUTPUT
		,@o_median = @o_median OUTPUT
		,@o_hu = @o_hu OUTPUT
		,@o_max = @o_max OUTPUT
		,@o_price = @o_price OUTPUT
		,@o_rank = @o_rank OUTPUT

SELECT	@o_price as N'@o_price',
		@o_min as N'@o_min',
		@o_hl as N'@o_hl',
		@o_median as N'@o_median',
		@o_hu as N'@o_hu',
		@o_max as N'@o_max',
		@o_rank as N'@o_rank'

*/
declare @tbl_Rank TABLE (db_ticker_id int, db_Close dec(9,2), CloseRank int, TickerCount int)

declare @today datetime
if @i_dt is null
	set @today = CONVERT(varchar(10), GETDATE(), 101)
else
	set @today = @i_dt

if @tick is null
	set @tick = 'VTI'

declare @ticker_id int
select @ticker_id = db_ticker_id from tbl_Ticker where db_strTicker=@tick

declare @start_dt datetime

set @start_dt = DATEADD(d,-365*@nYears,@today)
print 'Start Date=' + convert(varchar, @start_dt) + ' to ' + ' End Date=' + convert(varchar, @today)

--select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @start_dt
if not exists (select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @today)
	begin
	select @o_min=0,
		@o_hl=0,
		@o_median=0, 
		@o_hu=0,
		@o_max=0,
		@o_price=0,
		@o_rank=0
	return		
	end

declare @MIN dec(9,2), @HL dec(9,2), @MEDIAN dec(9,2), @HU dec(9,2),@MAX dec(9,2)

select @MIN=MIN(db_close), @MAX=MAX(db_close)
--select @MAX=MAX(db_close)
from tbl_Prices 
where db_ticker_id = @ticker_id 
and db_dt between @start_dt and @today 

insert @tbl_Rank
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
select
    @HL=AVG(db_close)
from @tbl_Rank x
where
    x.CloseRank  in (x.TickerCount/4+1, (x.TickerCount+1)/4)    
group by
    x.db_ticker_id 

select
    @MEDIAN=AVG(db_close)
from @tbl_Rank x
where
    x.CloseRank  in (x.TickerCount/2+1, (x.TickerCount+1)/2)    
group by
    x.db_ticker_id 


select
    @HU=AVG(db_close)
from @tbl_Rank x
where
    x.CloseRank  in (x.TickerCount*3/4+1, (x.TickerCount+1)*3/4)    
group by
    x.db_ticker_id 

select	@o_price = db_close from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @today

select @o_min=@MIN,
	@o_hl=@HL,
	@o_median=@MEDIAN, 
	@o_hu=@HU,
	@o_max=@MAX

select @o_rank = 
	      case 
			when (@o_price >= @o_max) then 4
			when (@o_price >= @o_hu) then 3
			when (@o_price >= @o_median) then 2
			when (@o_price >= @o_hl) then 1
			when (@o_price >= @o_min) then 0
			else 0
	      end	


/*
declare @tbl table (idx int identity, val dec(9,3))
insert @tbl
select top 7 0 from tbl_Prices

update @tbl set val= @MEDIAN where idx = 1
update @tbl set val= @MAX where idx = 7
update @tbl set val = (select AVG(val) from @tbl where val > 0) where idx = 4 
update @tbl set val = (select AVG(val) from @tbl where idx=1 or idx = 4) where idx = 3 
update @tbl set val = (select AVG(val) from @tbl where idx=1 or idx = 3) where idx = 2
update @tbl set val = (select AVG(val) from @tbl where idx=4 or idx = 7) where idx = 5
update @tbl set val = (select AVG(val) from @tbl where idx=5 or idx = 7) where idx = 6

select @o_min=@MEDIAN,
	@o_hl=(select val from @tbl where idx = 2),
	@o_median=(select val from @tbl where idx = 4), 
	@o_hu=(select val from @tbl where idx = 5),
	@o_max=@MAX

select	@o_rank = 
	      case 
			when (@o_price >= @o_max) then 4
			when (@o_price >= @o_hu) then 3
			when (@o_price >= @o_median) then 2
			when (@o_price >= @o_hl) then 1
			when (@o_price >= @o_min) then 0
			else 0
	      end	
--select * from @tbl

--print convert(varchar, @ticker_id) + '--- =' + convert(varchar,@o_price)
*/
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Daily]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_Daily]
(
	@db_dt datetime,
	@tick_id int,
	@str_ticker varchar(50)=null)
as
begin
/*
declare @Xtbl table (idx int, tid int, dt datetime, rRank int, price dec(9,2))
DECLARE @db_dt datetime
DECLARE @tick_id int
DECLARE @str_ticker varchar(50)

-- TODO: Set parameter values here.
set @db_dt = '1-1-2011'
set @tick_id = null
set @str_ticker = 'TLT'
insert @Xtbl
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_Daily] 
  @db_dt
  ,@tick_id
  ,@str_ticker

set @str_ticker = 'SPY'
insert @Xtbl
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_Daily] 
  @db_dt
  ,@tick_id
  ,@str_ticker

select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [SPY], [TLT], 'TIA2003' as DataSet
from (
select T.db_strTicker, FN.dt as dt, FN.rRank 
from @Xtbl FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY',	'TLT')
and FN.dt > '12-31-2002'
) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt
--- TIA2003 Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([SPY],2) as SPY,round([TLT],2) as TLT, 'TIA2003' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from @Xtbl FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY','TLT')
and FN.dt > '12-31-2002'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt

*/

declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int, price dec(9,2))

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int

-- Five Num Related Vars
DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
if @tick_id <=0 and @str_ticker is null
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and T.db_ticker_id = P.db_ticker_id 
	and T.db_inactive_dt is null
	and T.db_type=2

else		
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and (T.db_ticker_id = @tick_id or T.db_strTicker = @str_ticker)
	and T.db_ticker_id = P.db_ticker_id 
BEGIN TRY

Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk, @str_ticker
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin

	--if @wk > @prev_wk or @prev_wk - @wk > 51
	begin
		EXEC	[dbo].[csp_Calc_Five_Num]
							1,
							@i_dt = @dt,
							@tick = @str_ticker,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank


/*
					delete tbl_FiveNum_Daily
					where db_ticker_id = @ticker_id and db_dt = @dt
					
					insert tbl_FiveNum_Daily
					select @ticker_id,  @dt, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max
							,FiveNum_Rank = 
							      case 
									when (@o_price >= @o_max) then 4
									when (@o_price >= @o_hu) then 3
									when (@o_price >= @o_median) then 2
									when (@o_price >= @o_hl) then 1
									when (@o_price >= @o_min) then 0
									else 0
							      end		

*/
		insert @tbl
		select @ticker_id, @dt, @o_rank, 0
		update @tbl set price = CLS
		from (select db_close CLS from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @dt) A
		where tickID= @ticker_id and dt = @dt

	end
	--set @prev_wk = @wk
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk, @str_ticker

end
close cDSSSW
Deallocate cDSSSW
select * from @tbl
end try

BEGIN CATCH
close cDSSSW
Deallocate cDSSSW

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_For_Strategy_Tickers]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_For_Strategy_Tickers]
(
	@nYears int=5, -- set 5=Monthly, 1=Weekly
	@dt smalldatetime = null
)
as
--EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_For_Strategy_Tickers] 5, '8-12-2013'

begin
set nocount on;

declare @tbl table (id int identity, ticker varchar(10), freq_rank int null, 
					tick varchar(10), price dec(9,2),
					iMin dec(9,2),iHL dec(9,2),iMedian dec(9,2),iHU dec(9,2), iMax dec(9,2), Typ smallint )
insert @tbl select
'VTI', 0, null, 0,0,0,0,0,0,2 insert @tbl select
'VEU',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VNQ',0, null, 0,0,0,0,0,0,2 insert @tbl select
'TIP',0, null, 0,0,0,0,0,0,2 insert @tbl select
'TLT',0, null, 0,0,0,0,0,0,2 insert @tbl select
'IVV',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VO',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VB',0, null, 0,0,0,0,0,0,2 insert @tbl select
'ACWX',0, null, 0,0,0,0,0,0,2 insert @tbl select
'IYR',0, null, 0,0,0,0,0,0,2 insert @tbl select
'AGG',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VCR',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VDC',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VDE',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VFH',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VHT',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VIS',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VAW',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VGT',0, null, 0,0,0,0,0,0,2 insert @tbl select
'VPU',0, null, 0,0,0,0,0,0,2 insert @tbl select
'IWV',0, null, 0,0,0,0,0,0,2 insert @tbl select
'IJH',0, null, 0,0,0,0,0,0,2 insert @tbl select
'IJR',0, null, 0,0,0,0,0,0,2 insert @tbl select
'EEM',0, null, 0,0,0,0,0,0,2 insert @tbl select
'LQD',0, null, 0,0,0,0,0,0,2 insert @tbl select
'BLV',0, null, 0,0,0,0,0,0,2 insert @tbl select
'EMB',0, null, 0,0,0,0,0,0,2 insert @tbl select
'HYG',0, null, 0,0,0,0,0,0,2 insert @tbl select
'ONEQ',0, null, 0,0,0,0,0,0,2

/*
insert @tbl
select db_strTicker, 0, null, 0,0,0,0,0,0,1
from tbl_Ticker 
where db_type=1
and db_inactive_dt is null
*/
declare @cnt int
select @cnt = COUNT(*) from @tbl
declare @id int
set @id=1
declare @tick varchar(10)
declare @o_rank int
declare @price dec(9,2)

DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price decimal(9, 2)
		
while @id <= @cnt
  begin
	select @tick = ticker from @tbl where id=@id
	--exec @freq_rank = csp_Calc_Freq_Rank @dt, null, @tick, @ret_price = @price OUTPUT
	--exec @freq_rank = csp_Calc_Freq_Daily_For_Month @dt, null, @tick, @ret_price = @price OUTPUT
	EXEC	[dbo].[csp_Calc_Five_Num] 
		@nYears,
		@i_dt = @dt,
		@tick = @tick,
		@o_min = @o_min OUTPUT,
		@o_hl = @o_hl OUTPUT,
		@o_median = @o_median OUTPUT,
		@o_hu = @o_hu OUTPUT,
		@o_max = @o_max OUTPUT,
		@o_price = @o_price OUTPUT,
		@o_rank = @o_rank OUTPUT
		
	update @tbl
	set freq_rank = @o_rank
	where id = @id
	
	update @tbl
	set tick = @tick
		,price = @o_price 
		,iMin = @o_min 
		,iHL = @o_hl 
		,iMedian = @o_median 
		,iHU = @o_hu 
		,iMax = @o_max 
	where id = @id
	
	
	set @id = @id+1
  end
  
  select * from @tbl
  
 end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Monthly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_Monthly]
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null
)
as
begin
set nocount on;
/*
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_Monthly] 
   @sdt='1-1-2003'
  ,@tick='tlt'

*/
	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '1-1-2006' else set @start_dt = @sdt

DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
	declare @tid int
	declare @strTicker varchar(50)

	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where (db_type=2 or db_strTicker = 'SPY' or db_strTicker = 'TLT')
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
			print @e_yr
			print @strTicker

			declare @iMonth int
			if @sdt is null
				set @iMonth = 1
			else
				set @iMonth = Month(@sdt)
				
			declare @dt varchar(12)
			declare @freq_rank int
			declare @price dec(9,2)
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					--set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					select @dt = MIN(db_dt) from tbl_Prices where YEAR(db_dt)=@s_yr and MONTH(db_dt)=@iMonth and db_ticker_id = 538
					print @dt

					EXEC	[dbo].[csp_Calc_Five_Num]
							5,
							@i_dt = @dt,
							@tick = @strTicker,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT
						
		
					delete tbl_FiveNum
					where db_ticker_id = @tid and db_dt = @dt
					
					insert tbl_FiveNum
					select @tid,  @dt, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank
							--,FiveNum_Rank = 
							--      case 
							--		when (@o_price >= @o_max) then 4
							--		when (@o_price >= @o_hu) then 3
							--		when (@o_price >= @o_median) then 2
							--		when (@o_price >= @o_hl) then 1
							--		when (@o_price >= @o_min) then 0
							--		else 0
							--      end		
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

/*
alter procedure csp_Calc_Freq_Rank_For_ALL_ETF
(
	@dt smalldatetime = null,
	@tick varchar(10) = null
)		
as
begin

	if @dt is null set @dt = GETDATE()
	declare @strTicker varchar(50)
	declare @tid int

	if @tick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_type=2
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @tick
		order by db_ticker_id
	declare @tbl TABLE (id int identity(1,1), Ticker varchar(10), dt smalldatetime, freq_rank int, price dec(9,2) )

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @freq_rank int
			declare @price dec(9,2)
			exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT

			insert @tbl
			select @strTicker, @dt, @freq_rank, @price
			
			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS

	select * from @tbl order by Ticker
		  
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
*/

/*
alter procedure csp_Calc_Freq_Rank
(
	@dt datetime=null,
	@ticker_id int=null,
	@str_ticker varchar(10)=null,
	@ret_price dec(9,2) output
)
as
begin

set nocount on;
--input date & ticker ID to this procedure
declare @today datetime
if @dt is null
	set @today = GETDATE()
else
	set @today = @dt
	
declare @aid int
if @ticker_id is null
	if @str_ticker is not null
		select @aid = db_ticker_id from tbl_Ticker where db_strTicker = @str_ticker
	else
		return 0
else
	set @aid = @ticker_id


declare @spid int
declare @spidx dec(9,2)
declare @price dec(9,2)
set @spid = 538

declare @start datetime
set @start = dateadd(yy, -5, @today)
print @start


declare @tbl TABLE (id int Identity(1,1), db_dt datetime, mplr dec(9,2), price dec(9,2), sp_idx dec(9,2), mplr_minus_sd dec(9,2) null, mplr_mean dec(9,2) null, mplr_plus_sd dec(9,2) null, price_minus_sd dec(9,2) null, price_mean dec(9,2) null, price_plus_sd dec(9,2) null  )

insert @tbl
select A.db_dt, convert(dec(9,2), A.db_close/B.db_close*100), A.db_close, B.db_close,0,0,0,0,0,0
from tbl_Prices A, tbl_Prices B
where A.db_dt = B.db_dt
and B.db_ticker_id = @spid
and A.db_ticker_id = @aid
and A.db_dt >= @start
and A.db_dt <= @today

declare @min_mplr dec(9,2)
declare @max_mplr dec(9,2)
declare @sd_mplr dec(9,2)
declare @avg_mplr dec(9,2)

select @avg_mplr=avg(mplr), @min_mplr=MIN(mplr), @max_mplr=Max(mplr), @sd_mplr=stdev(mplr) from @tbl

declare @t_mplr dec(9,2)
declare @t_mplr_mean dec(9,2)
declare @t_mplr_stdev dec(9,2)

declare @t_price dec(9,2)
declare @t_price_mean dec(9,2)
declare @t_price_stdev dec(9,2)

declare @id_start int
set @id_start = 1

declare @idx int
set @idx=27
while exists (select * from @tbl where id = @idx)
  begin
	select @t_mplr = mplr, @t_mplr = price from @tbl where id = @idx
	
	select @t_mplr_mean = AVG(mplr), @t_mplr_stdev = stdev(mplr),
	@t_price_mean = AVG(price), @t_price_stdev = stdev(price)
	from @tbl where id between @id_start and @idx
	
	update @tbl 
	set mplr_mean=@t_mplr_mean, 
		mplr_minus_sd=@t_mplr_mean-@t_mplr_stdev, 
		mplr_plus_sd=@t_mplr_mean+@t_mplr_stdev,
		price_mean=@t_price_mean, 
		price_minus_sd=@t_price_mean-@t_price_stdev, 
		price_plus_sd=@t_price_mean+@t_price_stdev 		 
	where id = @idx
	
	set @idx=@idx+1
	set @id_start = @id_start+1
  end
  
-- update first 26 rows.
update @tbl
set mplr_mean = A.mplr_mean,
mplr_minus_sd = A.mplr_minus_sd,
mplr_plus_sd  = A.mplr_plus_sd,
price_mean    = A.price_mean,
price_minus_sd  = A.price_minus_sd,
price_plus_sd = A.price_plus_sd
from (select mplr_mean, mplr_minus_sd, mplr_plus_sd, price_mean, price_minus_sd, price_plus_sd from @tbl where id = 27) as A
where id <= 26

 select @spidx=sp_idx, @price=price  from @tbl where id = @idx-1  
 --select * from @tbl
 --select @avg_mplr as avg_mplr, @min_mplr as min_mplr, @max_mplr as max_mplr, @sd_mplr as sd_mplr, @spidx as SPINDEX, @price as PRICE
  
 -- ***************** Begin freq table { **************** 
 declare @tbl_freq table (id int identity(1,1), freq int null, mult dec(9,2) null, price dec(9,2) null)
 -- prime the table
 insert @tbl_freq
 select 0, 0, 0
 from @tbl
 where id <= 26
 
 update @tbl_freq
 set mult = @min_mplr
 where id=1
 
 update @tbl_freq
 set mult = @max_mplr
 where id=26

 update @tbl_freq
 set mult = (@min_mplr+@max_mplr)/2
 where id=14
 
 declare @t_mult dec(9,2)
 set @t_mult = @min_mplr
 set @idx=2
 while @idx<= 13
   begin
	set @t_mult = @t_mult  + (@avg_mplr - @min_mplr)/13
    update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 update @tbl_freq 
 set mult = @avg_mplr where id=@idx
 set @idx=15
 set @t_mult = @avg_mplr
 while @idx < 26
   begin
	set @t_mult = @t_mult  + (@max_mplr - @avg_mplr)/13
	update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 
 --set price
 update @tbl_freq
 set price = mult *  @spidx / 100
 
 --update freq
 declare @cnt int
 select @cnt = COUNT(*) from @tbl where mplr <= @min_mplr 
 update @tbl_freq 
 set freq = @cnt
 where id=1
 
 declare @curr_mult dec(9,2)
 declare @prev_mult dec(9,2)
 set @idx=2
 while @idx <= 26
   begin
	select @curr_mult = mult from @tbl_freq where id = @idx
	select @prev_mult = mult from @tbl_freq where id = @idx-1
	
	update @tbl_freq 
	set freq = A.CNT_ITEMS
	from ( select COUNT(*) as CNT_ITEMS from @tbl where mplr  between @prev_mult and @curr_mult) as A
	where id = @idx
	
	set @idx=@idx+1
   end
-- select * from @tbl_freq
-- ***************** end freq table } **************** 

declare @ac_38 dec(9,2), @ac_39 dec(9,2), @ac_40 dec(9,2)
declare @ad_39 dec(9,2)

select @ad_39 = MAX(price_mean) from @tbl where id > 26
set @ac_38 = @spidx * @avg_mplr / 100

select @ac_39 = AVG(price) 
from @tbl_freq 
where price > 0 and freq > 11

select @ac_40 = price
from @tbl_freq 
where freq = (select MAX(freq) from @tbl_freq)

declare @af_35 dec(9,2)
declare @ah_35 dec(9,2)

declare @af_36 dec(9,2)
declare @ah_36 dec(9,2)

declare @af_37 dec(9,2)
declare @ah_37 dec(9,2)


if (@ac_38+@ac_39+@ac_40)/3 < @ad_39 
	set @af_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @af_35 = @ad_39

if (@ac_38+@ac_39+@ac_40)/3 > @ad_39 
	set @ah_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @ah_35 = @ad_39

set @af_36 = @spidx * (@avg_mplr-@sd_mplr) / 100
set @ah_36 = @spidx * (@avg_mplr+@sd_mplr) / 100

set @af_37 = @spidx * @min_mplr  / 100
set @ah_37 = @spidx * @max_mplr  / 100

/*
select @ac_38 as AC38, @ac_39 as AC39, @ac_40 as AC40, @ad_39 as AD39
select @af_35  as AF35, @ah_35 as AH35
select @af_36 as AF36, @ah_36 as AH36 
select @af_37 as AF37, @ah_37 as AH37 
*/
-- final table
declare @af_38 dec(9,2)
declare @ah_38 dec(9,2)

declare @af_39 dec(9,2)
declare @ah_39 dec(9,2)

declare @ag_39 dec(9,2)

declare @af_40 dec(9,2)
declare @ah_40 dec(9,2)

set @af_38 = (@af_35 + @af_36 + @af_37 ) /3
set @ah_38 = (@ah_35 + @ah_36 + @ah_37 ) /3

set @af_40 = (@ah_38 - @af_38)/4 + @af_38


set @af_39 = (@af_38 + @af_40) /2
set @ag_39 = (@af_38 + @ah_38) / 2

set @ah_40 = 3*((@ah_38 - @af_38)/4) + @af_38
set @ah_39 = (@ah_38 + @ah_40) /2

/*
select @af_38 as AF38, 0 as XX38, @ah_38 as AH38
select @af_39 as AF38, @ag_39 as AG39, @ah_39 as AH39
select @af_40 as AF40, 0 as XX40, @ah_40 as AH40
*/
declare @freq_rank int

select @freq_rank= case
	when @price > @ah_38 then 7
	when @price > @ah_39 then 6
	when @price > @ah_40 then 5
	when @price > @ag_39 then 4
	when @price > @af_40 then 3
	when @price > @af_39 then 2
	when @price > @af_38 then 1
	else 0
	end

set @ret_price = @price
return @freq_rank


end
*/
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Trend_Monthly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_Trend_Monthly]
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null
)
as
begin
set nocount on;
/*
EXECUTE [csp_Calc_FiveNum_Trend_Monthly] 
   @sdt='12-31-2006'
  ,@tick='IP'

*/
	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick  else set @strTick = 'VTI'
	if @sdt is null set @start_dt = '1-1-2003' else set @start_dt = @sdt

declare @today datetime
select @today = max(db_dt)
from tbl_Prices
where db_ticker_id = 538

declare @tbl_FN TABLE (
	[id] int identity(1,1),
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
	[db_diff] [real] NULL,
	[db_correl] dec(9,3) NULL,
	[LT] dec(9,2) NULL
	
)
	
DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
	declare @tid int
	declare @strTicker varchar(50)

	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where ( db_type=2 or db_ticker_id = 471 or db_ticker_id = 442)
		and db_inactive_dt is null
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @strTick
		order by db_ticker_id

--	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @s_yr int
			set @s_yr = YEAR(@start_dt)

			declare @e_yr int
			set @e_yr = year(GETDATE())
			print @e_yr
			print @strTicker

			declare @iMonth int
			if @sdt is null
				set @iMonth = 1
			else
				set @iMonth = Month(@sdt)
				
			declare @dt varchar(12)
			declare @freq_rank int
			declare @price dec(9,2)
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					--set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					select @dt = MIN(db_dt) from tbl_Prices where YEAR(db_dt)=@s_yr and MONTH(db_dt)=@iMonth and db_ticker_id = 538
--					print @dt

					if @dt <= @today
					begin
						EXEC	[dbo].[csp_Calc_Five_Num_Trend]
								5,
								@i_dt = @dt,
								@tick = @strTicker,
								@o_min = @o_min OUTPUT,
								@o_hl = @o_hl OUTPUT,
								@o_median = @o_median OUTPUT,
								@o_hu = @o_hu OUTPUT,
								@o_max = @o_max OUTPUT,
								@o_price = @o_price OUTPUT,
								@o_rank = @o_rank OUTPUT
						
		
						insert @tbl_FN
						select @tid,  @dt, @o_price,
								@o_min,
								@o_hl,
								@o_median,
								@o_hu,
								@o_max,
								@o_rank,
								@o_hu-@o_median-@o_median+@o_hl,
								0,0
								--,FiveNum_Rank = 
								--      case 
								--		when (@o_price >= @o_max) then 4
								--		when (@o_price >= @o_hu) then 3
								--		when (@o_price >= @o_median) then 2
								--		when (@o_price >= @o_hl) then 1
								--		when (@o_price >= @o_min) then 0
								--		else 0
								--      end
			
				end
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

--insert latest date
print @today
					EXEC	[dbo].[csp_Calc_Five_Num_Trend]
							5,
							@i_dt = @today,
							@tick = @strTick,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT
						
		
					insert @tbl_FN
					select @tid,  @today, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank,
							@o_hu-@o_median-@o_median+@o_hl,
							0,0
		
-- Calc Pearson Correlation
declare @idx int
select @idx = COUNT(*) from @tbl_FN 
declare @tbl dbo.TBL_CORRELATION
declare @tbl_Ret table (cr dec(9,3))
while @idx > 19
	begin
		delete from @tbl_Ret 
		delete from @tbl

		insert @tbl
		select db_close, db_diff
		from @tbl_FN 
		where id between @idx-19 and @idx

		insert @tbl_Ret
		exec csp_Calc_Pearson_Correlation @tbl
		
		update @tbl_FN		
		set db_correl = (select cr from @tbl_Ret)
		where id = @idx
		
		set @idx = @idx-1
	end

-- update vix
--update @tbl_FN
--set vix = aVIX
--from ( select dt as DT, vix as aVIX from tbl_Return_Rank where tid = @tid ) as A
--where db_ticker_id = @tid
--and db_dt = A.DT

update @tbl_FN
set LT = aLT
from (select db_dt as DT, 	
		case when db_avg > db_index then 1 
		else 0 
			end
		as 'aLT' from tbl_Prices
		where db_ticker_id = @tid) as A
where db_ticker_id = @tid
and db_dt = A.DT


select * from @tbl_FN
--	END TRY
/*
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
*/
end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Trend_Monthly_CNX]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[csp_Calc_FiveNum_Trend_Monthly_CNX]
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null
)
as
begin
set nocount on;
/*
EXECUTE [csp_Calc_FiveNum_Trend_Monthly_CNX] 
   @sdt='12-31-2006'
  ,@tick=NULL

*/
	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick  else set @strTick = 'CNX500'
	if @sdt is null set @start_dt = '1-1-2003' else set @start_dt = @sdt

declare @today datetime
select @today = max(db_dt)
from tbl_Prices
where db_ticker_id = 538

declare @tbl_FN TABLE (
	[id] int identity(1,1),
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
	[db_diff] [real] NULL,
	[db_correl] dec(9,3) NULL,
	[LT] dec(9,2) NULL
	
)
	
DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
	declare @tid int
	declare @strTicker varchar(50)

	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where ( db_type=2 or db_ticker_id = 471 or db_ticker_id = 442)
		and db_inactive_dt is null
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @strTick
		order by db_ticker_id

--	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @s_yr int
			set @s_yr = YEAR(@start_dt)

			declare @e_yr int
			set @e_yr = year(GETDATE())
			print @e_yr
			print @strTicker

			declare @iMonth int
			if @sdt is null
				set @iMonth = 1
			else
				set @iMonth = Month(@sdt)
				
			declare @dt varchar(12)
			declare @freq_rank int
			declare @price dec(9,2)
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					--set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					select @dt = MIN(db_dt) from tbl_Prices where YEAR(db_dt)=@s_yr and MONTH(db_dt)=@iMonth and db_ticker_id = 6469
--					print @dt

					if @dt <= @today
					begin
						EXEC	[dbo].[csp_Calc_Five_Num_Trend]
								5,
								@i_dt = @dt,
								@tick = @strTicker,
								@o_min = @o_min OUTPUT,
								@o_hl = @o_hl OUTPUT,
								@o_median = @o_median OUTPUT,
								@o_hu = @o_hu OUTPUT,
								@o_max = @o_max OUTPUT,
								@o_price = @o_price OUTPUT,
								@o_rank = @o_rank OUTPUT
						
		
						insert @tbl_FN
						select @tid,  @dt, @o_price,
								@o_min,
								@o_hl,
								@o_median,
								@o_hu,
								@o_max,
								@o_rank,
								@o_hu-@o_median-@o_median+@o_hl,
								0,0
								--,FiveNum_Rank = 
								--      case 
								--		when (@o_price >= @o_max) then 4
								--		when (@o_price >= @o_hu) then 3
								--		when (@o_price >= @o_median) then 2
								--		when (@o_price >= @o_hl) then 1
								--		when (@o_price >= @o_min) then 0
								--		else 0
								--      end
			
				end
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

--insert latest date
print @today
					EXEC	[dbo].[csp_Calc_Five_Num_Trend]
							5,
							@i_dt = @today,
							@tick = @strTick,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT
						
		
					insert @tbl_FN
					select @tid,  @today, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank,
							@o_hu-@o_median-@o_median+@o_hl,
							0,0
		
-- Calc Pearson Correlation
declare @idx int
select @idx = COUNT(*) from @tbl_FN 
declare @tbl dbo.TBL_CORRELATION
declare @tbl_Ret table (cr dec(9,3))
while @idx > 19
	begin
		delete from @tbl_Ret 
		delete from @tbl

		insert @tbl
		select db_close, db_diff
		from @tbl_FN 
		where id between @idx-19 and @idx

		insert @tbl_Ret
		exec csp_Calc_Pearson_Correlation @tbl
		
		update @tbl_FN		
		set db_correl = (select cr from @tbl_Ret)
		where id = @idx
		
		set @idx = @idx-1
	end

-- update vix
--update @tbl_FN
--set vix = aVIX
--from ( select dt as DT, vix as aVIX from tbl_Return_Rank where tid = @tid ) as A
--where db_ticker_id = @tid
--and db_dt = A.DT

update @tbl_FN
set LT = aLT
from (select db_dt as DT, 	
		case when db_avg > db_index then 1 
		else 0 
			end
		as 'aLT' from tbl_Prices
		where db_ticker_id = @tid) as A
where db_ticker_id = @tid
and db_dt = A.DT


select * from @tbl_FN
--	END TRY
/*
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
*/
end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Trend_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_Trend_Weekly]
(
	@db_dt datetime,
	@tick_id int,
	@str_ticker varchar(50)=null)
as
begin
/*
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_Trend_Weekly] 
   @db_dt='1-1-2006'
  ,@tick_id = -1
  ,@str_ticker='IVV'
GO

*/

declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int, price dec(9,2))

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int


declare @tbl_FN TABLE (
	[id] int identity(1,1),
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
	[db_diff] [real] NULL,
	[db_correl] dec(9,3) NULL
	
)

-- Five Num Related Vars
DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
if @tick_id <=0 and @str_ticker is null
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and T.db_ticker_id = P.db_ticker_id 
	and T.db_inactive_dt is null
	and (T.db_type=2 or T.db_strTicker = 'SPY' or T.db_strTicker = 'TLT')

else		
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and (T.db_ticker_id = @tick_id or T.db_strTicker = @str_ticker)
	and T.db_ticker_id = P.db_ticker_id 
BEGIN TRY

Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk, @str_ticker
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin
	if @wk > @prev_wk or @prev_wk - @wk > 51
	begin

		EXEC	[dbo].[csp_Calc_Five_Num_Trend]
							5,
							@i_dt = @dt,
							@tick = @str_ticker,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT

					insert @tbl_FN
					select @ticker_id,  @dt, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank,
							@o_hu-@o_median-@o_median+@o_hl,
							0

/*
		update @tbl set price = CLS
		from (select db_close CLS from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @dt) A
		where tickID= @ticker_id and dt = @dt
*/
	end
	set @prev_wk = @wk
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk, @str_ticker

end
close cDSSSW
Deallocate cDSSSW
--insert latest date
declare @today datetime
select @today = max(db_dt)
from IDToDSN_DKC.dbo.tbl_Prices
where db_ticker_id = @ticker_id 
print @today
					EXEC	[dbo].[csp_Calc_Five_Num_Trend]
							5,
							@i_dt = @today,
							@tick = @str_ticker,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT
						
		
					insert @tbl_FN
					select @ticker_id,  @today, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank,
							@o_hu-@o_median-@o_median+@o_hl,
							0

-- Calc Pearson Correlation
declare @idx int
select @idx = COUNT(*) from @tbl_FN 
declare @tbl_C dbo.TBL_CORRELATION
declare @tbl_Ret table (cr dec(9,3))
while @idx > 19
	begin
		delete from @tbl_Ret 
		delete from @tbl

		insert @tbl_C
		select db_close, db_diff
		from @tbl_FN 
		where id between @idx-19 and @idx

		insert @tbl_Ret
		exec csp_Calc_Pearson_Correlation @tbl_C
		
		update @tbl_FN		
		set db_correl = (select cr from @tbl_Ret)
		where id = @idx
		
		set @idx = @idx-1
	end
select * from @tbl_FN order by db_dt

end try

BEGIN CATCH
close cDSSSW
Deallocate cDSSSW

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_FiveNum_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_FiveNum_Weekly]
(
	@db_dt datetime,
	@tick_id int,
	@str_ticker varchar(50)=null)
as
begin
/*
DECLARE @RC int
DECLARE @db_dt datetime
DECLARE @tick_id int
DECLARE @str_ticker varchar(50)

-- TODO: Set parameter values here.
set @db_dt = '5-1-2013'
set @tick_id = 0
set @str_ticker = null
EXECUTE @RC = [IDToDSN_DKC].[dbo].[csp_Calc_FiveNum_Weekly] 
  @db_dt
  ,@tick_id
  ,@str_ticker
GO

*/

declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int, price dec(9,2))

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int

-- Five Num Related Vars
DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2),
		@o_rank int
		
if @tick_id <=0 and @str_ticker is null
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and T.db_ticker_id = P.db_ticker_id 
	and T.db_inactive_dt is null
	and (T.db_type=2 or T.db_strTicker = 'SPY' or T.db_strTicker = 'TLT')

else		
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and (T.db_ticker_id = @tick_id or T.db_strTicker = @str_ticker)
	and T.db_ticker_id = P.db_ticker_id 
BEGIN TRY

Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk, @str_ticker
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin
	if @wk > @prev_wk or @prev_wk - @wk > 51
	begin

		EXEC	[dbo].[csp_Calc_Five_Num]
							1,
							@i_dt = @dt,
							@tick = @str_ticker,
							@o_min = @o_min OUTPUT,
							@o_hl = @o_hl OUTPUT,
							@o_median = @o_median OUTPUT,
							@o_hu = @o_hu OUTPUT,
							@o_max = @o_max OUTPUT,
							@o_price = @o_price OUTPUT,
							@o_rank = @o_rank OUTPUT


					delete tbl_FiveNum_Weekly
					where db_ticker_id = @ticker_id and db_dt = @dt
					
					insert tbl_FiveNum_Weekly
					select @ticker_id,  @dt, @o_price,
							@o_min,
							@o_hl,
							@o_median,
							@o_hu,
							@o_max,
							@o_rank
							--,FiveNum_Rank = 
							--      case 
							--		when (@o_price >= @o_max) then 4
							--		when (@o_price >= @o_hu) then 3
							--		when (@o_price >= @o_median) then 2
							--		when (@o_price >= @o_hl) then 1
							--		when (@o_price >= @o_min) then 0
							--		else 0
							--      end			

/*
		insert @tbl
		select @ticker_id, @dt, ( select 	FiveNum_Rank = 
							      case 
									when (@o_price >= @o_max) then 4
									when (@o_price >= @o_hu) then 3
									when (@o_price >= @o_median) then 2
									when (@o_price >= @o_hl) then 1
									when (@o_price >= @o_min) then 0
									else 0
							      end
							      ), 0
		update @tbl set price = CLS
		from (select db_close CLS from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @dt) A
		where tickID= @ticker_id and dt = @dt
*/
	end
	set @prev_wk = @wk
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk, @str_ticker

end
close cDSSSW
Deallocate cDSSSW
end try

BEGIN CATCH
close cDSSSW
Deallocate cDSSSW

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_Daily_For_Month]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_Daily_For_Month]
(
	@start_date datetime = null,
	@tick_id int,
	@str_ticker varchar(10)  = null,
	@ret_price dec(9,2) output
)
as
begin
/*
declare @r_price dec(9,2)
declare @RC int
DECLARE @tick_id int
-- TODO: Set parameter values here.
set @tick_id = 820
EXECUTE @RC = [IDToDSN_DKC].[dbo].[csp_Calc_Freq_Daily_For_Month] 
   '9-4-2007', @tick_id, null, @r_price output
select @RC, @r_price
GO


*/
declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int)

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int

declare @sdt datetime
declare @edt datetime
if @start_date is null
	set @edt = GETDATE()
else
	set @edt = @start_date
	
set @sdt = DATEADD(d,-10,@edt)
print @sdt
if @str_ticker is null
	declare cDSSS scroll cursor for
	select T.db_ticker_id, db_dt
	from tbl_Ticker T, tbl_Prices P
	where db_dt between @sdt and @edt
	and T.db_ticker_id = @tick_id
	and T.db_ticker_id = P.db_ticker_id 
else
	declare cDSSS scroll cursor for
	select T.db_ticker_id, db_dt
	from tbl_Ticker T, tbl_Prices P
	where db_dt between @sdt and @edt
	and T.db_strTicker = @str_ticker
	and T.db_ticker_id = P.db_ticker_id 

BEGIN TRY
Open cDSSS

Fetch last from cDSSS
into @ticker_id, @dt

Fetch relative -4 from cDSSS
into @ticker_id, @dt

while @@FETCH_STATUS = 0
begin

	begin
		EXECUTE @RC = [csp_Calc_Freq_Rank] 
		   @dt
		  ,@ticker_id
		  ,@str_ticker
		  ,@ret_price OUTPUT

		insert @tbl
		select @ticker_id, @dt, @RC
	end
	Fetch next from cDSSS
	into @ticker_id, @dt

end
close cDSSS
Deallocate cDSSS
--select * from @tbl
declare @ret dec(9,3)
select @ret = AVG(db_rank) from @tbl
return @ret
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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_For_Strategy_Tickers]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_For_Strategy_Tickers]
(
	@dt smalldatetime = null
)
as
--EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Freq_For_Strategy_Tickers]

begin
declare @tbl table (id int identity, ticker varchar(10), freq_rank int null)
insert @tbl select
'VTI', 0 insert @tbl select
'VEU', 0 insert @tbl select
'VNQ', 0 insert @tbl select
'TIP', 0 insert @tbl select
'TLT', 0 insert @tbl select
'IVV', 0 insert @tbl select
'VO', 0 insert @tbl select
'VB', 0 insert @tbl select
'ACWX', 0 insert @tbl select
'IYR', 0 insert @tbl select
'AGG', 0 insert @tbl select
'VCR', 0 insert @tbl select
'VDC', 0 insert @tbl select
'VDE', 0 insert @tbl select
'VFH', 0 insert @tbl select
'VHT', 0 insert @tbl select
'VIS', 0 insert @tbl select
'VAW', 0 insert @tbl select
'VGT', 0 insert @tbl select
'VPU', 0 insert @tbl select
'IWV', 0 insert @tbl select
'IJH', 0 insert @tbl select
'IJR', 0 insert @tbl select
'EEM', 0 insert @tbl select
'LQD', 0 insert @tbl select
'BLV', 0 insert @tbl select
'EMB', 0 insert @tbl select
'HYG', 0 insert @tbl select
'ONEQ', 0

declare @cnt int
select @cnt = COUNT(*) from @tbl
declare @id int
set @id=1
declare @tick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

while @id <= @cnt
  begin
	select @tick = ticker from @tbl where id=@id
	--exec @freq_rank = csp_Calc_Freq_Rank @dt, null, @tick, @ret_price = @price OUTPUT
	exec @freq_rank = csp_Calc_Freq_Daily_For_Month @dt, null, @tick, @ret_price = @price OUTPUT

	update @tbl
	set freq_rank = @freq_rank
	where id = @id
	
	set @id = @id+1
  end
  
  select * from @tbl
  
 end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_Monthly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_Monthly]
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null
)
as
begin
/*
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Freq_Monthly] 
   @sdt='12-31-2010'
  ,@tick='qcom'

*/
	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '1-1-2007' else set @start_dt = @sdt

	declare @tid int
	declare @strTicker varchar(50)

	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where (db_type=2 or db_strTicker = 'SPY' or db_strTicker = 'TLT')
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
			print @e_yr
			print @strTicker

			declare @iMonth int
			if @sdt is null
				set @iMonth = 1
			else
				set @iMonth = Month(@sdt)
				
			declare @dt varchar(12)
			declare @freq_rank int
			declare @price dec(9,2)
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					--set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					select @dt = MIN(db_dt) from tbl_Prices where YEAR(db_dt)=@s_yr and MONTH(db_dt)=@iMonth and db_ticker_id = 538
					print @dt
					--exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT
					exec @freq_rank = csp_Calc_Freq_Daily_For_Month @dt, @tid, null, @ret_price = @price OUTPUT
					if @price is null set @price = 0
					delete tbl_Freq_Rank
					where db_ticker_id = @tid and db_dt = @dt
					
					insert tbl_Freq_Rank
					select @tid,  @dt, @freq_rank, @price

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

/*
alter procedure csp_Calc_Freq_Rank_For_ALL_ETF
(
	@dt smalldatetime = null,
	@tick varchar(10) = null
)		
as
begin

	if @dt is null set @dt = GETDATE()
	declare @strTicker varchar(50)
	declare @tid int

	if @tick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_type=2
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @tick
		order by db_ticker_id
	declare @tbl TABLE (id int identity(1,1), Ticker varchar(10), dt smalldatetime, freq_rank int, price dec(9,2) )

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @freq_rank int
			declare @price dec(9,2)
			exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT

			insert @tbl
			select @strTicker, @dt, @freq_rank, @price
			
			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS

	select * from @tbl order by Ticker
		  
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
*/

/*
alter procedure csp_Calc_Freq_Rank
(
	@dt datetime=null,
	@ticker_id int=null,
	@str_ticker varchar(10)=null,
	@ret_price dec(9,2) output
)
as
begin

set nocount on;
--input date & ticker ID to this procedure
declare @today datetime
if @dt is null
	set @today = GETDATE()
else
	set @today = @dt
	
declare @aid int
if @ticker_id is null
	if @str_ticker is not null
		select @aid = db_ticker_id from tbl_Ticker where db_strTicker = @str_ticker
	else
		return 0
else
	set @aid = @ticker_id


declare @spid int
declare @spidx dec(9,2)
declare @price dec(9,2)
set @spid = 538

declare @start datetime
set @start = dateadd(yy, -5, @today)
print @start


declare @tbl TABLE (id int Identity(1,1), db_dt datetime, mplr dec(9,2), price dec(9,2), sp_idx dec(9,2), mplr_minus_sd dec(9,2) null, mplr_mean dec(9,2) null, mplr_plus_sd dec(9,2) null, price_minus_sd dec(9,2) null, price_mean dec(9,2) null, price_plus_sd dec(9,2) null  )

insert @tbl
select A.db_dt, convert(dec(9,2), A.db_close/B.db_close*100), A.db_close, B.db_close,0,0,0,0,0,0
from tbl_Prices A, tbl_Prices B
where A.db_dt = B.db_dt
and B.db_ticker_id = @spid
and A.db_ticker_id = @aid
and A.db_dt >= @start
and A.db_dt <= @today

declare @min_mplr dec(9,2)
declare @max_mplr dec(9,2)
declare @sd_mplr dec(9,2)
declare @avg_mplr dec(9,2)

select @avg_mplr=avg(mplr), @min_mplr=MIN(mplr), @max_mplr=Max(mplr), @sd_mplr=stdev(mplr) from @tbl

declare @t_mplr dec(9,2)
declare @t_mplr_mean dec(9,2)
declare @t_mplr_stdev dec(9,2)

declare @t_price dec(9,2)
declare @t_price_mean dec(9,2)
declare @t_price_stdev dec(9,2)

declare @id_start int
set @id_start = 1

declare @idx int
set @idx=27
while exists (select * from @tbl where id = @idx)
  begin
	select @t_mplr = mplr, @t_mplr = price from @tbl where id = @idx
	
	select @t_mplr_mean = AVG(mplr), @t_mplr_stdev = stdev(mplr),
	@t_price_mean = AVG(price), @t_price_stdev = stdev(price)
	from @tbl where id between @id_start and @idx
	
	update @tbl 
	set mplr_mean=@t_mplr_mean, 
		mplr_minus_sd=@t_mplr_mean-@t_mplr_stdev, 
		mplr_plus_sd=@t_mplr_mean+@t_mplr_stdev,
		price_mean=@t_price_mean, 
		price_minus_sd=@t_price_mean-@t_price_stdev, 
		price_plus_sd=@t_price_mean+@t_price_stdev 		 
	where id = @idx
	
	set @idx=@idx+1
	set @id_start = @id_start+1
  end
  
-- update first 26 rows.
update @tbl
set mplr_mean = A.mplr_mean,
mplr_minus_sd = A.mplr_minus_sd,
mplr_plus_sd  = A.mplr_plus_sd,
price_mean    = A.price_mean,
price_minus_sd  = A.price_minus_sd,
price_plus_sd = A.price_plus_sd
from (select mplr_mean, mplr_minus_sd, mplr_plus_sd, price_mean, price_minus_sd, price_plus_sd from @tbl where id = 27) as A
where id <= 26

 select @spidx=sp_idx, @price=price  from @tbl where id = @idx-1  
 --select * from @tbl
 --select @avg_mplr as avg_mplr, @min_mplr as min_mplr, @max_mplr as max_mplr, @sd_mplr as sd_mplr, @spidx as SPINDEX, @price as PRICE
  
 -- ***************** Begin freq table { **************** 
 declare @tbl_freq table (id int identity(1,1), freq int null, mult dec(9,2) null, price dec(9,2) null)
 -- prime the table
 insert @tbl_freq
 select 0, 0, 0
 from @tbl
 where id <= 26
 
 update @tbl_freq
 set mult = @min_mplr
 where id=1
 
 update @tbl_freq
 set mult = @max_mplr
 where id=26

 update @tbl_freq
 set mult = (@min_mplr+@max_mplr)/2
 where id=14
 
 declare @t_mult dec(9,2)
 set @t_mult = @min_mplr
 set @idx=2
 while @idx<= 13
   begin
	set @t_mult = @t_mult  + (@avg_mplr - @min_mplr)/13
    update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 update @tbl_freq 
 set mult = @avg_mplr where id=@idx
 set @idx=15
 set @t_mult = @avg_mplr
 while @idx < 26
   begin
	set @t_mult = @t_mult  + (@max_mplr - @avg_mplr)/13
	update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 
 --set price
 update @tbl_freq
 set price = mult *  @spidx / 100
 
 --update freq
 declare @cnt int
 select @cnt = COUNT(*) from @tbl where mplr <= @min_mplr 
 update @tbl_freq 
 set freq = @cnt
 where id=1
 
 declare @curr_mult dec(9,2)
 declare @prev_mult dec(9,2)
 set @idx=2
 while @idx <= 26
   begin
	select @curr_mult = mult from @tbl_freq where id = @idx
	select @prev_mult = mult from @tbl_freq where id = @idx-1
	
	update @tbl_freq 
	set freq = A.CNT_ITEMS
	from ( select COUNT(*) as CNT_ITEMS from @tbl where mplr  between @prev_mult and @curr_mult) as A
	where id = @idx
	
	set @idx=@idx+1
   end
-- select * from @tbl_freq
-- ***************** end freq table } **************** 

declare @ac_38 dec(9,2), @ac_39 dec(9,2), @ac_40 dec(9,2)
declare @ad_39 dec(9,2)

select @ad_39 = MAX(price_mean) from @tbl where id > 26
set @ac_38 = @spidx * @avg_mplr / 100

select @ac_39 = AVG(price) 
from @tbl_freq 
where price > 0 and freq > 11

select @ac_40 = price
from @tbl_freq 
where freq = (select MAX(freq) from @tbl_freq)

declare @af_35 dec(9,2)
declare @ah_35 dec(9,2)

declare @af_36 dec(9,2)
declare @ah_36 dec(9,2)

declare @af_37 dec(9,2)
declare @ah_37 dec(9,2)


if (@ac_38+@ac_39+@ac_40)/3 < @ad_39 
	set @af_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @af_35 = @ad_39

if (@ac_38+@ac_39+@ac_40)/3 > @ad_39 
	set @ah_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @ah_35 = @ad_39

set @af_36 = @spidx * (@avg_mplr-@sd_mplr) / 100
set @ah_36 = @spidx * (@avg_mplr+@sd_mplr) / 100

set @af_37 = @spidx * @min_mplr  / 100
set @ah_37 = @spidx * @max_mplr  / 100

/*
select @ac_38 as AC38, @ac_39 as AC39, @ac_40 as AC40, @ad_39 as AD39
select @af_35  as AF35, @ah_35 as AH35
select @af_36 as AF36, @ah_36 as AH36 
select @af_37 as AF37, @ah_37 as AH37 
*/
-- final table
declare @af_38 dec(9,2)
declare @ah_38 dec(9,2)

declare @af_39 dec(9,2)
declare @ah_39 dec(9,2)

declare @ag_39 dec(9,2)

declare @af_40 dec(9,2)
declare @ah_40 dec(9,2)

set @af_38 = (@af_35 + @af_36 + @af_37 ) /3
set @ah_38 = (@ah_35 + @ah_36 + @ah_37 ) /3

set @af_40 = (@ah_38 - @af_38)/4 + @af_38


set @af_39 = (@af_38 + @af_40) /2
set @ag_39 = (@af_38 + @ah_38) / 2

set @ah_40 = 3*((@ah_38 - @af_38)/4) + @af_38
set @ah_39 = (@ah_38 + @ah_40) /2

/*
select @af_38 as AF38, 0 as XX38, @ah_38 as AH38
select @af_39 as AF38, @ag_39 as AG39, @ah_39 as AH39
select @af_40 as AF40, 0 as XX40, @ah_40 as AH40
*/
declare @freq_rank int

select @freq_rank= case
	when @price > @ah_38 then 7
	when @price > @ah_39 then 6
	when @price > @ah_40 then 5
	when @price > @ag_39 then 4
	when @price > @af_40 then 3
	when @price > @af_39 then 2
	when @price > @af_38 then 1
	else 0
	end

set @ret_price = @price
return @freq_rank


end
*/
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_Rank]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_Rank]
(
	@dt datetime=null,
	@ticker_id int=null,
	@str_ticker varchar(10)=null,
	@ret_price dec(9,2) output
)
as
begin

set nocount on;
--input date & ticker ID to this procedure
declare @today datetime
if @dt is null
	set @today = GETDATE()
else
	set @today = @dt
	
declare @aid int
if @ticker_id is null
	if @str_ticker is not null
		select @aid = db_ticker_id from tbl_Ticker where db_strTicker = @str_ticker
	else
		return 0
else
	set @aid = @ticker_id


declare @spid int
declare @spidx dec(9,2)
declare @price dec(9,2)
set @spid = 538

declare @start datetime
set @start = dateadd(yy, -5, @today)
print @start


declare @tbl TABLE (id int Identity(1,1), db_dt datetime, mplr dec(9,2), price dec(9,2), sp_idx dec(9,2), mplr_minus_sd dec(9,2) null, mplr_mean dec(9,2) null, mplr_plus_sd dec(9,2) null, price_minus_sd dec(9,2) null, price_mean dec(9,2) null, price_plus_sd dec(9,2) null  )

insert @tbl
select A.db_dt, convert(dec(9,2), A.db_close/B.db_close*100), A.db_close, B.db_close,0,0,0,0,0,0
from tbl_Prices A, tbl_Prices B
where A.db_dt = B.db_dt
and B.db_ticker_id = @spid
and A.db_ticker_id = @aid
and A.db_dt >= @start
and A.db_dt <= @today

declare @min_mplr dec(9,2)
declare @max_mplr dec(9,2)
declare @sd_mplr dec(9,2)
declare @avg_mplr dec(9,2)

select @avg_mplr=avg(mplr), @min_mplr=MIN(mplr), @max_mplr=Max(mplr), @sd_mplr=stdev(mplr) from @tbl

declare @t_mplr dec(9,2)
declare @t_mplr_mean dec(9,2)
declare @t_mplr_stdev dec(9,2)

declare @t_price dec(9,2)
declare @t_price_mean dec(9,2)
declare @t_price_stdev dec(9,2)

declare @id_start int
set @id_start = 1

declare @idx int
set @idx=27
while exists (select * from @tbl where id = @idx)
  begin
	select @t_mplr = mplr, @t_mplr = price from @tbl where id = @idx
	
	select @t_mplr_mean = AVG(mplr), @t_mplr_stdev = stdev(mplr),
	@t_price_mean = AVG(price), @t_price_stdev = stdev(price)
	from @tbl where id between @id_start and @idx
	
	update @tbl 
	set mplr_mean=@t_mplr_mean, 
		mplr_minus_sd=@t_mplr_mean-@t_mplr_stdev, 
		mplr_plus_sd=@t_mplr_mean+@t_mplr_stdev,
		price_mean=@t_price_mean, 
		price_minus_sd=@t_price_mean-@t_price_stdev, 
		price_plus_sd=@t_price_mean+@t_price_stdev 		 
	where id = @idx
	
	set @idx=@idx+1
	set @id_start = @id_start+1
  end
  
-- update first 26 rows.
update @tbl
set mplr_mean = A.mplr_mean,
mplr_minus_sd = A.mplr_minus_sd,
mplr_plus_sd  = A.mplr_plus_sd,
price_mean    = A.price_mean,
price_minus_sd  = A.price_minus_sd,
price_plus_sd = A.price_plus_sd
from (select mplr_mean, mplr_minus_sd, mplr_plus_sd, price_mean, price_minus_sd, price_plus_sd from @tbl where id = 27) as A
where id <= 26

 select @spidx=sp_idx, @price=price  from @tbl where id = @idx-1  
 -- select * from @tbl
 --select @avg_mplr as avg_mplr, @min_mplr as min_mplr, @max_mplr as max_mplr, @sd_mplr as sd_mplr, @spidx as SPINDEX, @price as PRICE
  
 -- ***************** Begin freq table { **************** 
 declare @tbl_freq table (id int identity(1,1), freq int null, mult dec(9,2) null, price dec(9,2) null)
 -- prime the table
 insert @tbl_freq
 select 0, 0, 0
 from @tbl
 where id <= 26
 
 update @tbl_freq
 set mult = @min_mplr
 where id=1
 
 update @tbl_freq
 set mult = @max_mplr
 where id=26

 update @tbl_freq
 set mult = (@min_mplr+@max_mplr)/2
 where id=14
 
 declare @t_mult dec(9,2)
 set @t_mult = @min_mplr
 set @idx=2
 while @idx<= 13
   begin
	set @t_mult = @t_mult  + (@avg_mplr - @min_mplr)/13
    update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 update @tbl_freq 
 set mult = @avg_mplr where id=@idx
 set @idx=15
 set @t_mult = @avg_mplr
 while @idx < 26
   begin
	set @t_mult = @t_mult  + (@max_mplr - @avg_mplr)/13
	update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 
 --set price
 update @tbl_freq
 set price = mult *  @spidx / 100
 
 --update freq
 declare @cnt int
 select @cnt = COUNT(*) from @tbl where mplr <= @min_mplr 
 update @tbl_freq 
 set freq = @cnt
 where id=1
 
 declare @curr_mult dec(9,2)
 declare @prev_mult dec(9,2)
 set @idx=2
 while @idx <= 26
   begin
	select @curr_mult = mult from @tbl_freq where id = @idx
	select @prev_mult = mult from @tbl_freq where id = @idx-1
	
	update @tbl_freq 
	set freq = A.CNT_ITEMS
	from ( select COUNT(*) as CNT_ITEMS from @tbl where mplr  between @prev_mult and @curr_mult) as A
	where id = @idx
	
	set @idx=@idx+1
   end
-- select * from @tbl_freq
-- ***************** end freq table } **************** 

declare @ac_38 dec(9,2), @ac_39 dec(9,2), @ac_40 dec(9,2)
declare @ad_39 dec(9,2)

select @ad_39 = MAX(price_mean) from @tbl where id > 26
set @ac_38 = @spidx * @avg_mplr / 100

select @ac_39 = AVG(price) 
from @tbl_freq 
where price > 0 and freq > 11

select @ac_40 = price
from @tbl_freq 
where freq = (select MAX(freq) from @tbl_freq)

declare @af_35 dec(9,2)
declare @ah_35 dec(9,2)

declare @af_36 dec(9,2)
declare @ah_36 dec(9,2)

declare @af_37 dec(9,2)
declare @ah_37 dec(9,2)


if (@ac_38+@ac_39+@ac_40)/3 < @ad_39 
	set @af_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @af_35 = @ad_39

if (@ac_38+@ac_39+@ac_40)/3 > @ad_39 
	set @ah_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @ah_35 = @ad_39

set @af_36 = @spidx * (@avg_mplr-@sd_mplr) / 100
set @ah_36 = @spidx * (@avg_mplr+@sd_mplr) / 100

set @af_37 = @spidx * @min_mplr  / 100
set @ah_37 = @spidx * @max_mplr  / 100

/*
select @ac_38 as AC38, @ac_39 as AC39, @ac_40 as AC40, @ad_39 as AD39
select @af_35  as AF35, @ah_35 as AH35
select @af_36 as AF36, @ah_36 as AH36 
select @af_37 as AF37, @ah_37 as AH37 
*/
-- final table
declare @af_38 dec(9,2)
declare @ah_38 dec(9,2)

declare @af_39 dec(9,2)
declare @ah_39 dec(9,2)

declare @ag_39 dec(9,2)

declare @af_40 dec(9,2)
declare @ah_40 dec(9,2)

set @af_38 = (@af_35 + @af_36 + @af_37 ) /3
set @ah_38 = (@ah_35 + @ah_36 + @ah_37 ) /3

set @af_40 = (@ah_38 - @af_38)/4 + @af_38


set @af_39 = (@af_38 + @af_40) /2
set @ag_39 = (@af_38 + @ah_38) / 2

set @ah_40 = 3*((@ah_38 - @af_38)/4) + @af_38
set @ah_39 = (@ah_38 + @ah_40) /2

/*
select @af_38 as AF38, 0 as XX38, @ah_38 as AH38
select @af_39 as AF38, @ag_39 as AG39, @ah_39 as AH39
select @af_40 as AF40, 0 as XX40, @ah_40 as AH40
*/
declare @freq_rank int

select @freq_rank= case
	when @price > @ah_38 then 7
	when @price > @ah_39 then 6
	when @price > @ah_40 then 5
	when @price > @ag_39 then 4
	when @price > @af_40 then 3
	when @price > @af_39 then 2
	when @price > @af_38 then 1
	else 0
	end

set @ret_price = @price
return @freq_rank


end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_Rank_For_ALL_ETF]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_Rank_For_ALL_ETF]
(
	@dt smalldatetime = null,
	@tick varchar(10) = null
)		
as
begin

	if @dt is null set @dt = GETDATE()
	declare @strTicker varchar(50)
	declare @tid int

	if @tick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_type=2
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @tick
		order by db_ticker_id
	declare @tbl TABLE (id int identity(1,1), Ticker varchar(10), dt smalldatetime, freq_rank int, price dec(9,2) )

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @freq_rank int
			declare @price dec(9,2)
			--exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT
			exec @freq_rank = csp_Calc_Freq_Daily_For_Month @dt, @tid, null, @ret_price = @price OUTPUT
			insert @tbl
			select @strTicker, @dt, @freq_rank, @price
			
			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS

	select * from @tbl order by Ticker
		  
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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Freq_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Freq_Weekly]
(
	@db_dt datetime,
	@tick_id int,
	@str_ticker varchar(50)=null)
as
begin
/*
DECLARE @RC int
DECLARE @db_dt datetime
DECLARE @tick_id int
DECLARE @str_ticker varchar(50)

-- TODO: Set parameter values here.
set @db_dt = '10-8-2012'
set @tick_id = -1
set @str_ticker = PCLN
EXECUTE @RC = [IDToDSN_DKC].[dbo].[csp_Calc_Freq_Weekly] 
  @db_dt
  ,@tick_id
  ,@str_ticker
GO

*/

declare @tbl table (idx int identity, tickID int, dt datetime, db_rank int)

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int

declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt)
	from tbl_Ticker T, tbl_Prices P
	--where YEAR(db_dt) >= 2007
	where db_dt >= @db_dt
	and (T.db_ticker_id = @tick_id or T.db_strTicker = @str_ticker)
	and T.db_ticker_id = P.db_ticker_id 
BEGIN TRY

Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin

	if @wk > @prev_wk or @prev_wk - @wk > 51
	begin
		EXECUTE @RC = csp_Calc_Freq_Daily_For_Month 
		   @dt
		  ,@ticker_id
		  ,@str_ticker
		  ,@ret_price OUTPUT

		insert @tbl
		select @ticker_id, @dt, @RC
	end
	set @prev_wk = @wk
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk

end
close cDSSSW
Deallocate cDSSSW
select * from @tbl
end try

BEGIN CATCH
close cDSSSW
Deallocate cDSSSW

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Pearson_Correlation]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[csp_Calc_Pearson_Correlation]
(
      @tv TBL_CORRELATION READONLY
)
AS

/*
--Src = http://www.mathsisfun.com/data/correlation.html
--CREATE TYPE TBL_CORRELATION AS TABLE
-- (                     
--	Col_A dec(9,2),
--	Col_B dec(9,2)
-- )

declare @tbl dbo.TBL_CORRELATION
insert @tbl select 14.2, 215
insert @tbl select 16.4, 325
insert @tbl select 11.9, 185
insert @tbl select 15.2, 332
insert @tbl select 18.5, 406
insert @tbl select 22.1, 522
insert @tbl select 19.4, 412
insert @tbl select 25.1, 614
insert @tbl select 23.4, 544
insert @tbl select 18.1, 421
insert @tbl select 22.6, 445
insert @tbl select 17.2, 408


exec csp_Calc_Pearson_Correlation @tbl

*/
BEGIN
declare @tbl table (col_A dec(9,2), col_B dec(9,2), Diff_A dec(9,2), Diff_B dec(9,2), AB dec(9,2), Asq dec(9,2), Bsq dec(9,2) )
declare @colA_Mean dec(9,2)
declare @colB_Mean dec(9,2)

insert @tbl
select *, 0, 0, 0, 0, 0 from @tv

select @colA_Mean = AVG(col_A), @colB_Mean = AVG(Col_B) from @tv

update @tbl
set Diff_A = col_A - @colA_Mean,
	Diff_B = col_B - @colB_Mean
	
update @tbl
set AB		= Diff_A * Diff_B,
	Asq		= Diff_A * Diff_A,
	Bsq		= Diff_B * Diff_B

declare @sum_AB dec(19,2), @sum_Asq dec(19,2), @sum_Bsq dec(19,2)
select @sum_AB = sum(AB), @sum_Asq = sum(Asq), @sum_Bsq = sum(Bsq) from @tbl

select convert(dec(9,4), @sum_AB / (sqrt(@sum_Asq * @sum_Bsq))) as Correlation

END

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Ret]
(
	@sdt smalldatetime,
	@tick varchar(10)
)
as
begin
set nocount on;
/*
EXECUTE [csp_Calc_Ret] 
   @sdt='4-1-2015'
  ,@tick='TLT'

*/
	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '1-1-2007' else set @start_dt = @sdt

declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

--4/3/2015 - replaced the logic of this SP
insert @tbl
exec csp_Calc_Ret_Using_Lag @sdt, @tick
select * from @tbl
return

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
	declare @dt datetime
	declare @vix dec(9,2)
	declare @typ int
	select @tid = db_ticker_id, @strTicker = @tick, @typ=db_type from tbl_Ticker where db_strTicker = @tick 
	BEGIN TRY

		begin
			select top 1 @dt = db_dt from tbl_Prices where db_ticker_id = 538 and db_dt <= @start_dt order by db_dt desc
			select @price = db_close from tbl_Prices where db_dt = @dt and db_ticker_id = @tid
					print 'Current ' + convert(varchar,@dt) + ',' + convert(varchar, @price)

			--===================================
			--go back one month
			select top 1 @prev_dt = db_dt, @prev_price = db_close 
			from tbl_Prices 
			where db_ticker_id  = @tid
			and db_dt >= DATEADD(d,-30,convert(datetime, @dt))
			order by db_dt
					print 'Prev ' + convert(varchar, @prev_dt) + ',' + convert(varchar, @prev_price)

			-- calc ret
			set @r1 = 100*(@price/@prev_price - 1.0)
					print 'Return r1 = ' + convert(varchar,@r1)
			--===================================

			--===================================
			-- calc VIX
			SELECT @vix = [dbo].[fn_CalcVIX] (
						   @prev_dt
						  ,@dt
						  ,@tid
						)

			--===================================
			--go back 3 month
			select top 1 @prev_dt = db_dt, @prev_price = db_close 
			from tbl_Prices 
			where db_ticker_id  = @tid
			and db_dt >= DATEADD(d,-90,convert(datetime, @dt))
			order by db_dt
					print 'Prev ' + convert(varchar, @prev_dt) + ',' + convert(varchar, @prev_price)

			-- calc ret
			set @r3 = 100*(@price/@prev_price - 1.0)
					print 'Return r3 = ' + convert(varchar,@r3)
			--===================================

			--===================================
			--go back 6 month
			select top 1 @prev_dt = db_dt, @prev_price = db_close 
			from tbl_Prices 
			where db_ticker_id  = @tid
			and db_dt >= DATEADD(d,-180,convert(datetime, @dt))
			order by db_dt
					print 'Prev ' + convert(varchar, @prev_dt) + ',' + convert(varchar, @prev_price)

			-- calc ret
			set @r6 = 100*(@price/@prev_price - 1.0)
					print 'Return r6 = ' + convert(varchar,@r6)
			--===================================

			--===================================
			--go back a year
			select top 1 @prev_dt = db_dt, @prev_price = db_close 
			from tbl_Prices 
			where db_ticker_id  = @tid
			and db_dt >= DATEADD(d,-365,convert(datetime, @dt))
			order by db_dt
					print 'Prev ' + convert(varchar, @prev_dt) + ',' + convert(varchar, @prev_price)

			-- calc 1year ret
			set @r12 = 100*(@price/@prev_price - 1.0)
					print 'Return r12 = ' + convert(varchar,@r12)
			--===================================

			set @tmp = CEILING(.5*@r1+.3*@r3+.15*@r6+.05*@r12)
			if @tmp < 0
				set @rRank = 0
			else
				set @rRank = @tmp
			insert @tbl
			select @tid, @strTicker, @dt, @price, @r1, @r3, @r6, @r12, @vix, @rRank
					
		end
print 'Updating tbl_Prices for ticker= [' + @strTicker + '], dt= [' + convert(varchar, @dt) + ']'

update tbl_Prices
set db_rank = @rRank
where db_ticker_id = @tid 
and db_dt = @dt


select * from @tbl
		  
	END TRY

	BEGIN CATCH

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret_For_Strategy_Tickers]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Ret_For_Strategy_Tickers]
(
	@Curr_dt smalldatetime = null,
	@Prev_dt smalldatetime = null,
	@fnTickers varchar(100) = null,
	@typ int = 2
)
as
/*
EXECUTE [csp_Calc_Ret_For_Strategy_Tickers] @fnTickers='ivv.csv', @curr_dt='7-29-2015', @typ=1
*/


begin
set nocount on;

declare @tbl table (id int identity, ticker varchar(10))
declare @tbl_Current table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

declare @tbl_Previous table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)


--insert @tbl select
--'VTI' insert @tbl select
--'VEU'   insert @tbl select
--'VNQ'   insert @tbl select
--'TIP'   insert @tbl select
--'TLT'   insert @tbl select
--'IVV'   insert @tbl select
--'VO'   insert @tbl select
--'VB'   insert @tbl select
--'ACWX'   insert @tbl select
--'IYR'   insert @tbl select
--'AGG'   insert @tbl select
--'VCR'   insert @tbl select
--'VDC'   insert @tbl select
--'VDE'   insert @tbl select
--'VFH'   insert @tbl select
--'VHT'   insert @tbl select
--'VIS'   insert @tbl select
--'VAW'   insert @tbl select
--'VGT'   insert @tbl select
--'VPU'   insert @tbl select
--'IWV'   insert @tbl select
--'IJH'   insert @tbl select
--'IJR'   insert @tbl select
--'EEM'   insert @tbl select
--'LQD'   insert @tbl select
--'BLV'   insert @tbl select
--'EMB'   insert @tbl select
--'HYG'   insert @tbl select
--'ONEQ'  

--insert @tbl
--select db_strTicker
--from tbl_Ticker 
--where db_type=1
--and db_inactive_dt is null

--declare @tblImp table (s varchar(50))
--DECLARE	@retval int
--insert @tblImp
--EXEC	[dbo].[csp_ReadXLSTab]
--		@ssa_filename = N'd:\stockmon\Brandnames.xls',
--		@tab = N'Sheet1',
--		@retval = @retval OUTPUT

--delete from @tblImp where s like '%.%'
--insert @tbl 
--select * from @tblImp 


declare @cnt int
declare @id int
set @id=1
declare @tick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

if @Curr_dt is null
	select @Curr_dt = max(db_dt)
	from tbl_Prices
	where db_ticker_id = 538

if @Prev_dt is null
	select top 1 @prev_dt = db_dt
	from tbl_Prices
	where db_ticker_id = 538
	and db_dt < @Curr_dt 
	order by db_dt desc

if @fnTickers is null
	insert @tbl
	select distinct A.db_strTicker
	from tbl_Ticker A, tbl_Prices B
	where A.db_ticker_id = B.db_ticker_id
	and B.db_close > 10.0
	and B.db_dt >= @Curr_dt
	and (A.db_type = @typ or A.db_strTicker = 'SPY' or A.db_strTicker = 'TLT' or A.db_type=3)
	and A.db_strTicker <> 'CNX500'
else
insert @tbl
EXEC	[dbo].[csp_ReadCSV]
		@filename = @fnTickers,
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

select @cnt = COUNT(*) from @tbl
		
while @id <= @cnt
  begin
	select @tick = ticker from @tbl where id=@id
	
	insert @tbl_Current 
	exec csp_Calc_Ret_Using_Lag @Curr_dt, @tick
	--exec csp_Calc_Ret @Curr_dt, @tick

	--insert @tbl_Previous
	--exec csp_Calc_Ret_Using_Lag @Prev_dt, @tick
	--exec csp_Calc_Ret @Prev_dt, @tick

	set @id = @id+1
  end

  --select * from @tbl_Current
  --where tid is not null
  --order by rRank desc

  select A.tid, A.strTicker, convert(char(2),month(A.dt)) + '-' + convert(char(2),day(A.dt)) + '-' + convert(char(4),year(A.dt)) as Adte,
  A.price, A.r1, A.r3, A.r6, A.r12, A.vix, A.rRank
  --B.dt, B.rRank, B.price, A.rRank-B.rRank as Diff  
  from @tbl_Current A
  --, @tbl_Previous  B
  --where A.tid = B.tid
  --and A.rRank-B.rRank > 10
  --order by A.rRank-B.rRank Desc, A.rRank desc
  where A.tid is not null
  order by A.strTicker


  select top 10 A.tid, A.strTicker, convert(char(2),month(A.dt)) + '-' + convert(char(2),day(A.dt)) + '-' + convert(char(4),year(A.dt)) as Adte,
  A.price, A.r1, A.r3, A.r6, A.r12, A.vix, A.rRank--, NTILE(4) OVER(order by rRank asc) as RankQuartile
  from @tbl_Current A
  where A.r1 < 20
  order by rRank desc

  -- 1/28/2015 - added this to support csp_Calc_Portfolio_Ret_Rank.sql
  -- which calcs individual rankings of each ETF in a
  -- predefined portfolio. If this row is not deleted then the 
  -- Pivot SQL scripts for Return Rank will include this row as well.
  --delete from tbl_Return_Rank where dt = @Curr_dt
  --insert tbl_Return_Rank
  --select tid, strTicker, dt, price, r1, r3, r6, r12, vix, rRank
  --from @tbl_Current
 end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret_From_CSV]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Ret_From_CSV]
(
	@Curr_dt smalldatetime = null,
	@Prev_dt smalldatetime = null,
	@fn nvarchar(100),
	@dir nvarchar(100)
)
as
/*
EXECUTE [csp_Calc_Ret_From_CSV] null, null, 'Barrons_500_May5_2014.csv', 'd:\Stockmon'
EXECUTE [csp_Calc_Ret_From_CSV] null, null, 'VG_ETF.csv', 'd:\Stockmon'
EXECUTE [csp_Calc_Ret_From_CSV] null, null, 'ETF_Segments.csv', 'd:\Stockmon'
EXECUTE [csp_Calc_Ret_From_CSV] null, null, 'watch.csv', 'c:\Stockmon'
EXECUTE [csp_Calc_Ret_From_CSV] null, null, 'IVV.csv', 'c:\Stockmon'
*/


begin
set nocount on;

declare @tbl table (id int identity, ticker varchar(10))

declare @tbl_Current table (id int identity, tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2),  rRank int)

declare @tbl_Previous table (id int identity, tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

insert @tbl
EXEC	[dbo].[csp_ReadCSV]
		@filename = @fn,
		@dbDir = @dir,
		@cols='Ticker',
		@whereclause = N'1=1'

delete from @tbl where ticker  like '%.%'
delete from @tbl where ticker like '%--%'
delete from @tbl where ticker like '%/%'

declare @cnt int
declare @id int
set @id=1
declare @tick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

if @Curr_dt is null
	select @Curr_dt = max(db_dt)
	from tbl_Prices
	where db_ticker_id = 538

if @Prev_dt is null
	select top 1 @prev_dt = db_dt
	from tbl_Prices
	where db_ticker_id = 538
	and db_dt < @Curr_dt 
	order by db_dt desc

--insert @tbl
--select distinct A.db_strTicker
--from tbl_Ticker A, tbl_Prices B
--where A.db_ticker_id = B.db_ticker_id
--and B.db_close > 10.0
--and B.db_dt >= @Curr_dt
--and A.db_type = @typ 

select @cnt = COUNT(*) from @tbl
		
while @id <= @cnt
  begin
	select @tick = ticker from @tbl where id=@id
	
	insert @tbl_Current 
	exec csp_Calc_Ret_Using_Lag @Curr_dt, @tick

	--insert @tbl_Previous  
	--exec csp_Calc_Ret @Prev_dt, @tick

	set @id = @id+1
  end

  --select * from @tbl_Current order by id
	
  --select * from @tbl_Current
  --where tid is not null
  --order by rRank desc

	if exists ( select id from @tbl_Current where r1 >0 and r1 > r3 )
	  select A.*, case when A.r1 > 0 and A.r1 > A.r3 then 1 else 0 end as UP, @fn as FN
	  --, B.dt, B.rRank, B.price, A.rRank-B.rRank as Diff  
	  from @tbl_Current A
	  --where tid is not null and A.r1 > 0 and A.r1 > A.r3 
	  --, @tbl_Previous  B
	  --where A.tid = B.tid
	  --order by A.rRank-B.rRank Desc, A.rRank desc
	  order by UP desc, A.rRank desc
	else
		select @fn as FN
 end
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret_Monthly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Ret_Monthly]
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null,
	@srcFN varchar(100) = null
)
as
begin
set nocount on;
/*
EXECUTE [csp_Calc_Ret_Monthly] 
   @sdt='8-1-2015'
  ,@srcFN=null
  ,@tick='SDS'

*/
declare @nTicks int

-- collect tickers of interest
declare @dir varchar(50)
set @dir = 'c:\stockmon'

--declare @srcFN varchar (100)
--set @srcFN = 'nasdaq100.csv'

declare @tblTick table (idx int identity, fn varchar(100) )

if @srcFN is not null
insert @tblTick
EXEC	[dbo].[csp_ReadCSV]
		@filename = @srcFN,
		@dbDir = @dir,
		@cols='Ticker',
		@whereclause = N'1=1'


if @srcFN is not null
  select @nTicks = count(*) from @tblTick
else
	select @nTicks = count(distinct(tid)) from tbl_Return_Rank

print 'Ticks to Process ' + convert(varchar, @nTicks)

	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '12-30-2005' else set @start_dt = @sdt

declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)
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
	if @srcFN is not null
		/*
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker in ( select fn from @tblTick)
		and db_inactive_dt is null
		order by db_ticker_id
		*/
		-- Use this when new tickers have been added and don't exist in tbl_Return_Rank
		-- and want to calc only for the new ones
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker in ( select fn from @tblTick)
		--and db_strTicker not in ( select distinct(strTicker)  from tbl_Return_Rank )
		and db_inactive_dt is null
		order by db_ticker_id
	else if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		--where (db_type=2 or db_strTicker = 'SPY' or db_strTicker = 'TLT' or db_type=3)
		where  db_type in ( 1,2,3 )
		and db_inactive_dt is null
		order by db_ticker_id
		--select distinct(tid), strTicker 
		--from tbl_Return_Rank 
		----where dt = '7-1-2015'
		----and rRank is null 
		--order by tid
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
--			print @strTicker

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
					exec csp_Calc_Ret_Using_Lag @dt, @strTicker
					--exec csp_Calc_Ret @dt, @strTicker
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
			delete from @tbl
			Fetch next from cDSS
			into @tid, @strTicker
			set @nTicks = @nTicks - 1
			print 'Ticks to Process ' + convert(varchar, @nTicks)

		end
	close cDSS
	Deallocate cDSS
if @tick is null
	select * from @tbl
	where rRank is not NULL
	order by rRank desc, strTicker
else
	select * from @tbl
	where rRank is not NULL
	order by dt
		  
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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret_Using_Lag]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[csp_Calc_Ret_Using_Lag]
( 
	-- Add the parameters for the stored procedure here
	@sdt smalldatetime,
	@tick varchar(10)
)
AS
/*
EXECUTE [dbo].[csp_Calc_Ret_Using_Lag] 
   @sdt='4-1-2015'
  ,@tick='TLT'
GO

EXECUTE [dbo].[csp_Calc_Ret_Using_Lag] 
   @sdt='4-30-2015'
  ,@tick='TLT'
GO

*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @tickID int
select @tickID = db_ticker_id from tbl_Ticker where db_strTicker = @tick

declare @tbl_Prices table (idx int identity, tick varchar(10), pdt datetime, eom datetime, eomPrice dec(9,3), pPrice dec(9,3), p1 dec(9,3), p3 dec(9,3), p6 dec(9,3), p12 dec(9,3)
, r1 dec(9,3), r3 dec(9,3), r6 dec(9,3), r12 dec(9,3), rRank int )

if exists (select dt from tbl_Return_Rank where dt=@sdt and strTicker = @tick)
	insert @tbl_Prices
	select @tick, dt, EOMONTH(dt,-1),  0, price, lag(price, 1,0) over (order by dt) as p1,
	lag(price, 3,0) over (order by dt)  as p3, lag(price, 6,0) over (order by dt)  as p6, lag(price,12,0) over (order by dt) as p12
	,0,0,0,0,0
	from tbl_Return_Rank
	where strTicker = @tick
	and dt between EOMONTH(@sdt,-13) and @sdt
	order by dt
else
  begin
	insert @tbl_Prices
	select @tick, dt, EOMONTH(dt,-1),  0, price, lag(price, 1,0) over (order by dt) as p1,
	lag(price, 3,0) over (order by dt)  as p3, lag(price, 6,0) over (order by dt)  as p6, lag(price,12,0) over (order by dt) as p12
	,0,0,0,0,0
	from tbl_Return_Rank
	where strTicker = @tick
	and dt between EOMONTH(@sdt,-13) and @sdt
	union
	select @tick, db_dt, EOMONTH(@sdt,-1),  0, db_close, 0,
	0,0,0
	,0,0,0,0,0
	from tbl_Prices where db_dt = @sdt and db_ticker_id = @tickID
	order by dt


	update @tbl_Prices
	set p1 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-2) and  EOMONTH(@sdt, -1)
		) as A
	where pdt = @sdt

	update @tbl_Prices
	set p3 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-4) and  EOMONTH(@sdt, -3)
		) as A
	where pdt = @sdt


	update @tbl_Prices
	set p6 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-7) and  EOMONTH(@sdt, -6)
		) as A
	where pdt = @sdt


	update @tbl_Prices
	set p12 = A.price
	from (
			select dt, price
		from tbl_Return_Rank 
		where strTicker = @tick
		and dt between EOMONTH(@sdt,-13) and  EOMONTH(@sdt, -12)
		) as A
	where pdt = @sdt
  end

/*
select @tick, db_dt, EOMONTH(db_dt,-1),  0, db_close, lag(db_close, 1,0) over (order by db_dt) as p1,
lag(db_close, 3,0) over (order by db_dt)  as p3, lag(db_close, 6,0) over (order by db_dt)  as p6, lag(db_close,12,0) over (order by db_dt) as p12
,0,0,0,0,0
from tbl_Return_Rank RR, tbl_Prices P
where RR.tid = P.db_ticker_id
and RR.dt = P.db_dt
and strTicker = @tick
order by db_dt
*/

update @tbl_Prices
set eomPrice = A.Price
from (select db_dt as ADTE, db_close as Price from tbl_Prices where db_ticker_id = @tickID) as A
where (eom = ADTE)

-- get prices where eomPrice=0 due to eom falling on a non-trading day
declare @idx int
declare @midx int
declare @dt datetime

select top 1 @idx = idx from @tbl_Prices where pdt >= @sdt and eomPrice = 0
select top 1 @midx = idx from @tbl_Prices where pdt >= @sdt and eomPrice = 0 order by pdt desc
--print 'idx=' + convert(varchar, @idx)
--print 'midx=' + convert(varchar, @midx)
while exists (select * from @tbl_Prices where idx=@idx and idx <= @midx)
  begin
--	print 'idx=' + convert(varchar, @idx)
	select @dt = pdt from @tbl_Prices where idx=@idx
	update @tbl_Prices
	set eomPrice = A.Price, eom = ADTE
	from (	select top 1 db_dt as ADTE, db_close as Price from tbl_Prices
			where db_ticker_id = @tickID
			and db_dt < @dt
			order by db_dt desc) as A
	where idx = @idx

	select top 1 @idx = idx from @tbl_Prices where idx > @idx and eomPrice = 0
	if @@ROWCOUNT=0 set @idx=@midx+1
  end

--pN = BOM price and return calc using EOM price
update @tbl_Prices
set r1 = case when p1 > 0 then 100*(eomPrice/p1 - 1.0) else 0 end,
r3 = case when p3 > 0 then 100*(eomPrice/p3 - 1.0) else 0 end,
r6 = case when p6 > 0 then 100*(eomPrice/p6 - 1.0) else 0 end,
r12 = case when p12 > 0 then 100*(eomPrice/p12 - 1.0) else 0 end

update @tbl_Prices
set rRank = case when coalesce(CEILING(.5*r1+.3*r3+.15*r6+.05*r12),0) < 0 then 0 else coalesce(CEILING(.5*r1+.3*r3+.15*r6+.05*r12),0) end


--declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

-- calc VIX
declare @vix dec(9,2)
declare @eom datetime
select @eom = eom from @tbl_Prices where pdt = @sdt
SELECT @vix =  dbo.fn_CalcVIX(@eom
				,@sdt
				,@tickID
			)

select @tickID, @tick, @sdt, pPrice, r1, r3, r6, r12, @vix as VIX, rRank
from @tbl_Prices
where pdt = @sdt

--select * from @tbl_Prices
--where pdt > '12-31-2006'
END

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Ret_Weekly]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Calc_Ret_Weekly]
(
	@db_dt datetime,
	@tick_id int,
	@typ int=2,
	@str_ticker varchar(50)=null
)
as
begin
/*
DECLARE @RC int
DECLARE @db_dt datetime
DECLARE @tick_id int
DECLARE @str_ticker varchar(50)

-- TODO: Set parameter values here.
set @db_dt = '12-31-2006'
set @tick_id = 0
set @str_ticker = 'SBUX'
EXECUTE @RC = [IDToDSN_DKC].[dbo].[csp_Calc_Ret_Weekly] 
  @db_dt
  ,@tick_id
  ,1
  ,@str_ticker
GO

*/

declare @tbl table (tid int, strTicker varchar(10), dt datetime, price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)

DECLARE @RC int
DECLARE @dt datetime
DECLARE @ThursDt datetime
DECLARE @ticker_id int
DECLARE @prev_tid int

DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int

-- Ret Related Vars
DECLARE	@r1 decimal(9, 2),
		@r3 decimal(9, 2),
		@r6 decimal(9, 2),
		@r12 decimal(9, 2),
		@prev_price decimal(9,2),
		@prev_dt datetime,
		@o_price dec(9,2),
		@price dec(9,2)
declare @strTicker varchar(50)		
if @tick_id <=0 and @str_ticker is null
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and T.db_ticker_id = P.db_ticker_id 
	and T.db_inactive_dt is null
	and (T.db_type=@typ or T.db_strTicker = 'SPY' or T.db_strTicker = 'TLT')
	order by db_dt asc
else		
declare cDSSSW scroll cursor for
	select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= @db_dt
	and (T.db_ticker_id = @tick_id or T.db_strTicker = @str_ticker)
	and T.db_ticker_id = P.db_ticker_id 
	order by db_dt asc
BEGIN TRY

declare @bOut int
set @bOut=1

Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk, @str_ticker
set @prev_wk = 0
set @prev_tid=0
while @@FETCH_STATUS = 0
begin
	--print @str_ticker + ', ' + convert(varchar, @dt)
	
	if (@wk <> @prev_wk or @prev_wk - @wk >= 51)-- or (@prev_tid <> @ticker_id)
		begin
			--- We come here when its Monday
			if @bOut=1 --- we did not get a Fri in prev week - so grab the Thurs of the prev week
				begin
					set @bOut=0
					insert @tbl
					exec csp_Calc_Ret_Using_Lag @ThursDt, @str_ticker
					--exec csp_Calc_Ret @ThursDt, @str_ticker
					
					update @tbl set price = CLS
					from (select db_close CLS from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @ThursDt) A
					where tid= @ticker_id and dt = @ThursDt
					print convert(varchar, @ThursDt) + ' THURS calc here'
				end
			else
				print convert(varchar, @dt) + ' NO calc here'

			set @prev_wk = @wk
		end
	else 
		begin
			set @bOut=1
			print ' Out Dt=' + convert(varchar, @dt) + 'Wk=' + convert(varchar, @wk) + ', Prev Wk=' + convert(varchar, @prev_wk)
			if ( DATEPART(DW, @dt) = 6 ) -- Friday
				begin
					set @bOut=0
					print 'In Dt=' + convert(varchar, @dt) + 'Wk=' + convert(varchar, @wk) + ', Prev Wk=' + convert(varchar, @prev_wk)
					insert @tbl
					exec csp_Calc_Ret_Using_Lag  @dt, @str_ticker
					--exec csp_Calc_Ret @dt, @str_ticker
					
					update @tbl set price = CLS
					from (select db_close CLS from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @dt) A
					where tid= @ticker_id and dt = @dt
				end
			else
				set @ThursDt = @dt
		end	
	set @prev_tid = @ticker_id 
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk, @str_ticker

end
close cDSSSW
Deallocate cDSSSW
--insert latest date
declare @today datetime
select @today = max(db_dt)
from tbl_Prices
where db_ticker_id = @ticker_id
print @today

insert @tbl
exec csp_Calc_Ret_Using_Lag  @today, @str_ticker
--exec csp_Calc_Ret @today, @str_ticker

select * from @tbl
--where rRank is not NULL
order by tid, dt



end try

BEGIN CATCH
close cDSSSW
Deallocate cDSSSW

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

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Slope_Intercept]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	Dikesh Chokshi
-- Create date: 9/12/2014
-- Description:	Calc Slope (slp), Intercept(icpt), Predict next value (pred)
--				for a prices between dates dt1 & dt2 for a tid
-- =============================================
CREATE PROCEDURE [dbo].[csp_Calc_Slope_Intercept] 
(
	@sdt datetime,
	@edt datetime,
	@tid int,
	@slp dec(9,3) output,
	@icpt dec(9,3) output,
	@pred dec(9,3) output
)
AS

/*

DECLARE	@slp float,
		@icpt float,
		@pred float

exec [dbo].[csp_Calc_Slope_Intercept]
		@sdt = N'5/1/2014',
		@edt = N'10/1/2014',
		@tid = 4546,
		@slp = @slp OUTPUT,
		@icpt = @icpt OUTPUT,
		@pred = @pred OUTPUT

SELECT	@slp as N'@slp',
		@icpt as N'@icpt',
		@pred as N'@pred'

*/

BEGIN
	-- SET NOCOUNT ON added to prevent econvert(float,db_row_id)tra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	set @icpt = 0 
	set @pred = 0

declare @n dec(9,3) 

Select @n=count(*)
from tbl_Prices
where db_dt between @sdt and @edt
and db_ticker_id = @tid

--print '@n=' + convert(varchar, @n)

declare @xbar float
declare @ybar float

declare @tbl table (idx int identity, dt datetime, price dec(9,3))
insert @tbl
Select db_dt, db_close
from tbl_Prices
where db_dt between @sdt and @edt
and db_ticker_id = @tid
order by db_dt

begin try
	select 
	@ybar = AVG(convert(float,idx)), @xbar = AVG(price)
	from @tbl

	select 
	-- got this formula from Excel and verified the slope matches to 3 digits.
	@slp = sum( (convert(float,price)-@xbar)*(idx-@ybar) ) / sum( Power((convert(float,price)-@xbar),2))
	--@icpt = avg(db_close) - ((@n * sum(convert(float,db_row_id)*db_close)) - (sum(convert(float,db_row_id))*sum(db_close)))/
	--((@n * sum(Power(convert(float,db_row_id),2)))-Power(Sum(convert(float,db_row_id)),2)) * avg(convert(float,db_row_id))
	from @tbl

if 1=0
begin
	declare @rid dec(9,3)
	select top 1 @rid = convert(float,db_row_id) 
	from tbl_Prices
	where db_dt >= @edt
	and db_ticker_id = @tid
	
	set @pred = @icpt + @rid * @slp
end

--print 'In [csp_Calc_Slope_Intercept] -- sdt = ' + convert(varchar, @sdt) + ',  edt = ' + convert(varchar, @edt) + ', tid = ' + convert(varchar, @tid) + ', slp = ' + convert(varchar, @slp)

end try
begin catch
    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE() + ', ' + convert(varchar, @sdt),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	print '[csp_Calc_Slope_Intercept] - in catch for tid = ' + convert(varchar, @tid)
	set @slp = 0
	set @icpt = 0 
	set @pred = 0
end catch

	
END

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Update_Slope]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[csp_Calc_Update_Slope]
(
	@s_date datetime  = '1-1-2007',
	@e_date datetime = null,
	@typ smallint = 1,
	@tick_id int=0
)
as
/*
EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Update_Slope]
@s_date='9-8-2014', @e_date='9-12-2014', @typ=2
GO
*/
set nocount on
declare @doit int
set @doit=1

declare @SPID int
set @SPID = 538 -- S&P Index ticker id
declare @start_date datetime
set @start_date = '1/1/' + convert(varchar,YEAR(@s_date)-1)
print 'Start date = ' + convert(varchar, @start_date)
print 'End date = ' + convert(varchar, @e_date)
declare @sp_dt datetime
declare @sp_close float
declare @sp_tick_id int
declare @idx int
set @idx=1
declare @dt2 datetime
declare @tbl_SPID table (idx int identity, p_tid int, p_dt datetime)

insert @tbl_SPID
select db_ticker_id, db_dt
from tbl_Prices
where db_ticker_id = @SPID
and db_dt >= @start_date and db_dt <= @e_date
order by db_dt desc
--print 'nrows = ' + convert(varchar, @@ROWCOUNT)

select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt from @tbl_SPID where idx=1
--print 'sp_dt=' + convert(varchar, @sp_dt)

DECLARE	@slp decimal(9, 3),
		@icpt decimal(9, 3),
		@pred decimal(9, 3)

BEGIN TRY
  -- build ticker list
  declare @ticks table (idx int identity, t int)
  if @tick_id > 0 
	  insert @ticks
	  select db_ticker_id from tbl_Ticker where db_ticker_id = @tick_id 
  else
	  insert @ticks
	  select db_ticker_id 
	  from tbl_Ticker 
	  where db_type= @typ
	  order by db_ticker_id 

declare @cnt int
select @cnt = COUNT(*) from @ticks
declare @idx2 int

while @sp_dt > @s_date
begin
---- { MA 10
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx+4
	print 'dt2=' + convert(varchar, @dt2)
  if 1=@doit
  begin
  set @idx2=1
  while @idx2 <= @cnt
      begin
		select @tick_id = t from @ticks where idx = @idx2
		BEGIN TRY
			exec [dbo].[csp_Calc_Slope_Intercept]
			@sdt = @dt2,
			@edt = @sp_dt,
			@tid = @tick_id,
			@slp = @slp OUTPUT,
			@icpt = @icpt OUTPUT,
			@pred = @pred OUTPUT
		end try
		BEGIN CATCH
			set @slp=0
		END CATCH;


		update tbl_Prices
		set db_slope  = @slp
		where db_ticker_id = @tick_id 
		and db_dt = @sp_dt
		
		set @idx2 = @idx2+1
	  end
  end	
	
---- } MA 10

--do this after all MA are done to do the next date
	select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt 
	from @tbl_SPID 
	where idx=@idx+1
	print 'Reset sp_dt=' + convert(varchar, @sp_dt)
end
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

/***************************************/
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Update_Slope_2]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[csp_Calc_Update_Slope_2]
(
	@s_date datetime  = '1-1-2007',
	@e_date datetime = null,
	@typ smallint = 1,
	@tick_id int=0
)
as
-- calcs the slope for each date in tbl_Return_Rank
/*
EXECUTE [csp_Calc_Update_Slope_2] @s_date='12-31-2006', @e_date='7-2-2015'
, @typ=1, @tick_id=2
GO
*/
set nocount on
declare @doit int
set @doit=1

declare @SPID int
set @SPID = 442 -- S&P Index ticker id
declare @start_date datetime
set @start_date = '1/1/' + convert(varchar,YEAR(@s_date)-1)
print 'Start date = ' + convert(varchar, @start_date)
print 'End date = ' + convert(varchar, @e_date)
declare @sp_dt datetime
declare @sp_close float
declare @sp_tick_id int
declare @idx int
set @idx=1
declare @dt2 datetime
declare @tbl_SPID table (idx int identity, p_tid int, p_dt datetime)

insert @tbl_SPID
--select db_ticker_id, db_dt
--from tbl_Prices
--where db_ticker_id = @SPID
--and db_dt >= @start_date and db_dt <= @e_date
--order by db_dt desc
select tid, dt
from tbl_Return_Rank
where tid = @SPID
and dt >= @start_date and dt <= @e_date
order by dt desc
--print 'nrows = ' + convert(varchar, @@ROWCOUNT)

--select * from @tbl_SPID

select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt from @tbl_SPID where idx=1
print 'csp_Calc_Update_Slope_2 - sp_dt=' + convert(varchar, @sp_dt)

DECLARE	@slp decimal(9, 3),
		@icpt decimal(9, 3),
		@pred decimal(9, 3)

BEGIN TRY
  -- build ticker list
  declare @ticks table (idx int identity, t int)
  if @tick_id > 0 
	  insert @ticks
	  select db_ticker_id from tbl_Ticker where db_ticker_id = @tick_id 
  else
	  insert @ticks
	  select db_ticker_id 
	  from tbl_Ticker 
	  where db_type= @typ
	  order by db_ticker_id 
	  --select distinct(RR.tid)
	  --from tbl_Return_Rank RR, tbl_Ticker T
	  --where RR.tid = T.db_ticker_id
	  --and T.db_type = @typ
	  --order by tid

declare @cnt int
select @cnt = COUNT(*) from @ticks
declare @idx2 int

while @sp_dt > @s_date
begin
---- { 1 month slope
	select @sp_tick_id=p_tid, @dt2=p_dt 
	from @tbl_SPID 
	where idx=@idx + 1
	print 'csp_Calc_Update_Slope_2 dt2=' + convert(varchar, @dt2)
  if 1=@doit
  begin
  set @idx2=1
  while @idx2 <= @cnt
      begin
		select @tick_id = t from @ticks where idx = @idx2
		print 'csp_Calc_Update_Slope_2 @tick_id=' + convert(varchar, @tick_id)
		BEGIN TRY
			exec [dbo].[csp_Calc_Slope_Intercept]
			@sdt = @dt2,
			@edt = @sp_dt,
			@tid = @tick_id,
			@slp = @slp OUTPUT,
			@icpt = @icpt OUTPUT,
			@pred = @pred OUTPUT
		end try
		BEGIN CATCH
			set @slp=0
		END CATCH;

		print 'csp_Calc_Update_Slope_2 @slp=' + convert(varchar, @slp) + ' for dt = ' + convert(varchar, @sp_dt)

		update tbl_Prices
		set db_slope  = @slp
		where db_ticker_id = @tick_id 
		and db_dt = @sp_dt
		
		set @idx2 = @idx2+1
	  end
  end	
	
---- } MA 10

--do this after all MA are done to do the next date
	select @idx=idx, @sp_tick_id=p_tid, @sp_dt=p_dt 
	from @tbl_SPID 
	where idx=@idx+1
	print 'csp_Calc_Update_Slope_2 Reset sp_dt=' + convert(varchar, @sp_dt)
end
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

/***************************************/
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

GO
/****** Object:  StoredProcedure [dbo].[csp_CollectFans]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 1/15/2014
-- Description:	
-- Collect records from tbl_Prices after running csp_Calc_Averages_2
-- Specify monthly dates so that we can use stockmon to create
-- monthly ISM files.
-- Copy the tick and idx columns, paste it in x.txt and highlight & replace tabs with spaces.
-- This will put idx in the Date picked column of Stockmon and allow sorting on
-- them. Smaller the idx value, greater the chance 10-15-65 MA forming a fan
-- =============================================
CREATE PROCEDURE [dbo].[csp_CollectFans] (
	-- Add the parameters for the stored procedure here
	@sdt datetime = null,
	@edt datetime = null,
	@typ int = 1
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


-- Collect records from tbl_Prices after running csp_Calc_Averages
-- Specify monthly dates so that we can use stockmon to create
-- monthly ISM files.
-- Copy the tick and idx columns, paste it in x.txt and highlight & replace tabs with spaces.
-- This will put idx in the Date picked column of Stockmon and allow sorting on
-- them. Smaller the idx value, greater the chance 10-15-65 MA forming a fan

if @sdt is null set @sdt = '12-31-2013'
if @edt is null 
	select @edt = (select max(db_dt)
				from tbl_Prices
				where db_ticker_id = 538)

declare @dt datetime
set @dt = @sdt

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#tbl') AND type in (N'U'))
DROP TABLE #tbl

CREATE TABLE #tbl(
	id [int] IDENTITY(1,1) NOT NULL,
	tid [int] NOT NULL,
	dt [datetime],
	tick varchar(10),
	idx dec(9,2),
	LT int,
	[vol] [bigint] default(0),
 CONSTRAINT [PK_tbl_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_tbl_tid] ON [#tbl] 
(
	[tid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

print '[csp_CollectFans] - ' + convert(varchar,@dt) + ' --- ' + convert(varchar, @edt)

while @dt < @edt
 begin
	print '[csp_CollectFans] - ' + convert(varchar,@dt) + ' --- ' + convert(varchar, @edt)
	select top 1 @dt = db_dt 
	from tbl_Prices
	where db_ticker_id = 538
	and db_dt > @dt
	order by db_dt asc
	
	insert #tbl
	select P.db_ticker_id, P.db_dt, T.db_strTicker, convert(dec(9,2),(P.db_mult-P.db_avg+P.db_avg-P.db_index)/P.db_close * 100) as IDX,
	case when P.db_index > P.db_mult_avg_ratio then 1 
		else 0 
	end
	as 'LT', 0
	  FROM [tbl_Prices] P, tbl_Ticker T
	  where P.db_ticker_id = T.db_ticker_id
	  and db_dt = @dt
	  and P.db_mult > P.db_avg
	  and P.db_avg > db_index
	  and P.db_close >= 10.0
	  and P.db_index > P.db_mult_avg_ratio
	  and P.db_slope > 0
	  and T.db_ticker_id <> 538
	  and T.db_type = @typ
	  order by LT desc, IDX
  
 end
 

-- Delete duplicates
delete #tbl
where id in (
select B.id
from #tbl A, #tbl B
where A.tick  = B.tick 
and B.id > A.id
)
delete #tbl
where idx > 6.0

 
print 'Done 1'
 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#tbl_Vol') AND type in (N'U'))
DROP TABLE #tbl_Vol

CREATE TABLE #tbl_Vol(
	[itid] [int]NOT NULL,
	[vol] [bigint] NULL,
 CONSTRAINT [PK_tbl_Vol_itid] PRIMARY KEY CLUSTERED 
(
	[itid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


 insert #tbl_Vol 
 select db_ticker_id ITID, avg(convert(bigint, db_volume)) as AVGVOL 
		from tbl_Prices 
		where db_ticker_id in (select tid from #tbl)
		and db_dt between @sdt and @edt
		and db_ticker_id <> 538
		and db_type = @typ
		group by db_ticker_id
		

update #tbl 
set Vol = A.vol 
from #tbl_Vol A
where A.ITID = tid 


IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'#tbl_Vol') AND name = N'PK_tbl_Vol')
DROP INDEX [PK_tbl_Vol_itid] ON #tbl_Vol WITH ( ONLINE = OFF )

drop table #tbl_Vol 

print 'Done 2'

 if @typ=1
	 select * from #tbl 
	 where vol > 300000
	 order by idx asc, dt asc
else
	 select * from #tbl 
	 order by idx asc, dt asc

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[#tbl]') AND name = N'IX_tbl_tid')
DROP INDEX [IX_tbl_tid] ON [dbo].[#tbl] WITH ( ONLINE = OFF )

drop table #tbl
 END

GO
/****** Object:  StoredProcedure [dbo].[csp_Compare_Freq_Rank]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Compare_Freq_Rank]
(
	@dt datetime=null,
	@ticker_id int=null,
	@str_ticker varchar(10)=null,
	@tgt_id int=538,
	@ret_price dec(9,2) output
)
as
begin
/*
DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @str_ticker varchar(10)
DECLARE @tgt_id int
DECLARE @ret_price decimal(9,2)

-- TODO: Set parameter values here.
set @str_ticker = 'AAPL'
set @tgt_id = 538
EXECUTE @RC = [IDToDSN_DKC].[dbo].[csp_Compare_Freq_Rank] 
   '3-1-2013'
  ,null
  ,@str_ticker
  ,@tgt_id
  ,@ret_price OUTPUT
select @ret_price as Price, @RC as Rnk
*/
set nocount on;
--input date & ticker ID to this procedure
declare @today datetime
if @dt is null
	set @today = GETDATE()
else
	set @today = @dt
	
declare @aid int
if @ticker_id is null
	if @str_ticker is not null
		select @aid = db_ticker_id from tbl_Ticker where db_strTicker = @str_ticker
	else
		return 0
else
	set @aid = @ticker_id


declare @spid int
declare @spidx dec(9,2)
declare @price dec(9,2)
set @spid = @tgt_id

declare @start datetime
set @start = dateadd(yy, -5, @today)
print @start


declare @tbl TABLE (id int Identity(1,1), db_dt datetime, mplr dec(9,2), price dec(9,2), sp_idx dec(9,2), mplr_minus_sd dec(9,2) null, mplr_mean dec(9,2) null, mplr_plus_sd dec(9,2) null, price_minus_sd dec(9,2) null, price_mean dec(9,2) null, price_plus_sd dec(9,2) null  )

insert @tbl
select A.db_dt, convert(dec(9,2), A.db_close/B.db_close*100), A.db_close, B.db_close,0,0,0,0,0,0
from tbl_Prices A, tbl_Prices B
where A.db_dt = B.db_dt
and B.db_ticker_id = @spid
and A.db_ticker_id = @aid
and A.db_dt >= @start
and A.db_dt <= @today

declare @min_mplr dec(9,2)
declare @max_mplr dec(9,2)
declare @sd_mplr dec(9,2)
declare @avg_mplr dec(9,2)

select @avg_mplr=avg(mplr), @min_mplr=MIN(mplr), @max_mplr=Max(mplr), @sd_mplr=stdev(mplr) from @tbl

declare @t_mplr dec(9,2)
declare @t_mplr_mean dec(9,2)
declare @t_mplr_stdev dec(9,2)

declare @t_price dec(9,2)
declare @t_price_mean dec(9,2)
declare @t_price_stdev dec(9,2)

declare @id_start int
set @id_start = 1

declare @idx int
set @idx=27
while exists (select * from @tbl where id = @idx)
  begin
	select @t_mplr = mplr, @t_mplr = price from @tbl where id = @idx
	
	select @t_mplr_mean = AVG(mplr), @t_mplr_stdev = stdev(mplr),
	@t_price_mean = AVG(price), @t_price_stdev = stdev(price)
	from @tbl where id between @id_start and @idx
	
	update @tbl 
	set mplr_mean=@t_mplr_mean, 
		mplr_minus_sd=@t_mplr_mean-@t_mplr_stdev, 
		mplr_plus_sd=@t_mplr_mean+@t_mplr_stdev,
		price_mean=@t_price_mean, 
		price_minus_sd=@t_price_mean-@t_price_stdev, 
		price_plus_sd=@t_price_mean+@t_price_stdev 		 
	where id = @idx
	
	set @idx=@idx+1
	set @id_start = @id_start+1
  end
  
-- update first 26 rows.
update @tbl
set mplr_mean = A.mplr_mean,
mplr_minus_sd = A.mplr_minus_sd,
mplr_plus_sd  = A.mplr_plus_sd,
price_mean    = A.price_mean,
price_minus_sd  = A.price_minus_sd,
price_plus_sd = A.price_plus_sd
from (select mplr_mean, mplr_minus_sd, mplr_plus_sd, price_mean, price_minus_sd, price_plus_sd from @tbl where id = 27) as A
where id <= 26

 select @spidx=sp_idx, @price=price  from @tbl where id = @idx-1  
 -- select * from @tbl
 --select @avg_mplr as avg_mplr, @min_mplr as min_mplr, @max_mplr as max_mplr, @sd_mplr as sd_mplr, @spidx as SPINDEX, @price as PRICE
  
 -- ***************** Begin freq table { **************** 
 declare @tbl_freq table (id int identity(1,1), freq int null, mult dec(9,2) null, price dec(9,2) null)
 -- prime the table
 insert @tbl_freq
 select 0, 0, 0
 from @tbl
 where id <= 26
 
 update @tbl_freq
 set mult = @min_mplr
 where id=1
 
 update @tbl_freq
 set mult = @max_mplr
 where id=26

 update @tbl_freq
 set mult = (@min_mplr+@max_mplr)/2
 where id=14
 
 declare @t_mult dec(9,2)
 set @t_mult = @min_mplr
 set @idx=2
 while @idx<= 13
   begin
	set @t_mult = @t_mult  + (@avg_mplr - @min_mplr)/13
    update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 update @tbl_freq 
 set mult = @avg_mplr where id=@idx
 set @idx=15
 set @t_mult = @avg_mplr
 while @idx < 26
   begin
	set @t_mult = @t_mult  + (@max_mplr - @avg_mplr)/13
	update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 
 --set price
 update @tbl_freq
 set price = mult *  @spidx / 100
 
 --update freq
 declare @cnt int
 select @cnt = COUNT(*) from @tbl where mplr <= @min_mplr 
 update @tbl_freq 
 set freq = @cnt
 where id=1
 
 declare @curr_mult dec(9,2)
 declare @prev_mult dec(9,2)
 set @idx=2
 while @idx <= 26
   begin
	select @curr_mult = mult from @tbl_freq where id = @idx
	select @prev_mult = mult from @tbl_freq where id = @idx-1
	
	update @tbl_freq 
	set freq = A.CNT_ITEMS
	from ( select COUNT(*) as CNT_ITEMS from @tbl where mplr  between @prev_mult and @curr_mult) as A
	where id = @idx
	
	set @idx=@idx+1
   end
-- select * from @tbl_freq
-- ***************** end freq table } **************** 

declare @ac_38 dec(9,2), @ac_39 dec(9,2), @ac_40 dec(9,2)
declare @ad_39 dec(9,2)

select @ad_39 = MAX(price_mean) from @tbl where id > 26
set @ac_38 = @spidx * @avg_mplr / 100

select @ac_39 = AVG(price) 
from @tbl_freq 
where price > 0 and freq > 11

select @ac_40 = price
from @tbl_freq 
where freq = (select MAX(freq) from @tbl_freq)

declare @af_35 dec(9,2)
declare @ah_35 dec(9,2)

declare @af_36 dec(9,2)
declare @ah_36 dec(9,2)

declare @af_37 dec(9,2)
declare @ah_37 dec(9,2)


if (@ac_38+@ac_39+@ac_40)/3 < @ad_39 
	set @af_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @af_35 = @ad_39

if (@ac_38+@ac_39+@ac_40)/3 > @ad_39 
	set @ah_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @ah_35 = @ad_39

set @af_36 = @spidx * (@avg_mplr-@sd_mplr) / 100
set @ah_36 = @spidx * (@avg_mplr+@sd_mplr) / 100

set @af_37 = @spidx * @min_mplr  / 100
set @ah_37 = @spidx * @max_mplr  / 100

/*
select @ac_38 as AC38, @ac_39 as AC39, @ac_40 as AC40, @ad_39 as AD39
select @af_35  as AF35, @ah_35 as AH35
select @af_36 as AF36, @ah_36 as AH36 
select @af_37 as AF37, @ah_37 as AH37 
*/
-- final table
declare @af_38 dec(9,2)
declare @ah_38 dec(9,2)

declare @af_39 dec(9,2)
declare @ah_39 dec(9,2)

declare @ag_39 dec(9,2)

declare @af_40 dec(9,2)
declare @ah_40 dec(9,2)

set @af_38 = (@af_35 + @af_36 + @af_37 ) /3
set @ah_38 = (@ah_35 + @ah_36 + @ah_37 ) /3

set @af_40 = (@ah_38 - @af_38)/4 + @af_38


set @af_39 = (@af_38 + @af_40) /2
set @ag_39 = (@af_38 + @ah_38) / 2

set @ah_40 = 3*((@ah_38 - @af_38)/4) + @af_38
set @ah_39 = (@ah_38 + @ah_40) /2

/*
select @af_38 as AF38, 0 as XX38, @ah_38 as AH38
select @af_39 as AF38, @ag_39 as AG39, @ah_39 as AH39
select @af_40 as AF40, 0 as XX40, @ah_40 as AH40
*/
declare @freq_rank int

select @freq_rank= case
	when @price > @ah_38 then 7
	when @price > @ah_39 then 6
	when @price > @ah_40 then 5
	when @price > @ag_39 then 4
	when @price > @af_40 then 3
	when @price > @af_39 then 2
	when @price > @af_38 then 1
	else 0
	end

set @ret_price = @price
return @freq_rank


end
GO
/****** Object:  StoredProcedure [dbo].[csp_Get_FiveNum_By_Date]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Get_FiveNum_By_Date]
( 
	@sdt datetime = NULL)
as
begin
/*
EXECUTE [IDToDSN_DKC].[dbo].[csp_Get_FiveNum_By_Date] 
   @sdt = '1-2-2013'
*/

declare @today varchar(20)
set @today = GETDATE()

declare @dt datetime
if @sdt is NULL
	begin
	set @dt = CONVERT(varchar, MONTH(@today)) + '-1-' + CONVERT(varchar, YEAR(@today))
	print @dt
	end
else
	set @dt = @sdt

declare @tbl table (id int identity, ticker varchar(10), freq_rank int null, dt datetime, db_close dec(9,3))
insert @tbl select
'VTI', 0,@dt, 0  insert @tbl select
'VEU', 0,@dt, 0  insert @tbl select
'VNQ', 0,@dt, 0  insert @tbl select
'TIP', 0,@dt, 0  insert @tbl select
'TLT', 0,@dt, 0  insert @tbl select
'IVV', 0,@dt, 0  insert @tbl select
'VO', 0,@dt, 0  insert @tbl select
'VB', 0,@dt, 0  insert @tbl select
'ACWX', 0,@dt, 0  insert @tbl select
'IYR', 0,@dt, 0  insert @tbl select
'AGG', 0,@dt, 0  insert @tbl select
'VCR', 0,@dt, 0  insert @tbl select
'VDC', 0,@dt, 0  insert @tbl select
'VDE', 0,@dt, 0  insert @tbl select
'VFH', 0,@dt, 0  insert @tbl select
'VHT', 0,@dt, 0  insert @tbl select
'VIS', 0,@dt, 0  insert @tbl select
'VAW', 0,@dt, 0  insert @tbl select
'VGT', 0,@dt, 0  insert @tbl select
'VPU', 0,@dt, 0  insert @tbl select
'IWV', 0,@dt, 0  insert @tbl select
'IJK', 0,@dt, 0  insert @tbl select
'IJT', 0,@dt, 0  insert @tbl select
'EEM', 0,@dt, 0  insert @tbl select
'LQD', 0,@dt, 0  insert @tbl select
'BLV', 0,@dt, 0  insert @tbl select
'EMB', 0,@dt, 0  insert @tbl select
'HYG', 0,@dt, 0  insert @tbl select
'ONEQ',0,@dt, 0 

declare @cnt int
select @cnt = COUNT(*) from @tbl
declare @id int
set @id=1
declare @strtick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

while @id <= @cnt
  begin
	select @strtick = ticker from @tbl where id=@id

	update @tbl
	set freq_rank = FRANK, dt = FDT, db_close = FCLOSE
	from (	select F.db_rank FRANK, F.db_dt FDT, F.db_close FCLOSE
			from IDToDSN_DKC.dbo.tbl_FiveNum F, IDToDSN_DKC.dbo.tbl_Ticker T 
			where T.db_strTicker = @strtick
			and F.db_ticker_id = T.db_ticker_id
			and F.db_dt  = @dt) as A
	where id = @id

	
	set @id = @id+1
  end
  
  select * from @tbl
  end
  
GO
/****** Object:  StoredProcedure [dbo].[csp_Get_FR_By_Date]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_Get_FR_By_Date]
( 
	@sdt datetime = NULL)
as
begin
declare @today varchar(20)
set @today = GETDATE()

declare @dt datetime
if @sdt is NULL
	begin
	set @dt = CONVERT(varchar, MONTH(@today)) + '-1-' + CONVERT(varchar, YEAR(@today))
	print @dt
	end
else
	set @dt = @sdt

declare @tbl table (id int identity, ticker varchar(10), freq_rank int null, dt datetime, db_close dec(9,3))
insert @tbl select
'VTI', 0,@dt, 0  insert @tbl select
'VEU', 0,@dt, 0  insert @tbl select
'VNQ', 0,@dt, 0  insert @tbl select
'TIP', 0,@dt, 0  insert @tbl select
'TLT', 0,@dt, 0  insert @tbl select
'IVV', 0,@dt, 0  insert @tbl select
'VO', 0,@dt, 0  insert @tbl select
'VB', 0,@dt, 0  insert @tbl select
'ACWX', 0,@dt, 0  insert @tbl select
'IYR', 0,@dt, 0  insert @tbl select
'AGG', 0,@dt, 0  insert @tbl select
'VCR', 0,@dt, 0  insert @tbl select
'VDC', 0,@dt, 0  insert @tbl select
'VDE', 0,@dt, 0  insert @tbl select
'VFH', 0,@dt, 0  insert @tbl select
'VHT', 0,@dt, 0  insert @tbl select
'VIS', 0,@dt, 0  insert @tbl select
'VAW', 0,@dt, 0  insert @tbl select
'VGT', 0,@dt, 0  insert @tbl select
'VPU', 0,@dt, 0  insert @tbl select
'IWV', 0,@dt, 0  insert @tbl select
'IJK', 0,@dt, 0  insert @tbl select
'IJT', 0,@dt, 0  insert @tbl select
'EEM', 0,@dt, 0  insert @tbl select
'LQD', 0,@dt, 0  insert @tbl select
'BLV', 0,@dt, 0  insert @tbl select
'EMB', 0,@dt, 0  insert @tbl select
'HYG', 0,@dt, 0  insert @tbl select
'ONEQ',0,@dt, 0 

declare @cnt int
select @cnt = COUNT(*) from @tbl
declare @id int
set @id=1
declare @strtick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

while @id <= @cnt
  begin
	select @strtick = ticker from @tbl where id=@id

	update @tbl
	set freq_rank = FRANK, dt = FDT, db_close = FCLOSE
	from (select F.db_freq_rank FRANK, F.db_dt FDT, F.db_close FCLOSE from IDToDSN_DKC.dbo.tbl_Freq_Rank F, IDToDSN_DKC.dbo.tbl_Ticker T 
			where T.db_strTicker = @strtick
			and F.db_ticker_id = T.db_ticker_id
			and F.db_dt  = @dt) as A
	where id = @id

	
	set @id = @id+1
  end
  
  select * from @tbl
  end
  
GO
/****** Object:  StoredProcedure [dbo].[csp_GetActualMonthValues]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[csp_GetActualMonthValues]
(
	@tid int=442,
	@sdt datetime='1-1-2007'
)
as
begin
/*declare @tid int
set @tid = 471
declare @sdt datetime
set @sdt = '1-1-2003'
*/
declare @tbl table(id int identity, mth_start datetime, mth_end datetime, prev_mth_end datetime, prev_mth_close_price dec(9,2), mth_end_price dec(9,2), ret dec(9,5))

insert @tbl
select min(db_dt),null, 0,null,0,0
from tbl_Prices
where db_ticker_id = @tid
and db_dt >= @sdt
group by YEAR(db_dt), MONTH(db_dt)
order by min(db_dt)

update @tbl
set mth_end = MTH_END_DT
from (select max(db_dt) MTH_END_DT
		from tbl_Prices
		where db_ticker_id = @tid
		and db_dt >= @sdt
		group by YEAR(db_dt), MONTH(db_dt)
		) A
where MONTH(mth_start) = MONTH(MTH_END_DT)
and YEAR(mth_start) = YEAR(MTH_END_DT)  


declare @idx int
set @idx = 1

declare @mth_start datetime
declare @prev_mth_end datetime
declare @prev_mth_close_price dec(9,2)

while exists(select * from @tbl where id = @idx)
 begin

	select @mth_start = mth_start from @tbl where id = @idx
	
	select top 1 @prev_mth_end = db_dt
	from tbl_Prices 
	where db_ticker_id = @tid
	and db_dt < @mth_start
	order by db_dt desc
 
	select @prev_mth_close_price = db_close
	from tbl_Prices 
	where db_ticker_id = @tid
	and db_dt = @prev_mth_end

	update @tbl
	set prev_mth_end = @prev_mth_end,prev_mth_close_price = @prev_mth_close_price 
	where id = @idx
	
	set @idx=@idx+1
 end

update @tbl
set mth_end_price = CLS
from (select db_close CLS, db_dt DTE from tbl_Prices where db_ticker_id = @tid) as A
where mth_end = DTE

update @tbl
set ret = (mth_end_price-prev_mth_close_price)/prev_mth_close_price

select * from @tbl
end
GO
/****** Object:  StoredProcedure [dbo].[csp_ReadCSV]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[csp_ReadCSV]
	(
	@filename nvarchar(255),
	@dbDir nvarchar(255)='c:\',
	@cols nvarchar(255) = '*',
	@whereclause nvarchar(255)='1=1',
	@fmtfile nvarchar(255) = 'x.fmt'
	)
AS
SET NOCOUNT ON
declare @sql nvarchar(max)


if @cols = '*'
  set @sql = 'SELECT a.* FROM OPENROWSET( BULK ''' + @dbdir + '\' + @filename + ''',FORMATFILE = ''' + @dbdir + '\' + @fmtfile + '''' + ') AS a '
else
  set @sql = 'SELECT ' + @cols + ' FROM OPENROWSET( BULK ''' + @dbdir + '\' + @filename + ''',FORMATFILE = ''' + @dbdir + '\' + @fmtfile + '''' + ') AS a '
BEGIN TRY
	exec sp_executesql @sql
END TRY
BEGIN CATCH
    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
RETURN








GO
/****** Object:  StoredProcedure [dbo].[csp_ReadCSV_Jet]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create PROCEDURE [dbo].[csp_ReadCSV_Jet]
	(
	@filename nvarchar(255),
	@dbDir nvarchar(255)='c:\',
	@cols nvarchar(255) = '*',
	@whereclause nvarchar(255)='1=1'
	)
AS
SET NOCOUNT ON
declare @sql nvarchar(max)

declare @open_fn nvarchar(512)
set @sql = 'SELECT * FROM OPENROWSET(''Microsoft.Jet.OLEDB.4.0'',''Text;Database=';
set @sql = @sql + @dbDir;
if @cols = '*'
	set @sql = @sql + ';HDR=NO'',''SELECT * FROM [';
else
	set @sql = @sql + ';HDR=YES'',''SELECT ' + @cols + ' FROM [';

set @sql = @sql + @filename + '] where ';
set @sql = @sql + @whereclause + ''')';
/*
set @sql = @sql + @filename + '] ';
set @sql = @sql + ''')';
*/
BEGIN TRY
	--set @sql = 'select * from EXCEL...Main$'
	exec sp_executesql @sql
END TRY
BEGIN CATCH
    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
RETURN








GO
/****** Object:  StoredProcedure [dbo].[csp_ReadXLSTab]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[csp_ReadXLSTab]
	(
	@ssa_filename nvarchar(255),
	@tab nvarchar(255),
	@retval int OUTPUT
	)
AS

/*
USE [IDToDSN_DKC]
GO

DECLARE	@retval int

EXEC	[dbo].[csp_ReadXLSTab]
		@ssa_filename = N'c:\TestUsers_032811.xls',
		@tab = N'Sheet1',
		@retval = @retval OUTPUT
*/

SET NOCOUNT ON
declare @sql nvarchar(4000)

declare @open_fn nvarchar(512)
set @open_fn = ''''+ 'Excel 5.0;Database=' + @ssa_filename + ''''
set @sql = 'select * from OPENROWSET('''
set @sql = @sql +  'Microsoft.Jet.OLEDB.4.0'''
set @sql = @sql +  ',' +  @open_fn
set @sql = @sql +  ',' +  '''select * from ['
set @sql = @sql +  @tab + '$]'''
set @sql = @sql + ')'

print @sql
--set @sql = 'select * from EXCEL...' + @tab + '$'
BEGIN TRY
	--set @sql = 'select * from EXCEL...Main$'

	exec sp_executesql @sql
END TRY
BEGIN CATCH
    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
RETURN











GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_Add]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE  [dbo].[csp_tbl_Prices_Add]
(
		@db_ticker_id int = NULL, 
		@db_volume int = NULL, 
		@db_dt smalldatetime = NULL, 
		@db_close real = NULL, 
		@db_mult real = NULL, 
		@db_avg real = NULL, 
		@db_index real = NULL, 
		@db_rank smallint = NULL, 
		@db_mult_avg_ratio real = NULL, 
		@db_rank_change smallint = NULL, 
		@db_change_rank smallint = NULL, 
		@db_hi_lo smallint = NULL, 
		@db_hi_cnt int = NULL, 
		@db_lo_cnt int = NULL, 
		@db_type smallint = NULL, 

	@retval int output		-- row id
) 
As
	declare @cols nvarchar(1024), @val nvarchar(1024)
	Declare @Comma nvarchar(1)
	set @Comma = N' '
	set @val = ' values ('
	declare @sql nvarchar(4000)

	set @sql = 'insert into dbo.tbl_Prices' + ' ' +  ' (db_ticker_id, db_volume, db_dt, db_close, db_mult, db_avg, db_index, db_rank, db_mult_avg_ratio, db_rank_change, db_change_rank, db_hi_lo, db_hi_cnt, db_lo_cnt, db_type) '
	set @sql = @sql + ' values ( '
	
if ( @db_ticker_id is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_ticker_id' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_volume is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_volume' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_dt is not NULL)
	   BEGIN
			set @sql = @sql +   @Comma + ' @db_dt ' 
			set @Comma = N','
	   END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_close is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_close' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_mult is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_mult' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_avg is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_avg' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_index is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_index' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_rank is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_rank' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_mult_avg_ratio is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_mult_avg_ratio' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_rank_change is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_rank_change' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_change_rank is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_change_rank' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_hi_lo is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_hi_lo' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_hi_cnt is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_hi_cnt' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_lo_cnt is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_lo_cnt' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_type is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_type' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 



	set @sql = @sql + ' ) '

	exec sp_executesql @sql,
	N'@db_ticker_id int,
@db_volume int,
@db_dt smalldatetime,
@db_close real,
@db_mult real,
@db_avg real,
@db_index real,
@db_rank smallint,
@db_mult_avg_ratio real,
@db_rank_change smallint,
@db_change_rank smallint,
@db_hi_lo smallint,
@db_hi_cnt int,
@db_lo_cnt int,
@db_type smallint',
	@db_ticker_id,
@db_volume,
@db_dt,
@db_close,
@db_mult,
@db_avg,
@db_index,
@db_rank,
@db_mult_avg_ratio,
@db_rank_change,
@db_change_rank,
@db_hi_lo,
@db_hi_cnt,
@db_lo_cnt,
@db_type

set @retval=@@IDENTITY

GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_Delete]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[csp_tbl_Prices_Delete]
(
	@db_row_id int=NULL,
	@retval int output		
) 
As
	if @db_row_id IS NULL
	begin
		raiserror ('Please provide a key to delete a record in tbl_Prices.', 16, 1)
		return
	end

	

	Declare @sql nvarchar(4000)

	set @sql = N'delete from dbo.tbl_Prices' + ' ' + ' where db_row_id = @db_row_id '
	set @sql = @sql + ' ' + ' ' 

	exec @retval = sp_executesql @sql,
	N'@db_row_id int ',
	@db_row_id

	select @retval = @@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_Delete_Where]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE  [dbo].[csp_tbl_Prices_Delete_Where]
(
	@whereclause nvarchar(3000) = NULL,
	@db_Year int=-1,
	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N' '

	if @whereclause IS NULL
		BEGIN
			set @sql = N'delete from dbo.tbl_Prices'
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
		END
	else
		BEGIN
			set @sql = N'delete from dbo.tbl_Prices'			
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
			set @sql = @sql + ' where '			
			set @sql = @sql + @whereclause
		END
	exec sp_executesql @sql
	select @retval = @@ROWCOUNT


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_GetByID]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[csp_tbl_Prices_GetByID]
(
	@db_row_id int 
)
as
	if @db_row_id IS NULL
	begin
		raiserror ('Please provide a key to query tbl_Prices.', 16, 1)
		return -101
	end

	

	Declare @cmd nvarchar(4000)

	set @cmd = N'select db_row_id, db_ticker_id, db_volume, db_dt, db_close, db_mult, db_avg, db_index, db_rank, db_mult_avg_ratio, db_rank_change, db_change_rank, db_hi_lo, db_hi_cnt, db_lo_cnt, db_type '
	set @cmd = @cmd + N' from dbo.tbl_Prices' + ' '
	set @cmd = @cmd + N' where db_row_id = @db_row_id '
	set @cmd = @cmd + ' '
	exec sp_executesql @cmd,
	N'@db_row_id int ',
	@db_row_id


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_List]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[csp_tbl_Prices_List]
(
	@cols nvarchar(2000) = NULL,
	
	@whereclause nvarchar(2000) = NULL

)
as
	Declare @sql nvarchar(4000)
	if @cols IS NULL
	BEGIN
	
		if @whereclause IS NULL
			BEGIN
				set @sql = N'select * from dbo.tbl_Prices'
			END
		else
			BEGIN
				Set @sql = N'select * from dbo.tbl_Prices where ' + @whereclause
			END
	END
	else
	BEGIN
		if @whereclause IS NULL
			BEGIN
				set @sql = N'select  ' + @cols + ' from dbo.tbl_Prices'
			END
		else
			BEGIN

				Set @sql = N'select '
				Set @sql = @sql + @cols
				set @sql = @sql + ' from dbo.tbl_Prices where ' + @whereclause
			END
	END
	exec sp_executesql @sql


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Prices_Update]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE  [dbo].[csp_tbl_Prices_Update]
(

		@db_row_id int  = NULL, 
		@db_ticker_id int = NULL, 
		@db_volume int = NULL, 
		@db_dt smalldatetime = NULL, 
		@db_close real = NULL, 
		@db_mult real = NULL, 
		@db_avg real = NULL, 
		@db_index real = NULL, 
		@db_rank smallint = NULL, 
		@db_mult_avg_ratio real = NULL, 
		@db_rank_change smallint = NULL, 
		@db_change_rank smallint = NULL, 
		@db_hi_lo smallint = NULL, 
		@db_hi_cnt int = NULL, 
		@db_lo_cnt int = NULL, 
		@db_type smallint = NULL, 

	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N' '

	set @sql = N'update dbo.tbl_Prices' + ' '  + ' set '

 if @db_row_id is NULL 
    begin 
     	raiserror ('Please provide a key to update a record in tbl_Prices.', 16, 1) 
     	return -101 
    end 
if ( @db_ticker_id is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_ticker_id =  @db_ticker_id '  
			set @Comma = N','
		  END
if ( @db_volume is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_volume =  @db_volume '  
			set @Comma = N','
		  END
if ( @db_dt = '1/1/1900') 
	   BEGIN
			set @sql = @sql + @Comma + N' db_dt = NULL ' 
			set @Comma = N','
		 END
else
if ( @db_dt is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_dt = @db_dt ' 
			set @Comma = N','
		 END
if ( @db_close is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_close =  @db_close '  
			set @Comma = N','
		  END
if ( @db_mult is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_mult =  @db_mult '  
			set @Comma = N','
		  END
if ( @db_avg is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_avg =  @db_avg '  
			set @Comma = N','
		  END
if ( @db_index is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_index =  @db_index '  
			set @Comma = N','
		  END
if ( @db_rank is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_rank =  @db_rank '  
			set @Comma = N','
		  END
if ( @db_mult_avg_ratio is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_mult_avg_ratio =  @db_mult_avg_ratio '  
			set @Comma = N','
		  END
if ( @db_rank_change is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_rank_change =  @db_rank_change '  
			set @Comma = N','
		  END
if ( @db_change_rank is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_change_rank =  @db_change_rank '  
			set @Comma = N','
		  END
if ( @db_hi_lo is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_hi_lo =  @db_hi_lo '  
			set @Comma = N','
		  END
if ( @db_hi_cnt is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_hi_cnt =  @db_hi_cnt '  
			set @Comma = N','
		  END
if ( @db_lo_cnt is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_lo_cnt =  @db_lo_cnt '  
			set @Comma = N','
		  END
if ( @db_type is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_type =  @db_type '  
			set @Comma = N','
		  END


	set @sql = @sql + N' where db_row_id = ' +  CONVERT(nvarchar, @db_row_id)

	exec sp_executesql @sql,
	N'@db_ticker_id int,
@db_volume int,
@db_dt smalldatetime,
@db_close real,
@db_mult real,
@db_avg real,
@db_index real,
@db_rank smallint,
@db_mult_avg_ratio real,
@db_rank_change smallint,
@db_change_rank smallint,
@db_hi_lo smallint,
@db_hi_cnt int,
@db_lo_cnt int,
@db_type smallint',
	@db_ticker_id,
@db_volume,
@db_dt,
@db_close,
@db_mult,
@db_avg,
@db_index,
@db_rank,
@db_mult_avg_ratio,
@db_rank_change,
@db_change_rank,
@db_hi_lo,
@db_hi_cnt,
@db_lo_cnt,
@db_type


	select @retval = @@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_Add]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE  [dbo].[csp_tbl_Ticker_Add]
(
		@db_ticker_id int = NULL, 
		@db_strTicker nvarchar(50)=NULL,

	@retval int output		-- row id
) 
As
	declare @cols nvarchar(1024), @val nvarchar(1024)
	Declare @Comma nvarchar(1)
	set @Comma = N' '
	set @val = ' values ('
	declare @sql nvarchar(4000)

	set @sql = 'insert into dbo.tbl_Ticker' + ' ' +  ' (db_ticker_id, db_strTicker) '
	set @sql = @sql + ' values ( '
	
if ( @db_ticker_id is not NULL)
  BEGIN
			set @sql = @sql + @Comma + ' @db_ticker_id' 
			set @Comma = N','
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 

if ( @db_strTicker is not NULL)
	   BEGIN
			set @sql = @sql +   @Comma + ' @db_strTicker ' 
			set @Comma = N','
	   END
 else 
   BEGIN 
     set @sql = @sql + @Comma + ' DEFAULT ' 
     set @Comma = N',' 
   END 



	set @sql = @sql + ' ) '

	exec sp_executesql @sql,
	N'@db_ticker_id int,
@db_strTicker nvarchar(50)',
	@db_ticker_id,
@db_strTicker

set @retval=@@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_Delete]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[csp_tbl_Ticker_Delete]
(
	@db_ticker_id int=NULL,
	@retval int output		
) 
As
	if @db_ticker_id IS NULL
	begin
		raiserror ('Please provide a key to delete a record in tbl_Ticker.', 16, 1)
		return
	end

	

	Declare @sql nvarchar(4000)

	set @sql = N'delete from dbo.tbl_Ticker' + ' ' + ' where db_ticker_id = @db_ticker_id '
	set @sql = @sql + ' ' + ' ' 

	exec @retval = sp_executesql @sql,
	N'@db_ticker_id int ',
	@db_ticker_id

	select @retval = @@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_Delete_Where]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE  [dbo].[csp_tbl_Ticker_Delete_Where]
(
	@whereclause nvarchar(3000) = NULL,
	@db_Year int=-1,
	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N' '

	if @whereclause IS NULL
		BEGIN
			set @sql = N'delete from dbo.tbl_Ticker'
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
		END
	else
		BEGIN
			set @sql = N'delete from dbo.tbl_Ticker'			
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
			set @sql = @sql + ' where '			
			set @sql = @sql + @whereclause
		END
	exec sp_executesql @sql
	select @retval = @@ROWCOUNT


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_GetByID]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[csp_tbl_Ticker_GetByID]
(
	@db_ticker_id int 
)
as
	if @db_ticker_id IS NULL
	begin
		raiserror ('Please provide a key to query tbl_Ticker.', 16, 1)
		return -101
	end

	

	Declare @cmd nvarchar(4000)

	set @cmd = N'select db_ticker_id, db_ticker_id, db_strTicker '
	set @cmd = @cmd + N' from dbo.tbl_Ticker' + ' '
	set @cmd = @cmd + N' where db_ticker_id = @db_ticker_id '
	set @cmd = @cmd + ' '
	exec sp_executesql @cmd,
	N'@db_ticker_id int ',
	@db_ticker_id


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_List]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[csp_tbl_Ticker_List]
(
	@cols nvarchar(2000) = NULL,
	
	@whereclause nvarchar(2000) = NULL

)
as
	Declare @sql nvarchar(4000)
	if @cols IS NULL
	BEGIN
	
		if @whereclause IS NULL
			BEGIN
				set @sql = N'select * from dbo.tbl_Ticker'
			END
		else
			BEGIN
				Set @sql = N'select * from dbo.tbl_Ticker where ' + @whereclause
			END
	END
	else
	BEGIN
		if @whereclause IS NULL
			BEGIN
				set @sql = N'select  ' + @cols + ' from dbo.tbl_Ticker'
			END
		else
			BEGIN

				Set @sql = N'select '
				Set @sql = @sql + @cols
				set @sql = @sql + ' from dbo.tbl_Ticker where ' + @whereclause
			END
	END
	exec sp_executesql @sql


GO
/****** Object:  StoredProcedure [dbo].[csp_tbl_Ticker_Update]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE  [dbo].[csp_tbl_Ticker_Update]
(

		@db_ticker_id int = NULL, 
		@db_strTicker nvarchar(50)=NULL,

	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N' '

	set @sql = N'update dbo.tbl_Ticker' + ' '  + ' set '

 if @db_ticker_id is NULL 
    begin 
     	raiserror ('Please provide a key to update a record in tbl_Ticker.', 16, 1) 
     	return -101 
    end 
if ( @db_ticker_id is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_ticker_id =  @db_ticker_id '  
			set @Comma = N','
		  END
if ( @db_strTicker is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N' db_strTicker = @db_strTicker ' 
			set @Comma = N','
		 END


	set @sql = @sql + N' where db_ticker_id = ' +  CONVERT(nvarchar, @db_ticker_id)

	exec sp_executesql @sql,
	N'@db_ticker_id int,
@db_strTicker nvarchar(50)',
	@db_ticker_id,
@db_strTicker


	select @retval = @@ROWCOUNT

GO
/****** Object:  StoredProcedure [dbo].[csp_Update_Multiplier]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[csp_Update_Multiplier]
(
	@step_id int=1,
	@s_date datetime  = '1-1-2001',
	@typ smallint
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
	and db_type=@typ
	goto Done
  end

--Step 3
if @step_id=3
  begin
	update tbl_Prices
		set db_index = convert(dec(9,2), db_close/db_avg * 100.00)
	where db_type=@typ
	goto Done
 end


--Step 4
if @step_id=4
  begin
	update tbl_Prices
	set db_mult_avg_ratio = convert(dec(9,2),db_mult / db_avg)
	where db_type=@typ
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
--and db_dt between '1-1-2001' and '1-2-2004'
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
				and db_type=@typ
				group by db_ticker_id) A
		where tbl_Prices.db_ticker_id = A.db_ticker_id
		and tbl_Prices.db_dt = @sp_dt
		and tbl_Prices.db_type=@typ
	  end

	--Step 5
	if @step_id=5
		update tbl_Prices
		set db_rank = Rank
		from (select T.db_ticker_id, P.db_dt, rank() over (order by db_index desc) as Rank
		from tbl_Prices P, tbl_Ticker T
		where P.db_ticker_id = T.db_ticker_id
		and T.db_type=@typ and db_dt = @sp_dt) as X
		where tbl_Prices.db_ticker_id = X.db_ticker_id and tbl_Prices.db_dt = X.db_dt and tbl_Prices.db_type=@typ


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
			and P2.db_dt = @sp_dt
			and P1.db_type=@typ and P2.db_type=@typ) as X
			where tbl_Prices.db_ticker_id = X.db_ticker_id
			and tbl_Prices.db_dt = X.db_dt
			and tbl_Prices.db_type=@typ

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
		and db_dt = @sp_dt and P.db_type=@typ and T.db_type=@typ) as X
		where tbl_Prices.db_ticker_id = X.db_ticker_id and tbl_Prices.db_dt = X.db_dt and tbl_Prices.db_type=@typ
		
	--Step 8
		EXEC [dbo].[sp_CalcHiLow] @sp_dt

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


/***************************************/
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

GO
/****** Object:  StoredProcedure [dbo].[sp_Calc_Portfolio]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_Calc_Portfolio]
AS
BEGIN
	SET NOCOUNT ON;
/*
EXEC	IDToDSN_DKC.[dbo].[csp_Calc_Diff]
*/
/*
EXEC	IDToDSN_DKC.[dbo].[sp_GenSignals]
EXEC	IDToDSN_DKC.[dbo].[sp_Calc_Portfolio]
SELECT     strTicker, convert(char(2),month(bdate)) + '-' + convert(char(2),day(bdate)) + '-' + convert(char(4),year(bdate)) as bdt, convert(char(2),month(sdate)) + '-' + convert(char(2),day(sdate)) + '-' + convert(char(4),year(sdate)) as sdt, nshares, bprice, sprice, buy_amount, nshares*sprice as sell_amount, nshares*sprice-buy_amount as profit
FROM       IDToDSN_DKC.[dbo].tbl_Trades
ORDER BY bdate, sdate, strTicker
*/
update tbl_Trades set nshares = 0, buy_amount = 0 

declare @s_dt datetime
declare @e_dt datetime

--set @s_dt = '1-1-2005'
select top 1 @s_dt = convert(datetime, dateadd(yy,-1, bdate))
from tbl_Trades
order by bdate asc

select @e_dt = max(db_dt) from tbl_Prices where db_ticker_id = 538

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
	print '-------------------------------------'
	print @sp_dt
	if year(@sp_dt) < year(@s_dt)+1 goto Skip

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
	and nshares > 0

	select @s_nNewSells$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where sdate = @sp_dt
	and ticker_id = db_ticker_id
	and db_dt = sdate

	if @s_nNewBuys > 0
	  begin
		select @s_CurrentHoldings$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0)) + @cash_$ + @s_nNewSells$
		from tbl_Trades, tbl_Prices
		where ticker_id = db_ticker_id
		and db_dt = @sp_dt
		and (sdate > @sp_dt or bdate=sdate)
		and bdate < @sp_dt
		print 'CurrentHolding=' + convert(varchar, @s_CurrentHoldings$)

		select @sum_bprice=sum(bprice)	from tbl_Trades where bdate = @sp_dt
		print 'sum price = ' + convert(varchar, @sum_bprice)
		print 'cash available = ' + convert(varchar, @cash_$ + @s_nNewSells$ - (@cash_Allocn * @start_$))
		set @nshares = (@cash_$ + @s_nNewSells$ - (@cash_Allocn * @start_$) ) / @sum_bprice 
		if @nshares > 0 
			begin
				print 'Buy shares = ' + convert(varchar, @nshares)
				update tbl_Trades set nshares = @nshares, buy_amount = @nshares*bprice where bdate = @sp_dt
			end

		declare @iid int
		set @iid=0
		declare @bamt dec(12,2)
		declare @bprice dec(12,2)
		declare @tick_id int
		declare @adj_nshares int
		if @nshares > 0
			while exists (select * from tbl_Trades where iid > @iid and bdate = @sp_dt)
				begin
					--print 'Processing iid=[' + convert(varchar, @iid) + '], current nshares = ' + convert(varchar, @nshares)
					select top 1 @iid=iid, @tick_id = ticker_id, @bprice = bprice, @bamt=buy_amount from tbl_Trades where iid > @iid and bdate = @sp_dt order by iid
					print 'attempt adjusting tick id = ' + convert(varchar, @tick_id)
					SELECT     @bamt = SUM(buy_amount)
					FROM         tbl_Trades
					WHERE     (bBuy = 1) AND (nshares > 0) and ticker_id = @tick_id
					GROUP BY ticker_id

					print 'bAmt for iid=[' + convert(varchar, @iid) + '], bAmt=[' +  convert(varchar, @bamt) + ']'
					if @bamt > .5 * @s_CurrentHoldings$
					begin
						set @adj_nshares = .5 * @s_CurrentHoldings$ / @bprice
						if @adj_nshares < @nshares set @nshares = @adj_nshares
						print 'nshares = ' + convert(varchar,@nshares)
						update tbl_Trades
						set nShares = @nshares, buy_amount = @nshares*bprice
						where iid = @iid
						and bdate = @sp_dt
						if @@ROWCOUNT > 0 print 'Adjusted shares for iid=[' + convert(varchar, @iid) + '], nshares=[' + convert(varchar, @nshares) + ']' 
					end
				end		
	  end

	select @s_nNewBuys$ = coalesce(sum(buy_amount),0)
	from tbl_Trades
	where bdate = @sp_dt
	and nshares > 0

	set @cash_$ = @cash_$ + @s_nNewSells$ - @s_nNewBuys$
	print 'Cash+NewSell-NewBuy = [' + convert(varchar, @cash_$) + ']'
	select @tlt_close = db_close from tbl_Prices where db_ticker_id = @TLTID and db_dt = @sp_dt

	if @prev_tlt_close <=0	set @prev_tlt_close =  @tlt_close
	--set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * (1-(@prev_tlt_close/@tlt_close)))
	set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * .03/365)
	set @prev_tlt_close = @tlt_close

	print convert(varchar, @sp_dt) + ', nBuys=' + convert(varchar, @s_nNewBuys) + ', nSells=' + convert(varchar, @s_nNewSells) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', Sell$=' + convert(varchar, @s_nNewSells$) + ', Cash = ' + convert(varchar, @cash_$)

	select @s_CurrentHoldings$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where ticker_id = db_ticker_id
	and db_dt = @sp_dt
	and (sdate > @sp_dt or bdate=sdate)
	and bdate <= @sp_dt


	set @pv$ = @cash_$ + @s_CurrentHoldings$
	print 'Total --> ' + convert(varchar, @sp_dt) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', CurrentHolding=' + convert(varchar, @s_CurrentHoldings$) + ', Portfolio = ' + convert(varchar, @pv$)

	insert @port
	select @sp_dt,  @cash_$, @s_nNewBuys, @s_nNewSells, @s_CurrentHoldings$, @pv$, @Cash_TLT_Portfolio, @spbh,OpenTrades, OpenProfitTrades, Gain, OpenLossTrades, Loss
	, 0
	from
	(select count(*) as OpenTrades from tbl_Trades where bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) AS A,
	(select count(*) as OpenProfitTrades, coalesce(sum(gain*nshares),0) as Gain from tbl_Trades where gain > 0.0 and bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) as B,
	(select count(*) as OpenLossTrades, coalesce(sum(gain*nshares),0) as Loss from tbl_Trades where gain <= 0.0 and bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) as C
	--,(select coalesce(sum(nshares*(db_close - bprice)),0) as NetProfit from tbl_Trades, tbl_Prices where ticker_id = db_ticker_id and db_dt = @sp_dt and bdate <= @sp_dt) as D
Skip:
	Fetch next from cDSS
	into @sp_dt, @sp_close

end
close cDSS
Deallocate cDSS
--(dt datetime, cash dec(12,2), nBuys int, nSells int, CurrentHolding$ dec(12,2), PortFolioValue dec(12,2), Cash_TLT_Portfolio dec(12,2), SPBuyandHold dec(12,2),OpenTrades int, OpenProfitTrades int, Gain dec(12,2), OpenLossTrades int, Loss dec(12,2), NetProfit$ dec(12,2) )
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
cash, nBuys, nSells, CurrentHolding$, PortFolioValue, Cash_TLT_Portfolio, SPBuyandHold, OpenTrades, OpenProfitTrades, Gain, OpenLossTrades, Loss, NetProfit$
from @port
END




GO
/****** Object:  StoredProcedure [dbo].[sp_Calc_Portfolio_Fixed_Shares]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_Calc_Portfolio_Fixed_Shares]
AS
BEGIN
	SET NOCOUNT ON;
/*
EXEC	IDToDSN_DKC.[dbo].[csp_Calc_Diff]
*/
/*
EXEC	IDToDSN_DKC.[dbo].[sp_GenSignals]
EXEC	IDToDSN_DKC.[dbo].[sp_Calc_Portfolio_Fixed_Shares]
SELECT     strTicker, convert(char(2),month(bdate)) + '-' + convert(char(2),day(bdate)) + '-' + convert(char(4),year(bdate)) as bdt, convert(char(2),month(sdate)) + '-' + convert(char(2),day(sdate)) + '-' + convert(char(4),year(sdate)) as sdt, nshares, bprice, sprice, buy_amount, nshares*sprice as sell_amount, nshares*sprice-buy_amount as profit
FROM       IDToDSN_DKC.[dbo].tbl_Trades
ORDER BY bdate, sdate, strTicker
*/
update tbl_Trades set nshares = 0, buy_amount = 0 

declare @s_dt datetime
declare @e_dt datetime

--set @s_dt = '1-1-2005'
select top 1 @s_dt = convert(datetime, dateadd(yy,-1, bdate))
from tbl_Trades
order by bdate asc

select @e_dt = max(db_dt) from tbl_Prices where db_ticker_id = 538

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
	print '-------------------------------------'
	print @sp_dt
	if year(@sp_dt) < year(@s_dt)+1 goto Skip

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
	and nshares > 0

	select @s_nNewSells$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where sdate = @sp_dt
	and ticker_id = db_ticker_id
	and db_dt = sdate

	if @s_nNewBuys > 0
	  begin
		select @sum_bprice=sum(bprice)	from tbl_Trades where bdate = @sp_dt
		print 'sum price = ' + convert(varchar, @sum_bprice)
		set @nshares = 100 --(@cash_$ + @s_nNewSells$ - (@cash_Allocn * @start_$) ) / @sum_bprice 
		print 'Buy shares = ' + convert(varchar, @nshares)
		update tbl_Trades set nshares = @nshares, buy_amount = @nshares*bprice where bdate = @sp_dt
	  end

	select @s_nNewBuys$ = coalesce(sum(buy_amount),0)
	from tbl_Trades
	where bdate = @sp_dt

	set @cash_$ = @cash_$ + @s_nNewSells$ - @s_nNewBuys$
print 'Cash+NewSell-NewBuy = [' + convert(varchar, @cash_$) + ']'
	select @tlt_close = db_close from tbl_Prices where db_ticker_id = @TLTID and db_dt = @sp_dt

	if @prev_tlt_close <=0	set @prev_tlt_close =  @tlt_close
	--set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * (1-(@prev_tlt_close/@tlt_close)))
	set @Cash_TLT_Portfolio = @Cash_TLT_Portfolio + (@cash_$ * .03/365)
	set @prev_tlt_close = @tlt_close

	print convert(varchar, @sp_dt) + ', nBuys=' + convert(varchar, @s_nNewBuys) + ', nSells=' + convert(varchar, @s_nNewSells) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', Sell$=' + convert(varchar, @s_nNewSells$) + ', Cash = ' + convert(varchar, @cash_$)

	select @s_CurrentHoldings$ = convert(dec(12,2),coalesce(sum(db_close * nshares),0))
	from tbl_Trades, tbl_Prices
	where ticker_id = db_ticker_id
	and db_dt = @sp_dt
	and (sdate > @sp_dt or bdate=sdate)
	and bdate <= @sp_dt


	set @pv$ = @cash_$ + @s_CurrentHoldings$
	print 'Total --> ' + convert(varchar, @sp_dt) + ', Buy$=' + convert(varchar, @s_nNewBuys$) + ', CurrentHolding=' + convert(varchar, @s_CurrentHoldings$) + ', Portfolio = ' + convert(varchar, @pv$)

	insert @port
	select @sp_dt,  @cash_$, @s_nNewBuys, @s_nNewSells, @s_CurrentHoldings$, @pv$, @Cash_TLT_Portfolio, @spbh,OpenTrades, OpenProfitTrades, Gain, OpenLossTrades, Loss
	, 0
	from
	(select count(*) as OpenTrades from tbl_Trades where bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) AS A,
	(select count(*) as OpenProfitTrades, coalesce(sum(gain*nshares),0) as Gain from tbl_Trades where gain > 0.0 and bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) as B,
	(select count(*) as OpenLossTrades, coalesce(sum(gain*nshares),0) as Loss from tbl_Trades where gain <= 0.0 and bdate <= @sp_dt and sdate > @sp_dt and nshares > 0) as C
	--,(select coalesce(sum(nshares*(db_close - bprice)),0) as NetProfit from tbl_Trades, tbl_Prices where ticker_id = db_ticker_id and db_dt = @sp_dt and bdate <= @sp_dt) as D
Skip:
	Fetch next from cDSS
	into @sp_dt, @sp_close

end
close cDSS
Deallocate cDSS
--(dt datetime, cash dec(12,2), nBuys int, nSells int, CurrentHolding$ dec(12,2), PortFolioValue dec(12,2), Cash_TLT_Portfolio dec(12,2), SPBuyandHold dec(12,2),OpenTrades int, OpenProfitTrades int, Gain dec(12,2), OpenLossTrades int, Loss dec(12,2), NetProfit$ dec(12,2) )
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
cash, nBuys, nSells, CurrentHolding$, PortFolioValue, Cash_TLT_Portfolio, SPBuyandHold, OpenTrades, OpenProfitTrades, Gain, OpenLossTrades, Loss, NetProfit$
from @port
END




GO
/****** Object:  StoredProcedure [dbo].[sp_CalcHiLow]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_CalcHiLow]
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









GO
/****** Object:  StoredProcedure [dbo].[sp_CalcTrades_Diff]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_CalcTrades_Diff]
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

declare @trades table (iid int identity, id int, ticker_id int, strTicker nvarchar(50), bdate datetime, bprice dec(9,2), brank int, bBuy tinyint, sdate datetime null, sprice dec(9,2) null, srank int null, gain dec(9,2) null, ratio dec(9,2), sratio dec(9,2),typ smallint, cnt int, sp_rank int, mean_sp_rank int, nshares int, buy_amount dec(9,2))
declare @tops table (id int identity, strTicker nvarchar(50), ticker_id int, p2rank int, p1rank int, p2close dec(9,2), p1close dec(9,2), diff int, dt1 smalldatetime, dt2 smalldatetime)

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
			select A.id, A.ticker_id, A.strTicker, A.dt2, A.p2close, A.p2rank, 1, null, null, null, null,0,0,0,0,0,0,0,0
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
select strTicker, bdate, sdate, bprice, sprice, brank, srank from @trades order by strTicker, bdate 

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














GO
/****** Object:  StoredProcedure [dbo].[sp_GenSignals]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE procedure [dbo].[sp_GenSignals]
(
	@typ smallint
)
as
begin

set nocount on

declare @s_dt datetime
declare @e_dt datetime


-- To gen signals starting 1-1-2004, set the 
-- s_dt = 1-1-2003. This is because we need
-- 200 data points for 200 day MA.
set @s_dt = '1-1-2011'
select @e_dt = getdate()

declare @SPID int
set @SPID = 538 -- S&P Index ticker id
declare @SPYID int
set @SPYID = 442
declare @TLTID int
set @TLTID = 471

declare @t1 smallint
set @t1=1

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
declare @stk_close dec(9,2)

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
		and db_type=@typ
		print 'SPRank=' + convert(varchar, @sp_rank) + ', MR=' + convert(varchar, @mean_rank)
	  end

	Fetch relative -65 from cDSS
	into @sp_dt_prev, @sp_close, @sp_rank,@spy_tlt_ratio
	--print @sp_dt_prev

	select @MA1 = avg(db_close)
	from tbl_Prices
	where db_ticker_id = @SPYID
	and db_dt between @sp_dt_prev and @sp_dt
	and db_type=@typ

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
	and db_type=@typ

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
			/*
			print '**** Selling all stocks SPY closing below 65 Day MA.' 
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
			and ticker_id <> @TLTID
			*/

			-- get dates for indiv trades MA
			Fetch relative -15 from cDSS
			into @MA1_dt, @sp_close, @sp_rank,@spy_tlt_ratio
		
			Fetch relative 15 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio


			Fetch relative -30 from cDSS
			into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative 30 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			--if not exists (select * from @trades where ticker_id = @TLTID and sdate is null)
				begin
					select @MA1 = avg(db_close)
					from tbl_Prices
					where db_ticker_id = @TLTID
					and db_dt between @MA1_dt and @sp_dt

					select @MA2 = avg(db_close)
					from tbl_Prices
					where db_ticker_id = @TLTID
					and db_dt between @MA2_dt and @sp_dt

					select @stk_close=db_close
					from tbl_Prices
					where db_ticker_id = @TLTID
					and db_dt = @sp_dt
					
					if @stk_close > @MA1 --> @MA2
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

			-- SPY closing below 65 Day MA - so sell if needed
			-- Step thru each open trade to see if MA1 < MA2
			declare cTrades scroll cursor for
			select id, ticker_id, strTicker from @trades where sdate is null and bdate <= @sp_dt

			Open cTrades
			Fetch next from cTrades
			into @id, @tid,@t_strTicker
			print '**** Selling stocks SPY closing below 65 Day MA if Stock closes below 15 day MA' 
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

				select @stk_close=db_close
				from tbl_Prices
				where db_ticker_id = @tid
				and db_dt = @sp_dt
				
				if  @stk_close < @MA1 --< @MA2
					begin
						print '--- SELL A - Ticker=[' + @t_strTicker + '], Price=[' + convert(varchar, @stk_close) + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
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
					print '--- HOLD A - Ticker=[' + @t_strTicker + '], Price=[' + convert(varchar, @stk_close) + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'

				/*close out trades when the ticker is marked inactive 
				Note: Make inactive date equal to the date of the last price
				*/
				update @trades
				set bBuy=0, 
				sprice = db_close,
				sdate = db_dt,
				srank = db_rank,
				gain = db_close - bprice,
				sratio = db_mult / db_avg
				from tbl_Prices, tbl_Ticker
				where ticker_id = tbl_Prices.db_ticker_id
				and ticker_id = tbl_Ticker.db_ticker_id
				and sdate is null
				and typ=1
				and (tbl_Ticker.db_inactive_dt is not null and tbl_Ticker.db_inactive_dt <= @sp_dt)
				and tbl_Prices.db_dt = tbl_Ticker.db_inactive_dt
				and tbl_Prices.db_type=@typ
				and ticker_id = @tid

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
		print ' *** SPY close > 65 Day MA - so sell TLT and buy stocks'
		begin
			Fetch relative -30 from cDSS
			into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			Fetch relative 30 from cDSS
			into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

			select @MA2 = avg(db_close)
			from tbl_Prices
			where db_ticker_id = @TLTID
			and db_dt between @MA2_dt and @sp_dt

			select @stk_close=db_close
			from tbl_Prices
			where db_ticker_id = @TLTID
			and db_dt = @sp_dt
			
			if @stk_close < @MA2
				begin
					print '*** TLT SOLD if held'
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
			else
				print '*** HOLD TLT for now - its above 60 day MA'
		end

	if @t1=1
		begin
			insert @tops
			select T.db_ticker_id, T.db_strticker, db_dt, db_close, db_rank, 1,db_mult_avg_ratio, @sp_rank, @mean_rank
			from tbl_Prices P, tbl_Ticker T
			where P.db_ticker_id = T.db_ticker_id
			and db_dt = @sp_dt
			and P.db_type=@typ and T.db_type=@typ
			and (T.db_inactive_dt is null or T.db_inactive_dt > @sp_dt)
			--and ( db_rank between 1 and 50 or (db_rank < 75 and db_rank  < (select top 1 0.5*db_rank from tbl_Prices A where A.db_ticker_id = P.db_ticker_id and db_dt < @sp_dt order by db_dt desc) ))
			and ( db_rank between 1 and 50 or (db_rank < 75 and P.db_change_rank <= 10) )
			--and @sp_rank > @mean_rank
			and T.db_addition_dt <= @sp_dt
			and (T.db_inactive_dt is null or T.db_inactive_dt >= @sp_dt )
			order by db_rank asc
		end


	declare cTop25 cursor for
	select ticker_id, rank, strTicker from @tops

	open cTop25
	Fetch next from cTop25
	into @tid, @r, @t_strTicker

	Fetch relative -10 from cDSS
	into @MA1_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative 10 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative -15 from cDSS
	into @MA2_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	Fetch relative 15 from cDSS
	into @sp_dt, @sp_close, @sp_rank,@spy_tlt_ratio

	print ' *** SPY close > 65 Day MA - evaluate each stocks 10 & 15 day MA'
	while @@FETCH_STATUS = 0
	begin

		--if not exists (select * from @trades where ticker_id = @tid and sdate is null)
		begin

			select @MA1 = avg(db_close)
			from tbl_Prices
			where db_ticker_id = @tid
			and db_dt between @MA1_dt and @sp_dt

			select @MA2 = avg(db_close)
			from tbl_Prices
			where db_ticker_id = @tid
			and db_dt between @MA2_dt and @sp_dt

			select @stk_close=db_close
			from tbl_Prices
			where db_ticker_id = @tid
			and db_dt = @sp_dt

			if @MA1  > @MA2
					begin
						print '--- BUY - Ticker=[' + @t_strTicker + '], Price=[' + convert(varchar, @stk_close) + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'
						insert @trades
						select A.id, A.ticker_id, A.strTicker, A.dt, A.price, A.rank, 1, null, null, null, null,ratio,0,typ,0,sp_rank, mean_sp_rank,0,0
						from @tops A
						where ticker_id not in (select ticker_id from @trades where sdate is null and ticker_id = A.ticker_id)
						and ticker_id = @tid
					end
			else
				print '--- NO BUY - Ticker=[' + @t_strTicker + '], Price=[' + convert(varchar, @stk_close) + '], MA1=[' + convert(varchar, @MA1) + '], MA2=[' + convert(varchar, @MA2) + ']'

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
			and tbl_Prices.db_type=@typ

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
			and tbl_Prices.db_type=@typ

			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices, tbl_Ticker
			where ticker_id = tbl_Prices.db_ticker_id
			and ticker_id = tbl_Ticker.db_ticker_id
			and sdate is null
			and typ=1
			and (tbl_Ticker.db_inactive_dt is not null and tbl_Ticker.db_inactive_dt < @sp_dt)
			and tbl_Prices.db_dt = @sp_dt
			and tbl_Prices.db_type=@typ
			
			/*close out trades when the ticker is marked inactive 
			Note: Make inactive date equal to the date of the last price
			*/
			update @trades
			set bBuy=0, 
			sprice = db_close,
			sdate = db_dt,
			srank = db_rank,
			gain = db_close - bprice,
			sratio = db_mult / db_avg
			from tbl_Prices, tbl_Ticker
			where ticker_id = tbl_Prices.db_ticker_id
			and ticker_id = tbl_Ticker.db_ticker_id
			and sdate is null
			and typ=1
			and (tbl_Ticker.db_inactive_dt is not null and tbl_Ticker.db_inactive_dt <= @sp_dt)
			and tbl_Prices.db_dt = tbl_Ticker.db_inactive_dt
			and tbl_Prices.db_type=@typ
			
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
and tbl_Prices.db_type=@typ

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
and tbl_Prices.db_type=@typ

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
GO
/****** Object:  StoredProcedure [dbo].[sp_getfilenames]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_getfilenames]
(	@dir nvarchar(100)
)
as
BEGIN
--IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
--     DROP TABLE #DirectoryTree;

--CREATE TABLE #DirectoryTree (
--       id int IDENTITY(1,1)
--      ,subdirectory nvarchar(512)
--      ,depth int
--      ,isfile bit);

--INSERT #DirectoryTree (subdirectory,depth,isfile)
exec master.sys.xp_dirtree @dir, 0,1

--select subdirectory from #DirectoryTree
--where subdirectory like @wildcard



end
GO
/****** Object:  StoredProcedure [dbo].[test]    Script Date: 9/25/2016 9:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[test]
AS 
    WAITFOR DELAY '00:00:30'
    SELECT  *
    FROM    sys.sysobjects

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1=hi, 0=low, -1=niether' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tbl_Prices', @level2type=N'COLUMN',@level2name=N'db_hi_lo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1=US Stock, 2=US ETF' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tbl_Prices', @level2type=N'COLUMN',@level2name=N'db_type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1=US Stock, 2=US ETF, 3=Mutual Funds' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tbl_Ticker', @level2type=N'COLUMN',@level2name=N'db_type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Do not use this ticker after this date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tbl_Ticker', @level2type=N'COLUMN',@level2name=N'db_inactive_dt'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Use this ticker only after this date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tbl_Ticker', @level2type=N'COLUMN',@level2name=N'db_addition_dt'
GO
USE [master]
GO
ALTER DATABASE [StockDB] SET  READ_WRITE 
GO
