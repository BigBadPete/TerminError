**free
      // ===================================================================
      //  ERRLOG_H  -  Prototype d'appel de l'API journal incidents
      //  A inclure par /COPY dans les programmes appelants RPGLE.
      // ===================================================================

      Dcl-Pr WrtErrJrn ExtPgm('WRTERRJRN');
        errCode  Char(7)  Const;                         // CPFxxxx, SQLSTATE ou SQLCODE
        errType  Char(3)   Const;                        // 'CPF', 'STS' ou 'COD'
        pgm      Char(10)  Const Options(*Nopass:*Omit); // *Omit = pile d'appels auto
        errDesc  Char(100) Const Options(*Nopass:*Omit); // *Omit = recherche auto
      End-Pr;