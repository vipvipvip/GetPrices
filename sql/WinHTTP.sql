DECLARE @url varchar(300)  
DECLARE @win int 
DECLARE @hr  int 
DECLARE @text varchar(8000)
CREATE TABLE #text(html text NULL) /* comment out to use @text variable for small data */

SET @url = 'http://www.sqlteam.com/Forums/topic.asp?TOPIC_ID=18425'
--SET @url = 'https://www.censeoonline.com/360/index.asp'

EXEC @hr=sp_OACreate 'WinHttp.WinHttpRequest.5.1',@win OUT 

EXEC @hr=sp_OAMethod @win, 'Open',NULL,'GET',@url,'false'
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

EXEC @hr=sp_OAMethod @win,'Send'
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

/* comment out below to use @text variable for small data */
INSERT #text(html)
EXEC @hr=sp_OAGetProperty @win,'ResponseText'
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win

--EXEC @hr=sp_OAGetProperty @win,'ResponseText',@text OUTPUT
--IF @hr <> 0 EXEC sp_OAGetErrorInfo @win
--print @text

EXEC @hr=sp_OADestroy @win 
IF @hr <> 0 EXEC sp_OAGetErrorInfo @win 

select * from #text

drop table #text
go

/*
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO

SELECT * from [IDToDSN_DKC].[dbo].[GetHttp] (
   'http://www.sqlteam.com/Forums/topic.asp?TOPIC_ID=18425')

alter function GetHttp
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
*/

/*
--here's an xml example 


CREATE PROCEDURE get_ebrif_data @url varchar(500)
AS
SET NOCOUNT ON

DECLARE @object int
DECLARE @hr int
DECLARE @idoc int
DECLARE @source varchar(255)
DECLARE @description varchar(255)
DECLARE @xml varchar(8000)

DECLARE @ebrif_data TABLE (
        message varchar(100) ,
        ersc    varchar(10)  ,
        erst    varchar(10)  ,
        elid    varchar(10)  ,
        epww    varchar(10)  ,
        etrn    char(1)      ,
        etol    char(1)      ,
        ecap    char(1)      ,
        erty    char(1)      ,
        eaux    char(1)      ,
        escv    char(1)      ,
        epan    varchar(18)  ,
        eexm    char(2)      ,
        eexy    char(2)      ,
        estm    char(2)      ,
        esty    char(2)      ,
        eiss    char(1)      ,
        escs    char(3)      ,
        eval    char(4)      ,
        eotr    varchar(18)  ,
        ecur    char(3)      ,
        eref    varchar(25)  ,
        epac    varchar(11)  ,
        esta    char(1)      ,
        eaut    varchar(8)   ,
        eeam    varchar(100) ,
        eerr    char(4)      ,
        edat    char(8)      ,
        etim    char(6)      )


EXEC @hr = sp_OACreate 'WinHttp.WinHttpRequest.5', @object 
OUT
IF @hr <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object
    RETURN 
END

EXEC @hr = sp_OAMethod @object,'Open', NULL, 'GET', 
@url , 'false'
IF @hr <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object
    RETURN 
END

EXEC @hr = sp_OAMethod @object,'Send'
IF @hr <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object
    RETURN 
END

EXEC @hr = sp_OAGetProperty @object, 'ResponseText', @xml 
OUT
IF @hr <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object
    RETURN 
END

EXEC @hr = sp_OADestroy @object
IF @hr <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object
    RETURN 
END

SELECT @xml = RIGHT(@xml,(len(@xml)-38)) /* Trim XML version tag */

EXEC sp_xml_preparedocument @idoc OUTPUT, @xml

INSERT @ebrif_data
SELECT * FROM OPENXML (@idoc,'/root',2)
WITH(   message varchar(100) './logon/message',
        ersc    varchar(10)  './auth/MerchantData/ersc',
        erst    varchar(10)  './auth/MerchantData/erst',
        elid    varchar(10)  './auth/MerchantData/elid',
        epww    varchar(10)  './auth/MerchantData/epww',
        etrn    char(1)      './auth/TransactionData/etrn',
        etol    char(1)      './auth/TransactionData/etol',
        ecap    char(1)      './auth/TransactionData/ecap',
        erty    char(1)      './auth/TransactionData/erty',
        eaux    char(1)      './auth/TransactionData/eaux',
        escv    char(1)      './auth/TransactionData/escv',
        epan    varchar(18)  './auth/TransactionData/CardData/epan',
        eexm    char(2)      './auth/TransactionData/CardData/eexm',
        eexy    char(2)      './auth/TransactionData/CardData/eexy',
        estm    char(2)      './auth/TransactionData/CardData/estm',
        esty    char(2)      './auth/TransactionData/CardData/esty',
        eiss    char(1)      './auth/TransactionData/CardData/eiss',
        escs    char(3)      './auth/TransactionData/CardData/escs',
        eval    char(4)      './auth/TransactionData/eval',
        eotr    varchar(18)  './auth/TransactionData/eotr',
        ecur    char(3)      './auth/TransactionData/ecur',
        eref    varchar(25)  './auth/TransactionData/eref',
        epac    varchar(11)  './auth/TransactionStatus/epac',
        esta    char(1)      './auth/TransactionStatus/esta',
        eaut    varchar(8)   './auth/TransactionStatus/eaut',
        eeam    varchar(100) './auth/TransactionStatus/eeam',
        eerr    char(4)      './auth/TransactionStatus/eerr',
        edat    char(8)      './auth/TransactionStatus/edat',
        etim    char(6)      './auth/TransactionStatus/etim')      
       
EXEC sp_xml_removedocument @idoc

SELECT * from @ebrif_data

RETURN
go
*/