# Ant Pop

Eine Ameisenkolonie im Formicarium, gebaut mit Godot 4.4 und GDScript. Du siehst einen seitlichen Querschnitt durch den Boden unter Glas. Oben wachsen Bäume, Büsche und Gras. Unten graben deine Ameisen ihr Nest.

Das Spiel läuft auf iPhone, Android, Tablet und PC. Die Basisauflösung ist 270 x 480 Pixel im Hochformat. Alle Grafiken entstehen per Code. Du brauchst keine externen Assets.

## Starten

1. Öffne Godot 4.4 oder neuer.
2. Wähle Importieren und dann `ameisen/project.godot`.
3. Drück F5. Die Hauptszene ist `scenes/Main.tscn`.

## Im Browser spielen

`web/AntPop.html` ist eine eigenständige Browser-Version in JavaScript. Sie läuft auf dem iPhone in Safari ohne Installation und ist weiter ausgebaut als die Godot-Fassung:

- Beim Start zeigt ein Ladebildschirm einen Balken, über den eine Blattschneiderin läuft, dazu wechselnde Tipps. Danach öffnet sich das Hauptmenü über der lebenden Kolonie, die Kamera fährt langsam über das Nest.
- Im Hauptmenü spielst du weiter, gründest eine neue Kolonie oder liest die Anleitung. Für eine neue Kolonie wählst du den Namen der Kolonie und der Königin, die Schwierigkeit, die Zahl der Gründerinnen, die Länge eines Tages, ob Fluten und der Vogel vorkommen, und eine Weltnummer. Gleiche Weltnummer heißt gleiche Bäume und gleicher Boden. Mit dem Tempo "Natürlich" braucht die Brut zwölfmal länger, Ameisen leben zwölfmal länger, und die Königin gründet auf Wunsch ganz allein, wie in der Natur. Die ersten Töchter zieht sie dann aus ihren eigenen Reserven auf. Über das Kolonie-Panel kommst du jederzeit zurück ins Hauptmenü.
- Jede Ameise lebt eigenständig. Sie hat einen Namen, eigene Vorlieben für Arbeiten, Hunger, Müdigkeit und ein Alter. Junge Ameisen pflegen lieber die Brut, ältere gehen lieber hinaus. Was eine Ameise oft tut, fällt ihr leichter.
- Es gibt keinen festen Bauplan. Wenn die Kolonie Platz für Futter, Brut, Tote oder Abfall braucht, wählen die Ameisen einen passenden Ort, graben einen Verbindungsgang und heben die Kammer gemeinsam aus. Danach bringen sie alles an den richtigen Ort: Futter in die Kornkammer, Eier in die Brutkammer, Tote auf den Friedhof, Abfall in die Müllkammer.
- Die Königin legt nur Eier, wenn sie gefüttert wird und genug Vorrat da ist. Eier werden zu Larven und Puppen. Ammen tragen die Brut in die Brutkammer und füttern die Larven.
- Sammlerinnen riechen reife Äpfel, Futter im Gras und Büsche, deren Blätter gebraucht werden, auf etwa 4 cm Entfernung und laufen gezielt hin. Hunger meldet das Schild erst, wenn der Vorrat mehrere Sekunden lang leer ist.
- An der Oberfläche fällt Obst von den Bäumen, tote Käfer liegen im Gras, und ein Vogel jagt Ameisen. Der Tausendfüßler ist vorerst abgeschaltet.
- Wächst die Kolonie, bauen die Ameisen Sonderkammern:
  - Schlafkammer: Müde Ameisen erholen sich dort doppelt so schnell. Nachts steigen kleine Zs auf.
  - Puppenkammer: Sie liegt nah an der Oberfläche. Puppen reifen dort in der Wärme schneller.
  - Wachkammer: Soldatinnen warten nahe am Eingang. Kommt der Vogel, laufen sie hinaus und beißen ihn weg. Nachts verschließt eine Soldatin den Eingang mit ihrem Kopf.
  - Pilzgarten: Ameisen schneiden Blätter von Büschen und Bäumen und tragen sie wie Segel nach Hause. Aus jedem Blatt wachsen Pilzknollen, die als Futter dienen. Im Laub bleiben runde Bisse zurück.
  - Honigtopf-Kammer: Junge Arbeiterinnen werden zu Honigtöpfen. Sie hängen an der Decke, und ihr Hinterleib füllt sich golden mit Zucker und Honigtau. Werden die Vorräte knapp, geben sie ab.
  - Blattlaus-Stall: Er liegt an einer Baumwurzel. Wurzelläuse geben Honigtau, die Ameisen melken sie auch nachts und bei Regen. Gepflegte Läuse vermehren sich.
  - Drainage-Schacht: Er liegt unter dem tiefsten Gang. Bei einer Flut versickert das Wasser dort im Kies.
  - Prinzessinnenkammer: Ab 60 Ameisen zieht die Königin Prinzessinnen und Männchen mit Flügeln auf. An einem warmen, trockenen Tag klettern alle auf Grashalme und starten zum Hochzeitsflug.
