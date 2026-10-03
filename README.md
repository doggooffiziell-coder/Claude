# Ragpit

2D-Pixel-Sandbox mit Ragdoll-Physik, Flüssigkeiten und Pixel-Gore. Gebaut mit Godot 4.4 und GDScript.

Du wirfst eine Pixel-Puppe durch einen dunklen Raum, schneidest sie mit der Klinge, setzt sie in Brand oder frierst sie ein. Ein Statuspanel zeigt dir live ihre Werte und Zustände.

## Auf dem iPhone spielen

Die Web-Version liegt in `web/`. Sie läuft in Safari ohne App Store und ohne Mac.

1. Öffne die Seite in Safari.
2. Tippe auf Teilen und dann auf "Zum Home-Bildschirm".
3. Starte Ragpit über das neue Symbol und dreh das iPhone quer.

Die Web-Version zeichnet Menschen aus rechteckigen Körperteilen als Pixel-Art mit schwarzer Kontur: eckiger Kopf mit Haaren, Auge und Mund auf einem echten Hals, Arme an den Schultern, Shirt, Hose und Schuhe. Jede Puppe bekommt zufällige Haut-, Haar- und Kleidungsfarben. Wasser und Blut laufen in feiner Auflösung. Wasser fällt über Kanten als echter Strahl, läuft auf der Oberfläche bergab und gleicht sich wie in verbundenen Gefäßen aus, sodass ein Becken in ein bis zwei Sekunden glatt steht. Sie hat 11 Werkzeuge: Greifen, Wasser, Eimer, Klinge, Waffe, Feuer, Eis, Bombe, Infusion, Neue Puppe und Reset.

Unten liegt ein Dock mit allen Werkzeugen in Gruppen: Hand, Flüssigkeiten, Waffen, Elemente, Medizin und Puppen. Dünne Linien trennen die Gruppen. Das gewählte Werkzeug hebt sich an und bekommt einen Leuchtbalken in der Farbe seiner Gruppe. Alle Symbole sind gemalt, mit Licht von oben links: offene Hand, Wassertropfen, Metalleimer mit Wasser, Küchenmesser, Flammen, Schneeflocke, Bombe mit Funken, Blutbeutel, Figur mit grünem Plus und Kreispfeil. Der Waffen-Knopf zeigt die gewählte Waffe und ihre Patronen, zum Beispiel 30/30. Oben links erscheint je nach Werkzeug eine Leiste: beim Wasser die Menge in 5 Stufen (jede Stufe verdoppelt etwa die Menge, Stufe 5 ist ein dicker Strahl), bei der Waffe die Wahl zwischen AK-47, Sturmgewehr und Glock 17. Jede Waffe ist ein detailliertes Pixel-Sprite in echten Proportionen: die AK-47 mit Holzschaft, Gasrohr und gebogenem Magazin, das Sturmgewehr mit Schiene, Rotpunktvisier und Mündungsfeuerdämpfer, die Glock mit Schlitten, Griffwinkel und Abzugsbügel. Ohne Frontansicht steht die Waffe als Objekt im Raum. Zieh sie am Körper der Waffe an eine neue Stelle, zieh den Finger woanders durch den Raum, um zu zielen, und ein roter Laser zeigt den Treffpunkt. Der rote Knopf rechts unten schießt und zeigt die Patronen, "LADEN" lädt nach, "AUTO" schaltet zwischen Dauerfeuer und Einzelfeuer. Du kannst mit einem Finger zielen und mit dem anderen schießen.

Mit Frontansicht funktioniert die Waffe wie die Klinge: Tippe auf eine Puppe, und der Schuss trifft genau dort. Halte den Finger für Dauerfeuer, bei langen Salven streut es etwas. Daneben schlägt der Schuss mit Funken und einem Einschussloch in die Wand. Statt des roten Knopfs zeigt ein Kasten die Patronen, "LADEN" und "AUTO" bleiben.

Im Schadenspanel sehen Wunden echt aus: Einschüsse als dunkles Loch mit rotem Rand, Schnitte als schräger Riss, Prellungen als blauroter Fleck und abgetrennte Glieder als offener Stumpf mit Knochen. Blutende Wunden ziehen eine tropfende Blutspur nach unten.

Das Spiel startet mit einem Hauptmenü: Eine verletzte Figur im selben Pixel-Stil wie im Spiel steht unter einer flackernden Lampe, atmet und drückt eine Hand auf ihre Schusswunde. Vom Titel tropft Blut. Von dort kommst du zu SPIELEN, ANLEITUNG und EINSTELLUNGEN. Läuft schon ein Spiel, erscheint WEITERSPIELEN. Die Anleitung erklärt jedes Werkzeug mit seinem Symbol. In den Einstellungen schaltest du Ton, Bildschirmwackeln und das Schadenspanel an oder aus.

