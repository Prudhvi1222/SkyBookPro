@IsTest
private class AmadeusFlightPricingServiceTest {

    private class FlightPricingMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody(
                '{' +
                '"data":{' +
                '"id":"offer_123",' +
                '"total_amount":"8500.50",' +
                '"total_currency":"INR"' +
                '}' +
                '}'
            );

            return res;
        }
    }

    @IsTest
    static void testConfirmPriceSuccess() {

        Test.setMock(HttpCalloutMock.class, new FlightPricingMock());

        Test.startTest();

        FlightOfferWrapper result =
            AmadeusFlightPricingService.confirmPrice(
                'offer_123',
                '{}'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('offer_123', result.offerId);
        System.assertEquals(8500.50, result.price);
        System.assertEquals('INR', result.currency_x);
    }

    private class FlightPricingErrorMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest
    static void testConfirmPriceFailure() {

        Test.setMock(HttpCalloutMock.class, new FlightPricingErrorMock());

        Test.startTest();

        try {

            AmadeusFlightPricingService.confirmPrice(
                'offer_123',
                '{}'
            );

            System.assert(false);

        } catch (AuraHandledException ex) {

            System.assert(
                ex.getMessage().contains('Price confirmation failed.')
            );
        }

        Test.stopTest();
    }
}