- Der Ameisenhaufen: Aus dem Aushub wächst über dem Eingang ein Hügel mit Krater, Nadeln und Ästchen. Ist er hoch genug, wird er zu festem Boden, in den die Ameisen graben. Dort entstehen Sonnenkammern. Wie bei der Roten Waldameise tragen die Ammen tagsüber Larven und Puppen hinauf ins Warme, wo sie 1,8 mal schneller reifen. Abends und bei Regen tragen sie die Brut wieder hinunter.
- Wird es eng, laufen die Ameisen in vollen Gängen langsamer. Dann verbreitern sie die meistbenutzten Gänge, graben neue Seitengänge und legen Abkürzungen an.
- Im Tempo Natürlich kommen Vogel und Flut dreimal seltener. Die Königin ertrinkt nie, sie überlebt Hochwasser in einer Luftblase.
- Jahreszeiten: Jede Jahreszeit dauert drei Spieltage. Im Frühling blühen die Bäume, und die Schneeschmelze bringt Wasser. Im Sommer reifen Äpfel schnell, mittags macht die Hitze Sammlerinnen müde. Im Herbst färbt sich das Laub, Äpfel fallen, Laub weht. Im Winter sind die Bäume kahl, Schnee liegt und fällt, niemand geht hinaus, und die Kolonie hält Winterruhe mit wenig Verbrauch.
- Ameisenarten: Rote Gartenameise, Rote Waldameise, Blattschneiderameise, Honigtopfameise und Ernteameise. Jede Art hat eigene Farben und Stärken, zum Beispiel einen großen Hügel, einen frühen Pilzgarten, viele Honigtöpfe oder Samen von den Gräsern als Futter.
- Hygiene: Liegen Tote oder Abfall zu lange am falschen Ort, wächst Schimmel. Er breitet sich auf Abfall aus, verdirbt Futter und macht Ameisen krank. Aufräumerinnen kratzen ihn ab und tragen die Ursache weg.
- Futter teilen: Hungrige Ameisen betteln Sammlerinnen und Honigtöpfe an und bekommen Futter von Mund zu Mund. Ein goldener Tropfen glänzt zwischen ihren Köpfen.
- Nachbarn: Auf Wunsch lebt am Rand eine fremde Kolonie mit schwarzen Ameisen, höchstens 40 Tiere, von denen höchstens 6 gleichzeitig draußen sammeln. Ihr Nest ist sichtbar: Königinnenkammer mit Königin, Brutkammer mit Eiern, Larven und Puppen, Vorratskammer mit echten Futtersorten, dazu Ameisen, die darin herumlaufen. Sie kämpft um Futter, vor allem mit Soldatinnen, und schickt Räuberinnen ins Nest. Gestohlene Puppen schlüpfen bei ihr. Solange deine Kolonie unter 15 Ameisen hat, lässt sie deine Arbeiterinnen in Ruhe und plant keinen Raubzug. Sie wächst nur mit deiner Kolonie mit: 10 Ameisen plus eine pro zwei von deinen, höchstens 40. Bei Kämpfen steigt eine Staubwolke auf. Nach einem Hochzeitsflug gründet eine Prinzessin am Rand eine friedliche Tochterkolonie und zieht die ersten Töchter aus ihren Reserven auf. Tippe auf ein fremdes Nest, um Bewohner, Brut und Vorrat zu sehen.
- Lebenslauf: Jede Ameise sammelt Erlebnisse, zum Beispiel ihre erste Grabung, den Vogel vertrieben oder den Winter überstanden. Sie stehen im Steckbrief.
- Abzeichen: 22 Abzeichen gelten über alle Kolonien. Beim Freischalten erscheint eine Medaille mit Fanfare. Die Sammlung steht im Hauptmenü.
- Ton: Graben, Regen, Wind, Vogelgezwitscher, Klicks und leise Musik werden im Browser erzeugt. Im Hauptmenü unter Ton stellst du Geräusche, Musik und Lautstärke ein.
- Spielmenü: Der Knopf oben rechts öffnet das Spielmenü und pausiert das Spiel. Es zeigt Kolonie, Tag, Jahreszeit und Ameisenzahl, dazu die Abzeichen mit Fortschrittsbalken, den drei neuesten Abzeichen und einem Filter für alle, gesammelte und offene. Neue Abzeichen tragen ein rotes NEU, und ein roter Punkt am Knopf weist darauf hin. Außerdem: Ton, Hilfe, Kolonie-Panel, Foto, Kinomodus, Speichern und Hauptmenü. Escape öffnet und schließt das Menü.
- Fotomodus: Die Kamera unten rechts blendet die Bedienung aus. Du wählst den Ausschnitt, und das Foto bekommt ein Schild mit Name, Tag, Jahreszeit und Ameisenzahl. Du teilst es oder hältst es gedrückt, um es zu sichern.
- Ansichten: Das Auge in der unteren Leiste öffnet das Ansichtsmenü. Das Wärmebild zeigt warme Kammern rot und kalte Erde blau. Die Verkehrsansicht zeigt, welche Gänge am meisten belaufen sind. Der Kinomodus fährt die Kamera von Kammer zu Kammer und erklärt jeden Ort.
- Licht und Wetter: Tiefe Gänge sind dunkler, Kammern leuchten in ihrer Farbe. Morgens und abends fallen Sonnenstrahlen schräg durchs Glas, der Himmel färbt sich rot. Nachts siehst du Sterne, den Großen Wagen und den Mond in acht Phasen. Bei Vollmond ist die Nacht heller. Vor dem Regen frischt der Wind auf und die Wolken werden dunkel.
- Kleine Tiere: Schmetterlinge, eine Biene an den Blüten, ein Marienkäfer am Halm, Glühwürmchen in warmen Nächten und ein Regenwurm nach dem Regen. Nach dem Regen bleiben Pfützen, morgens hängt Tau am Gras.
- Details im Nest: Viel begangene Gänge bekommen einen hellen, festgetretenen Boden. Beim Graben fliegen Krümel. In den Wänden stecken Steine, tiefe Kammern tropfen von der Decke. Larven bewegen sich, hungrige Larven zappeln stärker. Eine fertige Kammer leuchtet kurz auf, ein neues Abzeichen bringt Konfetti.
- Rahmen und Glas: Der Holzrahmen hat Maserung, Astlöcher und Messingschrauben. Auf dem Glas siehst du Spiegelungen, Fingerabdrücke und Kratzer. Im Winter beschlägt das Glas von den Ecken her.
- Das Kolonie-Panel zeigt alle Sonderkammern mit ihrem Zustand, die Zahl der Hochzeitsflüge und das Gedränge in den Gängen.
- Tippe auf eine Ameise, um ihr zu folgen und ihren Steckbrief zu sehen. Das Schild öffnet das Kolonie-Panel mit Aufgabenverteilung, Verlauf und Chronik.
- Tippst du eine Kammer an, steht unter ihrem Namen, wozu sie da ist. Das gilt auch für Kammern im Bau, für Gänge, Erde, Bäume, Büsche, den Ameisenhaufen und Futter im Gras.
- Unten links liegt die Werkzeugkiste. Jedes Werkzeug braucht danach eine Pause:
  - Zucker: 8 Portionen ins Gras, sie landen zuerst in den Honigtöpfen.
  - Baum schütteln: Bis zu 3 Äpfel fallen ins Gras.
  - Blätter: ein Haufen Blätter für den Pilzgarten.
  - Windrad: Drei Minuten lang jagt der Vogel in seiner Nähe keine Ameisen.
  - Blattdach: Vier Minuten lang läuft kein Regen in den Eingang.
  - Wärme: Zwei Minuten lang reift die Brut in einer Kammer schneller, und Ruhende erholen sich schneller.
  - Wassertropfen: Erfrischt Sammlerinnen, die in der Sommerhitze müde geworden sind.
  - Futterschale: Füllt fünf Minuten lang alle 45 Sekunden Obst nach.
  - Stöckchen: Lehnt an einem Baum, dort klettern die Ameisen doppelt so schnell.