Kurze, ruhige Animationen begleiten jeden Klick. Im Menü erscheinen Titel, Knöpfe und Karten nacheinander von unten, die rote Linie unter dem Titel zieht sich auf. Knöpfe geben beim Drücken leicht nach und lösen beim Loslassen aus. Schalter gleiten, das Spiel blendet beim Start weich ein. Im Spiel heben sich gewählte Werkzeuge an, Leisten, Waffenknöpfe, Extras und Hinweise blenden ein und aus, und das Schadenspanel klappt fließend auf und zu.

Es gibt fünf Maps: Labor, Schwimmbad, Treppenhaus, Halle und Eiskeller. Jede Karte zeigt ein gemaltes Bild der Map mit Lampe, Blöcken, Wasser, Eis und den Figuren an ihren Startplätzen, dazu ein eigenes Symbol: Kolben, Wellen, Treppe, Plattformen und Schneeflocke. Der Knopf "MENÜ" im Spiel bringt dich zurück ins Hauptmenü, Reset baut die aktuelle Map neu auf.

Mit "Neue Puppe" tippst du auf die Stelle, an der die Puppe stehen soll. Sie steht dort sofort aufrecht auf dem Boden. Der Eimer saugt Wasser und Blut unter deinem Finger auf.

Tippe auf die Kopfzeile des Schadenspanels, um es zuzuklappen oder aufzuklappen. Zugeklappt bleiben Name, Zustand und EKG sichtbar. Das Spiel merkt sich deine Wahl.

Der Knopf "EXTRAS" oben öffnet eine Liste: Blut entfernen, Wasser entfernen, Feuer löschen, Eis entfernen, Reste entfernen, Alle heilen, Puppe entfernen, Alle Puppen weg, Zeitlupe und Pause. "Eis entfernen" lässt das Eis der Map stehen. "Alle heilen" schließt Wunden und füllt alle Werte auf, abgetrennte Glieder bleiben ab.

Das Schadenspanel ist auf Deutsch. Oben stehen der Name der Puppe und ihr Zustand. Rechts neben der Figur stehen fünf Werte mit Zahl und Balken: Bewusstsein, Blut, Schmerz, Sauerstoff und Puls mit laufendem EKG. Kritische Werte werden rot. Ganz unten erscheinen nur die Zustände, die gerade zutreffen, zum Beispiel BLUTET, BRENNT oder GLIED AB, sonst STABIL. Zugeklappt zeigt die Kopfzeile ein kleines EKG.

Das Schadenspanel zeigt eine Körpertafel von vorn in normalen Proportionen. Jeder Körperteil ist eine eigene Fläche mit schmalem Spalt und färbt sich nach seinem Schaden von Weiß über Gelb und Orange bis Rot. Fehlende Teile erscheinen als gestrichelte Umrisse. Oben läuft ein EKG.

Jede Puppe hat Organe: Gehirn, Herz, zwei Lungen, Leber, Magen, Nieren und Darm. Schüsse, Klingen und harte Stürze treffen die Organe an der getroffenen Stelle. Je nach Organ kommt der Tod schneller oder langsamer:

| Organ zerstört | Folge | Tod nach etwa |
| --- | --- | --- |
| Gehirn | sofort tot | 0 s |
| Herz | Herzstillstand, kein Sauerstoff mehr | 14 s |
| Beide Lungen | Ersticken | 20 s |
| Leber | starke innere Blutung | 45 s |
| Nieren | innere Blutung | 100 s |
| Magen | Schmerzen, Krämpfe, langsame Bauchfellentzündung | 10 min |
| Darm | Schmerzen, Krämpfe, langsame Bauchfellentzündung | 10 min |
| Magen und Darm | Bauchfellentzündung doppelt so schnell | 5 min |

Magen und Darm bluten kaum. Die Puppe krümmt sich vor Krämpfen und drückt eine Hand auf den Bauch. Tödlich wird erst die Entzündung, die langsam wächst, wenn Mageninhalt in den Bauch läuft. Ein nur verletzter Magen heilt, bevor es gefährlich wird. Im echten Leben dauert das Stunden bis Tage, das Spiel verkürzt die Zeit.

Verletzte Organe heilen langsam, mit Infusion schneller. Zerstörte Organe heilen nicht, nur "Alle heilen" in den Extras stellt sie wieder her. Die Infusion füllt Blut nach und kann so eine Leberblutung überbrücken, ein stehendes Herz rettet sie nicht. Die Körpertafel zeigt die Organe als kleine anatomische Bilder: Gehirn mit Windungen, Lungen mit Bronchien und Luftröhre, Herz mit Aorta und Lungenvene, Leber mit Gallenblase, Magen, Nieren mit Harnleitern und den Darm. Verletzte Organe werden dunkler, zerstörte bekommen ein rotes X, und das Herz schlägt mit. Darunter steht das schlimmste Organ mit der Zeit bis zum Tod, nach dem Tod die Ursache.

