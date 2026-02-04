*&---------------------------------------------------------------------*
*& Report ZUTI_MATRICOLA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

* FINALITA' DI QUESTO REPORT -> vedere gli impianti che hanno apparecchiature montate ma in stato DISP.

*- V_EGER (TABELLA) con vincolo fine validità 31.12.9999 -> mi prendo il n.log.apparecchiatura
*- BAPI_EQUI_GETSTATUS (FUNZIONE) -> inserire equipment e LANGUAGE_ISO = IT -> ottengo lo status (a noi interessa lo stato DISP)
*- BAPI_EQUI_GESTATUS essendo lenta verrà utilizzata una select massiva su jest
*- EASTL (TABELLA) -> in cui inserire il n.log.apparecchiatura e fine validità per i disp trovati.
*
*---- output finale report colonne -----
*- equipment
*- num. di serie
*- codice materiale
*- n.log.apparecchiatura
*- impianto
