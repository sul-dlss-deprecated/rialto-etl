TODO: wrap below mappings in @graph => {}

each mapping should include: @id, @type, rdfs:label, one or more obo:BFO\_0000050 or obo:BFO\_0000051

alias (string) => @id http://authorities.stanford.edu/orgs#{alias}
browsable (boolean) => ignore
children (array) => keep track of parent, iterate over values (for each obo:BFO\_0000050/partOf) and map, keep track of children for obo:BFO\_0000051/hasPart
name (string) => rdfs:label
onboarding (boolean) => ignore
orgCodes (array) => vivo:abbreviation
type (string) => see type mappings
url (string) => rdfs:seeAlso

type mappings

DIVISION        @type: http://vivoweb.org/ontology/core#Division
SUB_DIVISION    @type: http://vivoweb.org/ontology/core#Division
ROOT            @type: http://vivoweb.org/ontology/core#University
SCHOOL          @type: http://vivoweb.org/ontology/core#School
DEPARTMENT      @type: http://vivoweb.org/ontology/core#Department
