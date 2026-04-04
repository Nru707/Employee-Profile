trigger OpportunityFeedbackTrigger on Opportunity (after update) {
    
    List<Id> closedWonIds = new List<Id>();
    
    for (Opportunity newOpp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(newOpp.Id);
        
        if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            closedWonIds.add(newOpp.Id);
        }
    }
    
    if (!closedWonIds.isEmpty()) {
        OpportunityFeedbackTriggerHandler.sendFeedbackEmails(closedWonIds);
    }
}
