@IsTest
private class CurrencyServiceTest {

    /*
     * Mock for successful API response
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
                '{' +
                '"amount":1,' +
                '"base":"GBP",' +
                '"date":"2026-07-15",' +
                '"rates":{' +
                '"INR":112.75' +
                '}' +
                '}'
            );

            return res;
        }
    }

    /*
     * Mock for failed API response
     */
    private class FailureMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(500);

            res.setBody('{}');

            return res;
        }
    }

    @IsTest
    static void testGetGbpToInrRate_Success() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        Decimal rate =
            CurrencyService.getGbpToInrRate();

        Test.stopTest();

        System.assertEquals(
            112.75,
            rate
        );
    }

    @IsTest
    static void testGetGbpToInrRate_Failure() {

        Test.setMock(
            HttpCalloutMock.class,
            new FailureMock()
        );

        Test.startTest();

        Decimal rate =
            CurrencyService.getGbpToInrRate();

        Test.stopTest();

        System.assertEquals(
            1,
            rate
        );
    }
}