- Jede Futtereinheit im Nest hat ihre Sorte: Apfelstück, Zuckerwürfel, Käferstück, Honigtau oder Pilzknolle. Die Kammern zeigen genau das, was gerade darin liegt, und beim Antippen steht die Menge jeder Sorte. Auch die Ameisen tragen sichtbar die Sorte, die sie geholt haben.
- Die Bäume haben breite Stämme, ihre Wurzeln wachsen sichtbar aus dem Stammfuß in die Erde. Äpfel wachsen nur an den Bäumen, die Büsche liefern Blätter.

Der Spielstand liegt dort im Speicher des Browsers.

`docs/antpop/index.html` ist dieselbe Seite als vollständige HTML-Datei mit App-Symbol, App-Manifest und Vollbild für GitHub Pages. Mit GitHub Pages läuft sie unter https://doggooffiziell-coder.github.io/Claude/antpop/. Fügst du sie in Safari zum Home-Bildschirm hinzu, erscheint das Ant-Pop-Icon und das Spiel startet im Vollbild. Nach jeder Änderung an `web/AntPop.html` baut `web/build-pages.sh` die Datei neu.

## Bedienung

Tippe auf eine Kammer, und unten erscheint ihr Name mit Inhalt. Zieh zwei Finger auseinander, um zu zoomen. Schieb zwei Finger, um die Ansicht zu verschieben.

