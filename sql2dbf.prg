/*
 *   $Id: sql2dbf.prg 2138 2012-04-05 22:04:36Z leonardo $
 */

#include "hwgui.ch"
#include "sqlrdd.ch"
#include "pgs.ch"        // PARA POSTGRESQL
#include "firebird.ch"   // PARA FIREBIRD
#include "mysql.ch"      // PARA MYSQL
#include "hbclass.ch"

REQUEST SQLRDD
REQUEST SR_ODBC
REQUEST SR_PGS       // PARA POSTGRESQL
REQUEST SR_FIREBIRD  // PARA FIREBIRD
REQUEST SR_MYSQL     // PARA MYSQL

REQUEST SR_ODBC
REQUEST SQLEX

REQUEST DBFCDX
REQUEST DBFFPT

*************
FUNCTION MAIN
*************
PRIVATE oJanela, o_Obtn1
PRIVATE oFont, oButton1_export
PRIVATE aItens  :={"FIREBIRD","MYSQL","ORACLE","POSTGRESQL"}

PRIVATE oTIPO_SQL
PRIVATE oHOST
PRIVATE oPORTA
PRIVATE oDATABASE
PRIVATE oUSUARIO
PRIVATE oSENHA
PRIVATE oCHARSET

PRIVATE vTIPO_SQL:=aItens[1]
PRIVATE vHOST    :=""
PRIVATE vPORTA   :=""
PRIVATE vDATABASE:=""
PRIVATE vUSUARIO :=""
PRIVATE vSENHA   :=""
PRIVATE vCHARSET :=""

IF IsDirectory( "dbf" ) = .F.
   Makedir("dbf")
ENDIF

//RddSetDefault( "SQLEX" )
RddSetDefault("SQLRDD")
//DBSETDRIVER("DBFCDX")

IF !FILE("SYGECOM.DBF")
   private aField[8]
   aField[1] := {"TIPO_SQL", "C", 10,  0}  // FIREBIRD, MYSQL, POSTGRESQL
   aField[2] := {"HOST"    , "C", 60,  0}
   aField[3] := {"PORTA"   , "C",  5,  0}
   aField[4] := {"DATABASE", "C", 80,  0}
   aField[5] := {"USUARIO" , "C", 30,  0}
   aField[6] := {"SENHA"   , "C", 30,  0}
   aField[7] := {"CHARSET" , "C", 15,  0}
   aField[8] := {"OBS"     , "C", 40,  0}
   DBcreate("SYGECOM", aField, "DBFCDX")
ENDIF

DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
DbUseArea(.T.,'DBFCDX',"SYGECOM","SYGECOM",.T.,.F.,,)

SELE SYGECOM
IF LASTREC() > 0
   dbgotop()
   vTIPO_SQL=ALLTRIM(TIPO_SQL)
   vHOST    =ALLTRIM(HOST)
   vPORTA   =ALLTRIM(PORTA)
   vDATABASE=ALLTRIM(DATABASE)
   vCHARSET =ALLTRIM(CHARSET)
   vUSUARIO =alltrim(USUARIO)
   vSENHA   =alltrim(SENHA)
ELSE
   AppRede()
   Replace TIPO_SQL with vTIPO_SQL
   LIBERAREG()
   dbcommit()
ENDIF

SetToolTipBalloon(.t.)
SetColorinFocus( .t. )

PREPARE FONT oFont NAME "Arial" WIDTH 0 HEIGHT -12 WEIGHT 400
INIT DIALOG oJanela CLIPPER NOEXIT TITLE "Configuração de Conexão com Servidor";
AT 0,0 SIZE 600,280;
ICON HIcon():AddResource(1004) ;
FONT oFont ;
ON INIT{|| oButton1_export:Disable(),.t. };
ON EXIT{|| MyExitProc() };
STYLE DS_CENTER + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

@ 5,5 GROUPBOX grpConfiguracao        CAPTION "Configuração de Conexão com Servidor" SIZE 590,225;
COLOR 16711680

@ 31 ,42  SAY LINICIAR CAPTION "Tipo de Banco:" SIZE 100,22
@ 120,40 GET COMBOBOX oTIPO_SQL VAR vTIPO_SQL ITEMS aItens SIZE 150,24 TEXT;
ON CHANGE { || Atualiza_porta(vTIPO_SQL) };
VALID { || Atualiza_porta(vTIPO_SQL) };
TOOLTIP 'Selecione Aqui o Tipo de Banco de Dados'

@ 320,42  SAY LINICIAR CAPTION "Porta de Conexão:" SIZE 100,22
@ 434,40 GET oPORTA VAR vPORTA SIZE 100,24;
STYLE ES_AUTOHSCROLL PICTURE '99999';
TOOLTIP 'Informe a porta de Conexão com o Banco de dados'

@ 15 ,72  SAY LINICIAR CAPTION "Host de Conexão:" SIZE 100,22
@ 120,70 GET oHOST VAR vHOST SIZE 415,24;
STYLE ES_AUTOHSCROLL MAXLENGTH 60;
TOOLTIP 'Informe o Host ou IP de Conexão com o Banco de dados'

@ 27 ,102 SAY LINICIAR CAPTION "Base de dados:" SIZE 100,22
@ 120,100 GET oDATABASE VAR vDATABASE SIZE 415,24;
STYLE ES_AUTOHSCROLL MAXLENGTH 80;
TOOLTIP 'Informe o nome do banco de dados'

   @ 545,100  OWNERBUTTON o_Obtn1;
   SIZE 24,24 ;
   FLAT;
   ON CLICK {|| IIF(oButton1_export:IsEnabled(oButton1_export),msginfo("Conexão já testada"),oOwnerbutton1_onClick()) } ;
   BITMAP 1002 FROM RESOURCE TRANSPARENT;
   TOOLTIP "Clique aqui para Buscar o local de um arquivo de banco de dados"

@ 62 ,132 SAY LINICIAR CAPTION "Usuario:" SIZE 100,22
@ 120,130 GET oUSUARIO VAR vUSUARIO SIZE 150,24;
STYLE ES_AUTOHSCROLL MAXLENGTH 30;
TOOLTIP 'Informe o usuario para a conexão'

@ 330,132 SAY LINICIAR CAPTION "Senha:" SIZE 100,22
@ 385,130 GET oSENHA VAR vSENHA SIZE 150,24 PASSWORD;
STYLE ES_AUTOHSCROLL MAXLENGTH 30;
TOOLTIP 'Informe a senha do usuario'

@ 64 ,162 SAY LINICIAR CAPTION "CharSet:" SIZE 100,22
@ 120,160 GET oCHARSET VAR vCHARSET SIZE 150,24;
STYLE ES_AUTOHSCROLL MAXLENGTH 15;
TOOLTIP 'Informe o Ecoding ou Charset de conexão'

@ 10,235 BUTTONEX oButton1_export CAPTION "&Exportar para DBF" SIZE 180, 38 ;
BITMAP (HBitmap():AddResource(1006)):handle  ;
BSTYLE 0;
TOOLTIP "Clique aqui para exportar para DBF";
ON CLICK {||  EXPORTA_SQL() };
STYLE WS_TABSTOP

@ 200,235 BUTTONEX "&Abrir DBF" SIZE 100, 38 ;
BITMAP (HBitmap():AddResource(1006)):handle  ;
BSTYLE 0;
TOOLTIP "Clique aqui para abrir DBF";
ON CLICK {||  VISUALIZA_DBF() }


@ 355,235 BUTTONEX oButton1 CAPTION "&Salvar / Testa" SIZE 130, 38 ;
BITMAP (HBitmap():AddResource(1006)):handle  ;
BSTYLE 0;
TOOLTIP "Clique aqui para salvar os dados da conexão e realizar o teste de conexão";
ON CLICK {||  Salva_dados_sql() };
STYLE WS_TABSTOP

