-- =====================================================================
--  Table de surveillance des incidents
--  Nom systeme : ERR_JRN   /   Nom long SQL : JOURNAL_ERREURS
--  DB2 for i
-- ---------------------------------------------------------------------
--  >>> Adapter le schema/bibliotheque à votre environnement <<<
-- =====================================================================

CREATE OR REPLACE TABLE JOURNAL_ERREURS  FOR SYSTEM NAME ERR_JRN (

    ERR_ID    BIGINT
              GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1)
              NOT NULL,
    ERR_CODE  CHAR(7)       NOT NULL,        -- CPFxxxx, SQLSTATE ou SQLCODE
    ERR_TYPE  CHAR(3)       NOT NULL,        -- 'CPF' ou 'SQL'
    ERR_DESC  VARCHAR(100)  DEFAULT NULL,    -- libelle de l'erreur
    PGM       CHAR(10)      DEFAULT NULL,    -- programme a l'origine
    ERR_USER  CHAR(18)      DEFAULT USER NOT NULL,            -- utilisateur
    TIMESTMP  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL, -- horodatage

    CONSTRAINT ERR_JRN_PK      PRIMARY KEY (ERR_ID),
    CONSTRAINT ERR_JRN_TYPE_CK CHECK (ERR_TYPE IN ('CPF','SQL'))
);

-- En-tetes de colonnes
LABEL ON COLUMN JOURNAL_ERREURS (
    ERR_ID    IS 'Id',
    ERR_CODE  IS 'Code erreur',
    ERR_TYPE  IS 'Type erreur',
    ERR_DESC  IS 'Libelle erreur',
    PGM       IS 'Programme',
    ERR_USER  IS 'Utilisateur',
    TIMESTMP  IS 'Date heure'
);

LABEL ON TABLE ERR_JRN IS 'Journal des erreurs / incidents';

-- Index utiles pour la surveillance
CREATE INDEX ERR_JRN_DT
    ON ERR_JRN (TIMESTMP DESC);

CREATE INDEX ERR_JRN_CD
    ON ERR_JRN (ERR_TYPE, ERR_CODE);
