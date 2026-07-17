@IsTest
private class AirportSearchServiceTest {

    private class PlacesSuccessMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);

            res.setHeader(
                'Content-Type',
                'application/json'
            );

            res.setBody(
                '{' +
                '"data":[' +
                '{' +
                '"type":"airport",' +
                '"iata_code":"HYD",' +
                '"name":"Rajiv Gandhi International",' +
                '"iata_country_code":"IN",' +
                '"city":{"name":"Hyderabad"}' +
                '},' +
                '{' +
                '"type":"city",' +
                '"iata_code":"LON",' +
                '"name":"London",' +
                '"iata_country_code":"GB"' +
                '},' +
                '{' +
                '"type":"airport",' +
                '"iata_code":"LHR",' +
                '"name":"Heathrow",' +
                '"iata_country_code":"GB",' +
                '"city_name":"London"' +
                '}' +
                ']' +
                '}'
            );

            return res;
        }
    }

    private class EmptyPlacesMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);

            res.setHeader(
                'Content-Type',
                'application/json'
            );

            res.setBody('{"data":[]}');

            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(500);
            res.setBody('{"errors":[{"message":"Server error"}]}');

            return res;
        }
    }

    @IsTest
    static void testSearchAirports_returnsOnlyAirportTypeResults() {

        Test.setMock(
            HttpCalloutMock.class,
            new PlacesSuccessMock()
        );

        Test.startTest();

        List<AirportSearchService.AirportSuggestion> results =
            AirportSearchService.searchAirports('heath');

        Test.stopTest();

        System.assertEquals(
            2,
            results.size()
        );

        System.assertEquals(
            'HYD',
            results[0].code
        );

        System.assertEquals(
            'Hyderabad',
            results[0].city
        );

        System.assertEquals(
            'LHR',
            results[1].code
        );

        System.assertEquals(
            'London',
            results[1].city
        );
    }

    @IsTest
    static void testSearchAirports_blankQueryReturnsNoCallout() {

        Test.startTest();

        List<AirportSearchService.AirportSuggestion> results =
            AirportSearchService.searchAirports('');

        Test.stopTest();

        System.assertEquals(
            0,
            results.size()
        );
    }

    @IsTest
    static void testSearchAirports_tooShortQueryReturnsNoCallout() {

        Test.startTest();

        List<AirportSearchService.AirportSuggestion> results =
            AirportSearchService.searchAirports('a');

        Test.stopTest();

        System.assertEquals(
            0,
            results.size()
        );
    }

    @IsTest
    static void testSearchAirports_emptyResponse() {

        Test.setMock(
            HttpCalloutMock.class,
            new EmptyPlacesMock()
        );

        Test.startTest();

        List<AirportSearchService.AirportSuggestion> results =
            AirportSearchService.searchAirports('zzz');

        Test.stopTest();

        System.assertEquals(
            0,
            results.size()
        );
    }

    @IsTest
    static void testSearchAirports_errorResponseThrows() {

        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock()
        );

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            AirportSearchService.searchAirports('del');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown
        );
    }
}
