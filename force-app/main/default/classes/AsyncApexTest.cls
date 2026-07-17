@isTest
public class AsyncApexTest {

    @testSetup
    static void setupData() {

        Account a =
            TestDataFactory.createAccount(
                'Async Test Corp'
            );

        Contact c =
            TestDataFactory.createContact(
                a.Id,
                
                'Async',
                'Tester'
            );

        Flight__c f =
            TestDataFactory.createFlight(
                'BOM',
                'DEL',
                DateTime.now().addDays(1)
            );

        TestDataFactory.createBookingWithStatus(
            c.Id,
            f.Id,
            2,
            'Confirmed'
        );
    }


    // Test 1 : Future Method

    @isTest
    static void testFutureMethod() {

        Booking__c b = [

            SELECT Id

            FROM Booking__c

            LIMIT 1
        ];

        Test.startTest();

        BookingEmailService.sendConfirmationEmail(

            new Set<Id>{ b.Id }

        );

        Test.stopTest();

        System.assert(

            true,

            'Future method executed successfully'
        );
    }


    // Test 2 : Batch Apex

    @isTest
    static void testBatchApex() {

        Test.startTest();

        Database.executeBatch(

            new BookingArchiveBatch(),

            200
        );

        Test.stopTest();

        List<AsyncApexJob> jobs = [

            SELECT Id,
                   Status

            FROM AsyncApexJob

            WHERE ApexClass.Name =

                  'BookingArchiveBatch'
        ];

        System.assert(

            jobs.size() > 0
        );
    }
    @isTest
static void testExecuteUpdatesOldBookings() {

    Contact c = [SELECT Id FROM Contact LIMIT 1];
    Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

    Booking__c b = TestDataFactory.createBooking(c.Id, f.Id, 1);

    b.Booking_Date__c = Date.today().addYears(-3);
    update b;

    Test.startTest();

    Database.executeBatch(new BookingArchiveBatch(), 1);

    Test.stopTest();

    Booking__c updatedBooking = [
        SELECT Booking_Status__c
        FROM Booking__c
        WHERE Id = :b.Id
    ];

    System.assertEquals(
        'Cancelled',
        updatedBooking.Booking_Status__c
    );
}

    // Test 3 : Schedulable

    @isTest
    static void testSchedulable() {

        Test.startTest();

        System.schedule(

            'Test Daily Reminder',

            '0 0 7 * * ?',

            new DailyDepartureReminderScheduler()
        );

        Test.stopTest();

        List<CronTrigger> jobs = [

            SELECT Id,
                   State

            FROM CronTrigger

            WHERE CronJobDetail.Name =

                  'Test Daily Reminder'
        ];

        System.assertEquals(

            1,

            jobs.size()
        );
    }


    // Test 4 : Queueable

    @isTest
    static void testQueueable() {

        Contact c = [

            SELECT Id

            FROM Contact

            LIMIT 1
        ];

        Flight__c f = [

            SELECT Id

            FROM Flight__c

            LIMIT 1
        ];

        Booking__c b =

            TestDataFactory.createBookingWithStatus(

                c.Id,

                f.Id,

                2,

                'Draft'
            );

        Test.startTest();

        System.enqueueJob(

            new DraftBookingExpiryJob(

                new List<Id>{ b.Id }

            )

        );

        Test.stopTest();

        Booking__c updated = [

            SELECT Booking_Status__c,

                   Cancellation_Reason__c

            FROM Booking__c

            WHERE Id = :b.Id
        ];

        System.assertEquals(

            'Cancelled',

            updated.Booking_Status__c
        );

        System.assertEquals(

            'Auto-expired by system',

            updated.Cancellation_Reason__c
        );
    }
}