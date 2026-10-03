# Ragpit

2D-Pixel-Sandbox mit Ragdoll-Physik, Flüssigkeiten und Pixel-Gore. Gebaut mit Godot 4.4 und GDScript.

Du wirfst eine Pixel-Puppe durch einen dunklen Raum, schneidest sie mit der Klinge, setzt sie in Brand oder frierst sie ein. Ein Statuspanel zeigt dir live ihre Werte und Zustände.

## Auf dem iPhone spielen

Die Web-Version liegt in `web/`. Sie läuft in Safari ohne App Store und ohne Mac.

1. Öffne die Seite in Safari.
2. Tippe auf Teilen und dann auf "Zum Home-Bildschirm".
3. Starte Ragpit über das neue Symbol und dreh das iPhone quer.

Die Web-Version zeichnet Menschen aus rechteckigen Körperteilen als Pixel-Art mit schwarzer Kontur: eckiger Kopf mit Haaren, Auge und Mund auf einem echten Hals, Arme an den Schultern, Shirt, Hose und Schuhe. Jede Puppe bekommt zufällige Haut-, Haar- und Kleidungsfarben. Wasser und Blut laufen in feiner Auflösung. Sie hat 11 Werkzeuge: Greifen, Wasser, Eimer, Klinge, Waffe, Feuer, Eis, Bombe, Infusion, Neue Puppe und Reset.

Oben links unter dem Titel erscheint je nach Werkzeug eine Leiste. Beim Wasser stellst du die Menge in 5 Stufen ein. Bei der Waffe wählst du AK-47, Sturmgewehr oder Glock 17. Jede Waffe ist ein detailliertes Pixel-Sprite in echten Proportionen: die AK-47 mit Holzschaft, Gasrohr und gebogenem Magazin, das Sturmgewehr mit Schiene, Rotpunktvisier und Mündungsfeuerdämpfer, die Glock mit Schlitten, Griffwinkel und Abzugsbügel. Die Waffe steht als Objekt im Raum. Zieh sie am Körper der Waffe an eine neue Stelle. Zieh den Finger irgendwo anders durch den Raum, um zu zielen. Ein roter Laser zeigt dir, wo die Kugel trifft. Rechts unten liegen die Knöpfe: Der rote Knopf schießt und zeigt die Patronen im Magazin. Der runde Knopf "LADEN" lädt nach und das leere Magazin fällt zu Boden. Der Knopf "AUTO" schaltet bei AK-47 und Sturmgewehr zwischen Dauerfeuer und Einzelfeuer um. Du kannst mit einem Finger zielen und mit dem anderen schießen. Die Waffe springt bei jedem Schuss zurück und steigt bei langen Salven nach oben. AK-47 und Sturmgewehr haben 30 Schuss, die Glock 17.

Im Schadenspanel sehen Wunden echt aus: Einschüsse als dunkles Loch mit rotem Rand, Schnitte als schräger Riss, Prellungen als blauroter Fleck und abgetrennte Glieder als offener Stumpf mit Knochen. Blutende Wunden ziehen eine tropfende Blutspur nach unten.

Das Spiel startet mit einem Hauptmenü: Eine verletzte Figur im selben Pixel-Stil wie im Spiel steht unter einer flackernden Lampe, atmet und drückt eine Hand auf ihre Schusswunde. Vom Titel tropft Blut. Von dort kommst du zu SPIELEN, ANLEITUNG und EINSTELLUNGEN. Läuft schon ein Spiel, erscheint WEITERSPIELEN. Die Anleitung erklärt jedes Werkzeug mit seinem Symbol. In den Einstellungen schaltest du Ton, Bildschirmwackeln und das Schadenspanel an oder aus.

Kurze, ruhige Animationen begleiten jeden Klick. Im Menü erscheinen Titel, Knöpfe und Karten nacheinander von unten, die rote Linie unter dem Titel zieht sich auf. Knöpfe geben beim Drücken leicht nach und lösen beim Loslassen aus. Schalter gleiten, das Spiel blendet beim Start weich ein. Im Spiel heben sich gewählte Werkzeuge an, Leisten, Waffenknöpfe, Extras und Hinweise blenden ein und aus, und das Schadenspanel klappt fließend auf und zu.

Es gibt fünf Maps: Labor, Schwimmbad, Treppenhaus, Halle und Eiskeller. Jede Karte zeigt ein gemaltes Bild der Map mit Lampe, Blöcken, Wasser, Eis und den Figuren an ihren Startplätzen, dazu ein eigenes Symbol: Kolben, Wellen, Treppe, Plattformen und Schneeflocke. Der Knopf "MENÜ" im Spiel bringt dich zurück ins Hauptmenü, Reset baut die aktuelle Map neu auf.

Mit "Neue Puppe" tippst du auf die Stelle, an der die Puppe stehen soll. Sie steht dort sofort aufrecht auf dem Boden. Der Eimer saugt Wasser und Blut unter deinem Finger auf.

Tippe auf die Kopfzeile des Schadenspanels, um es zuzuklappen oder aufzuklappen. Zugeklappt bleiben Name, Zustand und EKG sichtbar. Das Spiel merkt sich deine Wahl.

Der Knopf "EXTRAS" oben öffnet eine Liste: Blut entfernen, Wasser entfernen, Feuer löschen, Eis entfernen, Reste entfernen, Alle heilen, Puppe entfernen, Alle Puppen weg, Zeitlupe und Pause. "Eis entfernen" lässt das Eis der Map stehen. "Alle heilen" schließt Wunden und füllt alle Werte auf, abgetrennte Glieder bleiben ab.

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
