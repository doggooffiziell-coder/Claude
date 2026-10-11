# Ant Pop

Eine Ameisenkolonie im Formicarium, gebaut mit Godot 4.4 und GDScript. Du siehst einen seitlichen Querschnitt durch den Boden unter Glas. Oben wachsen Bäume, Büsche und Gras. Unten graben deine Ameisen ihr Nest.

Das Spiel läuft auf iPhone, Android, Tablet und PC. Die Basisauflösung ist 270 x 480 Pixel im Hochformat. Alle Grafiken entstehen per Code. Du brauchst keine externen Assets.

## Starten

1. Öffne Godot 4.4 oder neuer.
2. Wähle Importieren und dann `ameisen/project.godot`.
3. Drück F5. Die Hauptszene ist `scenes/Main.tscn`.

## Im Browser spielen

`web/AntPop.html` ist eine eigenständige Browser-Version in JavaScript. Sie läuft auf dem iPhone in Safari ohne Installation und ist weiter ausgebaut als die Godot-Fassung:

- Jede Ameise lebt eigenständig. Sie hat einen Namen, eigene Vorlieben für Arbeiten, Hunger, Müdigkeit und ein Alter. Junge Ameisen pflegen lieber die Brut, ältere gehen lieber hinaus. Was eine Ameise oft tut, fällt ihr leichter.
- Es gibt keinen festen Bauplan. Wenn die Kolonie Platz für Futter, Brut, Tote oder Abfall braucht, wählen die Ameisen einen passenden Ort, graben einen Verbindungsgang und heben die Kammer gemeinsam aus. Danach bringen sie alles an den richtigen Ort: Futter in die Kornkammer, Eier in die Brutkammer, Tote auf den Friedhof, Abfall in die Müllkammer.
- Die Königin legt nur Eier, wenn sie gefüttert wird und genug Vorrat da ist. Eier werden zu Larven und Puppen. Ammen tragen die Brut in die Brutkammer und füttern die Larven.
- An der Oberfläche fällt Obst von den Bäumen, tote Käfer liegen im Gras, und ein Vogel jagt Ameisen. Der Tausendfüßler ist vorerst abgeschaltet.
- Tippe auf eine Ameise, um ihr zu folgen und ihren Steckbrief zu sehen. Das Schild öffnet das Kolonie-Panel mit Aufgabenverteilung, Verlauf und Chronik. Unten links streust du Zucker ins Gras.

Der Spielstand liegt dort im Speicher des Browsers.

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
