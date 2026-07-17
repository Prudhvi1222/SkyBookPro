public with sharing class ContactService {

    @AuraEnabled
    public static Id findOrCreatePassengerContact(

        String firstName,

        String lastName,

        String email,

        String phone

    ){

        if (String.isNotBlank(email)) {

            List<Contact> existing = [
                SELECT Id
                FROM Contact
                WHERE Email = :email
                LIMIT 1
            ];

            if (!existing.isEmpty()) {
                return existing[0].Id;
            }

        }

        return createPassengerContact(firstName, lastName, email, phone);

    }

    @AuraEnabled
    public static Id createPassengerContact(

        String firstName,

        String lastName,

        String email,

        String phone

    ){

        Contact c = new Contact();

        c.FirstName = firstName;

        c.LastName = lastName;

        c.Email = email;

        c.Phone = phone;

        insert c;

        return c.Id;

    }

}