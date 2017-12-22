# RIALTO / VIVO Mapping & Mapping Target

This is mapping documentation for the end result of our selected sources to RIALTO / VIVO models. See more information in our [docs folder](docs). This will be iterated on as sources and types are mapped.

# Reused Ontologies List (to be further vetted)

  - "dbpedia": "http://dbpedia.org/resource/"
  - "dbo": "http://dbpedia.org/ontology/"
  - "foaf": "http://xmlns.com/foaf/0.1/"
  - "obo": "http://purl.obolibrary.org/obo/"
  - "owl": "http://www.w3.org/2002/07/owl#"
  - "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  - "rdfs": "http://www.w3.org/2000/01/rdf-schema#"
  - "skos": "http://www.w3.org/2004/02/skos/core#"
  - "vivo": "http://vivoweb.org/ontology/core#"
  - "xsd": "http://www.w3.org/2001/XMLSchema#"

## Overarching RIALTO Model

TBD

## Mappings to RIALTO

### For Organizations

| Source & key   | RIALTO entry                                              | Notes |
| -------------- | --------------------------------------------------------- | ----- |
| CAP 'type'     | `rdf:type` / `@type` for given organization at RIALTO URI | See mapping below. |
| CAP 'alias'    | `@id` `http://rialto.stanford.edu/individual/{alias}`     | Domain may change. Want to confirm alias is consistent enough for use of minting resources that will be fed by all data sources. |
| CAP 'alias'    | `dbo:alias` then value as string                          | Capture the alias also in the metadata explicitly. |
| CAP 'name'     | `rdfs:label` then value as string                         | any alt labels? repeated labels? need to check.    |
| CAP 'orgCodes' | for each value, `dbo:code` then value as string           | alternate identifiers? where will we look for later matching? |
| CAP 'children' | `obo:BFO_0000051` (*has part*) then child's alias value as RIALTO URI  | capture each presumed URI from the alias, but get the data for that specific organization from separate API calls...? See question above. |
| CAP 'children' | for each child, `obo:BFO_000005` (*part of*) then parent's RIALTO URI | how to make sure this adds data to the child's graph without removing data the parent won't know about? Or just use Stanford / ROOT and add all data for all Organizations from that? |
| CAP 'url'      | `rdfs:seeAlso` then value as IRI                          |  |

### RIALTO Organization Types Mapping

| Source &  Type        | RIALTO / VIVO Entity Type            | Notes |
| --------------------- | ------------------------------------ | ----- |
| CAP@type ROOT         | vivo:University << foaf:Organization |       |
| CAP@type SCHOOL       | vivo:School << foaf:Organization     |       |
| CAP@type DEPARTMENT   | vivo:Department << foaf:Organization | From VIVO for Department: "Use for any non-academic department" so this may not fit long-term. Seems like vivo:AcademicDepartment could be better, but departments in CAP are not consistently academic or other. |
| CAP@type DIVISION     | vivo:Division << foaf:Organization, vivo:ExtensionUnit | From VIVO: subclass of Extension Unit, "A unit devoted primarily to extension activities, whether for outreach or research", so this may not fit long term. |
| CAP@type SUB_DIVISION | vivo:Division << foaf:Organization, vivo:ExtensionUnit | See note above. No requirement to distinguish sub-ness in RIALTO. |

## Sample RIALTO Graph

Sample output VIVO JSON-LD data for a provided Organization is in [our fixtures (this has been shortened and any real values replace)](spec/fixtures/vivo/org-out.json). A larger file with a fuller graph generated from multiple sources will be added in the near future.