@ 495,235 BUTTONEX oButton2 CAPTION "&Fechar" SIZE 100,38 ;
BITMAP (HBitmap():AddResource(1005)):handle  ;
BSTYLE 0;
TOOLTIP "Sair do sistema";
ON CLICK {|| oJanela:Close() };
STYLE WS_TABSTOP

oJanela:Activate()

RETURN nil

*************************************
STATIC FUNCTION oOwnerbutton1_onClick
*************************************
Local vSALVA_PATH := curdrive()+':\'+rtrim(curdir())  // SALVA O PATH ATUAL PARA RESTAURAR DEPOIS

Local s1 := "*.fdb"
Local s2 := "Base de dados Firebird" + "( " + s1 + " )"

Local s3 := "*.gdb"
Local s4 := "Base de dados Firebird" + "( " + s3 + " )"

Local vARQ := SelectFile( {s2, s4},{s1, s3} )

Dirchange(vSALVA_PATH)
IF !Empty(vARQ)
   oDATABASE:SetText(vARQ)
   oDATABASE:REFRESH()
ENDIF
RETURN Nil

************************
Function Salva_dados_sql
************************
IF EMPTY(vHOST)
   MsgInfo("Obrigatorio informar o Host de conexão, Favor revisar")
   oHOST:setfocus()
 	 RETURN
ENDIF

IF EMPTY(vDATABASE)
   MsgInfo("Obrigatorio informar o Banco de dados de Acesso, Favor revisar")
   oDATABASE:setfocus()
 	 RETURN
ENDIF

IF EMPTY(vUSUARIO)
   MsgInfo("Obrigatorio informar o Usuario de Acesso, Favor revisar")
   oUSUARIO:setfocus()
 	 RETURN
ENDIF

IF EMPTY(vSENHA)
   MsgInfo("Obrigatorio informar a Senha do Usuario, Favor revisar")
   oSENHA:setfocus()
 	 RETURN
ENDIF

vUSUARIO=alltrim(vUSUARIO)
vSENHA=alltrim(vSENHA)

SELE SYGECOM
dbgotop()
TRAVAREG("S")
Replace TIPO_SQL WITH ALLTRIM(vTIPO_SQL),;
HOST             WITH ALLTRIM(vHOST),;
PORTA            WITH vPORTA,;
DATABASE         WITH vDATABASE,;
USUARIO          WITH vUSUARIO,;
SENHA            WITH vSENHA,;
CHARSET          WITH vCHARSET
DBCOMMIT()
LIBERAREG()

IF MsgYesNo("Informações salvas com sucesso, Deseja testar a Conexão agora?")
   TESTA_CONEXAO_SQL(ALLTRIM(vTIPO_SQL),ALLTRIM(vHost),vPORTA,vDATABASE,vUSUARIO,vSENHA,ALLTRIM(vCHARSET))
ENDIF

RETURN

*************************************************************************************
FUNCTION TESTA_CONEXAO_SQL(vTIPO_SQL,vHost,vPORTA,vDATABASE,vUSUARIO,vSENHA,vCHARSET)
*************************************************************************************
Local vMEU_SQL, nCnn := -1

PRIVATE oDlgHabla:=NIL
MsgRun("Aguarde Testando conexão...")

/*
*SQLEX
IF vTIPO_SQL="MYSQL"
   cAtributes := "dsn=MySQL;Description=MySQL;Server="+vHost+";Database="+vDATABASE+";Uid="+vUSUARIO+";Pwd="+vSENHA
   cDriver    := "MySQL ODBC 3.51 Driver"
   cConnString := "dsn=MySQL"
ELSEIF vTIPO_SQL="POSTGRESQL"
   cAtributes := "dsn=PostgreSQL;Server="+vHost+";Database="+vDATABASE+";Uid="+vUSUARIO+";Pwd="+vSENHA+";BoolsAsChar=0;"
   cDriver    := "PostgreSQL ANSI"
   cConnString := "dsn=PostgreSQL"
ELSEIF vTIPO_SQL="FIREBIRD"
   cAtributes := "DSN=Firebird;Description=Firebird;Server="+vHost+";Database="+vDATABASE+";Uid="+vUSUARIO+";Pwd="+vSENHA+";CHARSET=ANSI_CHARSET;CLIENT=gds32.dll"
   cDriver    := "Firebird/InterBase(r) driver"
   cConnString := "dsn=Firebird"
ENDIF

//SR_UninstallDSN( cDriver, cAtributes )

nDetected   := DetectDBFromDSN( cConnString )
IF nDetected > SYSTEMID_UNKNOW
   TRY
      nCnn:= SR_AddConnection( nDetected, cConnString )
   CATCH
       FIM_RUN()
       MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
       RETURN
   END
ELSE
   FIM_RUN()
   MsgInfo("Não Localizou o Tipo de conexão")
   RETURN
ENDIF

If nCnn < 0
   FIM_RUN()
   IF MsgYesNo('Não conectou a base de dados, deseja tentar forçar a conexão ?')
      IF SR_InstallDSN( cDriver, cAtributes )
         cConnString := "dsn=sql"
         nDetected   := DetectDBFromDSN( cConnString )

         If nDetected > SYSTEMID_UNKNOW
            TRY
               nCnn:= SR_AddConnection( nDetected, cConnString )
            CATCH
               MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
               RETURN
            END
         EndIf
      ELSE
         vERR0=""
         For i = 1 to 8
            vERR0=vERR0 + SR_InstallError( i ) + HB_OsNewLine()
         Next

         MsgInfo(VALTOPRG(vERR0))

         MsgInfo("Não Consegui definir a Conexão ODBC, Favor revisar se os Driver ODBC foram instalados corretamente")
         RETURN
      ENDIF
   ENDIF
ENDIF
*/

IF vTIPO_SQL="MYSQL"
   vMEU_SQL="MySQL="+vHOST+";UID="+vUSUARIO+";PWD="+vSENHA+";DTB="+vDATABASE+";PRT="+vPORTA
   nCnn := SR_AddConnection(CONNECT_MYSQL, vMEU_SQL )
ELSEIF vTIPO_SQL="POSTGRESQL"
   OVERRIDE METHOD CONNECTRAW IN CLASS SR_PGS WITH SYG_CONNECTRAW
   //ESSE COMANDO ACIMA FAZ COM QUE A FUNÇÃO: MYCONNECTRAW() SUBISTITUA A FUNÇÃO: CONNECTRAW DENTRO DA CLASSE SR_PGS(SQLRDD)

   vMEU_SQL="PGS="+vHOST+";UID="+vUSUARIO+";PWD="+vSENHA+";DTB="+vDATABASE+";PRT="+vPORTA
   nCnn := SR_AddConnection(CONNECT_POSTGRES, vMEU_SQL)
ELSEIF vTIPO_SQL="FIREBIRD"
   vMEU_SQL="FIREBIRD="+vHOST+":"+vDATABASE+";UID="+vUSUARIO+";PWD="+vSENHA + ";charset="+vCHARSET  //";charset=ISO8859_1" ANSI_CHARSET
   nCnn := SR_AddConnection(CONNECT_FIREBIRD, vMEU_SQL)
ENDIF

Fim_Run()
If nCnn < 0
   oButton1_export:Disable()
   HabilitaAllGets( oJanela )
   MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
ELSE
   SR_EndConnection(nCnn)
   oButton1_export:enable()
   DesabilitaAllGets( oJanela )
   MsgInfo("Conexão realizada com Sucesso")
EndIf
Return

