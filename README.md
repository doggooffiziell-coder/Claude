# Ragpit

2D-Pixel-Sandbox mit Ragdoll-Physik, Flüssigkeiten und Pixel-Gore. Gebaut mit Godot 4.4 und GDScript.

Du wirfst eine Pixel-Puppe durch einen dunklen Raum, schneidest sie mit der Klinge, setzt sie in Brand oder frierst sie ein. Ein Statuspanel zeigt dir live ihre Werte und Zustände.

## Auf dem iPhone spielen

Die Web-Version liegt in `web/`. Sie läuft in Safari ohne App Store und ohne Mac.

1. Öffne die Seite in Safari.
2. Tippe auf Teilen und dann auf "Zum Home-Bildschirm".
3. Starte Ragpit über das neue Symbol und dreh das iPhone quer.

Die Web-Version zeichnet Puppen und Fleischfetzen als große Pixel-Art mit schwarzer Kontur und weicher Schattierung. Wasser und Blut laufen in feiner Auflösung. Sie hat 11 Werkzeuge: Greifen, Wasser, Eimer, Klinge, Waffe, Feuer, Eis, Bombe, Infusion, Neue Puppe und Reset.

Oben links unter dem Titel erscheint je nach Werkzeug eine Leiste. Beim Wasser stellst du die Menge in 5 Stufen ein. Bei der Waffe wählst du AK-47, Sturmgewehr oder Glock 17. Die Waffe steht als Objekt im Raum: Zieh sie mit dem Finger an eine neue Stelle, tippe woanders hin und sie schießt genau dorthin. AK-47 und Sturmgewehr schießen Dauerfeuer, solange du drückst, die Glock einen Schuss pro Tippen.

Das Spiel startet mit einem Hauptmenü und fünf Maps: Labor, Schwimmbad, Treppenhaus, Halle und Eiskeller. Der Knopf "MENÜ" oben links bringt dich zurück, Reset baut die aktuelle Map neu auf.

Mit "Neue Puppe" tippst du auf die Stelle, an der die Puppe stehen soll. Sie steht dort sofort aufrecht auf dem Boden. Der Eimer saugt Wasser und Blut unter deinem Finger auf.

Das Schadenspanel zeigt eine Körpertafel von vorn in normalen Proportionen. Jeder Körperteil ist eine eigene Fläche mit schmalem Spalt und färbt sich nach seinem Schaden von Weiß über Gelb und Orange bis Rot. Fehlende Teile erscheinen als gestrichelte Umrisse. Oben läuft ein EKG.

Die Infusion hängt einen Blutbeutel mit Schlauch an die Puppe. Sie füllt Blut auf, schließt Wunden, senkt Schmerz und weckt eine bewusstlose Puppe. Eine tote Puppe rettet sie nicht mehr.

Zustände: WACH, K.O. und TOT. Eine K.O.-Puppe atmet, ihr Herz schlägt und sie wacht nach einigen Sekunden wieder auf. Eine tote Puppe zuckt kurz und bleibt liegen. Verletzungen ändern die Bewegung: ein kaputtes Bein verhindert das Stehen, ein verletzter Arm hängt schlaff, Schmerz lässt die Puppe sich winden und eine Hand auf die Wunde drücken, Feuer und Ertrinken lösen Panik aus. Liegt eine wache Puppe am Boden, versucht sie aufzustehen. Mit einem kaputten Bein schafft sie es nicht und fällt zurück.

`web/ragpit.html` ist die Seite für die Claude-Artifact-Ansicht. `docs/index.html` ist dieselbe Seite als vollständige HTML-Datei mit App-Symbol für GitHub Pages. Nach jeder Änderung an `web/ragpit.html` baut `web/build.sh` die Datei neu.

Mit GitHub Pages läuft das Spiel unter https://doggooffiziell-coder.github.io/Claude/ und startet vom Home-Bildschirm im Vollbild ohne Browserleiste.

Der Raum passt seine Breite an den Bildschirm an, damit links und rechts keine schwarzen Balken bleiben.

## Starten in Godot

1. Installiere Godot 4.4 oder neuer.
2. Öffne den Ordner im Projektmanager über "Importieren".
3. Drücke F5.

## Steuerung

| Eingabe | Aktion |
| --- | --- |
| Linke Maustaste oder Finger | Werkzeug benutzen |
| Klick auf die Toolbar | Werkzeug wählen |
| 1 bis 7 | Werkzeug wählen |
| N | Neue Puppe |
| R | Reset |

## Werkzeuge

1. Greifen: Puppe packen, ziehen und werfen.
2. Wasser: Wasser aus dem Cursor gießen.
3. Klinge: Schnell durch die Puppe ziehen. Schnelle Schnitte trennen Glieder ab.
4. Feuer: Flammen setzen. Die Puppe fängt Feuer. Wasser löscht.
5. Eis: Eisblöcke setzen. Kontakt friert die Puppe ein.
6. Neue Puppe: Lässt eine neue Puppe unter der Lampe fallen.
7. Reset: Leert den Raum und stellt eine Puppe hin.

## Statuspanel

Balken: KO Bewusstsein, BL Blut, PN Schmerz, O2 Sauerstoff, HR Herzschlag.

Tags: OUT, BLEED, FIRE, CHOKE, AGONY, HEAL, BLADE, TORN, FROZEN.

- Offene Wunden senken BL. Unter 35 BL wird OUT aktiv.
- Treffer erhöhen PN. Ab 65 PN wird AGONY aktiv.
- Kopf unter Wasser senkt O2 und aktiviert CHOKE.
- Abgetrennte Glieder aktivieren TORN.
- Nach 4 Sekunden ohne Schaden startet HEAL. Werte steigen langsam, Wunden schließen sich.

## Aufbau

| Datei | Inhalt |
| --- | --- |
| `scripts/world.gd` | Falling-Sand-Raster mit Wasser, Blut, Feuer, Eis, Dampf und Rauch. Rendert über Image und ImageTexture. |
| `scripts/doll.gd` | Verlet-Ragdoll mit Gelenkgrenzen, Wunden, Blutung, Abtrennen und Vitalwerten. |
| `scripts/ui.gd` | Statuspanel, Toolbar und Cursor, komplett per `_draw()`. |
| `scripts/pixel_font.gd` | Eigene 3x5-Pixelschrift. |
| `scripts/background.gd` | Raum und Deckenlampe. |
| `scripts/main.gd` | Szenenaufbau, Eingabe, Werkzeuge und Lichtkegel. |

Das Spiel rendert in 384 x 216 Pixeln und skaliert mit Nearest-Filter auf die Fenstergröße.
