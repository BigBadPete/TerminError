**free
// =====================================================================
//  WRTERRJRN  -  API d'ecriture dans le journal d'incidents ERR_JRN
// ---------------------------------------------------------------------
//  Objet      : *PGM  -> appelable en CALL (CL / legacy) ET en CALLP (RPG)
//  Compilation: CRTSQLRPGI OBJ(WRTERRJRN) OBJTYPE(*PGM)
//               (COMMIT(*NONE) est force par SET OPTION ci-dessous :
//                le log est INDEPENDANT de la transaction de l'appelant
//                et survit donc a un ROLLBACK cote appelant.)
//
//  Parametres
//    1  ERR_CODE  CHAR(10)  in        - CPFxxxx, SQLSTATE ou SQLCODE
//    2  ERR_TYPE  CHAR(3)   in        - 'CPF' ou 'SQL'
//    3  PGM       CHAR(10)  in  *opt  - si omis/blanc -> pile d'appels
//    4  ERR_DESC  CHAR(100) in  *opt  - si omis/blanc -> recherche auto
//
//  USER et TIMESTMP sont alimentes par les DEFAULT de la table.
//  Philosophie : "fire and forget" - on n'interrompt jamais l'appelant.
// =====================================================================
Ctl-Opt DftActGrp(*No) ActGrp(*Caller)
        Option(*Srcstmt : *NoDebugIO)
        Text('API journal des incidents');

// ----- Interface programme (*ENTRY) ----------------------------------
Dcl-Pi *N;
  p_errCode Char(7)   Const;
  p_errType Char(3)   Const;
  p_pgm     Char(10)  Const Options(*Nopass);
  p_errDesc Char(100) Const Options(*Nopass);
End-Pi;

// ----- Prototypes API systeme ----------------------------------------
Dcl-Pr QMHRTVM ExtPgm('QMHRTVM');
  rcvVar      Char(32767) Options(*VarSize);
  rcvVarLen   Int(10)  Const;
  format      Char(8)   Const;
  msgId       Char(7)   Const;
  msgFileLib  Char(20)  Const;
  replData    Char(32767) Const Options(*VarSize);
  replDataLen Int(10)  Const;
  replSubVar  Char(10)  Const;
  rtnCtlChar  Char(10)  Const;
  apiError    Char(32767) Options(*VarSize);
End-Pr;

Dcl-Pr QWVRCSTK ExtPgm('QWVRCSTK');
  rcvVar    Char(32767) Options(*VarSize);
  rcvVarLen Int(10)  Const;
  format    Char(8)   Const;
  jobId     Char(56)  Const;
  jobIdFmt  Char(8)   Const;
  apiError  Char(32767) Options(*VarSize);
End-Pr;

// ----- Structure d'erreur API (BytesProvided > 0 => pas d'exception) --
Dcl-Ds apiErr Qualified;
  bytesProv Int(10);
  bytesAvl  Int(10);
  msgId     Char(7);
  rsv       Char(1);
  msgData   Char(256);
End-Ds;

// ----- Variables de travail ------------------------------------------
Dcl-S wPgm  Char(10)  Inz(*Blanks);
Dcl-S wDesc Char(100) Inz(*Blanks);

// Naming systeme + log hors commitment control (independant du ROLLBACK)
Exec SQL SET OPTION NAMING = *SYS, COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

// =====================================================================
//  Corps principal
// =====================================================================
apiErr.bytesProv = %size(apiErr);

// 1) Programme a l'origine de l'erreur
If %Parms >= 3 and p_pgm <> *Blanks;
  wPgm = p_pgm;
Else;
  wPgm = getCallerPgm();
EndIf;

// 2) Libelle de l'erreur
If %Parms >= 4 and p_errDesc <> *Blanks;
  wDesc = p_errDesc;
Else;
  wDesc = getMsgText(p_errType : p_errCode);
EndIf;

// 3) Insertion (ERR_USER et TIMESTMP via DEFAULT de la table)
Exec SQL
  INSERT INTO ERR_JRN
         (ERR_CODE, ERR_TYPE, ERR_DESC, PGM)
  VALUES (:p_errCode, :p_errType, :wDesc, :wPgm);

// Log "fire and forget" : aucun controle de retour ne remonte a l'appelant.
*InLR = *On;
Return;

