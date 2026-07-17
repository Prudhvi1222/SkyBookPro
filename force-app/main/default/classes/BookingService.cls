/*public class BookingService {

    @AuraEnabled(cacheable=false)
    public static Booking__c createBooking(Id contactId,Id flightId,String offerId,Integer seats,String seatClass,Decimal price,String passengersJson) {

        // ADD THIS
        if (flightId == null) {
            throw new AuraHandledException('Flight Id cannot be null');
        }

        try {

            Flight__c flight = [SELECT Id,Name, Origin_Airport__c, Destination_Airport__c, Departure_DateTime__c, Arrival_DateTime__c, Airline_Name__c, Amadeus_Offer_ID__c FROM Flight__c WHERE Id = :flightId LIMIT 1];

            flight.Amadeus_Offer_ID__c = offerId;
            update flight;
            

            Booking__c booking = new Booking__c(
                Passanger__c       = contactId,
                Flight__c          = flightId,
                Seat_Class__c      = seatClass,
                Number_Of_Seats__c = seats,
                Base_Fare__c       = price,
                Booking_Status__c  = 'Confirmed',
                Booking_Date__c    = Date.today()
            );

            insert booking;

            Contact con = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactId];

            // Passenger_Detail__c passenger = new Passenger_Detail__c(
            //     Booking__c        = booking.Id,
            //     First_Name__c              = con.FirstName,
            //     Last_Name__c      = con.LastName,
            //     Passenger_Type__c = 'Adult',
            //     Date_of_Birth__c  = Date.today().addYears(-25)
            // );

            // insert passenger;

            List<Passenger_Detail__c> passengersToInsert = new List<Passenger_Detail__c>();

            if (!String.isBlank(passengersJson)) {
                List<PassengerInput> passengerInputs =(List<PassengerInput>) JSON.deserialize(passengersJson,List<PassengerInput>.class);

                for (PassengerInput p : passengerInputs) {
                    passengersToInsert.add(
                        new Passenger_Detail__c(
                            Booking__c = booking.Id,
                            First_Name__c = p.firstName,
                            Last_Name__c = p.lastName,
                            Date_of_Birth__c = p.dateOfBirth,
                            Passenger_Type__c = String.isBlank(p.passengerType)
                                ? 'Adult'
                                : p.passengerType,
                            Passport_Number__c = p.passportNumber,
                            Meal_Preference__c = p.mealPreference
                        )
                    );
                }
            } else {
                Contact con = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];

                passengersToInsert.add(
                    new Passenger_Detail__c(
                        Booking__c = booking.Id,
                        First_Name__c = con.FirstName,
                        Last_Name__c = con.LastName,
                        Passenger_Type__c = 'Adult',
                        Date_of_Birth__c = Date.today().addYears(-25)
                    )
                );
            }

            if (!passengersToInsert.isEmpty()) {
                insert passengersToInsert;
            }

            Flight_Segment__c segment = new Flight_Segment__c(
                Booking__c            = booking.Id,
                Segment_Order__c      = 1,
                Name                  = flight.Origin_Airport__c,
                Destination__c        = flight.Destination_Airport__c,
                Carrier_Code__c       = flight.Airline_Name__c,
                Flight_Number__c      = flight.Name,
                Departure_DateTime__c = flight.Departure_DateTime__c,
                Arrival_DateTime__c   = flight.Arrival_DateTime__c,
                Origin__c = flight.Origin_Airport__c
            );

            insert segment;

            return booking;

        } catch (Exception e) {

            throw new AuraHandledException(
                'Booking failed: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getMyBookings() {

        return [
            SELECT Id,
                   Name,
                   Booking_Status__c,
                   Seat_Class__c,
                   Total_Amount__c,
                   Booking_Date__c,
                   Flight__r.Origin_Airport__c,
                   Flight__r.Destination_Airport__c,
                   Flight__r.Departure_DateTime__c
            FROM Booking__c
            WHERE Agent__c = :UserInfo.getUserId()
            ORDER BY Booking_Date__c DESC
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Booking__c getBookingDetails(Id bookingId) {

        return [
            SELECT Id,
                   Name,
                   Booking_Status__c,
                   Seat_Class__c,
                   Total_Amount__c,
                   Base_Fare__c,
                   Taxes_Fees__c,
                   Booking_Date__c,
                   Cancellation_Reason__c,
                   Payment_Reference__c,
                   Number_Of_Seats__c,
                   Passanger__r.FirstName,
                   Passanger__r.LastName,
                   Passanger__r.Email,
                   Flight__r.Name,
                   Flight__r.Origin_Airport__c,
                   Flight__r.Destination_Airport__c,
                   Flight__r.Departure_DateTime__c,
                   Flight__r.Arrival_DateTime__c,
                   Flight__r.Airline_Name__c,
                   Flight__r.Amadeus_Offer_ID__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
    }
    
    public class PassengerInput {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public Date dateOfBirth;
        @AuraEnabled public String passengerType;
        @AuraEnabled public String passportNumber;
        @AuraEnabled public String mealPreference;
    }

}*/
public with sharing class BookingService {

    @AuraEnabled(cacheable=false)
    public static Booking__c createBooking(
        Id contactId,
        Id flightId,
        String offerId,
        Integer seats,
        String seatClass,
        Decimal price,
        String passengersJson,
        Id returnFlightId
    ) {
        if (contactId == null) {
            throw new AuraHandledException('Contact Id cannot be null');
        }

        if (flightId == null) {
            throw new AuraHandledException('Flight Id cannot be null');
        }

        if (seats == null || seats < 1) {
            throw new AuraHandledException('At least 1 seat is required.');
        }

        if (price == null || price <= 0) {
            throw new AuraHandledException('Price must be greater than zero.');
        }

        try {
            Flight__c flight = [
                SELECT Id,
                       Name,
                       Origin_Airport__c,
                       Destination_Airport__c,
                       Departure_DateTime__c,
                       Arrival_DateTime__c,
                       Airline_Name__c,
                       Amadeus_Offer_ID__c
                FROM Flight__c
                WHERE Id = :flightId
                LIMIT 1
            ];

            flight.Amadeus_Offer_ID__c = offerId;
            update flight;

            Booking__c booking = new Booking__c(
                Passenger__c       = contactId,
                Flight__c          = flightId,
                Seat_Class__c      = String.isBlank(seatClass) ? 'Economy' : seatClass,
                Number_Of_Seats__c = seats,
                Base_Fare__c       = price,
                Booking_Status__c  = 'Confirmed',
                Booking_Date__c    = Date.today(),
                PNR__c             = generateUniquePnr()
            );

            insert booking;

            List<Passenger_Detail__c> passengersToInsert =
                new List<Passenger_Detail__c>();

            if (!String.isBlank(passengersJson)) {
                List<PassengerInput> passengerInputs =
                    (List<PassengerInput>) JSON.deserialize(
                        passengersJson,
                        List<PassengerInput>.class
                    );

                if (passengerInputs == null || passengerInputs.isEmpty()) {
                    throw new AuraHandledException('Passenger details are required.');
                }

                if (passengerInputs.size() != seats) {
                    throw new AuraHandledException(
                        'Passenger count must match number of seats.'
                    );
                }

                for (PassengerInput p : passengerInputs) {
                    if (String.isBlank(p.firstName)) {
                        throw new AuraHandledException('Passenger first name is required.');
                    }

                    if (String.isBlank(p.lastName)) {
                        throw new AuraHandledException('Passenger last name is required.');
                    }

                    if (p.dateOfBirth == null) {
                        throw new AuraHandledException('Passenger date of birth is required.');
                    }

                    passengersToInsert.add(
                        new Passenger_Detail__c(
                            Booking__c = booking.Id,
                            First_Name__c = p.firstName,
                            Last_Name__c = p.lastName,
                            Date_of_Birth__c = p.dateOfBirth,
                            Passenger_Type__c = String.isBlank(p.passengerType)
                                ? 'Adult'
                                : p.passengerType,
                            Passport_Number__c = p.passportNumber,
                            Meal_Preference__c = p.mealPreference
                        )
                    );
                }
            } else {
                Contact con = [
                    SELECT FirstName,
                           LastName
                    FROM Contact
                    WHERE Id = :contactId
                    LIMIT 1
                ];

                passengersToInsert.add(
                    new Passenger_Detail__c(
                        Booking__c = booking.Id,
                        First_Name__c = con.FirstName,
                        Last_Name__c = con.LastName,
                        Passenger_Type__c = 'Adult',
                        Date_of_Birth__c = Date.today().addYears(-25)
                    )
                );
            }

            if (!passengersToInsert.isEmpty()) {
                insert passengersToInsert;
            }

            Flight_Segment__c outboundSegment = new Flight_Segment__c(
                Booking__c            = booking.Id,
                Segment_Order__c      = 1,
                Origin__c             = flight.Origin_Airport__c,
                Destination__c        = flight.Destination_Airport__c,
                Carrier_Code__c       = flight.Airline_Name__c,
                Flight_Number__c      = flight.Name,
                Departure_DateTime__c = flight.Departure_DateTime__c,
                Arrival_DateTime__c   = flight.Arrival_DateTime__c
            );

            List<Flight_Segment__c> segmentsToInsert = new List<Flight_Segment__c>{
                outboundSegment
            };

            // Round-trip bookings pass the return leg's Flight__c Id (created
            // alongside the outbound Flight__c during search). When present,
            // record it as a second segment so both legs of the trip are
            // persisted against the booking, not just the outbound leg.
            if (returnFlightId != null) {
                Flight__c returnFlight = [
                    SELECT Id,
                           Name,
                           Origin_Airport__c,
                           Destination_Airport__c,
                           Departure_DateTime__c,
                           Arrival_DateTime__c,
                           Airline_Name__c
                    FROM Flight__c
                    WHERE Id = :returnFlightId
                    LIMIT 1
                ];

                segmentsToInsert.add(
                    new Flight_Segment__c(
                        Booking__c            = booking.Id,
                        Segment_Order__c      = 2,
                        Origin__c             = returnFlight.Origin_Airport__c,
                        Destination__c        = returnFlight.Destination_Airport__c,
                        Carrier_Code__c       = returnFlight.Airline_Name__c,
                        Flight_Number__c      = returnFlight.Name,
                        Departure_DateTime__c = returnFlight.Departure_DateTime__c,
                        Arrival_DateTime__c   = returnFlight.Arrival_DateTime__c
                    )
                );
            }

            insert segmentsToInsert;

            return [
                SELECT Id,
                    Name,
                    PNR__c,
                    Booking_Status__c,
                    Seat_Class__c,
                    Total_Amount__c,
                    Booking_Date__c,
                    Number_Of_Seats__c,
                    Flight__c,
                    Passenger__c
                FROM Booking__c
                WHERE Id = :booking.Id
                LIMIT 1
            ];

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Booking failed: ' + e.getMessage()
            );
        }
    }

    // Returns all Flight_Segment__c rows for a booking, ordered by leg
    // (1 = outbound, 2 = return for round-trip bookings), so the UI can
    // render both legs of a round-trip instead of just the outbound one.
    @AuraEnabled(cacheable=true)
    public static List<Flight_Segment__c> getBookingSegments(Id bookingId) {
        if (bookingId == null) {
            throw new AuraHandledException('Booking Id is required.');
        }

        return [
            SELECT Id,
                   Segment_Order__c,
                   Origin__c,
                   Destination__c,
                   Carrier_Code__c,
                   Flight_Number__c,
                   Departure_DateTime__c,
                   Arrival_DateTime__c
            FROM Flight_Segment__c
            WHERE Booking__c = :bookingId
            ORDER BY Segment_Order__c ASC
        ];
    }

    @AuraEnabled(cacheable=true)
