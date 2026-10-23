# Weltbox

Dein eigenes God-Game. Eine einzige Datei, `index.html`. Öffne sie im Browser, auch am Handy.

## Was drin ist

- Welt aus Kontinenten oder Inseln, leeres Meer oder leeres Grasland
- Terrain malen: Tiefsee, Wasser, Sand, Gras, Wald, Hügel, Berg, Schnee, Sumpf, Acker, Lava, Asche
- Völker: Mensch, Elf, Ork, Zwerg. Sie gründen Reiche, fällen Bäume, bauen Häuser, Felder und Türme und bekommen Kinder.
- Tiere und Monster: Schaf, Wolf, Drache, Zombie
- Kräfte: Feuer, Regen, Blitz, Meteor, Bombe, Säure, Beben, Segen, Fluch, Seuche, Löschen
- Politik: Reiche erklären sich Krieg und schließen Frieden. Du kannst beides auslösen.
- Tag und Nacht, Grenzen, Götterlaune (zufällige Ereignisse), Speichern und Laden im Browser

## Eigene Ideen einbauen

Alles Wichtige steht an wenigen Stellen in `index.html`.

- Neues Gelände: Konstante und Eintrag in `TD` ergänzen, dazu ein Werkzeug in `TOOLS` mit `paintT(ID)`.
- Neues Volk oder Tier: Eintrag in `SP` (Werte, Farben, Namen). Die Art der KI wählst du mit `ai`: `civ`, `sheep`, `wolf`, `zombie` oder `dragon`.
- Neue KI: Funktion in `AI` schreiben, zum Beispiel `AI.fisch = function(c){...}`.
- Neue Kraft: Funktion schreiben und in `TOOLS` eintragen. `brush:1` nutzt den Pinsel, `fixedR` zeichnet einen festen Kreis, `rate` ist die Pause zwischen zwei Anwendungen in Millisekunden, `instant:1` führt den Knopf sofort aus.
- Neues Gebäude: Typ in `addBuilding` und `drawBuilding` ergänzen, Bau-Regeln in `kingdomStep`.
- Spielregeln für Reiche: `kingdomStep` (Wirtschaft, Wachstum) und `diplomacy` (Kriegslust).

Im Browser steht das Objekt `G` für Experimente in der Konsole bereit, zum Beispiel `G.spawn('dragon', 50, 50)`.
