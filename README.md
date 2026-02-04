ZUTI_MATRICOLA - LINGUAGGIO ABAP

🎯 Finalità del Report  
***
Il report nasce con l'obiettivo di individuare le anomalie nel sistema SAP IS-U, specificamente per identificare gli impianti che hanno apparecchiature ancora associate (montate) nonostante queste risultino in stato DISP (Disponibile).

----------------------------------------------------------------------------------------
📊 Logica di Estrazione  
Il programma segue un flusso logico suddiviso in tre fasi principali:

    Analisi Anagrafica (Tabella V_EGER)
        Viene applicato un vincolo sulla fine validità al 31.12.9999.
        Viene estratto il N. Logico dell'Apparecchiatura (LOGIKNR) per ogni dispositivo.
    Verifica dello Stato (Tabella JEST)
        Inizialmente prevista tramite la funzione BAPI_EQUI_GETSTATUS.
        Ottimizzazione: Poiché la BAPI risulta lenta nell'elaborazione di grandi moli di dati (488.000 record), è stata implementata una SELECT massiva sulla tabella JEST.
        Viene ricercato lo stato DISP tramite il codice interno I0099.
    Incrocio Dati Impianto (Tabella EASTL)
        Utilizzo del N. Logico Apparecchiatura per interrogare la tabella.
        Verifica della fine validità per confermare le apparecchiature che risultano ancora associate a un impianto.

----------------------------------------------------------------------------------------
📋 Output Finale  
Il report produce una griglia ALV con le seguenti colonne:

    Equipment
    Num. di Serie (Matricola)
    Codice Materiale
    N. Log. Apparecchiatura
    Impianto (ANLAGE)
