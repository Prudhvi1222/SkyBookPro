@isTest
public class DraftBookingExpiryJobTest {

    @isTest

    static void testQueueable() {

        Account a =
            TestDataFactory.createAccount(
                'Queue Test'
            );

        Contact c =
            TestDataFactory.createContact(
                a.Id,
                'Test',
                'User'
            );

        Flight__c f =
            TestDataFactory.createFlight(
                'DEL',
                'BOM',
                DateTime.now().addDays(5)
            );

        Booking__c b =
            TestDataFactory.createBooking(
                c.Id,
                f.Id,
                2
            );

        Test.startTest();

        System.enqueueJob(

            new DraftBookingExpiryJob(

                new List<Id>{ b.Id }

            )

        );

        Test.stopTest();

        Booking__c updated = [

            SELECT Booking_Status__c

            FROM Booking__c

            WHERE Id=:b.Id
        ];

        System.assertEquals(

            'Cancelled',

            updated.Booking_Status__c
        );
    }
}