**free

// =====================================================================
// Programme : Gestion des codes retour SQL en RPG Free Form
//             + journalisation des incidents via l'API WRTERRJRN
// =====================================================================
//  Principe : l'appelant se contente de DETECTER l'erreur et passe le
//  minimum a l'API -> WrtErrJrn(code : type). L'API WRTERRJRN fait tout
//  le reste : libelle de l'erreur, programme appelant, utilisateur et
//  horodatage. Aucun Dsply, aucun GET DIAGNOSTICS cote applicatif.
//
//  Liaison : ce programme appelle le *PGM WRTERRJRN.
//  CRTSQLRPGI ... OBJTYPE(*PGM)  (WRTERRJRN doit etre sur la *LIBL)
// =====================================================================

Ctl-Opt DftActGrp(*No) ActGrp(*Caller)
        Option(*Srcstmt : *NoDebugIO)
        Text('Ex Gestions Erreurs');

/COPY QRPGLESRC,ERRLOG_H          // prototype de WrtErrJrn

// =====================================================================
// Programme principal
// =====================================================================
ExempleSelect();
ExempleInsert();
ExempleUpdate();
ExempleDelete();
ExempleCurseur();
ExempleCurseurUpdate();

*InLR = *On;
Return;

// =====================================================================
// EXEMPLE 1 : SELECT simple avec gestion des codes retour
// =====================================================================
Dcl-Proc ExempleSelect;

  // Variables locales a la procedure
  Dcl-S clientId     Int(10);
  Dcl-S clientNom    Char(50);
  Dcl-S clientPrenom Char(50);

  clientId = 12345;

  Exec SQL
    SELECT NOM, PRENOM
    INTO :clientNom, :clientPrenom
    FROM CLIENTS
    WHERE IDCLIENT = :clientId;

  Select;
    When SQLCODE = 0;
      // client trouve -> traitement nominal
    When SQLCODE = 100;
      // aucun client trouve
    When SQLCODE < 0;
      WrtErrJrn(SQLSTATE : 'SQL');
  Endsl;

End-Proc;

// =====================================================================
// EXEMPLE 2 : INSERT avec gestion des codes retour
// =====================================================================
Dcl-Proc ExempleInsert;

  // Variables locales a la procedure
  Dcl-S clientId     Int(10);
  Dcl-S clientNom    Char(50);
  Dcl-S clientPrenom Char(50);

  clientId     = 99999;
  clientNom    = 'DUPONT';
  clientPrenom = 'Jean';

  Exec SQL
    INSERT INTO CLIENTS (IDCLIENT, NOM, PRENOM, DATECREA)
    VALUES (:clientId, :clientNom, :clientPrenom, CURRENT_DATE);

  Select;
    When SQLCODE = 0;
      Exec SQL COMMIT;             
      If SQLCODE < 0;
        WrtErrJrn(SQLSTATE : 'SQL');
      Endif;
    When SQLCODE < 0;
      WrtErrJrn(SQLSTATE : 'SQL');
      Exec SQL ROLLBACK;
  Endsl;

End-Proc;

// =====================================================================
// EXEMPLE 3 : UPDATE avec gestion des codes retour
// =====================================================================
Dcl-Proc ExempleUpdate;

  // Variables locales a la procedure
  Dcl-S clientId  Int(10);
  Dcl-S clientNom Char(50);

  clientId  = 12345;
  clientNom = 'MARTIN';

  Exec SQL
    UPDATE CLIENTS
    SET NOM = :clientNom,
        DATEMAJ = CURRENT_TIMESTAMP
    WHERE IDCLIENT = :clientId;

  Select;
    When SQLCODE = 0;
      Exec SQL COMMIT;                 
      If SQLCODE < 0;
        WrtErrJrn(SQLSTATE : 'SQL');
      Endif;
    When SQLCODE = 100;
      // aucun client trouve
    When SQLCODE < 0;
      WrtErrJrn(SQLSTATE : 'SQL');
      Exec SQL ROLLBACK;
  Endsl;

