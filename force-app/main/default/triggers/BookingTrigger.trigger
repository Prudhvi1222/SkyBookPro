trigger BookingTrigger on Booking__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            BookingTriggerHandler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            BookingTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }

        if (Trigger.isDelete) {
            BookingTriggerHandler.beforeDelete(Trigger.old);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            BookingTriggerHandler.afterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            BookingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}