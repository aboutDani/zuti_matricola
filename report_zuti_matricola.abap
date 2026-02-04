*&---------------------------------------------------------------------*
*& Report ZUTI_MATRICOLA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zuti_matricola.

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

*--- 1. DEFINIZIONE DELLE COLONNE DEL REPORT e select su tabella V_EGER
TYPES: BEGIN OF ty_output,
         equnr   TYPE v_eger-equnr,   " Equipment
         geraet  TYPE v_eger-geraet,  " Matricola
         matnr   TYPE v_eger-matnr,   " Materiale
         logiknr TYPE v_eger-logiknr, " N. Logico
         anlage  TYPE eastl-anlage,   " Impianto
       END OF ty_output.

DATA: lt_tabella_finale TYPE TABLE OF ty_output, " Tabella finale che vedrò a video
      lo_alv            TYPE REF TO cl_salv_table.

START-OF-SELECTION.

* TABELLA V_EGER
  SELECT equnr, geraet, matnr, logiknr
    FROM v_eger
    INTO CORRESPONDING FIELDS OF TABLE @lt_tabella_finale
    WHERE bis = '99991231'. " Prende solo i dati attuali

  IF sy-subrc = 0.

*--- 2. FILTRO PER STATO "DISP" -> non utilizzo BAPI, perchè lenta nell'elaborazione dei 488.000 record
* Questa parte serve a scartare tutti i contatori che non sono liberi a magazzino

    "struttura per contenere l'Object Number
    TYPES: BEGIN OF ty_id_oggetto,
             objnr TYPE j_objnr,   " Il campo OBJNR deve essere di 22 caratteri
           END OF ty_id_oggetto.

    " Dichiarazione delle tabelle interne
    DATA: lt_lista_id_cerca TYPE TABLE OF ty_id_oggetto, " Tabella degli ID
          ls_id_oggetto     TYPE ty_id_oggetto,          " Riga per la tabella sopra
          lt_risultati_disp TYPE TABLE OF j_objnr,      " Tabella per gli ID che sono DISP
          lv_id_da_testare  TYPE j_objnr.               " Variabile per confrontare i dati nel loop

    " Trasformo ogni Equipment (18 caratteri) nel formato OBJNR (22 caratteri)
    " aggiungendo il prefisso 'IE' richiesto dalla tabella JEST.
    LOOP AT lt_tabella_finale INTO DATA(ls_riga_v_eger).
      ls_id_oggetto-objnr = 'IE' && ls_riga_v_eger-equnr. " Unisco 'IE' al numero equipment
      APPEND ls_id_oggetto TO lt_lista_id_cerca.       " Inserisco l'ID nella lista di ricerca
    ENDLOOP.

    " Invece di interrogare un record alla volta, controllo tutta la lista.
    IF lt_lista_id_cerca IS NOT INITIAL.
      SELECT objnr FROM jest
        INTO TABLE @lt_risultati_disp
        FOR ALL ENTRIES IN @lt_lista_id_cerca " Confronto massivo con la lista
        WHERE objnr = @lt_lista_id_cerca-objnr
          AND stat  = 'I0099'          " I0099 è il codice interno fisso per lo stato 'DISP'
          AND inact = ' '.             " ' ' (spazio) significa che lo stato è attualmente ATTIVO
    ENDIF.

    SORT lt_risultati_disp.

    " Scorro la tabella principale e verifichiamo chi ha superato il controllo dello stato.
    LOOP AT lt_tabella_finale ASSIGNING FIELD-SYMBOL(<fs_riga>).
      " ID dell'oggetto corrente per il confronto
      lv_id_da_testare = 'IE' && <fs_riga>-equnr.

      " Cerchiamo l'ID corrente nella lista dei risultati DISP ottenuti dal database
      READ TABLE lt_risultati_disp WITH KEY table_line = lv_id_da_testare
           BINARY SEARCH
           TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        CLEAR <fs_riga>-equnr.
      ENDIF.
    ENDLOOP.

    " Elimino i record marcati come 'non DISP' -> con EQUNR vuoto
    DELETE lt_tabella_finale WHERE equnr IS INITIAL.

*--- 3. RECUPERO IMPIANTO (EASTL)
    IF lt_tabella_finale IS NOT INITIAL.

      " Cerco gli impianti attivi
      SELECT logiknr, anlage FROM eastl
        INTO TABLE @DATA(lt_lista_impianti)
        FOR ALL ENTRIES IN @lt_tabella_finale
        WHERE logiknr = @lt_tabella_finale-logiknr
          AND bis     = '99991231'.

      SORT lt_lista_impianti BY logiknr.

      LOOP AT lt_tabella_finale ASSIGNING FIELD-SYMBOL(<fs_anomalia>).
        READ TABLE lt_lista_impianti WITH KEY logiknr = <fs_anomalia>-logiknr
             BINARY SEARCH INTO DATA(ls_impianto).

        IF sy-subrc = 0.
          <fs_anomalia>-anlage = ls_impianto-anlage.
        ELSE.
          CLEAR <fs_anomalia>-equnr.
        ENDIF.
      ENDLOOP.

      DELETE lt_tabella_finale WHERE equnr IS INITIAL.

    ENDIF.

*--- 4. VISUALIZZAZIONE FINALE con griglia alv
    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = lt_tabella_finale ).

        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->display( ).
      CATCH cx_salv_msg.
        MESSAGE 'Errore visualizzazione' TYPE 'E'.
    ENDTRY.

  ELSE.
    WRITE: / 'Nessun dato trovato.'.
  ENDIF.
