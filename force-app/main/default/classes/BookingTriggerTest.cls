@isTest
public class BookingTriggerTest {

    @testSetup
    static void setupData() {
        Account a = TestDataFactory.createAccount('Trigger Test Corp');
        Contact c = TestDataFactory.createContact(a.Id, 'Trigger', 'Tester');
        TestDataFactory.createFlight('DEL', 'BOM', DateTime.now().addDays(5));
    }

    // Test 1: before insert — sets date and default status
    @isTest
    static void testBeforeInsert() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

        Test.startTest();
        Booking__c b = TestDataFactory.createBooking(c.Id, f.Id, 2);
        Test.stopTest();

        Booking__c result = [
            SELECT Booking_Status__c, Booking_Date__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertEquals('Draft', result.Booking_Status__c, 'Default status should be Draft');
        System.assertEquals(Date.today(), result.Booking_Date__c, 'Booking date should be today');
    }

    // Test 2: before insert — null status gets defaulted to Draft
    @isTest
    static void testBeforeInsert_NullStatus() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

        Test.startTest();
        Booking__c b = new Booking__c(
            Passenger__c = c.Id,
            Flight__c = f.Id,
            Seat_Class__c = 'Economy',
            Number_Of_Seats__c = 1,
            Base_Fare__c = 3000,
            Booking_Date__c = Date.today()
            // No Booking_Status__c set deliberately
        );
        insert b;
        Test.stopTest();

        Booking__c result = [
            SELECT Booking_Status__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertEquals('Draft', result.Booking_Status__c, 'Null status should default to Draft');
    }

    // Test 3: after insert — booking created successfully
    @isTest
    static void testAfterInsert() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

        Test.startTest();
        Booking__c b = TestDataFactory.createBooking(c.Id, f.Id, 2);
        Test.stopTest();

        List<Booking__c> bookings = [SELECT Id FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(1, bookings.size(), 'Booking should be created successfully');
    }

    // Test 4: after update — status changes to Cancelled
    @isTest
    static void testAfterUpdate_StatusChanged() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];
        Booking__c b = TestDataFactory.createBookingWithStatus(c.Id, f.Id, 2, 'Confirmed');

        Test.startTest();
        b.Booking_Status__c = 'Cancelled';
        b.Cancellation_Reason__c = 'Test cancellation';
        update b;
        Test.stopTest();

        Booking__c updated = [
            SELECT Booking_Status__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertEquals('Cancelled', updated.Booking_Status__c, 'Status should be Cancelled');
    }

    // Test 5: before delete — Confirmed booking cannot be deleted
    @isTest
    static void testBeforeDelete_PreventDeleteConfirmed() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];
        Booking__c b = TestDataFactory.createBookingWithStatus(c.Id, f.Id, 2, 'Confirmed');

        Test.startTest();
        try {
            delete b;
            System.assert(false, 'Should have thrown an exception');
        } catch (DmlException e) {
            System.assert(true, 'Exception thrown as expected for Confirmed booking');
        }
        Test.stopTest();
    }

    // Test 6: before delete — Draft booking CAN be deleted
    @isTest
    static void testBeforeDelete_AllowDeleteDraft() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];
        Booking__c b = TestDataFactory.createBooking(c.Id, f.Id, 1);

        Test.startTest();
        delete b;
        Test.stopTest();

        List<Booking__c> remaining = [SELECT Id FROM Booking__c WHERE Id = :b.Id];
        System.assertEquals(0, remaining.size(), 'Draft booking should be deletable');
    }
    @isTest
static void testBeforeUpdate_ReconfirmCancelled() {

    Contact c = [SELECT Id FROM Contact LIMIT 1];
    Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

    Booking__c b = TestDataFactory.createBookingWithStatus(
        c.Id,
        f.Id,
        2,
        'Cancelled'
    );

    Test.startTest();

    try {

        b.Booking_Status__c = 'Confirmed';

        update b;

        System.assert(
            false,
            'Exception should have been thrown'
        );

    } catch (DmlException e) {

        System.assert(
            e.getMessage().contains(
                'Cancelled bookings cannot be reconfirmed.'
            ),
            'Correct validation message should appear'
        );
    }

    Test.stopTest();
}
@isTest
static void testAfterUpdate_RefundCreated() {

    Contact c = [SELECT Id FROM Contact LIMIT 1];
    Flight__c f = [SELECT Id FROM Flight__c LIMIT 1];

    Booking__c b = TestDataFactory.createBookingWithStatus(
        c.Id,
        f.Id,
        2,
        'Confirmed'
    );

    b = [
        SELECT Id,
               Booking_Status__c,
               Total_Amount__c
        FROM Booking__c
        WHERE Id = :b.Id
    ];

    Test.startTest();

    b.Booking_Status__c = 'Cancelled';
    b.Cancellation_Reason__c = 'Test Refund';

    update b;

    Test.stopTest();

    List<Refund__c> refunds = [
        SELECT Id,
               Booking__c,
               Refund_Status__c,
               Refund_Amount__c,
               Requested_Date__c
        FROM Refund__c
        WHERE Booking__c = :b.Id
    ];

    System.assertEquals(
        1,
        refunds.size(),
        'One refund record should be created'
    );

    System.assertEquals(
        'Initiated',
        refunds[0].Refund_Status__c
    );

    System.assertEquals(
        b.Total_Amount__c,
        refunds[0].Refund_Amount__c
    );

    System.assertEquals(
        Date.today(),
        refunds[0].Requested_Date__c
    );
}
}