********************
FUNCTION EXPORTA_SQL
********************
Local nPos, nErr, cMEU_SQL, nCnn, aTABELAS:={}, cSqlComando:="",oSQL, aRET:={}

SELE SYGECOM
IF LASTREC() > 0
   dbgotop()
   vTIPO_SQL=ALLTRIM(TIPO_SQL)
   vHOST    =ALLTRIM(HOST)
   vPORTA   =ALLTRIM(PORTA)
   vDATABASE=ALLTRIM(DATABASE)
   vCHARSET =ALLTRIM(CHARSET)
   vUSUARIO =alltrim(USUARIO)
   vSENHA   =alltrim(SENHA)
ELSE
   MsgInfo("Ainda não foi configurado uma conexão SQL, Favor Revisar")
   Return
ENDIF

PRIVATE oDlgHabla:=NIL
MsgRun("Aguarde Conectando ao Banco.: " + vTIPO_SQL )

/*
IF vTIPO_SQL="MYSQL"
   cConnString := "dsn=MySQL"
   cDriver    := "MySQL ODBC 3.51 Driver"
ELSEIF vTIPO_SQL="POSTGRESQL"
   cConnString := "dsn=PostgreSQL"
   cDriver    := "PostgreSQL ANSI"
ELSEIF vTIPO_SQL="FIREBIRD"
   cConnString := "DSN=Firebird"
   cDriver    := "Firebird/InterBase(r) driver"
ENDIF

nDetected   := DetectDBFromDSN( cConnString )
IF nDetected > SYSTEMID_UNKNOW
   TRY
      nCnn:= SR_AddConnection( nDetected, cConnString )
   CATCH
       FIM_RUN()
       MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
       RETURN
   END
ELSE
   FIM_RUN()
   MsgInfo("Não Localizou o Tipo de conexão")
   RETURN
ENDIF

If nCnn < 0
   IF MsgYesNo('Não conectou a base de dados, deseja tentar forçar a conexão ?')
      IF SR_InstallDSN( cDriver, cAtributes )
         cConnString := "dsn=sql"
         nDetected   := DetectDBFromDSN( cConnString )

         If nDetected > SYSTEMID_UNKNOW
            TRY
               nCnn:= SR_AddConnection( nDetected, cConnString )
            CATCH
               FIM_RUN()
               MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
               RETURN
            END
         EndIf
      ELSE
         Fim_Run()
         vERR0=""
         For i = 1 to 8
            vERR0=vERR0 + SR_InstallError( i ) + HB_OsNewLine()
         Next

         MsgInfo(VALTOPRG(vERR0))

         MsgInfo("Não Consegui definir a Conexão ODBC, Favor revisar se os Driver ODBC foram instalados corretamente")
         RETURN
      ENDIF
   ENDIF
ENDIF
*/

IF vTIPO_SQL="MYSQL"
   cMEU_SQL="MySQL="+vHOST+";UID="+vUSUARIO+";PWD="+vSENHA+";DTB="+vDATABASE+";PRT="+vPORTA
   nCnn := SR_AddConnection(CONNECT_MYSQL, cMEU_SQL )
ELSEIF vTIPO_SQL="POSTGRESQL"
   OVERRIDE METHOD CONNECTRAW IN CLASS SR_PGS WITH SYG_CONNECTRAW
   //ESSE COMANDO ACIMA FAZ COM QUE A FUNÇÃO: MYCONNECTRAW() SUBISTITUA A FUNÇÃO: CONNECTRAW DENTRO DA CLASSE SR_PGS(SQLRDD)

   cMEU_SQL="PGS="+vHOST+";UID="+vUSUARIO+";PWD="+vSENHA+";DTB="+vDATABASE+";PRT="+vPORTA
   nCnn := SR_AddConnection(CONNECT_POSTGRES, cMEU_SQL)
ELSEIF vTIPO_SQL="FIREBIRD"
   cMEU_SQL="FIREBIRD="+vHOST+":"+vDATABASE+";UID="+vUSUARIO+";PWD="+vSENHA + ";charset="+vCHARSET  //";charset=ISO8859_1" ANSI_CHARSET
   nCnn := SR_AddConnection(CONNECT_FIREBIRD, cMEU_SQL)
ENDIF

Fim_Run()
IF nCnn < 0
   MsgInfo("Não Conectou ao Banco de Dados, Favor revisar")
   Return
EndIf

aTABELAS:=SR_ListTables()
IF LEN(aTABELAS) > 0
   aTABELAS:=SELECIONA_TABELAS(aTABELAS)
ELSE
   SR_EndConnection(nCnn)
   MsgInfo("Não foi localizada Nenhuma Tabela, Favor revisar o banco de dados")
   Return
ENDIF

IF LEN(aTABELAS) = 0
   SR_EndConnection(nCnn)
   MsgInfo("Não foi localizada Nenhuma Tabela, Favor revisar o banco de dados")
   Return
ENDIF

PRIVATE oDlgHabla:=NIL
MsgRun("Aguarde Exportando Tabelas..")

vTOT:=LEN(aTABELAS)

IF vTIPO_SQL="FIREBIRD"   // ALTERA TODOS OS CAMPOS FLOAT PARA DOUBLE PRECISION, PARA O SQLRDD PODER MIGRAR AS CASAS DECIMAIS
*   For nI := 1 to LEN(aTABELAS)
*      HW_Atualiza_Dialogo("Aguarde, Examinando Tabelas.: " +Str((nI/vTOT)*100,4) +" % - " + aTABELAS[nI])

      cComm :='UPDATE RDB$FIELDS '
      cComm+='SET RDB$FIELD_TYPE = 27, '
      cComm+='RDB$FIELD_LENGTH = 8, '
      cComm+='RDB$CHARACTER_LENGTH = NULL '
      cComm+='WHERE RDB$FIELD_NAME IN ( SELECT RDB$RELATION_FIELDS.RDB$FIELD_SOURCE '
      cComm+='FROM RDB$RELATION_FIELDS, RDB$FIELDS '
      cComm+='WHERE (RDB$RELATION_FIELDS.RDB$FIELD_SOURCE = RDB$FIELDS.RDB$FIELD_NAME) '
      cComm+='AND (RDB$FIELDS.RDB$FIELD_TYPE = 10 ) '
      cComm+='AND (RDB$FIELDS.RDB$SYSTEM_FLAG <> 1 ) ) '
      oSql   := SR_GetConnection()   // Obtem o objeto da conexão ativa
      nErr   := oSql:exec( cComm,,.t.,@aRET,,)   // Executa a query no banco e armazena
   //   MemoWrit( "a.log",valtoprg(aRET) )
*   NEXT
ENDIF

