# CAP Organizations to VIVO / RIALTO Stanford Organizations Mapping

This is mapping documentation for taking CAP API Organizations data (`http://api.stanford.edu/cap/v1/orgs/org-path-name`) and mapping them to our RIALTO model (based on VIVO-ISF Ontology) for `Organizations` (a subclass of `Agents`).

## Mapping

Reused Ontologies List (to be vetted):
  - "bibo": "http://purl.org/ontology/bibo/"
  - "c4o": "http://purl.org/spar/c4o/"
  - "cito": "http://purl.org/spar/cito/"
  - "dbpedia": "http://dbpedia.org/resource/"
  - "dbo": "http://dbpedia.org/ontology/"
  - "event": "http://purl.org/NET/c4dm/event.owl#"
  - "fabio": "http://purl.org/spar/fabio/"
  - "foaf": "http://xmlns.com/foaf/0.1/"
  - "geo": "http://aims.fao.org/aos/geopolitical.owl#"
  - "obo": "http://purl.obolibrary.org/obo/"
  - "ocrer": "http://purl.org/net/OCRe/research.owl#"
  - "ocresd": "http://purl.org/net/OCRe/study_design.owl#"
  - "owl": "http://www.w3.org/2002/07/owl#"
  - "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  - "rdfs": "http://www.w3.org/2000/01/rdf-schema#"
  - "scires": "http://vivoweb.org/ontology/scientific-research#"
  - "skos": "http://www.w3.org/2004/02/skos/core#"
  - "vcard": "http://www.w3.org/2006/vcard/ns#"
  - "vitro": "http://vitro.mannlib.cornell.edu/ns/vitro/0.7#"
  - "vitro-public": "http://vitro.mannlib.cornell.edu/ns/vitro/public#"
  - "vivo": "http://vivoweb.org/ontology/core#"
  - "xsd": "http://www.w3.org/2001/XMLSchema#"

For a given organization hash:

| CAP key      | RIALTO entry                                              | Notes |
| ------------ | --------------------------------------------------------- | ----- |
| 'type'       | `rdf:type` / `@type` for given organization at RIALTO URI | See mapping below. |
| 'alias'      | `@id` `http://rialto.stanford.edu/individual/{alias}`     | Domain may change. Want to confirm alias is consistent enough for use of minting resources that will be fed by all data sources. |
| 'alias'      | `dbo:alias` then value as string                          | Capture the alias also in the metadata explicitly. |
| 'name'       | `rdfs:label` then value as string                         | any alt labels? repeated labels? need to check.    |
| 'orgCodes'   | for each value, `dbo:code` then value as string           | alternate identifiers? where will we look for later matching? |
| 'children'   | `obo:BFO_0000051` (*has part*) then child's alias value as RIALTO URI  | capture each presumed URI from the alias, but get the data for that specific organization from separate API calls...? See question above. |
| 'children'   | for each child, `obo:BFO_000005` (*part of*) then parent's RIALTO URI | how to make sure this adds data to the child's graph without removing data the parent won't know about? Or just use Stanford / ROOT and add all data for all Organizations from that? |
| 'url'        | `rdfs:seeAlso` then value as IRI                          |  |
| 'browsable'  | n/a                                                       | Ignore. |
| 'onboarding' | n/a                                                       | Ignore. |

| CAP Organization Type | RIALTO / VIVO Entity Type            | Notes |
| --------------------- | ------------------------------------ | ----- |
| ROOT                  | vivo:University << foaf:Organization |       |
| SCHOOL                | vivo:School << foaf:Organization     |       |
| DEPARTMENT            | vivo:Department << foaf:Organization | From VIVO for Department: "Use for any non-academic department" so this may not fit long-term. Seems like vivo:AcademicDepartment could be better, but departments in CAP are not consistently academic or other. |
| DIVISION              | vivo:Division << foaf:Organization, vivo:ExtensionUnit | From VIVO: subclass of Extension Unit, "A unit devoted primarily to extension activities, whether for outreach or research", so this may not fit long term. |
| SUB_DIVISION          | vivo:Division << foaf:Organization, vivo:ExtensionUnit | See note above. No requirement to distinguish sub-ness in RIALTO. |

## Sample Input

Sample source CAP data for a provided Organization is in [our fixtures (this has been shortened and any real values replace)](spec/fixtures/cap/organization.json). See a simplified example of the JSON output below:

```JSON
{
  "alias": "stanford-test",
  "browsable": false,
  "children": [{
      "alias": "department-of-funny-walks",
      "browsable": false,
      "children": [{
          "alias": "department-of-funny-walks/intercollegiate-walks",
          "browsable": false,
          "name": "Intercollegiate Walks",
          "onboarding": true,
          "orgCodes": [
            "WALK",
            "WALZ"
          ],
          "type": "DEPARTMENT"
        },
        {
          "alias": "department-of-funny-walks/walks-education",
          "browsable": false,
          "children": [{
              "alias": "department-of-funny-walks/walks-education/adventure-walks",
              "browsable": false,
              "name": "Adventure Walks",
              "onboarding": true,
              "orgCodes": [
                "ADVE"
              ],
              "type": "DIVISION"
            }
          ],
          "name": "Walks Education",
          "onboarding": true,
          "orgCodes": [
            "EDUC",
            "WEDU",
            "EDUW",
            "WAED",
            "EDWA"
          ],
          "type": "DEPARTMENT"
        }
      ],
      "name": "Department of Funny Walks",
      "onboarding": false,
      "orgCodes": [
        "HAAA"
      ],
      "type": "SCHOOL"
    },
    {
      "alias": "graduate-school-of-parrots",
      "browsable": false,
      "name": "Graduate School of Parrots",
      "onboarding": true,
      "orgCodes": [
        "PARR"
      ],
      "type": "SCHOOL",
      "url": "http://parrots.python.pizza/"
    }],
  "name": "Stanford Test",
  "onboarding": false,
  "orgCodes": [
    "STAN"
  ],
  "type": "ROOT",
  "url": "http://python.pizza/"
}
```

