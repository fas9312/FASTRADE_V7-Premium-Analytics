FASTRADE APP V3.1 - GENERAZIONE APK GRATIS CON GITHUB ACTIONS
=============================================================

COSA CONTIENE QUESTO PROGETTO
- App Android FasTrade V3 con grafica dark/blu/verde.
- Dashboard, nuova operazione, diario, statistiche e bankroll.
- Gestione Strategie: aggiungi/modifica/attiva/disattiva strategie personalizzate.
- Workflow GitHub Actions già pronto per generare l'APK automaticamente.

COME GENERARE L'APK ONLINE
1. Vai su https://github.com e crea un account gratuito, se non lo hai già.
2. Crea un nuovo repository (può essere privato).
3. Estrai questo ZIP sul PC.
4. Carica TUTTI i file e le cartelle contenuti nella cartella FasTradeApp_v3_1 nel repository.
   IMPORTANTE: deve essere caricata anche la cartella nascosta .github/workflows.
5. Dopo il caricamento, apri la scheda "Actions" del repository.
6. Seleziona "Build FasTrade APK".
7. Premi "Run workflow" e poi ancora "Run workflow".
8. Quando la build diventa verde, aprila.
9. In fondo alla pagina, nella sezione "Artifacts", clicca "FasTrade-APK".
10. GitHub scaricherà uno ZIP; al suo interno trovi:
    FasTrade-v3.1-debug.apk

INSTALLAZIONE SUL TELEFONO
- Trasferisci il file .apk sul telefono Android.
- Aprilo.
- Se Android lo richiede, autorizza temporaneamente l'installazione da quella fonte.
- Installa FasTrade.

NOTA
Questa procedura genera un APK DEBUG, perfetto per uso personale e test sul proprio telefono.
Per pubblicare l'app sul Play Store servirà in seguito una build RELEASE firmata con una chiave privata.