For nI := 1 to LEN(aTABELAS)
   HW_Atualiza_Dialogo("Aguarde, Exportando Tabela.: " +Str((nI/vTOT)*100,4) +" % - " + aTABELAS[nI])

   IF Select('relator1') >0
      relator1->( dBCloseArea() )
   ENDIF

   cComm:="select * from " + aTABELAS[nI]
   oSql:= SR_GetConnection()   // Obtem o objeto da conexão ativa
   nErr:= oSql:exec( cComm,,.t.,,'dbf\'+aTABELAS[nI] ,'relator1',,.t.)   // Executa a query no banco e armazena

   //nErr:= oSql:exec(cQuery,lErro,.t.,,(cPathDBF),cAlias,,.t.) // Executa a query no banco e armazena em DBF

   IF FILE('dbf\'+aTABELAS[nI])
      relator1->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
   ENDIF

   IF getkeystate(VK_ESCAPE,.F.,.T.) < 0
      IF MsgYesNo("Deseja Realmente Parar a Exportação de dados ?")
        EXIT
      ENDIF
   ENDIF
Next
SR_EndConnection(nCnn)

HW_Atualiza_Dialogo("Aguarde, Verificando estruturas Duplicadas...")

aArq:={}
aDir1 := curdrive()+":\"+rtrim(curdir()) + "\dbf\*.dbf"
aDir0 := directory(aDir1)

For x=1 to len(aDir0)
   HW_Atualiza_Dialogo("Aguarde, Verificando estruturas Duplicadas: " + aDir0[x,1] )
   IF UPPER(ALLTRIM(aDir0[x,1])) # "SYGECOM.DBF"
      AADD(aArq, "dbf\"+aDir0[x,1] )
   ENDIF
NEXT

For x=1 to len(aArq)
   HW_Atualiza_Dialogo("Aguarde, Verificando estruturas Duplicadas: " + aArq[x] )
   lMudou:=.F.
   vFILE:=SUBSTR(aArq[x], 1,LEN(aArq[x])-4) // Nome do DBF sem a extenção

   DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
   dbUseArea(.T., "DBFCDX", vFILE, "TEMP1", .F., .F.)

   aStruct1 := dbStruct()     // pega a estrutura atual
   aStruct2 := {}

   For z=1 to len(aStruct1)

      cCAMPO:=aStruct1[z,1]

      nSCAN:=AScan( aStruct2, cCAMPO )

      IF nSCAN > 0
         aStruct1[z,1] := "CAMPO"+STRZERO(z,3)
         lMudou:=.T.
      ELSE
         AADD(aStruct2, cCAMPO )
      ENDIF
   Next
   IF Select('TEMP1') > 0
      TEMP1->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
   ENDIF
   FERASE("dbf\TEMP.DBF")
   FERASE("dbf\TEMP.FPT")

   IF lMudou=.T.
      DbCreate( "dbf\TEMP", aStruct1, "DBFCDX" )
      dbUseArea(.T., "DBFCDX", "dbf\TEMP", "TEMP2", .F., .F.)

      APPEND FROM &vFILE VIA "DBFCDX" //HW_Atualiza_Dialogo("Copiando Tabela.: " + STR((RECNO()/LASTREC())*100,4) + "%" ) VIA "DBFCDX"

      HW_Atualiza_Dialogo("Copiando Tabela...")

      TEMP2->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
      __CopyFile("dbf\TEMP.DBF",vFILE+".DBF")
      IF FILE("dbf\TEMP.FPT")
         __CopyFile("dbf\TEMP.FPT",vFILE+".FPT")
      ENDIF
      FERASE("dbf\TEMP.DBF")
      FERASE("dbf\TEMP.FPT")
   ENDIF
NEXT

FIM_RUN()
dbcloseall()

IF MsgYesNo("Exportação de dados concluida com Sucesso, Deseja Visualizar Alguma Tabela ?")
   vESCOLHA :=  MY_WChoice( aArq, "Seleciona uma Tabela", 15+LEN(aArq), 200,HFont():Add( '',0,-12,400,,,) ,,,,,,)
   IF vESCOLHA > 0
      vFILE:=aArq[vESCOLHA]
      vFILE:=SUBSTR(vFILE, 1,LEN(vFILE)-4) // Nome do DBF sem a extenção

      DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
      dbUseArea(.T., "DBFCDX", vFILE, "TEMP", .F., .T.)
      IF Select('TEMP1') > 0
         SELE TEMP
         HW_BROWSE()
         TEMP->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
      ENDIF
   ELSE
      MsgInfo("Nenhuma Tabela Selecionada, Favor Revisar")
   ENDIF
ENDIF

RETURN

**********************************
FUNCTION SELECIONA_TABELAS(aVETOR)
**********************************
PRIVATE vCombo1 := 1
PRIVATE oGroup1, oLabel1, oButtonex3, oButtonex5, oData, oLabel2 ;
        , oGroup2, oBrowse1, oButtonex4, oButtonex6, oButtonex2, oButtonex1

PRIVATE vITENS := aVETOR

PRIVATE aARRAY_TEMP := {}
AADD(aARRAY_TEMP,"")

  INIT DIALOG oDlg TITLE "Modulo de Seleção de Tabelas" ;
  ICON HIcon():AddResource(1004) ;
  AT 331,188 SIZE 476,507 ;
  FONT HFont():Add( '',0,-13,400,,,) CLIPPER  NOEXIT  ;
  ON INIT  {|| ADD_EXCLUIR(1),.T.} ;
  STYLE WS_POPUP+WS_CAPTION+DS_CENTER +WS_SYSMENU+WS_MINIMIZEBOX

  @ 15,31 BROWSE oBrowse2 ARRAY OF oGroup1 SIZE 440,139 ;
  ON CLICK {|o,key| ADD_LISTA(oBrowse2:nCurrent) };
  STYLE WS_TABSTOP        ;
  FONT HFont():Add( '',0,-11,400,,,)

   // CREATE oBrowse2   //  SCRIPT GENARATE BY DESIGNER
*   oBrowse2:aColumns := {}
*   oBrowse2:nHeadRows:= 1
*   oBrowse2:nFootRows:= 0
*   oBrowse2:lDispHead:= .T.
*   oBrowse2:lDispSep:= .T.
*   oBrowse2:lSep3d:= .F.
*   oBrowse2:headColor:= 0
*   oBrowse2:sepColor:= 12632256
*   oBrowse2:nLeftCol:= 0
*   oBrowse2:freeze:= 0
   oBrowse2:aArray := vITENS

   oBrowse2:bKeyDown := {|o,key| BrowseKey(o, key ) }
   CreateArList( oBrowse2, vITENS )

   oBrowse2:aColumns[1]:heading := "Nome da Tabela"

   @ 25,173 BUTTONEX oButtonex3 CAPTION "&Adicionar"  OF oGroup1 SIZE 98,32 ;
   STYLE WS_TABSTOP  ;
   ON CLICK {|| ADD_LISTA(oBrowse2:nCurrent) };
   TOOLTIP 'Clique aqui para adicionar a Tabela para exportação'

   @ 135,173 BUTTONEX oButtonex5 CAPTION "Adicionar Todos"  OF oGroup1 SIZE 114,32 ;
   STYLE WS_TABSTOP;
   ON CLICK {|| ADD_TODOS() };
   TOOLTIP 'Clique aqui para adicionar Todas as Tabelas para Exportação'

   @ 9,10 GROUPBOX oGroup1 CAPTION "Seleção de Tabelas a ser exportadas"  SIZE 453,201  ;
   COLOR 16711680

   @ 18,236 BROWSE oBrowse1 ARRAY OF oGroup2 SIZE 438,172 ;
   STYLE WS_TABSTOP        ;
   ON CLICK {|o,key| ADD_EXCLUIR(oBrowse1:nCurrent) };
   FONT HFont():Add( '',0,-11,400,,,)

    // CREATE oBrowse1   //  SCRIPT GENARATE BY DESIGNER
    oBrowse1:aColumns := {}
    oBrowse1:nHeadRows:= 1
    oBrowse1:nFootRows:= 0
    oBrowse1:lDispHead:= .T.
    oBrowse1:lDispSep:= .T.
    oBrowse1:lSep3d:= .F.
    oBrowse1:headColor:= 0
    oBrowse1:sepColor:= 12632256
    oBrowse1:nLeftCol:= 0
    oBrowse1:freeze:= 0
    oBrowse1:aArray := aARRAY_TEMP

   oBrowse1:bKeyDown := {|o,key| BrowseKey(o, key ) }
   CreateArList( oBrowse1, aARRAY_TEMP )

   oBrowse1:aColumns[1]:heading := "Nome da Tabela"
   oBrowse1:aColumns[1]:length := 60

   @ 25,418 BUTTONEX oButtonex4 CAPTION "&Excluir"  OF oGroup2 SIZE 98,32 ;
   STYLE WS_TABSTOP  ;
   ON CLICK {|| ADD_EXCLUIR(oBrowse1:nCurrent) };
   TOOLTIP 'Clique aqui para Excluir uma tabela'

   @ 131,418 BUTTONEX oButtonex6 CAPTION "Excluir Todos"  OF oGroup2 SIZE 98,32 ;
   STYLE WS_TABSTOP  ;
   ON CLICK {|| ADD_EXCLUIR_TODOS() };
   TOOLTIP 'Clique aqui para Excluir Todas as tabelas'

   @ 9,218 GROUPBOX oGroup2 CAPTION "Tabelas que irão ser exportadas"  SIZE 453,243  ;
   COLOR 16711680

   @ 248,465 BUTTONEX oButtonex2 CAPTION "&Ok"  SIZE 100,38 ;
   STYLE WS_TABSTOP   ;
   BITMAP (HBitmap():AddResource(1006)):handle  ;
   BSTYLE 0;
   TOOLTIP 'Clique aqui para iniciar a Exportação das Tabelas selecionadas' ;
   ON CLICK {|| oDlg:Close() }

   @ 362,465 BUTTONEX oButtonex1 CAPTION "&Fechar"  SIZE 100,38 ;
   STYLE WS_TABSTOP   ;
   BITMAP (HBitmap():AddResource(1005)):handle  ;
   BSTYLE 0;
   TOOLTIP 'Clique aqui para Fechar' ;
   ON CLICK {|| aARRAY_TEMP:={}, oDlg:Close() }

   ACTIVATE DIALOG oDlg

RETURN(aARRAY_TEMP)

**************************
Function ADD_EXCLUIR_TODOS
**************************
DO WHILE .T.
   FOR nI := 1 TO Len(aARRAY_TEMP)
      ADel( aARRAY_TEMP, nI, .T. )
   NEXT

   IF Len(aARRAY_TEMP) <= 0
      EXIT
   ENDIF
ENDDO

oBrowse1:Refresh(.T.)
oBrowse1:SetFocus()
setfocus(oBrowse1)
Return

**************************
Function ADD_EXCLUIR(vADD)
**************************
if vADD > 0
   ADel( aARRAY_TEMP, vADD, .T. )
endif
oBrowse1:Refresh(.T.)
oBrowse1:SetFocus()
setfocus(oBrowse1)
Return

******************
Function ADD_TODOS
******************
FOR nI := 1 TO Len(vITENS)
   IF AScan( aARRAY_TEMP, vITENS[nI] )=0
      AADD(aARRAY_TEMP, LOWER(vITENS[nI]) )
   ENDIF
NEXT
oBrowse1:Refresh(.T.)
oBrowse1:SetFocus()
setfocus(oBrowse1)
Return

************************
Function ADD_LISTA(vADD)
************************
IF AScan( aARRAY_TEMP, vITENS[vADD] )=0
   AADD(aARRAY_TEMP, LOWER(vITENS[vADD]) )
ELSE
   MsgInfo("Essa Tabela já foi adicionada")
ENDIF
oBrowse1:Refresh(.T.)
oBrowse1:SetFocus()
setfocus(oBrowse1)
Return

******************
FUNCTION HW_BROWSE
******************
Local oFrm, oBrw, aCAMPOS:={}

//aStruct := sr_dbStruct()  // para ver campos SQL
aStruct := dbStruct()  // para ver campos SQL
/*
FOR nI := 1 TO Len(aStruct)
    AADD(aCAMPOS ,aStruct[nI,1] )
NEXT
*/
FOR nI := 1 TO Len(aStruct)
    IF aStruct[nI,2]="D"
       aStruct[nI,3]:=aStruct[nI,3]+2
    ENDIF
    AADD(aCAMPOS ,{aStruct[nI,1],aStruct[nI,2],aStruct[nI,3],aStruct[nI,4]} )
NEXT

INIT DIALOG oFrm TITLE "Pesquisa em Tela" CLIPPER;
AT 0,0;
SIZE GETDESKTOPWIDTH(),GETDESKTOPHEIGHT()-28 ;
ICON HIcon():AddResource(1004) ;
STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

@ 10,40 BROWSE oBrw DATABASE OF oFrm SIZE GETDESKTOPWIDTH()-30, GETDESKTOPHEIGHT()-250  ;
STYLE  WS_VSCROLL + WS_HSCROLL;
FONT HFont():Add( '',0,-12,400,,,);
ON CLICK {|o,key| BrowseKey(o, key ) }

oBrw:alias := ALIAS()

oBrw:bKeyDown := {|o,key| BrowseKey(o, key ) }

@ 5,10 say "F1 - Sobre  / F2 - Busca  / F4 - Muda Ordem  / F5 - Gera Excel  / F9 - Calculadora" size GETDESKTOPWIDTH()-20,20;
STYLE SS_CENTER

*aEVAL(aCAMPOS,;
*{|cVAL,nIND| oBrw:addcolumn(HColumn():New( aCAMPOS[nIND], FieldBlock(aCAMPOS[nIND]) ,,,,.T.,0,0,,,,,,)) })

aEVAL(aCAMPOS,;
{|cVAL,nIND| oBrw:addcolumn(HColumn():New( aCAMPOS[nIND,1], FieldBlock(aCAMPOS[nIND,1]) ,IIF(aCAMPOS[nIND,2]='M','M',), aCAMPOS[nIND,3],aCAMPOS[nIND,4],.T.,0,0,,,,,,)) })

oBrw:Freeze:=1                       // congela

FOR nI := 1 TO Len(oBrw:aColumns)
   oBrw:aColumns[nI]:lEditable := .T.
   oBrw:aColumns[nI]:nJusHead := DT_CENTER    //CENTRALIZA NO NOME DO CAMPO
   oBrw:aColumns[nI]:nJusLin  := DT_LEFT     //COLOCA PARA DIREITA A LINHA
NEXT

oFrm:Activate()

RETURN NIL

Static Function BrowseKey( oBrowse, key )
DO CASE
   CASE KEY= VK_ESCAPE
        EndDialog()
   CASE KEY = VK_RETURN
        EndDialog()
   CASE KEY = VK_F9
        ShellExecute("calc")
   otherwise
ENDCASE
Return .T.

***************************
FUNCTION ATUALIZA_PORTA(vP)
***************************
oCHARSET:DISABLE()
IF vP="MYSQL"
   vPORTA="3306"
   o_Obtn1:Disable()
ELSEIF vP="POSTGRESQL"
   vPORTA="5432"
   o_Obtn1:Disable()
ELSEIF vP="FIREBIRD"
   vPORTA="3050"
   o_Obtn1:Enable()

   oCHARSET:ENABLE()
   vCHARSET:='ISO8859_1'
   oCHARSET:SETTEXT(vCHARSET)
   oCHARSET:REFRESH()
ELSEIF vP="ORACLE"
   vPORTA="1521"
   o_Obtn1:Disable()
ENDIF
oPORTA:SetText( vPORTA )
oPORTA:Refresh()
Return(.T.)

******************
Function LiberaREG
******************
DBUNLOCK()
Return

****************
Function AppRede
****************
Local vCONTA := 0
DO While .T.
   vCONTA= vCONTA + 1
   DbAppend()
   IF NetErr()
      MilliSec( 1000 )    // espera um segundo antes de tentar novamente
   ELSE
      TravaReg("S")
      Return(.T.)
   ENDIF

   IF vCONTA > 10
      IF MsgYesNo("Não Foi possivel Adicionar o Registro, Deseja Tentar Novamente ?")
         vCONTA=0
         loop
      Else
         exit
         Return(.F.)
      Endif
   ENDIF
Enddo
Return(.F.)

**************************
Function TravaReg(xEterno)
**************************
TRAVATEC(.T.)  // TRAVA O TECLADO
DO While .T.
   vTentativas=0
   DO While .T.
      IF Rlock()
         TRAVATEC(.F.)  // LIBERA O TECLADO
         Return .T.
      ElSE // TENTA DE NOVO
         IF xEterno="N"  // É OBRIGADO A TRAVAR
            TRAVATEC(.F.)  // LIBERA O TECLADO
            Return .F.
         ENDIF
         Private oDlgHabla:=nil
         MsgRun("Aguarde... Tentativa de acesso.: "+str(vTentativas)+" De.: 10")
         MilliSec( 1000 )    // espera um segundo antes de voltar
         Fim_Run()

         If vTentativas=10
            IF xEterno="S"  // É OBRIGADO A TRAVAR
               vTentativas=0
               LOOP
            ELSE
               TRAVATEC(.F.)  // LIBERA O TECLADO
               EXIT
            ENDIF
         else
            vTentativas=vTentativas+1
            Loop
         endif
      EndIf
   EndDo
   TRAVATEC(.F.)  // LIBERA O TECLADO
   IF MsgYesNo("Não Foi possivel Travar o Registro, Deseja Tentar Novamente ?")
      loop
   Else
      exit
      Return .F.
   Endif
ENDDO
TRAVATEC(.F.)  // LIBERA O TECLADO
Return .F.

FUNCTION MsgRun(cMsg)
MsgRun2(cMsg)
HW_Atualiza_Dialogo(cMsg)
Return

*********************
FUNCTION MsgRun2(cMsg)
*********************
PRIVATE oTimHabla

if cMsg=Nil
   cMsg:="Aguarde em processamento...."
endif

INIT DIALOG oDlgHabla TITLE "Processando..." NOEXIT NOEXITESC ;//NOCLOSABLE;
AT 0,0 SIZE 485,95 ;
ON EXIT {|| NoSaidaF4() };
STYLE DS_CENTER +WS_VISIBLE;
COLOR Rgb(255, 255, 255)

@ 45,20 SAY oTimHabla CAPTION cMsg SIZE 465,20;
FONT HFont():Add( '',0,-12,400,,,);
BACKCOLOR Rgb(255, 255, 255)

HWG_DOEVENTS()

ACTIVATE DIALOG oDlgHabla NOMODAL

Return Nil

****************
Function Fim_Run
****************
IF oDlgHabla#NIL
   oDlgHabla:CLOSE()
ENDIF
Return Nil

****************************************
FUNCTION HW_Atualiza_Dialogo(vMensagem)
****************************************
IF vMensagem=nIL
   vMensagem:="Aguarde em processamento...."
endif
//HWG_DOEVENTS()
hwg_processmessage()
TRY
   oDlgHabla:ACONTROLS[1]:SETTEXT(vMensagem)
catch e
   HWG_DOEVENTS()
END
RETURN NIL

******************
FUNCTION NoSaidaF4
******************
if getkeystate(VK_F4,.F.,.T.) < 0
   RETURN .F.
ENDIF
RETURN .T.

*******************
Function MyExitProc
*******************
DBCLOSEALL()
HB_GCALL()
//CLEAR ALL
IF MSGNOYES("Deseja Realmente Sair do Programa ?")
   SR_End()
   Release All
   PostQuitMessage(0)
  	__Quit()
Else
   RETURN .F.
ENDIF
RETURN .T.

#pragma begindump
#include "windows.h"
#include "winable.h"  // tem que revisar para poder compilar com MSVC
#include "hbapi.h"

HB_FUNC( TRAVATEC )
{
   BlockInput( hb_parl(1) );
}
#pragma enddump


**************************************************************************************************
FUNCTION MY_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel )
**************************************************************************************************
   LOCAL oDlg, oBrw, nChoice := 0, lArray := .T., nField, lNewFont := .F.
   LOCAL i, aLen, nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height, aArea, aRect
   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX +DS_CENTER

   IF cTitle == Nil ; cTitle := "" ; ENDIF
   IF nLeft == Nil .AND. nTop == Nil ; nStyle += DS_CENTER ; ENDIF
   IF nLeft == Nil ; nLeft := 0 ; ENDIF
   IF nTop == Nil ; nTop := 0 ; ENDIF
   IF oFont == Nil
      oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
      lNewFont := .T.
   ENDIF
   IF cOk != Nil
      minWidth += 120
      IF cCancel != Nil
         minWidth += 100
      ENDIF
      addY += 30
   ENDIF

   IF ValType( arr ) == "C"
      lArray := .F.
      aLen := RecCount()
      IF ( nField := FieldPos( arr ) ) == 0
         RETURN 0
      ENDIF
      nLen := dbFieldInfo( 3, nField )
   ELSE
      aLen := Len( arr )
      IF ValType( arr[ 1 ] ) == "A"
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[ i, 1 ] ) )
         NEXT
      ELSE
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[ i ] ) )
         NEXT
      ENDIF
   ENDIF

   hDC := GetDC( GetActiveWindow() )
   SelectObject( hDC, oFont:handle )
   aMetr := GetTextMetric( hDC )
   aArea := GetDeviceArea( hDC )
   aRect := GetWindowRect( GetActiveWindow() )
   ReleaseDC( GetActiveWindow(), hDC )
   height := ( aMetr[ 1 ] + 1 ) * aLen + 4 + addY + 8
   IF height > aArea[ 2 ] - aRect[ 2 ] - nTop - 60
      height := aArea[ 2 ] - aRect[ 2 ] - nTop - 60
   ENDIF
   width := Max( aMetr[ 2 ] * 2 * nLen + addX, minWidth )

   if height <= 0
      height=440
   endif

   if width < 240
      width=240
   endif

   INIT DIALOG oDlg TITLE cTitle ;
        At 0,0  ;
        SIZE width, height       ;
        ICON HIcon():AddResource(1004) ;
        STYLE nStyle            ;
        FONT oFont              ;
        ON INIT { | o | ResetWindowPos( o:handle ), oBrw:setfocus() }

   IF lArray
      @ 0, 0 Browse oBrw Array
      oBrw:aArray := arr
      IF ValType( arr[ 1 ] ) == "A"
         oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), o:aArray[ o:nCurrent, 1 ] }, "C", nLen ) )
      ELSE
         oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), o:aArray[ o:nCurrent ] }, "C", nLen ) )
      ENDIF
   ELSE
      @ 0, 0 Browse oBrw DATABASE
      oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), ( o:Alias ) ->( FieldGet( nField ) ) }, "C", nLen ) )
   ENDIF

   oBrw:oFont  := oFont
   oBrw:bSize  := { | o, x, y | MoveWindow( o:handle, addX / 2, 10, x - addX, y - addY ) }
   oBrw:bEnter := { | o | nChoice := o:nCurrent, EndDialog( o:oParent:handle ) }
   oBrw:bKeyDown := {|o,key|Iif(key==27,(EndDialog(oDlg:handle),.F.),.T.)}

   oBrw:lDispHead := .F.
   IF clrT != Nil
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != Nil
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != Nil
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != Nil
      oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != Nil
      x1 := Int( width / 2 ) - IIf( cCancel != Nil, 90, 40 )
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ON CLICK { || nChoice := oBrw:nCurrent, EndDialog( oDlg:handle ) }
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ON CLICK { || nChoice := 0, EndDialog( oDlg:handle ) }
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

