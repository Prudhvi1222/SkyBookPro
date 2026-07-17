@IsTest
private class BookingArchiveBatchTest {

    @TestSetup
    static void setupData() {

        Account acc = TestDataFactory.createAccount('Archive Test');

        Contact con = TestDataFactory.createContact(
            acc.Id,
            'John',
            'Doe'
        );

        Flight__c flight = TestDataFactory.createFlight(
            'HYD',
            'DEL',
            System.now().addDays(10)
        );

        Booking__c booking = TestDataFactory.createBookingWithStatus(
            con.Id,
            flight.Id,
            2,
            'Confirmed'
        );

        booking.Booking_Date__c = Date.today().addYears(-3);

        update booking;
    }

    @IsTest
    static void testBookingArchiveBatch() {

        Test.startTest();
        Database.executeBatch(new BookingArchiveBatch(), 1);
        Test.stopTest();

        Booking__c booking = [
            SELECT Id,
                   Booking_Status__c,
                   Cancellation_Reason__c
            FROM Booking__c
            LIMIT 1
        ];

        System.assertEquals(
            'Cancelled',
            booking.Booking_Status__c
        );

        System.assertEquals(
            'Archived after 2 years',
            booking.Cancellation_Reason__c
        );

        Integer refundCount = [
            SELECT COUNT()
            FROM Refund__c
            WHERE Booking__c = :booking.Id
        ];

        System.assert(
            refundCount >= 1,
            'At least one refund should exist.'
        );

        Integer caseCount = [
            SELECT COUNT()
            FROM Case
            WHERE Booking__c = :booking.Id
        ];

        System.assert(
            caseCount >= 1,
            'At least one Case should exist.'
        );
    }

    @IsTest
    static void testFinishMethod() {

        Test.startTest();

        Id jobId = Database.executeBatch(
            new BookingArchiveBatch(),
            1
        );

        Test.stopTest();

        AsyncApexJob job = [
            SELECT Status,
                   NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals(
            'Completed',
            job.Status
        );

        System.assertEquals(
            0,
            job.NumberOfErrors
        );
    }
}