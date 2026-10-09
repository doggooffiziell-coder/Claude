# Changelog

Alle Änderungen an Verwuchert. Jede Version bekommt hier einen Eintrag.

## 0.2.0

Phase 2: der Zeitraffer.

- "Stadt fertig" startet 50 Jahre in 45 Sekunden. Jahreszähler mit Jahreszeit, Zeitleiste mit Ereignissen, Chronik am unteren Rand, Knopf "Überspringen" (zweimal drücken springt zum Ende).
- Die Kamera fährt im Nahbild über die auffälligsten Gebäude und zieht zum Schluss auf die ganze Stadt zurück.
- Der Verfall folgt aus Typ, Material und Seed (DecayModel). Holz fault schnell, Ziegel hält länger, Beton am längsten, Stahl rostet. Jede Stadt verwuchert anders, dieselbe Stadt immer gleich.
- Neue Shader malen den Verfall Pixel für Pixel in der Palette: Moos und Ranken von unten, Rost in Streifen, Löcher im Dach, Einsturz von oben nach unten mit Schutt am Fuß, Schnee auf allen Kanten. Der Schatten schrumpft mit dem Gebäude.
- Der Boden verändert sich: Gras bricht durch Asphalt und Gehwege, Wasser sammelt sich in den Senken, im Winter liegt Schnee.
- Pflanzen wachsen vom Trieb über den Busch zum Baum, in den Ruinen, auf den Straßen und im Gras. Neuer Trieb als Grafik.
- Jahreszeiten färben die Welt. Regen im Frühling und Herbst, fallendes Laub im Herbst, Schnee im Winter. Tag und Jahreszeit laufen in eigenem Tempo, damit nichts flackert.
- Die Lichter gehen aus, wenn das Kraftwerk ausfällt, die Häuser leeren sich vorher.
- Am Ende nennt eine Zusammenfassung, was steht, was dachlos ist und was eingestürzt ist. Die Inhalte der Gebäude verderben je nach Art und liegen für Phase 3 in `ruin` jedes Gebäudes. Neue Bäume werden in `new_trees` gespeichert.
- Hauptmenü: Phase 2 ist in der Leiste freigeschaltet, Weiterspielen zeigt den Stand der Phase.
- Alle Werte stehen in `phase2` der balance.json.
- Der Platzhalter für Phase 3 zeigt jetzt die Ruinen und Fundstücke.
- Der Wald im Rand kommt aus einer eigenen Klasse (ForestPlan), Stadt und Zeitraffer teilen sie.
- Neuer Test: tests/timelapse_test.gd. Der Eingabetest braucht `--resolution 640x360`.

## 0.1.5

iPhone-Version, getestet auf dem Maß des iPhone 14 Plus (Querformat, 926 x 428 Punkte, 3-fache Dichte).

- Neuer Autoload Platform: erkennt das Handy, rechnet die ganzzahlige Pixelvergrößerung selbst aus und pausiert das Spiel, wenn die Seite verdeckt oder hochkant ist. Auf dem Handy speichert das Spiel alle 20 Sekunden und beim Pausieren.
- Touch-Steuerung: Tippen wählt und baut beim Loslassen. Beim Bauen schwebt die Vorschau über dem Finger. Ein Finger zieht die Karte, zwei Finger schieben und zoomen. Straßen entstehen durch Ziehen.
- Handy-Oberfläche: kompakte Leiste oben mit Tempo-Knopf, Zoom-Knopf und Menü-Knopf. Größere Knöpfe, angepasste Hinweise und Anleitung.
- Das Menü passt Himmel, Insel und Phasenleiste an jedes Bildformat an.
- Neue Webseite: Querformat füllt den ganzen Bildschirm mit Sicherheitsrändern, kein Scrollen, kein Zoomen, Hinweis "Dreh dein Handy quer" im Hochformat, Bildschirm bleibt wach. Das Spiel startet erst im Querformat, sonst blieb das Bild nach dem Drehen ein schmaler Streifen. Ändert sich die Bildgröße später, lädt die Seite neu (das Spiel hat vorher gespeichert). Für iOS vor 16.4 gibt es einen Ersatz für das Entpacken.
- Laden in Schritten mit Fortschrittsbalken. Der Boden entsteht rund viermal schneller (GroundJob).
- Weniger Rechenzeit: Straßen sind in den Boden eingebrannt, Boden, Schatten, Licht, Himmel und Hausansichten zeichnen nur bei Änderung, Häuser kommen aus festen Varianten und werden im Hintergrund vorgemalt.
- Neue Tests: touch_test, perf_test, perf_calls, perf_load.

## 0.1.4

- Neues Hauptmenü: Eine schwebende Insel im isometrischen Stil zeigt eine kleine lebende Stadt. Sie nutzt die echten Spielklassen: Gebäude, Bäume, Strommasten, Autos, Fußgänger, Schatten, Rauch und Licht.
- Der Tag auf der Insel läuft in 90 Sekunden durch. Der Himmel wechselt zwischen Tag, Abendrot und Nacht, mit Sternen, Mond und Glühwürmchen. Nachts leuchten die Fenster und Laternen.
- Der Titel ist Blockschrift mit Tiefe. Jeder Buchstabe wird im 2:1-Winkel der Insel diagonal nach hinten gezogen. Ranken hängen von den Buchstaben.
- Unter der Insel hängt eine zackige Gesteinsspitze mit Wurzeln. Die Insel schwebt in ganzen Pixeln.
- Menüpunkte: Neues Spiel, Weiterspielen mit Angaben zum Spielstand (Tag, Familien, Geld), Anleitung, Einstellungen, Beenden. Ein Pfeil zeigt auf den Punkt unter der Maus.
- Neues Spiel fragt nach, wenn ein Spielstand besteht.
- Anleitung erklärt die drei Phasen und die Steuerung.
- Einstellungen: Vollbild (nicht im Browser), Schatten, Rauch und Partikel, Tempo beim Start. Dazu "Spielstand löschen" mit zwei Klicks. Alles wird in user://verwuchert_settings.json gespeichert und wirkt im Spiel.
- Phasenleiste unten links zeigt die drei Phasen. Nur Phase 1 ist spielbar.
- Neuer Wasserturm: ein gemauerter Turm mit Bogenfenstern und Tür, darüber ein genieteter Behälter unter einem Kupferdach mit Laterne. Es gibt Varianten in Ziegelrot und Sandstein, mit Behältern in Blaugrün, Wasserblau, Grau und Moosgrün.
- Neue Maltechnik für Türme: Zylinder und Kegel mit freier Oberfläche in IsoPainter.
- Die Erdkante unter der Karte ist jetzt eine eigene Klasse (IsoCliff), die Stadt und Menü teilen.
- Texte der Gebäude beschreiben jetzt die Versorgung über die Straßen.
- Neue Symbole für Wasserturm, Zeitraffer und Bunker.
- Neuer Test: tests/menu_test.gd.

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