public static List<Booking__c> getMyBookings() {

    return [
        SELECT
            Id,
            Name,
            PNR__c,
            Booking_Status__c,
            Seat_Class__c,
            Total_Amount__c,
            Booking_Date__c,
            Flight__c,

            Flight__r.Name,
            Flight__r.Origin_Airport__c,
            Flight__r.Destination_Airport__c,
            Flight__r.Departure_DateTime__c,
            Flight__r.Arrival_DateTime__c,
            Flight__r.Airline_Name__c

        FROM Booking__c
        WHERE Agent__c = :UserInfo.getUserId()
        ORDER BY Booking_Date__c DESC
        LIMIT 50
    ];
}

    @AuraEnabled(cacheable=true)
    public static Booking__c getBookingDetails(Id bookingId) {
        if (bookingId == null) {
            throw new AuraHandledException('Booking Id is required.');
        }

        return [
            SELECT Id,
                   Name,
                   PNR__c,
                   Booking_Status__c,
                   Seat_Class__c,
                   Total_Amount__c,
                   Base_Fare__c,
                   Taxes_Fees__c,
                   Booking_Date__c,
                   Cancellation_Reason__c,
                   Payment_Reference__c,
                   Number_Of_Seats__c,
                   Passenger__c,
                   Passenger__r.FirstName,
                   Passenger__r.LastName,
                   Passenger__r.Email,
                   Flight__c,
                   Flight__r.Name,
                   Flight__r.Origin_Airport__c,
                   Flight__r.Destination_Airport__c,
                   Flight__r.Departure_DateTime__c,
                   Flight__r.Arrival_DateTime__c,
                   Flight__r.Airline_Name__c,
                   Flight__r.Amadeus_Offer_ID__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
    }

    // Generates a 6-character alphanumeric PNR (Passenger Name Record
    // locator), similar in style to real airline booking codes, and
    // confirms it isn't already in use before returning it.
    private static String generateUniquePnr() {
        final String CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion
        String candidate;
        Integer attempts = 0;

        do {
            candidate = randomPnrCode(CHARS);
            attempts++;
        } while (
            attempts < 5 &&
            !([SELECT Id FROM Booking__c WHERE PNR__c = :candidate LIMIT 1].isEmpty())
        );

        return candidate;
    }

    private static String randomPnrCode(String chars) {
        String code = '';
        for (Integer i = 0; i < 6; i++) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            code += chars.substring(idx, idx + 1);
        }
        return code;
    }

    public class PassengerInput {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public Date dateOfBirth;
        @AuraEnabled public String passengerType;
        @AuraEnabled public String passportNumber;
        @AuraEnabled public String mealPreference;
    }
}