End-Proc;

// =====================================================================
// EXEMPLE 4 : DELETE avec gestion des codes retour
// =====================================================================
Dcl-Proc ExempleDelete;

  // Variable locale a la procedure
  Dcl-S clientId Int(10);

  clientId = 99999;

  Exec SQL
    DELETE FROM CLIENTS
    WHERE IDCLIENT = :clientId;

  Select;
    When SQLCODE = 0;
      Exec SQL COMMIT;               
      If SQLCODE < 0;
        WrtErrJrn(SQLSTATE : 'SQL');
      Endif;
    When SQLCODE < 0;
      WrtErrJrn(SQLSTATE : 'SQL');
      Exec SQL ROLLBACK;
  Endsl;

End-Proc;

// =====================================================================
// EXEMPLE 5 : CURSEUR avec gestion complete des codes retour
// =====================================================================
Dcl-Proc ExempleCurseur;

  // Variables locales a la procedure
  Dcl-S clientId     Int(10);
  Dcl-S clientNom    Char(50);
  Dcl-S clientPrenom Char(50);
  Dcl-S montant      Packed(11:2);
  Dcl-S finCurseur   Ind Inz(*Off);

  montant = 1000.00;

  Exec SQL
    DECLARE C1 CURSOR FOR
    SELECT IDCLIENT, NOM, PRENOM
    FROM CLIENTS
    WHERE SOLDE > :montant
    ORDER BY NOM;

  Exec SQL OPEN C1;

  If SQLCODE < 0;
    WrtErrJrn(SQLSTATE : 'SQL');
    Return;
  Endif;

  Dou finCurseur;

    Exec SQL
      FETCH NEXT FROM C1
      INTO :clientId, :clientNom, :clientPrenom;

    Select;
      When SQLCODE = 0;
        // traiter la ligne
      When SQLCODE = 100;
        finCurseur = *On;
      When SQLCODE < 0;
        WrtErrJrn(SQLSTATE : 'SQL');
        finCurseur = *On;
    Endsl;

  Enddo;

  Exec SQL CLOSE C1;

  If SQLCODE < 0;
    WrtErrJrn(SQLSTATE : 'SQL');
  Endif;

End-Proc;

// =====================================================================
// EXEMPLE 6 : Curseur FOR UPDATE avec gestion des erreurs
// =====================================================================
Dcl-Proc ExempleCurseurUpdate;

  // Variables locales a la procedure
  Dcl-S clientId      Int(10);
  Dcl-S clientNom     Char(50);
  Dcl-S montant       Packed(11:2);
  Dcl-S nouveauMontant Packed(11:2);
  Dcl-S finCurseur    Ind Inz(*Off);

  nouveauMontant = 500.00;

  Exec SQL
    DECLARE C2 CURSOR FOR
    SELECT IDCLIENT, NOM, SOLDE
    FROM CLIENTS
    WHERE SOLDE < 0
    FOR UPDATE OF SOLDE;

  Exec SQL OPEN C2;

  If SQLCODE < 0;
    WrtErrJrn(SQLSTATE : 'SQL');
    Return;
  Endif;

  Dou finCurseur;                

    Exec SQL
      FETCH NEXT FROM C2
      INTO :clientId, :clientNom, :montant;

    Select;
      When SQLCODE = 0;
        Exec SQL
          UPDATE CLIENTS
          SET SOLDE = SOLDE + :nouveauMontant
          WHERE CURRENT OF C2;

        If SQLCODE < 0;
          WrtErrJrn(SQLSTATE : 'SQL');
        Endif;

      When SQLCODE = 100;
        finCurseur = *On;

      When SQLCODE < 0;
        WrtErrJrn(SQLSTATE : 'SQL');
        finCurseur = *On;
    Endsl;

  Enddo;

  Exec SQL CLOSE C2;

  Exec SQL COMMIT;
  If SQLCODE < 0;                 
    WrtErrJrn(SQLSTATE : 'SQL');
  Endif;

End-Proc;