RETURN nChoice

**********************************
Function DesabilitaAllGets( oFrm )
**********************************
AEval( oFrm:GetList, {|o|o:disable()} )
Return .T.

********************************
Function HabilitaAllGets( oFrm )
********************************
AEval( oFrm:GetList, {|o|o:enable()} )
Return .T.

STATIC FUNCTION SYG_CONNECTRAW( cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit )
/*
ESSA FUNÇÃO É USADA PARA FAZER A CONEXÃO COM O BANCO DE DADOS NO POSTGRESQL COM O SQLRDD
*/
   local hEnv := 0, hDbc := 0
   local nret, cVersion := "", cSystemVers := "", cBuff := ""
   Local aRet := {}
   LOCAl Self := HB_QSelf()

   (cDSN)
   (cUser)
   (cPassword)
   (nVersion)
   (cOwner)
   (nSizeMaxBuff)
   (lTrace)
   (nPrefetch)
   (nSelMeth)
   (nEmptyMode)
   (nDateMode)
   (lCounter)
   (lAutoCommit)

   //DEFAULT ::cPort := 5432
   IF EMPTY(::cPort)
      ::cPort := 5432
   ENDIF
   cConnect := "host=" + ::cHost + " user=" + ::cUser + " password=" + ::cPassword + " dbname=" + ::cDTB + " port=" + str(::cPort,6)

