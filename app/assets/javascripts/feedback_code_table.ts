export class FeedbackCodeTable {
    table: Element;

    constructor(feedbackTableSelector = "#feedback-code-table") {
        this.table = document.querySelector(feedbackTableSelector);
    }

    initMessages(messagesJson): void {
        console.log(messagesJson);
    }
}
