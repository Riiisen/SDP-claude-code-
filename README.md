# SDP – NXT-Linienfolger (WiSe 2026/27)

NXC-Code für unseren LEGO-NXT-Roboter im System Design Projekt.
Meilenstein: **Mi 09.12.2026, 10:40** (Testbahn, Keller Gebäude 103).

## Dateien

| Datei | Wofür |
|---|---|
| `meilenstein.nxc` | Hauptprogramm: Linie folgen → an der Wand wenden → zurück bis zum Ziel |
| `kalibrierung.nxc` | Misst Grau/Weiß der drei Lichtsensoren und Totzone/Gleichlauf der Motoren |
| `sensortest.nxc` | Zeigt alle Sensorwerte live auf dem Display, kurzer Motortest |
| `pid-messfahrt.nxc` | Roboter von Hand schieben → Startwerte für KP und KD |
| `pid-tuning.csv` | Tabelle aller Testläufe (in Excel öffnen, Trennzeichen `;`) |
| `werte-uebertragen.bat` / `.ps1` | Nimmt die Zeile mit `x` in Spalte „Beste“, trägt die Werte in `meilenstein.nxc` ein und überträgt auf den NXT (nur Windows) |

## Aufbau / Anschlüsse

| Port | Teil |
|---|---|
| IN_1 | Lichtsensor (in `meilenstein`/`pid-messfahrt`: rechts) |
| IN_2 | Lichtsensor Mitte |
| IN_3 | Lichtsensor (in `meilenstein`/`pid-messfahrt`: links) |
| IN_4 | Ultraschall nach vorne |
| OUT_B | Motor links |
| OUT_A | Motor rechts |

`kalibrierung` und `sensortest` zeigen noch IN_1 als „Links“ an.

## Übersetzen und auf den NXT laden

VS Code + Kurs-Plugin `nxt-compiler` (SDP-Webseite → Materialien). `.nxc`-Datei öffnen, oben rechts **Execute on NXT Brick** (übertragen und starten) oder **Transfer to NXT Brick** (nur übertragen).

## Wie `meilenstein.nxc` arbeitet

- **Kalibrierung:** feste Offsets/Skalierung aus `kalibrierung.nxc` (Regelwerk 5.4)
- **Linienlage:** (rechts − links) / Summe aller drei Sensoren → unabhängig von der Helligkeit (Tunnel, Schatten)
- **Dynamische Schwelle:** Min-Max im Zeitfenster von 1 s (5.4), keine feste Schwelle (5.6)
- **Regler:** PD mit festem Takt 15 ms (5.5), Tempo sinkt bei großem Fehler (`SLOW_PCT`)
- **Linie verloren:** war sie mittig → Lücke, geradeaus; war sie seitlich → zur Seite drehen
- **Wand:** alle drei Sensoren weiß (Querstrich) **und** Ultraschall < 30 cm → wenden bzw. Ziel

## Tuning am NXT

Mit `#define BUTTON_TUNING 1` erscheint vor jeder Fahrt ein Menü: Pfeile ändern den Wert, orange geht weiter (KP → KD → BASE → SLOW% → START). Orange während der Fahrt bricht ab.

> **Vor Meilenstein und Wettbewerb `BUTTON_TUNING` auf 0 setzen** und die besten Werte fest eintragen (Regelwerk 1.2 und 6: kein Nachjustieren).

Jeder Testlauf kommt als Zeile in `pid-tuning.csv` – das ist zugleich unsere Begründung der festen Werte für den Zwischenbericht.

## Hinweis

Der Code wurde mit Hilfe von Claude (KI) geschrieben. Laut Regelwerk 1.3 muss **jedes Gruppenmitglied** den Code erklären und die Entscheidungen begründen können – also bitte durchlesen und Fragen in der Gruppe klären.