*   IF !Empty( ::sslcert )
*      cConnect += " sslmode=prefer sslcert="+::sslcert +" sslkey="+::sslkey +" sslrootcert="+ ::sslrootcert +" sslcrl="+ ::sslcrl
*   ENDIF

   hDbc := PGSConnect( cConnect )
   nRet := PGSStatus( hDbc )

   if nRet != SQL_SUCCESS .and. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      SR_MsgLogFile( "Connection Error: " + alltrim(str(PGSStatus2( hDbc ))) + " (see pgs.ch)" )
      Return Self
   else
      ::cConnect = cConnect
      ::hStmt    = NIL
      ::hDbc     = hDbc
      cTargetDB  = "PostgreSQL Native"
      ::exec( "select version()",.t.,.t.,@aRet )
      If len (aRet) > 0
         cSystemVers := aRet[1,1]
      Else
         cSystemVers= "??"
      EndIf
   EndIf

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID   := SYSTEMID_POSTGR
   ::cTargetDB   := Upper( cTargetDB )

   // na linha abaixo acresenta as versões suportadas pelo SQLRDD
   If ! ("7.3" $ cSystemVers .or. "7.4" $ cSystemVers .or. "8.0" $ cSystemVers .or. "8.1" $ cSystemVers .or. "8.2" $ cSystemVers .or. "8.3" $ cSystemVers .or. "8.4" $ cSystemVers .or. "9.0" $ cSystemVers .or. "9.1" $ cSystemVers)
      ::End()
      ::nRetCode  := SQL_ERROR
      ::nSystemID := NIL
      SR_MsgLogFile( "Unsupported Postgres version: " + cSystemVers )
   EndIf

   ::exec( "select pg_backend_pid()", .T., .T., @aRet )

   If len( aRet ) > 0
      ::uSid := val(str(aRet[1,1],8,0))
   EndIf