Mit einem Finger verschiebst du die Ansicht. Tippe zweimal schnell, um hineinzuzoomen oder wieder alles zu sehen. Unten rechts pausierst du das Spiel und stellst das Tempo auf 1x, 2x, 4x, 8x oder 16x.

Am PC zoomst du mit dem Mausrad. Mit gedrückter rechter Maustaste verschiebst du die Ansicht. Ein Linksklick wählt eine Kammer.

Der Spielstand landet alle 30 Sekunden in `user://save.json`. Er wird auch gespeichert, wenn du das Fenster schließt oder die App in den Hintergrund geht.

## So hängen die Szenen zusammen

Die Szenen sind fertig verbunden. Du musst nichts im Editor zuweisen. Willst du sie selbst nachbauen, leg diese Struktur an:

```
Main (Node2D)                 Main.gd
├─ DayNight (CanvasModulate)
├─ World (Node2D)             World.gd
│  ├─ Sky (Node2D)            Sky.gd         z_index -10
│  ├─ Ground (TileMapLayer)                  bekommt das Tileset per Code
│  ├─ Decor (Node2D)          Decor.gd       z_index 1
│  ├─ Water (Sprite2D)                       z_index 5
│  └─ Frame (Node2D)                         z_index 20
├─ Pheromones (Node2D)        Pheromones.gd  z_index 2
├─ Colony (Node)              Colony.gd
├─ Ants (Node2D)              AntManager.gd  z_index 3
│  └─ MultiMeshInstance2D
├─ EventManager (Node2D)      EventManager.gd  z_index 6
├─ Camera2D                   CameraController.gd
└─ HUD (Instanz von HUD.tscn)
```

`HUD.tscn` ist ein CanvasLayer (Layer 10) mit `HUD.gd`. Darin liegt ein Control namens `Canvas` über den ganzen Bildschirm mit Mouse Filter Ignore.

Die Namen müssen genau so lauten. `Main.gd` holt sich die Knoten über diese Pfade und ruft bei jedem `setup(self)` auf. Danach gibt `Main._process` den Takt für alle Teile vor.

## Scripts

| Script | Aufgabe |
| --- | --- |
| `Main.gd` | Verbindet alle Teile, Takt, Antippen, Speichern und Laden |
| `World.gd` | Boden-Grid, Tileset per Code, Tunnel, Wegfelder, Wasser, Sandhügel, Früchte, Rahmen |
| `Sky.gd` | Himmel, Sonne, Mond, Wolken, Bäume, Büsche, Gras, Blumen, Hügel |
| `Ant.gd` | Zustandsmaschine einer Ameise: graben, Futter suchen, Futter tragen, Brut pflegen, Tote wegbringen |
| `AntManager.gd` | Zentrale Arrays für alle Ameisen, Aufgabenverteilung, Zeichnen über ein MultiMesh |
| `Colony.gd` | Königin, Futter, Eier, Larven, Tote, Müll, Bauplan der Kammern |
| `Pheromones.gd` | Duftspuren als 2D-Array, verblassen alle 6 Frames |
| `EventManager.gd` | Tag und Nacht, Flut, Tausendfüßler |
| `Decor.gd` | Inhalt der Kammern: Futter, Eier, Larven, Tote, Abfall |
| `HUD.gd` | Grünes Holzschild mit ANT POP., Kammer-Infos, Meldungen |
| `CameraController.gd` | Zoom und Verschieben für Touch und Maus |
| `AntFont.gd` | Kleine 3x5-Pixelschrift |

## Icon

Das Icon liegt in `icons/`. Es ist Pixel-Art mit 48 x 48 Pixeln: die Königin mit Krone auf dem Sandhügel, darunter das Nest mit Königinnenkammer, Brutkammer und Kornkammer. `icon.svg` ist das Projekt-Icon in Godot. Die PNG-Dateien gibt es von 16 bis 1024 Pixel, dazu Vorder- und Hintergrund für das adaptive Android-Icon. Beide Export-Presets nutzen sie schon.

## Exportieren

Lade zuerst die Export-Vorlagen über Editor, Export-Vorlagen verwalten.

Android: Trag in den Editor-Einstellungen den Pfad zum Android SDK und den Debug-Keystore ein. Wähle dann Projekt, Exportieren, Android.

iOS: Du brauchst einen Mac mit Xcode und ein Apple-Entwicklerkonto. Trag deine Team ID im Preset iOS unter App Store Team ID ein. Godot erzeugt ein Xcode-Projekt, das du in Xcode signierst und auf dein iPhone lädst.

Beide Presets nutzen das Hochformat und Touch-Eingabe.
