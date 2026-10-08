# Changelog

Alle Änderungen an Verwuchert. Jede Version bekommt hier einen Eintrag.

## 0.1.3

Neuer Stil und weniger Simulation, mehr Stadt zum Kennenlernen.

- Isometrische Ansicht: Jedes Gebäude zeigt zwei Wände und das Dach. Linke Wände liegen im Licht, rechte im Schatten.
- Alle Gebäude neu gemalt, mit Satteldächern in zwei Richtungen, Giebeln, Gauben, Schornsteinen und Zäunen.
- Türen zeigen zur Straße, wenn beim Bauen eine daneben liegt.
- Autos als kleine Iso-Kisten in vier Richtungen, mit Lichtkegel in der Nacht.
- Unter der Karte liegt eine Erdkante mit Schichten, Steinen und Wurzeln.
- Strom und Wasser fließen über das Straßennetz statt über Kreise. Ein Kraftwerk versorgt 24 Plätze, ein Wasserturm 16 Häuser. Die Leiste oben zeigt die Auslastung.
- Strommasten mit Leitungen und Laternen stehen nur an Straßen mit Strom. Hydranten zeigen Straßen mit Wasser.
- Jedes Haus bekommt beim Einzug eine Familie mit Namen und Bewohnern. Jede Straße hat einen Namen, jedes Gebäude eine Adresse.
- Läden und Fabriken heißen nach ihren Besitzern, zum Beispiel "Bäckerei Krüger".
- Chronik unten links: wer einzieht, was öffnet, wer auszieht. Sie wird mit dem Spielstand gespeichert.
- Grundsteuer: Leere Häuser zahlen 6 pro Zahltag. Wer kein Geld für das Kraftwerk hat, spart es zusammen.
- Gebäude lassen sich auch über ihr Bild anklicken, nicht nur über ihre Felder.

## 0.1.2

- Web-Version: Der Knopf "Vollbild" funktioniert jetzt auch dort, wo der Browser echtes Vollbild verbietet. Dann füllt das Spiel das ganze Fenster der Seite.
- Im Vollbild erscheint oben rechts "Vollbild beenden".

## 0.1.1

- Web-Version: Das Spiel läuft als Artefakt im Browser.
- Export-Vorlage export_presets.cfg für Web, ohne Threads, damit keine besonderen Server-Header nötig sind.
- web/page.html ist die Seite um das Spiel. Sie skaliert das Bild in ganzen Vielfachen und füllt die Bühne.
- web/build.sh baut alle Dateien für das Artefakt.
- Im Browser fehlt der Knopf "Beenden" im Hauptmenü.

## 0.1.0

Phase 1, Stadtbau, als spielbarer Prototyp.

- Eigenes Godot-4.4-Projekt im Ordner verwuchert/, getrennt von Ragpit.
- Hauptmenü mit Abendhimmel, Häuserzeile mit Ranken, Glühwürmchen und einem Titel, über den Ranken wachsen.
- Raster mit 24 x 16 Feldern zu 32 Pixeln in leichter Schrägansicht, umgeben von dichtem Wald.
- Sieben Gebäude: Straße, Wohnhaus, Laden, Fabrik, Park, Wasserturm, Kraftwerk. Alle Grafiken entstehen im Code.
- Wohnhäuser in drei Bauformen, aus Holz oder Ziegel, mit zufälligen Farben für Dach, Wand und Tür.
- Straßen verbinden sich automatisch, mit Gehwegen, Zebrastreifen, Kanaldeckeln und Laternen.
- Bautrupps: zwei Baustellen laufen gleichzeitig, weitere warten. Baustellen zeigen Gerüst, Arbeiter, Kran und Fortschritt.
- Versorgung: Häuser brauchen Straße, Strom und Wasser. Läden brauchen Kunden. Warnblasen zeigen, was fehlt.
- Einnahmen alle 12 Sekunden: Steuern, Läden, Fabriken, minus Unterhalt. Parks bringen mehr, Fabrikrauch weniger.
- Jedes Gebäude speichert Material, Zustand und Inhalt. Der Inhalt liegt in Phase 3 in den Ruinen.
- Tag und Nacht mit weichem Farbverlauf, leuchtenden Fenstern, Laternen, Lichtkegeln und Autoscheinwerfern.
- Schatten wandern mit der Sonne und überlagern sich ohne doppelte Dunkelheit.
- Autos fahren rechts, Fußgänger laufen auf dem Gehweg von Haus zu Laden oder Park.
- Rauch, Dampf, Staub, fallende Blätter, Funken, Wolkenschatten und Vogelschwärme.
- Bäume wiegen im Wind, Böen laufen als Welle über die Karte. Teiche mit Schilf, Seerosen und Glitzern.
- Eigene Pixel-Schrift mit Umlauten und ß. Alle Menüs nutzen sie.
- Geschwindigkeit: Pause, 1x, 2x, 3x. Ziel nach 8 Minuten, Ende nach 10 Minuten.
- Button "Stadt fertig" speichert und startet Phase 2. Phase 2 zeigt vorerst die übergebenen Stadtdaten.
- Speichern und Laden als JSON, automatisch jede Minute.
- Alle Werte für das Balancing in config/balance.json.
- Tests: tests/play_test.gd und tests/input_test.gd spielen Phase 1 automatisch durch.
