import { FeedbackCodeTable } from "../../app/assets/javascripts/feedback_code_table";

beforeEach(() => {
    document.body.innerHTML = "<table class='feedback-code-table'><tbody>" +
        "<tr><td id='line-1' class='lineno'><pre>print(5 + 6)</pre></td></tr>" +
        "<tr><td id='line-2' class='lineno'><pre>print(6 + 3)</pre></td></tr>" +
        "<tr><td id='line-3' class='lineno'><pre>print(9 + 15)</pre></td></tr>" +
        "</tbody></table>";
});

test("create feedback table with default settings", () => {
    const feedbackCodeTable = new FeedbackCodeTable();
    feedbackCodeTable.initAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    expect(document.querySelectorAll(".annotation").length).toBe(3);
});

test("feedback table should support more than 1 annotation per row (first and last row)", () => {
    const feedbackCodeTable = new FeedbackCodeTable();
    feedbackCodeTable.initAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    expect(document.querySelectorAll(".annotation").length).toBe(6);
});

test("annotation types should be transmitted into the view", () => {
    const feedbackCodeTable = new FeedbackCodeTable();
    feedbackCodeTable.initAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 1, "type": "warning" },
        { "text": "Division by zero", "row": 2, "type": "error" },
    ]);

    expect(document.querySelectorAll(".annotation.info").length).toBe(1);
    expect(document.querySelectorAll(".annotation.warning").length).toBe(1);
    expect(document.querySelectorAll(".annotation.error").length).toBe(1);
});
