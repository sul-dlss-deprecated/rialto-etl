# CAP Organizations to VIVO / RIALTO Stanford Organizations Mapping

This is mapping documentation for taking CAP API Organizations data (`http://api.stanford.edu/cap/v1/orgs/org-path-name`) and mapping them to our RIALTO model (based on VIVO-ISF Ontology) for `Organizations` (a subclass of `Agents`).

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
        "STAN"
      ],
      "type": "SCHOOL",
      "url": "http://funnywalks.stanford.pizza/"
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



## Previous notes, being merged above

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
