@IsTest
private class DuffelFlightSearchServiceTest {

    /*
     * SUCCESS RESPONSE
     */
    private class SuccessMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);

            res.setHeader(
                'Content-Type',
                'application/json'
            );

            res.setBody(
            '{'+
            '"data":{'+
            '"offers":['+
            '{'+
            '"id":"off_123",'+
            '"total_amount":"5000",'+
            '"total_currency":"INR",'+
            '"slices":['+

            '{'+
            '"segments":['+
            '{'+
            '"flight_number":"AI202",'+
            '"departing_at":"2026-09-01T10:00:00",'+
            '"arriving_at":"2026-09-01T12:30:00",'+
            '"origin":{"iata_code":"DEL"},'+
            '"destination":{"iata_code":"BOM"},'+
            '"operating_carrier":{"name":"Air India"}'+
            '}'+
            ']'+
            '},'+

            '{'+
            '"segments":['+
            '{'+
            '"flight_number":"AI203",'+
            '"departing_at":"2026-09-05T13:00:00",'+
            '"arriving_at":"2026-09-05T15:30:00",'+
            '"origin":{"iata_code":"BOM"},'+
            '"destination":{"iata_code":"DEL"},'+
            '"operating_carrier":{"name":"Air India"}'+
            '}'+
            ']'+
            '}'+

            ']'+
            '}'+
            ']'+
            '}'+
            '}'
            );

            return res;
        }
    }

    /*
     * EMPTY OFFERS
     */
    private class EmptyMock implements HttpCalloutMock {

        public HTTPResponse respond(
            HTTPRequest req
        ){

            HttpResponse res =
                new HttpResponse();

            res.setStatusCode(200);

            res.setBody(
                '{"data":{"offers":[]}}'
            );

            return res;

        }

    }

    /*
     * ERROR RESPONSE
     */
    private class ErrorMock
        implements HttpCalloutMock{

        public HTTPResponse respond(
            HTTPRequest req
        ){

            HttpResponse res =
                new HttpResponse();

            res.setStatusCode(500);

            res.setBody(
                '{"error":"failure"}'
            );

            return res;

        }

    }

    @IsTest
    static void testOneWaySearch(){

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<FlightOfferWrapper> offers =

            DuffelFlightSearchService.searchFlights(

                'DEL',

                'BOM',

                '2026-09-01',

                null,

                'oneway',

                'economy',

                1

            );

        Test.stopTest();

        System.assertEquals(
            1,
            offers.size()
        );

        System.assertEquals(
            'off_123',
            offers[0].offerId
        );

        System.assertEquals(
            'DEL',
            offers[0].origin
        );

        System.assertEquals(
            'BOM',
            offers[0].destination
        );

        System.assertEquals(
            'oneway',
            offers[0].tripType
        );

    }

    @IsTest
    static void testRoundTripSearch(){

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<FlightOfferWrapper> offers =

            DuffelFlightSearchService.searchFlights(

                'DEL',

                'BOM',

                '2026-09-01',

                '2026-09-05',

                'roundtrip',

                'business',

                2

            );

        Test.stopTest();

        System.assertEquals(
            1,
            offers.size()
        );

        System.assertEquals(
            'roundtrip',
            offers[0].tripType
        );

        System.assertNotEquals(
            null,
            offers[0].returnFlightNumber
        );

        System.assertNotEquals(
            null,
            offers[0].returnDepartureTime
        );

    }
        @IsTest
    static void testEmptyOffers() {

        Test.setMock(
            HttpCalloutMock.class,
            new EmptyMock()
        );

        Test.startTest();

        List<FlightOfferWrapper> offers =
            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '2026-09-01',
                null,
                'oneway',
                'economy',
                1
            );

        Test.stopTest();

        System.assertEquals(
            0,
            offers.size()
        );
    }

    @IsTest
    static void testHttpFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock()
        );

        Test.startTest();

        Boolean exceptionThrown = false;

        try{

            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '2026-09-01',
                null,
                'oneway',
                'economy',
                1
            );

        }catch(Exception e){

            exceptionThrown = true;

        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown
        );
    }

    @IsTest
    static void testBlankOrigin() {

        Boolean exceptionThrown = false;

        try{

            DuffelFlightSearchService.searchFlights(
                '',
                'BOM',
                '2026-09-01',
                null,
                'oneway',
                'economy',
                1
            );

        }catch(Exception e){

            exceptionThrown = true;

        }

        System.assertEquals(
            true,
            exceptionThrown
        );
    }

    @IsTest
    static void testBlankDestination() {

        Boolean exceptionThrown = false;

        try{

            DuffelFlightSearchService.searchFlights(
                'DEL',
                '',
                '2026-09-01',
                null,
                'oneway',
                'economy',
                1
            );

        }catch(Exception e){

            exceptionThrown = true;

        }

        System.assertEquals(
            true,
            exceptionThrown
        );
    }

    @IsTest
    static void testBlankDepartureDate() {

        Boolean exceptionThrown = false;

        try{

            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '',
                null,
                'oneway',
                'economy',
                1
            );

        }catch(Exception e){

            exceptionThrown = true;

        }

        System.assertEquals(
            true,
            exceptionThrown
        );
    }

    @IsTest
    static void testRoundTripWithoutReturnDate() {

        Boolean exceptionThrown = false;

        try{

            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '2026-09-01',
                '',
                'roundtrip',
                'economy',
                1
            );

        }catch(Exception e){

            exceptionThrown = true;

        }

        System.assertEquals(
            true,
            exceptionThrown
        );
    }

    @IsTest
    static void testNullAdults() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<FlightOfferWrapper> offers =
            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '2026-09-01',
                null,
                'oneway',
                '',
                null
            );

        Test.stopTest();

        System.assertEquals(
            1,
            offers.size()
        );
    }

    @IsTest
    static void testZeroAdults() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<FlightOfferWrapper> offers =
            DuffelFlightSearchService.searchFlights(
                'DEL',
                'BOM',
                '2026-09-01',
                null,
                'oneway',
                '',
                0
            );

        Test.stopTest();

        System.assertEquals(
            1,
            offers.size()
        );
    }

}