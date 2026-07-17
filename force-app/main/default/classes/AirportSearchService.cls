// Live airport/city autocomplete backed by Duffel's Places API
// (GET /places/suggestions), replacing the old static, ~100-airport
// hardcoded list in flightSearchForm/airports.js. That static list only
// covered a handful of major airports and always capped results at 6,
// so most cities/airports typed by a user simply never matched anything.
public with sharing class AirportSearchService {

    private static final Integer MIN_QUERY_LENGTH = 2;
    private static final Integer MAX_SUGGESTIONS = 8;

    // Lightweight shape returned to the LWC — mirrors the fields the
    // flightSearchForm autocomplete dropdown already renders
    // (code / city / name), so no template changes are required beyond
    // swapping the data source.
    public class AirportSuggestion {
        @AuraEnabled public String code;
        @AuraEnabled public String city;
        @AuraEnabled public String name;
        @AuraEnabled public String country;
    }

    @AuraEnabled(cacheable=false)
    public static List<AirportSuggestion> searchAirports(String query) {
        List<AirportSuggestion> results = new List<AirportSuggestion>();

        if (String.isBlank(query) || query.trim().length() < MIN_QUERY_LENGTH) {
            return results;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'https://api.duffel.com/places/suggestions?query=' +
            EncodingUtil.urlEncode(query.trim(), 'UTF-8')
        );
        req.setMethod('GET');
        req.setHeader('Authorization', DuffelAuthService.getAccessToken());
        req.setHeader('Accept', 'application/json');
        req.setHeader('Duffel-Version', 'v2');
        req.setTimeout(15000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'Airport search failed. Status: ' + res.getStatusCode()
            );
        }

        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        List<Object> places = (List<Object>) parsed.get('data');

        if (places == null) {
            return results;
        }

        for (Object o : places) {
            Map<String, Object> place = (Map<String, Object>) o;

            // Places suggestions can also return "city" entries (e.g.
            // searching "London" can suggest the London metro area itself).
            // Only airports have a bookable IATA airport code, so those are
            // the only ones useful for origin/destination selection.
            if (place.get('type') != 'airport') {
                continue;
            }

            String code = (String) place.get('iata_code');

            if (String.isBlank(code)) {
                continue;
            }

            AirportSuggestion suggestion = new AirportSuggestion();
            suggestion.code = code;
            suggestion.name = (String) place.get('name');
            suggestion.country = (String) place.get('iata_country_code');

            Map<String, Object> city = (Map<String, Object>) place.get('city');
            suggestion.city = city != null
                ? (String) city.get('name')
                : (String) place.get('city_name');

            results.add(suggestion);

            if (results.size() >= MAX_SUGGESTIONS) {
                break;
            }
        }

        return results;
    }
}