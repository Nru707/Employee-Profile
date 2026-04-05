public without sharing class PublicFeedbackController {

    public String  oppId                  { get; set; }
    public String  opportunityName        { get; set; }
    public String  accountName            { get; set; }
    public String  ownerName              { get; set; }
    public String  closeDate              { get; set; }
    public String  respondentName         { get; set; }
    public String  respondentEmail        { get; set; }
    public String  feedbackDate           { get; set; }
    public String  subject                { get; set; }
    public String  comments               { get; set; }
    public String  improvementSuggestions { get; set; }
    public String  starRating             { get; set; }
    public String  npsScore               { get; set; }
    public String  dynamicResponsesJSON   { get; set; }
    public Boolean isInvalidLink          { get; set; }
    public Boolean alreadySubmitted       { get; set; }
    public Boolean isSubmitted            { get; set; }
    public Boolean showForm               { get; set; }
    public String  submittedFeedbackId    { get; set; }
    public Boolean hasDynamicQuestions    { get; set; }
    public List<String> sectionLabels     { get; set; }
    public Map<String, List<QuestionWrapper>> questionsBySection { get; set; }

    public PublicFeedbackController() {
        isInvalidLink       = false;
        alreadySubmitted    = false;
        isSubmitted         = false;
        showForm            = false;
        hasDynamicQuestions = false;
        feedbackDate        = String.valueOf(Date.today());
    }

    public PageReference initPage() {
        oppId = ApexPages.currentPage().getParameters().get('oppId');
        if (String.isBlank(oppId)) { isInvalidLink = true; return null; }
        try {
            Opportunity opp = [
                SELECT Id, Name, StageName, CloseDate,
                       Account.Name, Owner.Name, Owner.Email
                FROM Opportunity
                WHERE Id = :oppId
                AND StageName = 'Closed Won'
                LIMIT 1
            ];
            opportunityName = opp.Name;
            accountName     = opp.Account?.Name;
            ownerName       = opp.Owner?.Name;
            closeDate       = opp.CloseDate.format();
            respondentName  = opp.Owner?.Name;
            respondentEmail = opp.Owner?.Email;

            List<Product_Feedback__c> existing = [
                SELECT Id FROM Product_Feedback__c
                WHERE Opportunity__c = :oppId
                AND Submission_Status__c = 'Submitted'
                LIMIT 1
            ];
            if (!existing.isEmpty()) { alreadySubmitted = true; return null; }

            loadDynamicQuestions();
            showForm = true;

        } catch (Exception e) {
            isInvalidLink = true;
        }
        return null;
    }

    private void loadDynamicQuestions() {
        List<Feedback_Question__c> questions = [
            SELECT Id, Question_Text__c, Question_Type__c,
                   Picklist_Values__c, Is_Required__c,
                   Placeholder_Text__c, Section_Label__c, Display_Order__c
            FROM Feedback_Question__c
            WHERE Is_Active__c = true
            ORDER BY Display_Order__c ASC
        ];
        if (questions.isEmpty()) return;

        hasDynamicQuestions = true;
        sectionLabels       = new List<String>();
        questionsBySection  = new Map<String, List<QuestionWrapper>>();

        for (Feedback_Question__c q : questions) {
            String section = String.isNotBlank(q.Section_Label__c) ? q.Section_Label__c : 'Additional Questions';
            if (!questionsBySection.containsKey(section)) {
                questionsBySection.put(section, new List<QuestionWrapper>());
                sectionLabels.add(section);
            }
            questionsBySection.get(section).add(new QuestionWrapper(q));
        }
    }

    public PageReference submitFeedback() {
        try {
            // Debug log
            System.debug('=== SUBMIT START ===');
            System.debug('oppId: ' + oppId);
            System.debug('dynamicResponsesJSON: ' + dynamicResponsesJSON);
            System.debug('starRating: ' + starRating);
            System.debug('npsScore: ' + npsScore);
            System.debug('respondentName: ' + respondentName);
            System.debug('comments: ' + comments);

            // OppId URL se lo agar blank hai
            if (String.isBlank(oppId)) {
                oppId = ApexPages.currentPage().getParameters().get('oppId');
            }

            Product_Feedback__c fb = new Product_Feedback__c();
            fb.Opportunity__c       = oppId;
            fb.Submission_Status__c = 'Submitted';
            fb.Feedback_Date__c     = String.isNotBlank(feedbackDate) ? Date.valueOf(feedbackDate) : Date.today();
            insert fb;

            System.debug('Feedback inserted: ' + fb.Id);

            // Dynamic responses save karo
            if (String.isNotBlank(dynamicResponsesJSON)) {
                System.debug('Saving dynamic responses...');
                Map<String, Object> dynData = (Map<String, Object>) JSON.deserializeUntyped(dynamicResponsesJSON);
                List<Feedback_Response__c> responses = new List<Feedback_Response__c>();

                for (String qId : dynData.keySet()) {
                    String responseVal = String.valueOf(dynData.get(qId));
                    System.debug('Q: ' + qId + ' => ' + responseVal);

                    Feedback_Response__c fr = new Feedback_Response__c();
                    fr.Product_Feedback__c = fb.Id;
                    fr.Question__c         = qId;
                    fr.Response_Text__c    = responseVal;
                    responses.add(fr);
                }

                if (!responses.isEmpty()) {
                    insert responses;
                    System.debug('Responses inserted: ' + responses.size());
                }
            } else {
                System.debug('dynamicResponsesJSON is BLANK - responses not saved!');
            }

            submittedFeedbackId = fb.Id;
            showForm            = false;
            isSubmitted         = true;

        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()
            ));
        }
        return null;
    }

    public class QuestionWrapper {
        public String  id             { get; set; }
        public String  questionText   { get; set; }
        public String  questionType   { get; set; }
        public String  placeholder    { get; set; }
        public Boolean isRequired     { get; set; }
        public List<String> picklistOptions { get; set; }

        public Boolean isText     { get { return questionType == 'Text'; } }
        public Boolean isLongText { get { return questionType == 'Long Text'; } }
        public Boolean isNumber   { get { return questionType == 'Number'; } }
        public Boolean isDate     { get { return questionType == 'Date'; } }
        public Boolean isPicklist { get { return questionType == 'Picklist'; } }

        public QuestionWrapper(Feedback_Question__c q) {
            this.id           = q.Id;
            this.questionText = q.Question_Text__c;
            this.questionType = q.Question_Type__c;
            this.placeholder  = q.Placeholder_Text__c;
            this.isRequired   = q.Is_Required__c;
            if (q.Question_Type__c == 'Picklist' && String.isNotBlank(q.Picklist_Values__c)) {
                this.picklistOptions = new List<String>();
                for (String v : q.Picklist_Values__c.split(',')) {
                    this.picklistOptions.add(v.trim());
                }
            }
        }
    }
}