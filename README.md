# Lager godkjentmappe :ok_hand:
Denne funksjonen er for å lage mapper for godkjente friskvik filler.

Alle de gamle filene some brukes til å lage godkjentmapper er nå slått sammen i en funksjonen som heter
`godkjent()` og argumenter er:

 - `profil` : om det er FHP eller OVP
 - `modus` : valg mellom K, F og B som representerer kommuner, fylker eller bydeler
 - `aar` : utvalgte årgang for å lage godkjentmapper

Eksample hvordan det skal brukes er følgende:

```
source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions_20200430.R')
godkjent(profil = "FHP", modus = "K", aar = 2020)
```

Det er nødvending å **source** `KHfunctions` fil for å hente alle de utvalgte filstier og databasen.