Mit "Fixieren" tippst du auf ein Körperteil. Es bleibt dann wie mit einer roten Nadel festgesteckt an seiner Stelle, auch in der Luft. Ein zweiter Tipp löst es wieder, "Pins lösen" in den Extras löst alle.

Fallschaden: Ein Sturz bis etwa 1,5 m macht nichts. Darüber wächst der Schaden mit der Geschwindigkeit im Quadrat. Beine und Füße fangen eine Landung am besten ab, der Kopf am schlechtesten. Harte Aufpralle brechen Arme und Beine (KNOCHENBRUCH, die Puppe kann dann nicht mehr stehen), erst sehr harte reißen Wunden auf. Körperteile prallen jetzt auch mit ihrer ganzen Länge an Wänden und Plattformen ab, und Puppen stoßen sich gegenseitig an.

Die Puppe kann nicht durch sich selbst gleiten: Kopf, Hals und Bauch halten Abstand zu Hüfte und Beinen. Drückst du sie nach unten, knickt sie wie ein Körper ein, statt zu einem Knäuel zu werden. Auf dem Boden bremst Reibung jede Bewegung, damit Puppen nicht weiterrollen. Setzt du eine Puppe so hin, dass ihre Gelenke falsch herum knicken müssten, dreht sie sich von selbst in die andere Blickrichtung.

Die Organzeile nennt immer den echten Grund für die Zeit: BLUTVERLUST bei offenen Wunden, das blutende Organ, HERZSTILLSTAND, LUNGEN VERSAGEN, ERTRINKT oder BAUCHFELLENTZÜNDUNG.

In den Einstellungen schaltet FRONTANSICHT die Puppen auf Blick nach vorn: zwei Augen, beide Arme und Beine gleich hell nebeneinander, Haare an beiden Seiten und Schuhe, die nach vorn zeigen. Stehende Puppen halten sich dann mit ihren Muskeln aufrecht wie in der Vorschau von "Schuss präzisieren": Arme gerade neben dem Körper, Beine gerade und parallel. Das passiert in der echten Physik, darum sitzen Treffer, Wunden und Blut genau dort, wo du die Puppe siehst. Ein Schuss in Brust oder Arm lässt sie kurz zucken, sie bleibt aber stehen. Ein Schuss in Kopf oder Bein lässt sie einknicken. Mehrere Treffer machen so viel Schmerz, dass sie zusammensackt. Dann öffnet langes Drücken auf eine Puppe mit dem Greifen-Werkzeug ein Menü: SCHUSS PRÄZISIEREN, HEILEN, PINS LÖSEN und ENTFERNEN. "Schuss präzisieren" zeigt die Puppe groß von vorn. Du ziehst den Finger zum Zielen, die Ansicht zeigt Körperteil und getroffene Organe, und beim Loslassen fällt der Schuss genau dort. RÖNTGEN macht die Organe sichtbar. Das Spiel läuft dabei in Zeitlupe weiter.

Die Infusion hängt einen Blutbeutel mit Schlauch an die Puppe. Sie füllt Blut auf, schließt Wunden, senkt Schmerz und weckt eine bewusstlose Puppe. Eine tote Puppe rettet sie nicht mehr.

Zustände: WACH, K.O. und TOT. Eine K.O.-Puppe atmet, ihr Herz schlägt und sie wacht nach einigen Sekunden wieder auf. Eine tote Puppe zuckt kurz und bleibt liegen. Verletzungen ändern die Bewegung: ein kaputtes Bein verhindert das Stehen, ein verletzter Arm hängt schlaff, Schmerz lässt die Puppe sich winden und eine Hand auf die Wunde drücken, Feuer und Ertrinken lösen Panik aus. Liegt eine wache Puppe am Boden, versucht sie aufzustehen. Mit einem kaputten Bein schafft sie es nicht und fällt zurück.

`web/ragpit.html` ist die Seite für die Claude-Artifact-Ansicht. `docs/index.html` ist dieselbe Seite als vollständige HTML-Datei mit App-Symbol für GitHub Pages. Nach jeder Änderung an `web/ragpit.html` baut `web/build.sh` die Datei neu.

Mit GitHub Pages läuft das Spiel unter https://doggooffiziell-coder.github.io/Claude/ und startet vom Home-Bildschirm im Vollbild ohne Browserleiste.

Der Raum passt seine Breite an den Bildschirm an, damit links und rechts keine schwarzen Balken bleiben.

## Leistung

Das Spiel spart Rechenzeit, wo es geht. Der Wasserausgleich rechnet nur jeden zweiten Schritt und schläft, solange kein Becken im Raum ist. Die Symbole im Dock, die Waffen-Sprites und die Körpertafel im Panel werden einmal gemalt und danach als fertiges Bild wiederverwendet. Ein langsames Handy rechnet höchstens drei Physikschritte pro Bild und lässt den Rest fallen, damit sich Ruckler nicht aufschaukeln.

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
