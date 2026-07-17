// BRD Section 10.4: Schedulable class — runs daily at 7 AM
// Schedule via: System.schedule('Daily Departure Reminder', '0 0 7 * * ?', new DailyDepartureReminderScheduler());
public class DailyDepartureReminderScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // BRD: Find confirmed bookings departing tomorrow and send reminders
        Date tomorrow = Date.today().addDays(1);

        List<Booking__c> departures = [
            SELECT Id, Name,
                   Passenger__r.Email,
                   Passenger__r.FirstName,
                   Flight__r.Origin_Airport__c,
                   Flight__r.Destination_Airport__c,
                   Flight__r.Departure_DateTime__c
            FROM Booking__c
            WHERE Booking_Status__c = 'Confirmed'
            AND Flight__r.Departure_DateTime__c >= :DateTime.newInstance(tomorrow, Time.newInstance(0,0,0,0))
            AND Flight__r.Departure_DateTime__c <  :DateTime.newInstance(tomorrow.addDays(1), Time.newInstance(0,0,0,0))
        ];

        if (!departures.isEmpty()) {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Booking__c b : departures) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ b.Passenger__r.Email });
                email.setSubject('Reminder: Your flight departs tomorrow! — ' + b.Name);
                email.setPlainTextBody(
                    'Dear ' + b.Passenger__r.FirstName + ',\n\n' +
                    'This is a reminder that your flight from ' +
                    b.Flight__r.Origin_Airport__c + ' to ' +
                    b.Flight__r.Destination_Airport__c +
                    ' departs tomorrow.\n\n' +
                    'Booking Reference: ' + b.Name + '\n\n' +
                    'Safe travels!\nSkyBook Pro Team'
                );
                emails.add(email);
            }

            Messaging.sendEmail(emails);
        }

        System.debug('DailyDepartureReminderScheduler executed. Reminders sent: ' + departures.size());
    }
}