return Self

***********************************************************************
FUNCTION SYG_BROWSE(aARRAY_BRW,cTITULO,lEDIT,aCOLUNAS,aPICTURE,aTOTAIS)
***********************************************************************
/*
aARRAY_BRW = VETOR COM O CONTEUDO QUE DESEJA VISUALIZAR OU ALTERAR
cTITULO    = TITULO DA JANELA
lEDIT      = SE .T. PODE ALTERAR O CAMPO, SE .F. APENAS VISUALIZA
aCOLUNAS   = VETOR CONTENDO OS NOMES DAS COLUNAS, UTIL PARA QUANDO É BROWSE DE VETOR

NOTA: QUANDO ABRI UM DBF, SELECIONA A AREA DO DBF E CHAMA A FUNÇÃO SYG_BROWSE() ELE JÁ SE ENCARREGA DE MOSTRAR TUDO NA TELA, COMO O ANTIGO
BROWSE() DO CLIPPER
*/
Local nI, nI3, oFrm_Browse, oBRW_BROWSE, oBRW_TOTAIS, nLen:=0
Local aArq:={}, aArq2:={}
Local cFILE    := ALIAS()
Local aCAMPOS  := {}
Local oBUS,cBUS:=''
Local oORDEM, cORDEM:='', aORDEM:={}

IF lEDIT=NIL
   lEDIT:=.F.
ENDIF

IF aTOTAIS=NIL
   aTOTAIS:={}
ENDIF

IF aPICTURE=NIL
   aPICTURE:={}
ENDIF

IF aARRAY_BRW=Nil
   IF EMPTY(cFILE)
      MsgStop("Não foi selecionado nenhuma tabela, Favor revisar")
      Return
   ENDIF

   SELE &cFILE // seleciona a area
   aStruct := DbStruct()  // pega a estrutura

   FOR nI := 1 TO Len(aStruct)
       IF aStruct[nI,2]="D"
          aStruct[nI,3]:=aStruct[nI,3]+2
       ENDIF
       AADD(aCAMPOS ,{aStruct[nI,1],aStruct[nI,2],aStruct[nI,3],aStruct[nI,4]} )
       AADD(aORDEM,aStruct[nI,1])
   NEXT
ELSE
   cFILE:="TABELA TEMPORARIA (VETOR)"
   IF aARRAY_BRW=NIl
      Return(.f.)
   ELSE
      IF LEN(aARRAY_BRW)=0
         Return(.f.)
      ENDIF
   ENDIF
   IF aCOLUNAS#Nil
      IF LEN(aCOLUNAS) > 0
         FOR nI := 1 TO Len(aCOLUNAS)
            AADD(aORDEM,aCOLUNAS[nI])
         NEXT
      ELSE
         FOR nI := 1 TO Len(aARRAY_BRW)
            AADD(aORDEM,"Coluna: " + alltrim(str(nI)))
         NEXT
      ENDIF
   ELSE
      FOR nI := 1 TO Len(aARRAY_BRW)
         AADD(aORDEM,"Coluna: " + alltrim(str(nI)))
      NEXT
   ENDIF
ENDIF
cORDEM:=aORDEM[1]

IF cTITULO=Nil
   cTITULO:="Registros da Tabela: " + cFILE
ENDIF

INIT DIALOG oFrm_Browse TITLE cTITULO CLIPPER;
FONT HFont():Add( '',0,-14,400,,,);
AT 0,0;
SIZE GETDESKTOPWIDTH(),GETDESKTOPHEIGHT()-50 ;
ICON HIcon():AddResource(1001) ;
ON INIT  {|| (oFrm_Browse:nInitFocus := oBRW_BROWSE:handle),.T.};
STYLE DS_CENTER + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

@ oFrm_Browse:nWidth-110,oFrm_Browse:nHeight-55  BUTTONEX "&Fechar" SIZE 100, 38 ;
TOOLTIP "Sair do Modulo e Voltar aos Menus";
FONT HFont():Add( '',0,-12,400,,,);
ON CLICK {|| oFrm_Browse:Close() };
BITMAP (HBitmap():AddResource(1003)):handle  ;
STYLE WS_TABSTOP

IF aARRAY_BRW=Nil
   @ 10,40 BROWSE oBRW_BROWSE DATABASE OF oFrm_Browse;
   SIZE oFrm_Browse:nWidth-20,oFrm_Browse:nHeight-180 ;
   STYLE  WS_VSCROLL + WS_HSCROLL;
   FONT HFont():Add( '',0,-11,400,,,);
   MULTISELECT

   oBRW_BROWSE:alias := ALIAS()
