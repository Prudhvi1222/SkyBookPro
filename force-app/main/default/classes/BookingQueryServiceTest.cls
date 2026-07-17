@isTest
public class BookingQueryServiceTest {

    @testSetup
    static void setupData() {

        Account a =
            TestDataFactory.createAccount(
                'Query Test Corp'
            );

        Contact c =
            TestDataFactory.createContact(
                a.Id,
                'Query',
                'Tester'
            );

        Flight__c f =
            TestDataFactory.createFlight(
                'DEL',
                'BOM',
                DateTime.now().addDays(1)
            );

        Booking__c b =
            TestDataFactory.createBookingWithStatus(
                c.Id,
                f.Id,
                2,
                'Confirmed'
            );

        b.Agent__c = UserInfo.getUserId();

        update b;
    }



    @isTest
    static void testGetConfirmedBookingsByAgent() {

        Test.startTest();

        List<Booking__c> results =
            BookingQueryService.getConfirmedBookingsByAgent(
                UserInfo.getUserId()
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            results
        );
    }



    @isTest
    static void testGetTomorrowDepartures() {

        Test.startTest();

        List<Booking__c> results =
            BookingQueryService.getTomorrowDepartures();

        Test.stopTest();

        System.assertNotEquals(
            null,
            results
        );
    }



    @isTest
    static void testGetRevenueByMonth() {

        Test.startTest();

        List<AggregateResult> results =
            BookingQueryService.getRevenueByMonth();

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Revenue results should not be null'
        );
    }

}