For any given Organization, these keys / fields appear in its Organization object:

| Key          | Expectation                   | Definition | Notes |
| ------------ | ----------------------------- | ---------- | ----- |
| 'orgCodes'   | Array of 4-letter strings     | the Stanford-specific (for ... HR?) organization code or identifier | history / previous projects says these can be helpful but also reflect previous / no longer extent departments or relationships |
| 'type'       | String, 1 of following values: `ROOT`, `SCHOOL`, `DEPARTMENT`, `DIVISION`, `SUB_DIVISION` | The type of organization within the University (aka the `ROOT`) | See mappings to RIALTO / VIVO types below |
| 'name'       | String                        | Name or label for the organization represented by the present JSON Object | n/a |
| 'children'   | Array of Organization Objects | Any organizations that are children of the organization represented by the present JSON Object | Should we iterate on these for data or just to know what orgs are children, then call their own API response separately? |
| 'browsable'  | Boolean                       | Uncertain. If is public data? | n/a |
| 'alias'      | String, API query path value  | The API URL path value for the organization. | Is this used for anything other than the API? |
| 'url'        | String, HTTP URL              | URL provided for the given organization.     | n/a |
| 'onboarding' | Boolean                       | Uncertain. If onboarding exists? | n/a |

## Sample Output

Sample output VIVO JSON-LD data for a provided Organization is in [our fixtures (this has been shortened and any real values replace)](spec/fixtures/vivo/org-out.json). See a simplified example of the JSON output below:

```JSON
{
  "@context": {
    "dbpedia": "http://dbpedia.org/resource/",
    "dbo": "http://dbpedia.org/ontology/",
    "obo": "http://purl.obolibrary.org/obo/",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "vivo": "http://vivoweb.org/ontology/core#"
  },
  "@graph": [
    {
      "@id": "http://rialto.stanford.edu/individual/stanford-test",
      "@type": "vivo:University",
      "dbo:alias": "stanford-test",
      "rdfs:label": "Stanford Test",
      "rdfs:seeAlso": "http://python.pizza/",
      "dbo:code": [
        "STAN"
      ],
      "obo:BFO_0000051": [
        {
          "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks"
        },
        {
          "@id": "http://rialto.stanford.edu/individual/graduate-school-of-parrots"
        }
      ],
      "obo:RO_0001025": {
        "@id": "dbpedia:Palo_Alto,_California"
      }
    },
    {
      "@id": "http://rialto.stanford.edu/individual/graduate-school-of-parrots",
      "@type": "vivo:School",
      "dbo:alias": "graduate-school-of-parrots",
      "rdfs:label": "Graduate School of Parrots",
      "rdfs:seeAlso": "http://parrots.python.pizza/",
      "dbo:code": [
        "PARR"
      ],
      "obo:BFO_0000050": {
        "@id": "http://rialto.stanford.edu/individual/stanford-test"
      }
    },
    {
      "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks",
      "@type": "vivo:School",
      "dbo:alias": "department-of-funny-walks",
      "rdfs:label": "Department of Funny Walks",
      "dbo:code": [
        "HAAA"
      ],
      "obo:BFO_0000050": {
        "@id": "http://rialto.stanford.edu/individual/stanford-test"
      },
      "obo:BFO_0000051": [
        {
          "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/intercollegiate-walks"
        },
        {
          "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/walks-education"
        }
      ]
    },
    {
      "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/intercollegiate-walks",
      "@type": "vivo:Department",
      "dbo:alias": "department-of-funny-walks/intercollegiate-walks",
      "rdfs:label": "Intercollegiate Walks",
      "dbo:code": [
        "WALK",
        "WALZ"
      ],
      "obo:BFO_0000051": {
        "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks"
      }
    },
    {
      "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/walks-education",
      "@type": "vivo:Department",
      "dbo:alias": "department-of-funny-walks/walks-education",
      "rdfs:label": "Walks Education",
      "dbo:code": [
        "EDUC",
        "WEDU",
        "EDUW",
        "WAED",
        "EDWA"
      ],
      "obo:BFO_0000051": {
        "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks"
      },
      "obo:BFO_0000050": {
        "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/walks-education/adventure-walks"
      }
    },
    {
      "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/walks-education/adventure-walks",
      "@type": "vivo:Division",
      "dbo:alias": "department-of-funny-walks/walks-education/adventure-walks",
      "rdfs:label": "Adventure Walks",
      "dbo:code": [
        "ADVE"
      ],
      "obo:BFO_0000051": {
        "@id": "http://rialto.stanford.edu/individual/department-of-funny-walks/walks-education"
      }
    }
  ]
}
```