ELSE
   @ 05,oFrm_Browse:nHeight-80 SAY "Pesquisa:"  SIZE 50,22
   @ 75,oFrm_Browse:nHeight-84 GET COMBOBOX oORDEM VAR cORDEM ITEMS aORDEM SIZE 150,22  TEXT ;
   DISPLAYCOUNT 27;
   ON CHANGE{|| oBUS:SETFOCUS(),.T. };
   FONT HFont():Add( '',0,-11,400,,,);
   TOOLTIP 'Escolha a Ordem da Pesquisa'

   @ 10,40 BROWSE oBRW_BROWSE Array OF oFrm_Browse;
   SIZE oFrm_Browse:nWidth-20,oFrm_Browse:nHeight-180 ;
   STYLE  WS_VSCROLL + WS_HSCROLL;
   FONT HFont():Add( '',0,-11,400,,,);
   MULTISELECT

   oBRW_BROWSE:aArray := aARRAY_BRW
   CreateArList( oBRW_BROWSE, aARRAY_BRW )
ENDIF

oBRW_BROWSE:bKeyDown := {|o,key,c,d| BrowseKey_alt(o, key, c, d, cTITULO ) }

oBRW_BROWSE:Freeze:=1
oBRW_BROWSE:lESC:=.T.

@ 5,10 SAY "F1 - Sobre  / F2 - Busca  / F4 - Muda Ordem  / F5 - Gera Excel  / F9 - Calculadora" size oFrm_Browse:nWidth,20;
STYLE SS_CENTER

IF aARRAY_BRW=Nil
   AEVAL(aCAMPOS,;
   {|cVAL,nIND| oBRW_BROWSE:addcolumn(HColumn():New( aCAMPOS[nIND,1], FieldBlock(aCAMPOS[nIND,1]) ,,aCAMPOS[nIND,3],aCAMPOS[nIND,4],lEDIT,0,0,,,,,,)) })
ENDIF

FOR nI := 1 TO Len(oBRW_BROWSE:aColumns)
    IF aCOLUNAS#Nil
       IF LEN(aCOLUNAS) >= nI
          IF VALTYPE(aCOLUNAS[nI])='U'
             oBRW_BROWSE:aColumns[nI]:heading   := "Coluna: " + alltrim(str(nI))
          ELSE
             oBRW_BROWSE:aColumns[nI]:heading   := aCOLUNAS[nI]
          ENDIF
       ENDIF
    ELSE
       IF aARRAY_BRW#Nil
          oBRW_BROWSE:aColumns[nI]:heading   := "Coluna: " + alltrim(str(nI))
       ENDIF
    ENDIF

    oBRW_BROWSE:aColumns[nI]:lEditable := lEDIT
    oBRW_BROWSE:aColumns[nI]:nJusHead  := DT_CENTER    //CENTRALIZA NO NOME DO CAMPO
    oBRW_BROWSE:aColumns[nI]:nJusLin   := DT_LEFT     //COLOCA PARA DIREITA A LINHA
NEXT

IF LEN(aPICTURE)>0
   FOR nI := 1 TO LEN(aPICTURE)
      oBRW_BROWSE:aColumns[nI]:picture:=aPICTURE[nI]
   NEXT
ENDIF

IF aARRAY_BRW=Nil
   IF LEN(aTOTAIS) >0
      @ 10,oBRW_BROWSE:nHeight+50 BROWSE oBRW_TOTAIS Array OF oFrm_Browse;
      SIZE oFrm_Browse:nWidth-250,130 ;
      FONT HFont():Add( '',0,-11,400,,,)

      oBRW_TOTAIS:aArray := aTOTAIS
      CreateArList( oBRW_TOTAIS, aTOTAIS )
   ENDIF
ENDIF

ACTIVATE DIALOG oFrm_Browse //Show SW_SHOWMAXIMIZED

Return( IIF( LEN(oBRW_BROWSE:aSelected)=0,{oBRW_BROWSE:nCURRENT}, oBRW_BROWSE:aSelected) )

***************************************************************
STATIC FUNCTION BROWSEKEY_ALT( oBrowse, key, p1, p2, cTITULO )
***************************************************************
DO CASE
   CASE KEY = VK_RETURN
        EndDialog()
   CASE KEY= VK_ESCAPE
        EndDialog()
   otherwise
ENDCASE
Return .T.

STATIC FUNCTION VISUALIZA_DBF
aArq:={}
aDir1 := curdrive()+":\"+rtrim(curdir()) + "\dbf\*.dbf"
aDir0 := directory(aDir1)

For x=1 to len(aDir0)
   HW_Atualiza_Dialogo("Aguarde, Verificando estruturas Duplicadas: " + aDir0[x,1] )
   IF UPPER(ALLTRIM(aDir0[x,1])) # "SYGECOM.DBF"
      AADD(aArq, "dbf\"+aDir0[x,1] )
   ENDIF
NEXT

For x=1 to len(aArq)
   HW_Atualiza_Dialogo("Aguarde, Verificando estruturas Duplicadas: " + aArq[x] )
   lMudou:=.F.
   vFILE:=SUBSTR(aArq[x], 1,LEN(aArq[x])-4) // Nome do DBF sem a extenção

   DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
   dbUseArea(.T., "DBFCDX", vFILE, "TEMP1", .F., .F.)

   aStruct1 := dbStruct()     // pega a estrutura atual
   aStruct2 := {}

   For z=1 to len(aStruct1)

      cCAMPO:=aStruct1[z,1]

      nSCAN:=AScan( aStruct2, cCAMPO )

      IF nSCAN > 0
         aStruct1[z,1] := "CAMPO"+STRZERO(z,3)
         lMudou:=.T.
      ELSE
         AADD(aStruct2, cCAMPO )
      ENDIF
   Next
   IF Select('TEMP1') > 0
      TEMP1->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
   ENDIF
   FERASE("dbf\TEMP.DBF")
   FERASE("dbf\TEMP.FPT")

   IF lMudou=.T.
      DbCreate( "dbf\TEMP", aStruct1, "DBFCDX" )
      dbUseArea(.T., "DBFCDX", "dbf\TEMP", "TEMP2", .F., .F.)

      APPEND FROM &vFILE VIA "DBFCDX" //HW_Atualiza_Dialogo("Copiando Tabela.: " + STR((RECNO()/LASTREC())*100,4) + "%" ) VIA "DBFCDX"

      HW_Atualiza_Dialogo("Copiando Tabela...")

      TEMP2->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
      __CopyFile("dbf\TEMP.DBF",vFILE+".DBF")
      IF FILE("dbf\TEMP.FPT")
         __CopyFile("dbf\TEMP.FPT",vFILE+".FPT")
      ENDIF
      FERASE("dbf\TEMP.DBF")
      FERASE("dbf\TEMP.FPT")
   ENDIF
NEXT

dbcloseall()

vESCOLHA :=  MY_WChoice( aArq, "Seleciona uma Tabela", 15+LEN(aArq), 200,HFont():Add( '',0,-12,400,,,) ,,,,,,)
IF vESCOLHA > 0
   vFILE:=aArq[vESCOLHA]
   vFILE:=SUBSTR(vFILE, 1,LEN(vFILE)-4) // Nome do DBF sem a extenção

   DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
   dbUseArea(.T., "DBFCDX", vFILE, "TEMP", .T., .F.)
   SELE TEMP
   HW_BROWSE()
   TEMP->(DbCloseArea())  // FECHA PARA ABRIR DE NOVO
ELSE
   MsgInfo("Nenhuma Tabela Selecionada, Favor Revisar")
ENDIF
RETURN(.T.)