// =====================================================================
//  getCallerPgm : nom du *PGM appelant via QWVRCSTK (CSTK0100)
//  Remarque : best effort. Pour une fiabilite a 100 %, passez le 3e
//             parametre PGM explicitement depuis l'appelant.
// =====================================================================
Dcl-Proc getCallerPgm;
  Dcl-Pi *N Char(10);
  End-Pi;

  // Receveur CSTK0100 : 5 entiers d'en-tete puis les elements de pile
  Dcl-Ds cstk Len(8192) Qualified;
    bytRtn  Int(10);
    bytAvl  Int(10);
    nbEnt   Int(10);
    offEnt  Int(10);   // offset (base 0) du 1er element
    nbRet   Int(10);
  End-Ds;

  Dcl-S  pEntry Pointer;
  Dcl-Ds entry Len(256) Qualified Based(pEntry);
    entLen  Int(10)  Pos(1);
    pgmName Char(10) Pos(25);  // nom du *PGM (format CSTK0100)
    pgmLib  Char(10) Pos(35);
  End-Ds;

  Dcl-Ds jobId Qualified;
    qName  Char(26) Inz('*');
    intId  Char(16);
    rsv    Char(2)  Inz(*Loval);
    thrInd Int(10)  Inz(1);
    thrId  Char(8)  Inz(*Loval);
  End-Ds;

  Dcl-S myPgm  Char(10);
  Dcl-S caller Char(10) Inz('*UNKNOWN');
  Dcl-S i      Int(10);

  QWVRCSTK( cstk : %size(cstk) : 'CSTK0100'
          : jobId : 'JIDF0100' : apiErr );

  If apiErr.bytesAvl > 0 or cstk.nbRet < 2;
    Return caller;
  EndIf;

  // Element 1 = frame courant de WRTERRJRN. On avance jusqu'au 1er
  // element dont le *PGM differe du notre = l'appelant externe.
  pEntry = %Addr(cstk) + cstk.offEnt;
  myPgm  = entry.pgmName;

  For i = 1 to cstk.nbRet;
    If entry.pgmName <> myPgm and entry.pgmName <> 'QWVRCSTK';
      caller = entry.pgmName;
      Leave;
    EndIf;
    pEntry = pEntry + entry.entLen;
  EndFor;

  Return caller;
End-Proc;

// =====================================================================
//  getMsgText : libelle de l'erreur a partir du code et du type
//    - CPF : message CPFxxxx dans QCPFMSG
//    - SQL : SQLCODE <= 9999  -> message SQLnnnn dans QSQLMSG
//            sinon (SQLSTATE) -> libelle generique "TYPE CODE"
//  (Texte de 1er niveau, sans donnees de substitution : suffisant pour
//   un libelle. Pour le texte exact, passez ERR_DESC depuis l'appelant.)
// =====================================================================
Dcl-Proc getMsgText;
  Dcl-Pi *N Char(100);
    inType Char(3) Const;
    inCode Char(7) Const;
  End-Pi;

  Dcl-Ds rcv Qualified;
    bytRtn    Int(10);
    bytAvl    Int(10);
    lenMsgRet Int(10);
    lenMsgAvl Int(10);
    lenHlpRet Int(10);
    lenHlpAvl Int(10);
    msgText   Char(512);   // commence apres l'en-tete (24 octets) RTVM0100
  End-Ds;

  Dcl-S msgId    Char(7)  Inz(*Blanks);
  Dcl-S msgFile  Char(20) Inz(*Blanks);
  Dcl-S codeTrim Varchar(7);
  Dcl-S codeNum  Int(10);
  Dcl-S result   Char(100);

  result = %Trim(inType) + ' ' + %Trim(inCode);   // valeur par defaut

  Select;
    When inType = 'CPF';
      msgId   = inCode;
      msgFile = 'QCPFMSG   *LIBL';

    When inType = 'SQL';
      codeTrim = %Trim(inCode);
      If %Len(codeTrim) > 0 and %Subst(codeTrim:1:1) = '-';
        codeTrim = %Subst(codeTrim:2);
      EndIf;
      Monitor;
        codeNum = %Int(codeTrim);
        If codeNum > 0 and codeNum <= 9999;
          // 10000+nnn -> '1nnnn' -> on conserve les 4 derniers chiffres
          msgId = 'SQL' + %Subst(%Char(10000 + codeNum):2);
        EndIf;
      On-Error;
        // non numerique (SQLSTATE) : on garde le libelle generique
      EndMon;
      msgFile = 'QSQLMSG   *LIBL';

    Other;
      Return result;
  EndSl;

  If msgId <> *Blanks;
    QMHRTVM( rcv : %size(rcv) : 'RTVM0100' : msgId : msgFile
           : ' ' : 0 : '*NO' : '*NO' : apiErr );
    If apiErr.bytesAvl = 0 and rcv.lenMsgRet > 0;
      result = %Subst(rcv.msgText : 1 : %Min(rcv.lenMsgRet : 100));
    EndIf;
  EndIf;

  Return result;
End-Proc;