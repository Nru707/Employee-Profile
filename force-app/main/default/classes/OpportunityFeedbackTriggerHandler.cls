public with sharing class OpportunityFeedbackTriggerHandler {

    public static void sendFeedbackEmails(List<Id> opportunityIds) {
        try {
            List<Opportunity> opps = [
                SELECT Id, Name, Owner.Email, Owner.Name, Account.Name
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Opportunity opp : opps) {
                String formUrl = 'https://orgfarm-ab09574311-dev-ed.develop.my.salesforce-sites.com/feedback/FeedbackPage?oppId=' + opp.Id;
                String body =
            '<html><body style="font-family:Arial,sans-serif;">' +
            '<div style="max-width:600px;margin:auto;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden;">' +
            '<div style="background:linear-gradient(135deg,#0176d3,#014486);padding:32px;text-align:center;">' +
            '<h1 style="color:#fff;margin:0;">📋 Product Feedback Request</h1></div>' +
            '<div style="padding:32px;">' +
            '<p>Hi <strong>' + opp.Owner.Name + '</strong>,</p>' +
            '<p>Opportunity <strong>' + opp.Name + '</strong> is <strong style="color:#2e844a;">Closed Won!</strong> 🎉</p>' +
            '<div style="text-align:center;margin:28px 0;">' +
            '<a href="' + formUrl + '" style="background:#0176d3;color:#fff;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold;">Submit Feedback</a>' +
            '</div></div></div></body></html>';

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ opp.Owner.Email });
                mail.setSubject('Feedback Request: ' + opp.Name);
                mail.setHtmlBody(body);
                mail.setSaveAsActivity(true);
                emails.add(mail);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}
