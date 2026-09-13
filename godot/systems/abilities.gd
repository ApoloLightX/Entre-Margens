extends RefCounted
## Data-driven magic: techniques alter space and attention instead of spending mana.
const TABLE={
	"cordao": {"name":"Cordão de Calor","cost":18,"cooldown":1.2,"shape":"arc","damage":14},
	"fratura": {"name":"Fratura de Gelo","cost":28,"cooldown":2.4,"shape":"line","damage":26},
	"silencio": {"name":"Silêncio da Margem","cost":36,"cooldown":4.0,"shape":"ring","damage":40}
}
func spec(id:String)->Dictionary:return TABLE.get(id,{})
