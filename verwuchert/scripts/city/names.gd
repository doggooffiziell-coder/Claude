class_name Names
extends RefCounted
## Namen für Familien, Bewohner, Straßen und Geschäfte. Alles hängt am Seed der Stadt,
## damit eine Straße immer gleich heißt und eine Familie in Phase 3 wiederkommt.

const FAMILIES := [
	"Berger", "Krüger", "Hofmann", "Brandt", "Vogel", "Lehmann", "Winter", "Schäfer", "Roth", "Kuhn",
	"Franke", "Lorenz", "Busch", "Seidel", "Haas", "Sommer", "Engel", "Pohl", "Ludwig", "Kraus",
	"Jung", "Hahn", "Schubert", "Graf", "Albrecht", "Wolff", "Hartmann", "Böhm", "Fuchs", "Simon",
	"Beck", "Martens", "Arnold", "Peters", "Thiel", "Ernst", "Raabe", "Kessler", "Lindner", "Stahl",
	"Ackermann", "Brückner", "Dietrich", "Eckert", "Falk", "Gerber", "Heinz", "Kaiser", "Mohr", "Nagel",
]

const FIRST := [
	"Anna", "Paul", "Marie", "Jonas", "Lena", "Felix", "Clara", "Emil", "Ida", "Max", "Greta", "Theo",
	"Frieda", "Karl", "Mila", "Oskar", "Lotte", "Ben", "Hanna", "Erik", "Rosa", "Moritz", "Elsa", "Jakob",
	"Ruth", "Hugo", "Martha", "Leo", "Wilma", "Fritz", "Nele", "Arne", "Inge", "Kurt", "Paula", "Otto",
]

const STREETS := [
	"Lindenweg", "Ahornstraße", "Mühlgasse", "Birkenallee", "Am Teich", "Gartenstraße", "Schulweg",
	"Rosengasse", "Kastanienweg", "Brunnenstraße", "Wiesenweg", "Kirchgasse", "Am Wasserturm", "Feldweg",
	"Eichenring", "Holunderweg", "Bahnhofstraße", "Am Markt", "Fliederweg", "Uferstraße", "Hauptstraße",
	"Erlenweg", "Bergstraße", "Hasengasse",
]

const SHOP_KIND := {"can": "Krämerladen", "bread": "Bäckerei", "bottle": "Getränke"}
const FACTORY := ["Werke", "Schraubenfabrik", "Ziegelei", "Weberei", "Konservenfabrik", "Maschinenbau"]


static func _pick(list: Array, key: Array) -> String:
	return list[absi(hash(key)) % list.size()]


## Jede Rasterlinie hat einen Straßennamen. axis 0: Straße läuft nach rechts unten (entlang U).
static func street(seed_value: int, axis: int, line: int) -> String:
	return _pick(STREETS, [seed_value, axis, line])


## "im Lindenweg", "in der Ahornstraße", "Am Teich". Für "an": "am Lindenweg", "an der Ahornstraße".
static func place(addr: String, prep: String = "in") -> String:
	var name := addr.rstrip("0123456789 ")
	var no := addr.substr(name.length()).strip_edges()
	var full := (name + " " + no).strip_edges()
	if name.begins_with("Am "):
		return name if prep == "an" else full
	var feminine := name.ends_with("straße") or name.ends_with("gasse") or name.ends_with("allee")
	if prep == "an":
		return ("an der " if feminine else "am ") + name
	return ("in der " if feminine else "im ") + full


static func family(seed_value: int, id: int) -> String:
	return _pick(FAMILIES, [seed_value, "fam", id])


static func residents(seed_value: int, id: int, count: int) -> Array:
	var out := []
	for i in count:
		var n := _pick(FIRST, [seed_value, "first", id, i])
		var tries := 0
		while out.has(n) and tries < 8:
			tries += 1
			n = _pick(FIRST, [seed_value, "first", id, i, tries])
		out.append(n)
	return out


static func shop(seed_value: int, id: int, kind: String) -> String:
	return "%s %s" % [SHOP_KIND.get(kind, "Laden"), family(seed_value, id + 500)]


static func factory(seed_value: int, id: int) -> String:
	var f := _pick(FACTORY, [seed_value, "fab", id])
	var owner := family(seed_value, id + 900)
	return "%s %s" % [owner, f] if f == "Werke" else "%s %s" % [f, owner]
