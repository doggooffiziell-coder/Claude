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
- Im Hauptmenü spielst du weiter, gründest eine neue Kolonie oder liest die Anleitung. Für eine neue Kolonie wählst du den Namen der Kolonie und der Königin, die Schwierigkeit, die Zahl der Gründerinnen, die Länge eines Tages, ob Fluten und der Vogel vorkommen, und eine Weltnummer. Gleiche Weltnummer heißt gleiche Bäume und gleicher Boden. Über das Kolonie-Panel kommst du jederzeit zurück ins Hauptmenü.
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
- Das Kolonie-Panel zeigt alle Sonderkammern mit ihrem Zustand, die Zahl der Hochzeitsflüge und das Gedränge in den Gängen.
- Tippe auf eine Ameise, um ihr zu folgen und ihren Steckbrief zu sehen. Das Schild öffnet das Kolonie-Panel mit Aufgabenverteilung, Verlauf und Chronik.
- Unten links liegt die Werkzeugkiste. Jedes Werkzeug braucht danach eine Pause:
  - Zucker: 8 Portionen ins Gras, sie landen zuerst in den Honigtöpfen.
  - Baum schütteln: Bis zu 3 Äpfel fallen ins Gras.
  - Blätter: ein Haufen Blätter für den Pilzgarten.
  - Windrad: Drei Minuten lang jagt der Vogel in seiner Nähe keine Ameisen.
  - Blattdach: Vier Minuten lang läuft kein Regen in den Eingang.
  - Wärme: Zwei Minuten lang reift die Brut in einer Kammer schneller, und Ruhende erholen sich schneller.
- Jede Futtereinheit im Nest hat ihre Sorte: Apfelstück, Zuckerwürfel, Käferstück, Honigtau oder Pilzknolle. Die Kammern zeigen genau das, was gerade darin liegt, und beim Antippen steht die Menge jeder Sorte. Auch die Ameisen tragen sichtbar die Sorte, die sie geholt haben.
- Die Bäume haben breite Stämme, ihre Wurzeln wachsen sichtbar aus dem Stammfuß in die Erde. Äpfel wachsen nur an den Bäumen, die Büsche liefern Blätter.

Der Spielstand liegt dort im Speicher des Browsers.

`docs/antpop/index.html` ist dieselbe Seite als vollständige HTML-Datei mit App-Symbol, App-Manifest und Vollbild für GitHub Pages. Mit GitHub Pages läuft sie unter https://doggooffiziell-coder.github.io/Claude/antpop/. Fügst du sie in Safari zum Home-Bildschirm hinzu, erscheint das Ant-Pop-Icon und das Spiel startet im Vollbild. Nach jeder Änderung an `web/AntPop.html` baut `web/build-pages.sh` die Datei neu.

## Bedienung

Tippe auf eine Kammer, und unten erscheint ihr Name mit Inhalt. Zieh zwei Finger auseinander, um zu zoomen. Schieb zwei Finger, um die Ansicht zu verschieben.

Mit einem Finger verschiebst du die Ansicht. Tippe zweimal schnell, um hineinzuzoomen oder wieder alles zu sehen. Unten rechts pausierst du das Spiel und stellst das Tempo auf 1x, 2x oder 4x.

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
