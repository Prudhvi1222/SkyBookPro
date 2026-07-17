@IsTest
public class BookingServiceTest {

    @TestSetup
    static void setupData() {

        Account acc =
            TestDataFactory.createAccount(
                'Booking Service Test'
            );

        Contact con =
            TestDataFactory.createContact(
                acc.Id,
                'John',
                'Doe'
            );

        TestDataFactory.createFlight(
            'HYD',
            'DEL',
            System.now().addDays(5)
        );

        TestDataFactory.createFlight(
            'DEL',
            'HYD',
            System.now().addDays(10)
        );
    }

    @IsTest
    static void testCreateBookingOneWay() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        List<Flight__c> flights = [
            SELECT Id,
                   Amadeus_Offer_ID__c
            FROM Flight__c
            ORDER BY CreatedDate
        ];

        Test.startTest();

        Booking__c booking =
            BookingService.createBooking(

                con.Id,

                flights[0].Id,

                'offer001',

                2,

                'Economy',

                5000,

                null,

                null

            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            booking.Id
        );

        System.assertEquals(
            'Confirmed',
            booking.Booking_Status__c
        );

        System.assertNotEquals(
            null,
            booking.PNR__c
        );

        Integer passengerCount = [

            SELECT COUNT()

            FROM Passenger_Detail__c

            WHERE Booking__c=:booking.Id

        ];

        System.assertEquals(
            1,
            passengerCount
        );

        Integer segmentCount = [

            SELECT COUNT()

            FROM Flight_Segment__c

            WHERE Booking__c=:booking.Id

        ];

        System.assertEquals(
            1,
            segmentCount
        );

        Flight__c updatedFlight = [

            SELECT
                Amadeus_Offer_ID__c

            FROM Flight__c

            WHERE Id=:flights[0].Id

        ];

        System.assertEquals(
            'offer001',
            updatedFlight.Amadeus_Offer_ID__c
        );

    }

    @IsTest
    static void testCreateBookingRoundTrip() {

        Contact con = [

            SELECT Id

            FROM Contact

            LIMIT 1

        ];

        List<Flight__c> flights = [

            SELECT Id

            FROM Flight__c

            ORDER BY CreatedDate

        ];

        Test.startTest();

        Booking__c booking =

            BookingService.createBooking(

                con.Id,

                flights[0].Id,

                'offer002',

                2,

                'Business',

                9000,

                null,

                flights[1].Id

            );

        Test.stopTest();

        Integer segmentCount = [

            SELECT COUNT()

            FROM Flight_Segment__c

            WHERE Booking__c=:booking.Id

        ];

        System.assertEquals(

            2,

            segmentCount

        );

    }

    @IsTest
    static void testNullContact() {

        Flight__c flight = [

            SELECT Id

            FROM Flight__c

            LIMIT 1

        ];

        Boolean thrown = false;

        try{

            BookingService.createBooking(

                null,

                flight.Id,

                'offer',

                1,

                'Economy',

                1000,

                null,

                null

            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(

            true,

            thrown

        );

    }

    @IsTest
    static void testNullFlight() {

        Contact con = [

            SELECT Id

            FROM Contact

            LIMIT 1

        ];

        Boolean thrown = false;

        try{

            BookingService.createBooking(

                con.Id,

                null,

                'offer',

                1,

                'Economy',

                1000,

                null,

                null

            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(

            true,

            thrown

        );

    }

    @IsTest
    static void testZeroSeats() {

        Contact con = [

            SELECT Id

            FROM Contact

            LIMIT 1

        ];

        Flight__c flight = [

            SELECT Id

            FROM Flight__c

            LIMIT 1

        ];

        Boolean thrown = false;

        try{

            BookingService.createBooking(

                con.Id,

                flight.Id,

                'offer',

                0,

                'Economy',

                1000,

                null,

                null

            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(

            true,

            thrown

        );

    }
        @IsTest
    static void testNullPrice() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                1,
                'Economy',
                null,
                null,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testZeroPrice() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                1,
                'Economy',
                0,
                null,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testDefaultSeatClass() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        Test.startTest();

        Booking__c booking =
            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offerDefault',
                1,
                null,
                3500,
                null,
                null
            );

        Test.stopTest();

        System.assertEquals(
            'Economy',
            booking.Seat_Class__c
        );
    }

    @IsTest
    static void testPassengerJsonSuccess() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        String json =
        '['+
        '{'+
        '"firstName":"John",'+
        '"lastName":"Doe",'+
        '"dateOfBirth":"1995-01-01",'+
        '"passengerType":"Adult",'+
        '"passportNumber":"A123456",'+
        '"mealPreference":"Veg"'+
        '}'+
        ']';

        Test.startTest();

        Booking__c booking =
            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offerJson',
                1,
                'Economy',
                4500,
                json,
                null
            );

        Test.stopTest();

        Integer passengers = [

            SELECT COUNT()

            FROM Passenger_Detail__c

            WHERE Booking__c=:booking.Id

        ];

        System.assertEquals(
            1,
            passengers
        );
    }

    @IsTest
    static void testPassengerCountMismatch() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        String json =
        '['+
        '{'+
        '"firstName":"John",'+
        '"lastName":"Doe",'+
        '"dateOfBirth":"1995-01-01"'+
        '}'+
        ']';

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                2,
                'Economy',
                4500,
                json,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testMissingFirstName() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        String json =
        '['+
        '{'+
        '"lastName":"Doe",'+
        '"dateOfBirth":"1995-01-01"'+
        '}'+
        ']';

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                1,
                'Economy',
                5000,
                json,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testMissingLastName() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        String json =
        '['+
        '{'+
        '"firstName":"John",'+
        '"dateOfBirth":"1995-01-01"'+
        '}'+
        ']';

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                1,
                'Economy',
                5000,
                json,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }
        @IsTest
    static void testMissingDOB() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Flight__c flight = [
            SELECT Id
            FROM Flight__c
            LIMIT 1
        ];

        String json =
        '['+
        '{'+
        '"firstName":"John",'+
        '"lastName":"Doe"'+
        '}'+
        ']';

        Boolean thrown = false;

        try{

            BookingService.createBooking(
                con.Id,
                flight.Id,
                'offer',
                1,
                'Economy',
                5000,
                json,
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testGetMyBookings() {

        Test.startTest();

        List<Booking__c> bookings =
            BookingService.getMyBookings();

        Test.stopTest();

        System.assertNotEquals(
            null,
            bookings
        );
    }

    @IsTest
    static void testGetBookingDetails() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            LIMIT 1

        ];

        Test.startTest();

        Booking__c result =
            BookingService.getBookingDetails(
                booking.Id
            );

        Test.stopTest();

        System.assertEquals(
            booking.Id,
            result.Id
        );

        System.assertNotEquals(
            null,
            result.PNR__c
        );
    }

    @IsTest
    static void testGetBookingDetailsNullId() {

        Boolean thrown = false;

        try{

            BookingService.getBookingDetails(
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

    @IsTest
    static void testGetBookingSegments() {

        Booking__c booking = [

            SELECT Id

            FROM Booking__c

            LIMIT 1

        ];

        Test.startTest();

        List<Flight_Segment__c> segments =

            BookingService.getBookingSegments(
                booking.Id
            );

        Test.stopTest();

        System.assert(
            segments.size() > 0
        );
    }

    @IsTest
    static void testGetBookingSegmentsNullId() {

        Boolean thrown = false;

        try{

            BookingService.getBookingSegments(
                null
            );

        }catch(Exception e){

            thrown = true;

        }

        System.assertEquals(
            true,
            thrown
        );
    }

}