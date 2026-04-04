public without sharing class DynamicFeedbackController {

    // ─── Load all active questions (ordered) ─────────────────────────────
    @AuraEnabled
    public static List<Map<String, Object>> getActiveQuestions() {
        List<Feedback_Question__c> questions = [
            SELECT Id, Name, Question_Text__c, Question_Type__c,
                   Picklist_Values__c, Display_Order__c,
                   Is_Required__c, Placeholder_Text__c, Section_Label__c
            FROM Feedback_Question__c
            WHERE Is_Active__c = true
            ORDER BY Display_Order__c ASC
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();

        for (Feedback_Question__c q : questions) {
            Map<String, Object> qMap = new Map<String, Object>();
            qMap.put('id',           q.Id);
            qMap.put('name',         q.Name);
            qMap.put('questionText', q.Question_Text__c);
            qMap.put('questionType', q.Question_Type__c);
            qMap.put('isRequired',   q.Is_Required__c);
            qMap.put('placeholder',  q.Placeholder_Text__c);
            qMap.put('sectionLabel', q.Section_Label__c);
            qMap.put('order',        q.Display_Order__c);

            // Picklist values →
            if (q.Question_Type__c == 'Picklist' && String.isNotBlank(q.Picklist_Values__c)) {
                List<String> vals = q.Picklist_Values__c.split(',');
                List<Map<String, String>> options = new List<Map<String, String>>();
                for (String v : vals) {
                    String trimmed = v.trim();
                    Map<String, String> opt = new Map<String, String>();
                    opt.put('label', trimmed);
                    opt.put('value', trimmed);
                    options.add(opt);
                }
                qMap.put('picklistOptions', options);
            }
            result.add(qMap);
        }
        return result;
    }

    // ─── Load Opportunity Details ─────────────────────────────────────────
    @AuraEnabled
    public static Map<String, Object> getOpportunityDetails(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, Name, StageName, CloseDate,
                   Account.Name, Owner.Name, Owner.Email, Amount
            FROM Opportunity
            WHERE Id = :opportunityId LIMIT 1
        ];
        Map<String, Object> result = new Map<String, Object>();
        result.put('opportunityId',   opp.Id);
        result.put('opportunityName', opp.Name);
        result.put('accountName',     opp.Account?.Name);
        result.put('ownerName',       opp.Owner?.Name);
        result.put('ownerEmail',      opp.Owner?.Email);
        result.put('closeDate',       String.valueOf(opp.CloseDate));
        result.put('amount',          opp.Amount);
        result.put('stage',           opp.StageName);
        return result;
    }

    // ─── Save Dynamic Feedback Responses ─────────────────────────────────
    @AuraEnabled
    public static String saveFeedback(String opportunityId, String responsesJSON) {
        try {
            Product_Feedback__c fb = new Product_Feedback__c();
            fb.Opportunity__c       = opportunityId;
            fb.Submission_Status__c = 'Submitted';
            fb.Feedback_Date__c     = Date.today();
            insert fb;

            List<Map<String, Object>> responses =
                (List<Map<String, Object>>) JSON.deserializeUntyped(responsesJSON);

            List<Feedback_Response__c> responseRecords = new List<Feedback_Response__c>();
            for (Map<String, Object> r : responses) {
                Feedback_Response__c fr = new Feedback_Response__c();
                fr.Product_Feedback__c = fb.Id;
                fr.Question__c         = (String) r.get('questionId');
                fr.Response_Text__c    = (String) r.get('response');
                responseRecords.add(fr);
            }
            if (!responseRecords.isEmpty()) insert responseRecords;

            return fb.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    // ─── Check Feedback Sent ──────────────────────────────────────────────
    @AuraEnabled
    public static Boolean checkFeedbackSent(Id opportunityId) {
        return ![SELECT Id FROM Product_Feedback__c
                 WHERE Opportunity__c = :opportunityId
                 AND Submission_Status__c = 'Submitted' LIMIT 1].isEmpty();
    }
}
