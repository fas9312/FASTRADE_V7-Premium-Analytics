# FasTrade Trading Journal V7 — iOS

Questa cartella contiene la versione nativa iPhone della V7 Android.

Funzioni incluse nella prima base iOS:
- Dashboard con bankroll, net profit, ROI e win rate
- Grafico andamento bankroll
- Nuova operazione con sport, mercato, strategia, minuto, tranche, stake %, quota, esito, P/L, voto e note
- Diario operazioni con filtri Tutte/Oggi/Settimana/Mese
- Statistiche generali e performance per strategia
- Bankroll e Starting Bank
- Gestione attivazione strategie
- Esportazione CSV
- Persistenza locale dei dati

## Generazione progetto
Richiede macOS con Xcode e XcodeGen.

```bash
cd ios
xcodegen generate
open FasTradeV7.xcodeproj
```

## Installazione su iPhone
Per installare sul dispositivo fisico occorre aprire il progetto in Xcode, selezionare un Apple Development Team e firmare l'app con il proprio Apple ID / account Apple Developer.

La grafica riprende la palette V7 Android: fondo blu notte, card scure, accenti blu/ciano, verde per profitti e rosso per perdite.
