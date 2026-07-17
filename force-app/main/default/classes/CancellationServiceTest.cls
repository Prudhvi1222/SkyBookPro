@IsTest
public class CancellationServiceTest {

    @TestSetup
    static void setupData() {

        Account acc =
            TestDataFactory.createAccount(
                'Cancellation Test'
            );

        Contact con =
            TestDataFactory.createContact(
                acc.Id,
                'John',
                'Doe'
            );

        Flight__c flight =
            TestDataFactory.createFlight(
                'HYD',
                'DEL',
                System.now().addDays(5)
            );

        TestDataFactory.createBookingWithStatus(
            con.Id,
            flight.Id,
            2,
            'Confirmed'
        );

        TestDataFactory.createBookingWithStatus(
            con.Id,
            flight.Id,
            2,
            'Cancelled'
        );
    }

    @IsTest
    static void testCancelBookingSuccess() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            WHERE Booking_Status__c='Confirmed'

            LIMIT 1

        ];

        Test.startTest();

        CancellationService.cancelBooking(

            booking.Id,

            'Passenger requested cancellation'

        );

        Test.stopTest();

        Booking__c updated = [

            SELECT
                Booking_Status__c,
                Cancellation_Reason__c

            FROM Booking__c

            WHERE Id=:booking.Id

        ];

        System.assertEquals(
            'Cancelled',
            updated.Booking_Status__c
        );

        System.assertEquals(
            'Passenger requested cancellation',
            updated.Cancellation_Reason__c
        );
    }

    @IsTest
    static void testAlreadyCancelledBooking() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            WHERE Booking_Status__c='Cancelled'

            LIMIT 1

        ];

        Test.startTest();

        Boolean exceptionThrown = false;

        try{

            CancellationService.cancelBooking(

                booking.Id,

                'Test'

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
    static void testNullBookingId() {

        Test.startTest();

        Boolean exceptionThrown = false;

        try{

            CancellationService.cancelBooking(

                null,

                'Reason'

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
    static void testBlankReason() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            WHERE Booking_Status__c='Confirmed'

            LIMIT 1

        ];

        Test.startTest();

        Boolean exceptionThrown = false;

        try{

            CancellationService.cancelBooking(

                booking.Id,

                ''

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
    static void testNullReason() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            WHERE Booking_Status__c='Confirmed'

            LIMIT 1

        ];

        Test.startTest();

        Boolean exceptionThrown = false;

        try{

            CancellationService.cancelBooking(

                booking.Id,

                null

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
    static void testRefundFound() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            LIMIT 1

        ];

        TestDataFactory.createRefund(

            booking.Id,

            2500

        );

        Test.startTest();

        Refund__c refund =

            CancellationService.getRefundStatus(

                booking.Id

            );

        Test.stopTest();

        System.assertNotEquals(

            null,

            refund

        );
    }

    @IsTest
    static void testRefundNotFound() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            WHERE Booking_Status__c='Confirmed'

            LIMIT 1

        ];

        Test.startTest();

        Refund__c refund =

            CancellationService.getRefundStatus(

                booking.Id

            );

        Test.stopTest();

        System.assertEquals(

            null,

            refund

        );
    }

    @IsTest
    static void testNullRefundBookingId() {

        Test.startTest();

        Refund__c refund =

            CancellationService.getRefundStatus(

                null

            );

        Test.stopTest();

        System.assertEquals(

            null,

            refund

        );
    }

}