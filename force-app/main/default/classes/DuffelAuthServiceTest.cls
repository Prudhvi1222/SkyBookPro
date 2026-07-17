@IsTest
private class DuffelAuthServiceTest {

    @IsTest
    static void testGetAccessToken() {

        Test.startTest();

        String token =
            DuffelAuthService.getAccessToken();

        Test.stopTest();

        System.assertNotEquals(
            null,
            token
        );

        System.assert(
            token.startsWith('Bearer ')
        );
    }

    @IsTest
    static void testTokenNotBlank() {

        Test.startTest();

        String token =
            DuffelAuthService.getAccessToken();

        Test.stopTest();

        System.assertNotEquals(
            '',
            token
        );
    }

    @IsTest
    static void testBearerPrefix() {

        String token =
            DuffelAuthService.getAccessToken();

        System.assertEquals(
            true,
            token.contains('Bearer')
        );
    }

    @IsTest
    static void testMultipleCalls() {

        Test.startTest();

        String token1 =
            DuffelAuthService.getAccessToken();

        String token2 =
            DuffelAuthService.getAccessToken();

        Test.stopTest();

        System.assertEquals(
            token1,
            token2
        );
    }

}