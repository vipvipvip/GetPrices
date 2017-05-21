Imports System.Data.SqlClient
Imports System.Net
Imports System.IO
Imports System.Data.OleDb



Module GetPrices
    'Private Const URL As String = "http://www2.standardandpoors.com/servlet/Satellite?pagename=spcom/page/DownloadDataTab&dt=<DateField>&indexcode=500"
    'Private Const URL As String = "http://ichart.finance.yahoo.com/table.csv?d=&e=&f=&g=d&a=0&b=22&c=1999&ignore=.csv&s="
    'Private Const URL As String = "http://ichart.finance.yahoo.com/table.csv?ignore=.csv&g=d"
    Private Const URL As String = "http://real-chart.finance.yahoo.com/table.csv?ignore=.csv&g=d"
    Private Const BSE_STK_URL As String = "http://www.bseindia.com/stockinfo/stockprc2_excel.aspx?"
    Private Const BSE_INDEX_URL As String = "http://www.bseindia.com/stockinfo/indices_main_excel.aspx?ind=BSE500&DMY=D"

    Private Const DATADIR As String = "c:\temp\Prices\"
    Private _oDAL As New DAL.NetDB
    Private _sqcSQL As New SqlConnection
    Private _sqcCSV As New OleDbConnection
    Private _sqcPrices As New SqlConnection
    Private g_ticker_id As Integer
    Private g_type As Integer '1=US Stocks, 2=ETF
    Private g_Mode As String
    Private g_Action As Integer
  Private g_startTick As String
  Private g_P1 As String
  Private g_P2 As String
  Private g_Cookie As String

  Dim sd As DateTime = "1-1-2006"
    Dim ed As DateTime = "12-31-2020"
    Dim a, b, c, d, e, f As Integer
    Dim today As DateTime
    Sub Main(ByVal CmdArgs() As String)
        Dim arg As String = ""
        Dim strTicker As String = ""
        Dim i As Integer = 0
        Dim argArr As String()
        Dim dnload As Integer = 1
        g_type = 0
        g_ticker_id = -1
        g_Action = 1
        g_startTick = ""
    For i = 0 To CmdArgs.Length - 1
      arg = CmdArgs(i).Trim()
      argArr = arg.Split("=")

      Select Case argArr(0).ToUpper()
        Case "SD"
          sd = argArr(1)
        Case "ED"
          ed = argArr(1)
        Case "DN"
          dnload = argArr(1)
        Case "TICKER"
          strTicker = argArr(1)
        Case "ID"
          g_ticker_id = argArr(1)
        Case "MODE"
          g_Mode = argArr(1)
        Case "TYPE"
          g_type = argArr(1)
        Case "ACTION"
          g_Action = argArr(1)
        Case "STARTTICK"
          g_startTick = argArr(1)
      End Select
    Next

    ' Read cookie
    Dim idx As Integer
    idx = 1
    For Each line As String In File.ReadLines("cookie.txt")
      Select Case idx
        Case 1
          g_P1 = line
        Case 2
          g_P2 = line
        Case 3
          g_Cookie = line
      End Select
      idx = idx + 1
    Next line
    If g_type = 0 Then
      g_type = 1
      'Console.WriteLine("Provide Type=1 or 2")
    End If


    If g_Mode = "BSE" Then
            ProcBSE(strTicker)
            Return
        End If
        'If CmdArgs.Length <= 0 Then
        'sd = GetMaxDate()
        'sd = DateAdd(DateInterval.Day, 1, sd)
        'ed = Now()
        'dnload = 1
        'End If

        Dim fn As String = ""
        _sqcSQL.ConnectionString = _oDAL.GetConnectionString("StockDB", False)
        _sqcSQL.Open()
        _sqcPrices.ConnectionString = _oDAL.GetConnectionString("StockDB", False)
        'While sd <= ed
        'If (sd.DayOfWeek = DayOfWeek.Saturday Or sd.DayOfWeek = DayOfWeek.Sunday) Then
        'nothing to do..mkts are closed
        'Else
        'Console.WriteLine(sd.ToString("d-MMM-yyyy"))
        'u = URL.Replace("<DateField>", sd.ToString("d-MMM-yyyy"))
        Dim drTickers As SqlDataReader
        Dim strUT As String
        Try
            drTickers = GetTickers(strTicker, g_ticker_id)
            'drTickers = GetRRTickers(strTicker, g_ticker_id)

            If drTickers.HasRows Then
                While drTickers.Read()
                    strTicker = drTickers("db_strTicker")
                    SetDates(drTickers("db_ticker_id"), "csp_tbl_Prices_List")
                    If g_Action = 2 Then
                        a = 1
                        b = 1
                        c = 2001
                    End If
          'strUT = URL & "&a=" & a & "&b=" & b & "&c=" & c & "&d=" & d & "&e=" & e & "&f=" & f & "&s=" & strTicker
          strUT = "http://query1.finance.yahoo.com/v7/finance/download/" & strTicker & "?period1=" & g_P1 & "&period2=" & g_P2 & "&interval=1d&events=history&crumb=IhF8o1JyWko"
          fn = DATADIR & Replace(strTicker, ".", "_") & ".csv"
                    Try
                        If (dnload <> 0) Then downloadFromURL(strUT, fn)
                    Catch e As Exception
                        Console.WriteLine(" bytes=0")
                        Continue While
                    End Try
          ProcFn(strTicker, drTickers("db_ticker_id"), drTickers("db_type"), fn, DATADIR)
        End While


            End If
            'fn = DATADIR & sd.ToString("d-MMM-yyyy") & ".csv"
            'If (dnload <> 0) Then downloadFromURL(u, fn)
            'ProcFn(sd.ToString("d-MMM-yyyy") & ".csv", DATADIR, sd.ToString("d-MMM-yyyy"))
        Catch ex As Exception
      Console.WriteLine(sd + " ---> " + ex.ToString + " -- TICKER " + strTicker)
    End Try
        'End If
        'sd = DateAdd(DateInterval.Day, 1, sd)
        'End While
        _sqcCSV.Close()
        _sqcSQL.Close()
        _sqcPrices.Close()
    End Sub
    Private Sub ProcBSE(ByVal strTicker As String)
        Dim fn As String = ""
        Dim dnload As Integer = 0
        Dim scrip_cd As Integer

        _sqcSQL.ConnectionString = _oDAL.GetConnectionString("StockDB", False)
        _sqcSQL.Open()
        _sqcPrices.ConnectionString = _oDAL.GetConnectionString("StockDB", False)
        Dim drTickers As SqlDataReader
        Dim strUT As String
        Try
            drTickers = GetBSETickers(g_ticker_id)
            If drTickers.HasRows Then
                While drTickers.Read()
                    scrip_cd = drTickers("db_scrip_cd")
                    SetBSEDates(drTickers("db_ticker_id"), "csp_tbl_BSE_Prices_List")
                    If (scrip_cd = 1) Then
                        strUT = BSE_INDEX_URL & "&FromDate="
                        strUT = strUT & b & "/" & a & "/" & c & "&ToDate="
                        strUT = strUT & e & "/" & d & "/" & f
                    Else
                        strUT = BSE_STK_URL & "scripcd=" & scrip_cd & "&FromDate="
                        strUT = strUT & b & "/" & a & "/" & c & "&ToDate="
                        strUT = strUT & e & "/" & d & "/" & f & "&OldDMY=D&ScripName="
                    End If
                    fn = DATADIR & scrip_cd & ".csv"
                    Try
                        If (dnload <> 0) Then downloadFromURL(strUT, fn)
                    Catch e As Exception
                        Continue While
                    End Try
                    ProcBSEFn(scrip_cd, drTickers("db_ticker_id"), fn, DATADIR)
                End While


            End If
        Catch ex As Exception
        End Try
        _sqcCSV.Close()
        _sqcSQL.Close()
        _sqcPrices.Close()
    End Sub
    Private Function GetBSETickers(ByVal id As Integer) As SqlDataReader
        Dim ar() As SqlParameter
        Dim dr As SqlDataReader
        Try
            ar = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcSQL, "csp_tbl_BSE_Ticker_List")
            ar(0).Value = "*"
            If id > 0 Then
                ar(1).Value = "db_scrip_cd=" & id
            Else
                ar(1).Value = "1=1"
            End If

            dr = DAL.NetDB.ExecuteReader(_sqcSQL, Data.CommandType.StoredProcedure, "csp_tbl_BSE_Ticker_List", ar)
            GetBSETickers = dr
        Catch ex As Exception

        Finally

        End Try
    End Function
    Private Function SetBSEDates(ByVal db_ticker_id As Integer, ByVal spname As String)
        Dim ar() As SqlParameter
        Dim dr As SqlDataReader
        today = Now()
        Try
            _sqcPrices.Open()
            ar = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcPrices, spname)
            ar(0).Value = "max(db_dt)"
            ar(1).Value = "db_ticker_id = " & db_ticker_id
            dr = DAL.NetDB.ExecuteReader(_sqcPrices, Data.CommandType.StoredProcedure, spname, ar)
            If dr.HasRows Then
                While dr.Read
                    ed = dr(0)
                    ed = DateAdd(DateInterval.Day, 1, ed)
                    a = Month(ed)
                    b = Day(ed)
                    c = Year(ed)
                    d = Month(today)
                    e = Day(today)
                    f = Year(today)

                End While
            Else
                a = 1
                b = 1
                c = 2001

                d = Month(today)
                e = Day(today)
                f = Year(today)
            End If
        Catch ex As Exception
            a = 1
            b = 1
            c = 2001

            d = Month(today)
            e = Day(today)
            f = Year(today)
        Finally
            _sqcPrices.Close()
        End Try

    End Function
    Private Sub downloadFromURL(ByVal URL As String, ByVal localPath As String)
        Dim myWebClient As New WebClient
        Console.Write("Downloading from " & URL & " to " & localPath & " .....")
    If (File.Exists(localPath) = True) Then
      'File.Delete(localPath)

    Else
      myWebClient.Headers.Add("cookie", g_Cookie)
      myWebClient.DownloadFile(URL, localPath)
      Dim bytes() = myWebClient.DownloadData(URL)
        If (bytes.Length > 0) Then
            Console.WriteLine(" bytes= " + Convert.ToString(bytes.Length))
            File.WriteAllBytes(localPath, bytes)
        End If
        myWebClient.Dispose()
    End If

  End Sub

    Private Sub ProcBSEFn(ByVal strTabName As String, ByVal ticker_id As Integer, ByVal fn As String, ByVal dbDir As String)
        Dim dr As OleDbDataReader
        Dim arAdd() As SqlParameter
        Dim nRecs As Integer
        Try
            If ReadTab(strTabName, dr, fn, _sqcCSV, nRecs) = False Then
                Throw New ApplicationException(fn & " could not be read.")
            End If
            _sqcPrices.Open()
            If dr.HasRows Then
                arAdd = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcPrices, "csp_tbl_BSE_Prices_Add")
                While dr.Read
                    SetSQLParmVal(arAdd, "@db_ticker_id", ticker_id)
                    SetSQLParmVal(arAdd, "@db_volume", 0)
                    SetSQLParmVal(arAdd, "@db_dt", dr("Date"))
                    If (ticker_id = 1) Then 'BSE Index
                        SetSQLParmVal(arAdd, "@db_close", dr("Close"))
                    Else
                        SetSQLParmVal(arAdd, "@db_close", dr("Close Price"))
                    End If

                    DAL.NetDB.ExecuteScalar(_sqcPrices, CommandType.StoredProcedure, "csp_tbl_BSE_Prices_Add", arAdd)
                End While
            End If
        Catch ex As Exception
            'Throw ex
        Finally
            _sqcPrices.Close()
            dr.Close()
        End Try
    End Sub
  Private Sub ProcFn(ByVal strTabName As String, ByVal ticker_id As Integer, ByVal typ As Integer, ByVal fn As String, ByVal dbDir As String)
    Dim dr As OleDbDataReader
    Dim arAdd() As SqlParameter
    Dim wc As String = "1=1"
    Dim sql As String
    Dim nRecs As Integer
    Try
      If ReadTab(strTabName, dr, fn, _sqcCSV, nRecs) = False Then
        Throw New ApplicationException(fn & " could not be read.")
      End If
      _sqcPrices.Open()
      If dr.HasRows Then
        arAdd = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcPrices, "csp_tbl_Prices_Add")
        While dr.Read
          '          nRecs = DAL.NetDB.ExecuteScalar(_sqcPrices, CommandType.Text, "select count(*) from tbl_Prices where db_ticker_id = " & ticker_id & " and db_dt = '" & dr("Date") & "'")
          '          If nRecs <= 0 Then
          SetSQLParmVal(arAdd, "@db_ticker_id", ticker_id)
          If (dr("Volume") >= 2147483647) Then
            SetSQLParmVal(arAdd, "@db_volume", 0)
          Else
            SetSQLParmVal(arAdd, "@db_volume", dr("Volume"))
          End If
          SetSQLParmVal(arAdd, "@db_dt", dr("Date"))
          SetSQLParmVal(arAdd, "@db_close", dr("Adj Close"))
          SetSQLParmVal(arAdd, "@db_type", typ)
          DAL.NetDB.ExecuteScalar(_sqcPrices, CommandType.StoredProcedure, "csp_tbl_Prices_Add", arAdd)
          'Else
          '  sql = "update tbl_Prices set db_close = " & dr("Adj Close")
          '  sql = sql & " where db_ticker_id = " & ticker_id
          '  sql = sql & " and db_dt = '" & dr("Date") & "'"
          '  DAL.NetDB.ExecuteScalar(_sqcPrices, CommandType.Text, sql)
          'End If

        End While
      End If
    Catch ex As Exception
      sql = "update tbl_Prices set db_close = " & dr("Adj Close")
      sql = sql & " where db_ticker_id = " & ticker_id
      sql = sql & " and db_dt = '" & dr("Date") & "'"
      DAL.NetDB.ExecuteScalar(_sqcPrices, CommandType.Text, sql)
    Finally
      _sqcPrices.Close()
      dr.Close()
    End Try
  End Sub

  Private Function SetDates(ByVal db_ticker_id As Integer, ByVal spname As String)
        Dim ar() As SqlParameter
        Dim dr As SqlDataReader
        today = Now()
        Try
            _sqcPrices.Open()
            ar = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcPrices, spname)
            ar(0).Value = "max(db_dt)"
            ar(1).Value = "db_ticker_id = " & db_ticker_id
            dr = DAL.NetDB.ExecuteReader(_sqcPrices, Data.CommandType.StoredProcedure, spname, ar)
            If dr.HasRows Then
                While dr.Read
                    ed = dr(0)
                    ed = DateAdd(DateInterval.Day, 1, ed)
                    a = Month(ed) - 1
                    b = Day(ed)
                    c = Year(ed)
                    d = Month(today) - 1
                    e = Day(today)
                    f = Year(today)

                End While
            Else
                a = 0
                b = 1
                c = 2001

                d = Month(today) - 1
                e = Day(today)
                f = Year(today)
            End If
        Catch ex As Exception
            a = 0
            b = 1
            c = 2001

            d = Month(today) - 1
            e = Day(today)
            f = Year(today)
        Finally
            _sqcPrices.Close()
        End Try

    End Function
    Private Function GetRRTickers(ByVal strTicker As String, ByVal id As Integer) As SqlDataReader
        Dim dr As SqlDataReader
        Dim strSQL As String

        Try
            strSQL = "select distinct(tid) as db_ticker_id, strTicker as db_strTicker from tbl_Return_Rank where 1=1 "
            If Len(strTicker) > 0 Then
                strSQL += " and strTicker = '" & Trim(strTicker) & "'"
            End If
            If g_startTick <> "" Then
                strSQL += " and strTicker >= '" & g_startTick & "'"
            End If
            strSQL += " order by strTicker asc"
            dr = DAL.NetDB.ExecuteReader(_sqcSQL, Data.CommandType.Text, strSQL)
            GetRRTickers = dr
        Catch ex As Exception

        Finally

        End Try

    End Function
    Private Function GetTickers(ByVal strTicker As String, ByVal id As Integer) As SqlDataReader
        Dim ar() As SqlParameter
        Dim dr As SqlDataReader
        Dim strSQL As String

        Try
            '_sqcSQL.ConnectionString = _oDAL.GetConnectionString("StockDB", False)
            '_sqcSQL.Open()
            ar = DAL.NetDB.SqlHelperParameterCache.GetSpParameterSet(_sqcSQL, "csp_tbl_Ticker_List")
            ar(0).Value = "*"
            If (Len(strTicker) <= 0) Then
                ar(1).Value = "1=1 and db_type = " & g_type
            Else
                ar(1).Value = " db_strTicker = '" & Trim(strTicker) & "'"
            End If
            If id > 0 Then
                ar(1).Value = "db_ticker_id=" & id
            End If
            If g_startTick <> "" Then
                ar(1).Value = ar(1).Value & " and db_strTicker >= '" & g_startTick & "'"
            End If


            ar(1).Value = ar(1).Value & " order by db_strTicker asc "
            dr = DAL.NetDB.ExecuteReader(_sqcSQL, Data.CommandType.StoredProcedure, "csp_tbl_Ticker_List", ar)

            'update only from certain date
            'strSQL = "select distinct(T.db_ticker_id), T.db_type, max(P.db_dt),T.db_strTicker from tbl_Prices P, tbl_Ticker T where P.db_ticker_id = T.db_ticker_id group by T.db_ticker_id, T.db_type, T.db_strTicker order by max(db_dt)"
            'strSQL = "select * from tbl_Ticker where db_strticker in ('AMP',	'DTV',	'FLIR',	'JDSU',	'S',	'TRV',	'LQD',	'AGG',	'BLV',	'EMB',	'HYG',	'AHL',	'ALEX',	'AMID',	'AMTD',	'APU',	'ARCX',	'ASC',	'AVX',	'AWF',	'AWK',	'BAH',	'BBD',	'ATLO',	'CBD',	'CE',	'CXW',	'BBCN',	'ETF',	'EXL',	'BMRC',	'BPFH',	'BRKL',	'BSRR',	'CALM',	'CBNJ',	'CBNK',	'MRH',	'CTRX',	'CY',	'CYBE',	'RLH',	'RTI',	'RZA',	'SA',	'ACTG',	'AGNC',	'ANCX',	'ARTNA',	'LACO',	'MCRL',	'SUSQ',	'TKMR',	'VGLT',	'BIV',	'BND',	'BNDX',	'BSV',	'VCIT',	'VCLT',	'VCSH',	'VGIT',	'VGSH',	'VMBS',	'VWOB',	'MUB',	'ILTB',	'ARCP',	'AEC')"
            'dr = DAL.NetDB.ExecuteReader(_sqcSQL, Data.CommandType.Text, strSQL)
            GetTickers = dr
        Catch ex As Exception

        Finally

        End Try

    End Function
    Private Function ReadTab(ByVal TabName As String, ByRef dr As OleDbDataReader, ByVal fn As String, ByRef sqc As OleDbConnection, ByRef nRecs As Integer) As Boolean
        'UNCfn is not used
        Try
            sqc = New OleDbConnection( _
                 "Provider=Microsoft.ACE.OLEDB.12.0;" & _
                "Data Source=" & "c:\temp\prices\" & ";" & _
               "Extended Properties=""text;Excel 12.0;HDR=Yes;FMT=Delimited""")
            sqc.Open()
            Dim SQLString As String = "SELECT count(*) FROM [" & Replace(TabName, ".", "_") & ".csv" & "]"
            Dim DBCommand = New OleDbCommand(SQLString, sqc)
            Dim drCnt = DBCommand.ExecuteReader()
            If drCnt.IsClosed Then
                Return False
            Else
                drCnt.Read()
                '_resp.Write("num recs in " & TabName & " tab:" & drCnt(0) & "<BR>")
                nRecs = drCnt(0)
                drCnt.Close()
                SQLString = "SELECT * FROM [" & Replace(TabName, ".", "_") & ".CSV" & "]"
                DBCommand = New OleDbCommand(SQLString, sqc)
                dr = DBCommand.ExecuteReader()
                Return True
            End If

        Catch ex As Exception
            Throw ex
        Finally
            'The calling function should remember to close the sqc
            'immediately after consuming the dr,
            'else the XLS file (fn) will be locked and would require
            'an iisreset to unlock it.
        End Try
    End Function


    Private Function SetSQLParmVal(ByRef SqlParmsArray As SqlParameter(), ByVal colname As String, ByVal val As String) As Boolean
        Dim p As SqlParameter
        For Each p In SqlParmsArray
            If p.ParameterName = colname Then
                p.Value = val
                Return True
            End If
        Next
        Throw New Exception("SetSQLParmVal() - Parameter: " & colname & " not found.")
        Return False
    End Function

    Private Function IsValid(ByRef SqlParmsArray As SqlParameter(), ByRef dr As SqlDataReader, ByVal colname As String) As Boolean
        Dim p As SqlParameter
        Dim idx As Integer = 0
        Dim drIdx As Integer = 0
        drIdx = GetDRIndex(colname.Substring(1), dr)
        If (drIdx < 0) Then Return False

        For Each p In SqlParmsArray
            'Both SqlParmsArray and dr should match in column names for the same index value
            'If p.ParameterName = colname And dr.GetName(idx) = colname.Substring(1) Then
            If p.ParameterName = colname Then
                Return Not TypeOf dr(drIdx) Is System.DBNull
            End If
            'Since arrays are zero based, increment index only after the first element has been checked.
            idx = idx + 1
        Next
        If (idx <= 0 Or idx >= SqlParmsArray.Count) Then Throw New Exception("IsValid() - Parameter: " & colname & " not found.")
        Return False
    End Function
    Private Function GetDRIndex(ByVal colname As String, ByRef dr As SqlDataReader) As Integer
        Dim idx As Integer = dr.FieldCount()
        Dim i As Integer = 0
        For i = 0 To idx

            If (dr.GetName(i) = colname) Then
                Return i
            End If
        Next
        Return -1
    End Function

    Private Function GetSQLParmIndex(ByRef SqlParmsArray As SqlParameter(), ByVal colname As String) As Integer
        Dim p As SqlParameter
        Dim idx As Integer = 0
        For Each p In SqlParmsArray
            If p.ParameterName = colname Then
                Return idx
            End If
            'Since arrays are zeor based, increment index only after the first element has been checked.
            idx = idx + 1
        Next
        If (idx <= 0 Or idx >= SqlParmsArray.Count) Then Throw New Exception("GetSQLParmIndex() - Parameter: " & colname & " not found.")
        Return idx
    End Function
    Private Function getFieldFromSP(ByVal db As String, ByVal sp As String, ByVal cols As String, ByVal fldName As String, ByVal wc As String) As Object
        getFieldFromSP = Nothing
        Dim dr As SqlDataReader = Nothing
        Dim sqc As New SqlConnection
        Dim oDAL As New DAL.NetDB
        Try
            dr = oDAL.ListSPReturnDR(db, sp, cols, wc, sqc)
            If dr.HasRows Then
                While dr.Read()
                    getFieldFromSP = dr(fldName)
                End While
            End If
        Finally
            closeDRandSQC(dr, sqc) 'clean up dr and sqc
        End Try
    End Function
    Public Function getFieldFromSQL(ByVal db As String, ByVal sql As String) As Object
        getFieldFromSQL = Nothing
        Dim dr As SqlDataReader = Nothing
        Dim sqc As New SqlConnection
        Dim oDAL As New DAL.NetDB
        Try
            dr = oDAL.RunSQLReturnDR(db, sql, sqc)
            If dr.HasRows Then
                While dr.Read()
                    getFieldFromSQL = dr(0)
                End While
            End If
        Finally
            closeDRandSQC(dr, sqc) 'clean up dr and sqc
        End Try
    End Function
    Public Function RetDataDR(ByVal DBName As String, ByVal sp As String, ByVal cols As String, ByVal wc As String, ByRef sqc As SqlConnection, ByRef bSuccess As Boolean) As SqlDataReader
        Dim _oDAL As New DAL.NetDB
        bSuccess = 0
        Dim dr As SqlDataReader
        Dim db As String
        db = If(String.IsNullOrEmpty(DBName), "", DBName)
        If (String.IsNullOrEmpty(db)) Then
            Return dr
        End If

        Try
            dr = _oDAL.ListSPReturnDR(db, sp, cols, wc, sqc)
            bSuccess = 1
        Catch e As SqlException
            bSuccess = 0
            Throw New ApplicationException(e.Message)
        Finally
            'Callee must close sqc
            'sqc.Close()
        End Try
        Return dr
    End Function
    Public Sub closeDRandSQC(ByRef dr As SqlDataReader, ByRef sqc As SqlConnection)
        If Not (dr Is Nothing) Then dr.Close()
        dr = Nothing
        If Not (sqc Is Nothing) Then
            If (sqc.State = Data.ConnectionState.Open) Then sqc.Close()
            sqc = Nothing
        End If
    End Sub

End Module
