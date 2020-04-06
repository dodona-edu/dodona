import { CodeListing } from "code_listing/code_listing";

let codeListing;

beforeEach(() => {
    document.body.innerHTML = "<span class='badge' data-description='code'></span>" +
        "<div class='code-table' data-submission-id='54'>" +
        "<div class='feedback-table-options'>" +
            "<span id='annotations-were-hidden' class='hide'></span>" +
            "<span class='flex-spacer'></span>" +
            "<span class='diff-switch-buttons diff-buttons'>" +
                "<span id='diff-switch-prefix' class='hide'>Berichten</span>" +
                "<div class='btn-group btn-toggle' role='group' data-toggle='buttons'>" +
                    "<button class='btn btn-secondary active hide' id='show_all_annotations'><i class='mdi mdi-18 mdi-comment-multiple-outline'></i></button>" +
                    "<button class='btn btn-secondary hide' id='show_only_errors'><i class='mdi mdi-18 mdi-comment-alert-outline'></i></button>" +
                    "<button class='btn btn-secondary hide' id='hide_all_annotations'><i class='mdi mdi-18 mdi-comment-remove-outline'></i></button>" +
                "</div>" +
            "</span>" +
        "</div>" +
        "<table class='code-listing'><tbody>" +
            "<tr id='line-1' class='lineno'><td class='rouge-gutter gl'><pre>1</pre></td><td class='rouge-code'><pre>print(5 + 6)</pre></td></tr>" +
            "<tr id='line-2' class='lineno'><td class='rouge-gutter gl'><pre>2</pre></td><td class='rouge-code'><pre>print(6 + 3)</pre></td></tr>" +
            "<tr id='line-3' class='lineno'><td class='rouge-gutter gl'><pre>3</pre></td><td class='rouge-code'><pre>print(9 + 15)</pre></td></tr>" +
        "</tbody></table>" +
        "</div>";
    codeListing = new CodeListing("print(5 + 6)\nprint(6 + 3)\nprint(9 + 15)\n");
});

test("create feedback table with default settings", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    expect(document.querySelectorAll(".annotation").length).toBe(3);
});

test("feedback table should support more than 1 annotation per row (first and last row)", () => {
    codeListing.addAnnotations([
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
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 1, "type": "warning" },
        { "text": "Division by zero", "row": 2, "type": "error" },
    ]);

    expect(document.querySelectorAll(".annotation.info").length).toBe(1);
    expect(document.querySelectorAll(".annotation.warning").length).toBe(1);
    expect(document.querySelectorAll(".annotation.error").length).toBe(1);
});

test("line highlighting", () => {
    codeListing.highlightLine(1);

    expect(document.querySelectorAll(".lineno.marked").length).toBe(1);

    codeListing.highlightLine(2);

    expect(document.querySelectorAll(".lineno.marked").length).toBe(2);

    codeListing.highlightLine(2);

    expect(document.querySelectorAll(".lineno.marked").length).toBe(2);

    codeListing.clearHighlights();

    expect(document.querySelectorAll(".lineno.marked").length).toBe(0);
});

test("dots only for non-shown messages and only the worst", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.hideAllAnnotations();

    expect(document.querySelectorAll(".dot.hide").length).toBe(0);

    expect(document.querySelectorAll(".dot.dot-info.dot-warning.dot-error").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning.dot-error:not(.dot-info)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-info.dot-error:not(.dot-warning)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-info.dot-warning:not(.dot-error)").length).toBe(0);
});

test("dots not visible when all annotations are shown", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.showAllAnnotations();

    // 1 Dot, that does not have a single dot-type class
    expect(document.querySelectorAll(".dot:not(.dot-info)").length).toBe(1);
    expect(document.querySelectorAll(".dot:not(.dot-warning)").length).toBe(1);
    expect(document.querySelectorAll(".dot:not(.dot-error)").length).toBe(1);
    expect(document.querySelectorAll(".dot").length).toBe(1);
});


test("only warning dot visible when in compressed error mode", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.compressAnnotations();

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error.dot-warning.dot-info").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.dot-info").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);

    // Simulating user switching
    codeListing.showAllAnnotations();
    codeListing.hideAllAnnotations();
    codeListing.showAllAnnotations();

    codeListing.compressAnnotations();

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error.dot-warning.dot-info").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.dot-info").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);
});

test("no double dots", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "info" },
        { "text": "Division by zero", "row": 0, "type": "info" },
    ]);

    expect(document.querySelectorAll(".dot").length).toBe(1);

    codeListing.showAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);

    codeListing.hideAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);

    codeListing.compressAnnotations();

    expect(document.querySelectorAll(".dot.dot-error.dot-warning.dot-info").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.dot-info").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);
});

test("correct buttons & elements are hidden and unhidden", () => {
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "info" },
        { "text": "Division by zero", "row": 0, "type": "info" },
    ]);

    expect(document.querySelectorAll("#hide_all_annotations.hide").length).toBe(0);
    expect(document.querySelectorAll("#hide_all_annotations:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#show_all_annotations.hide").length).toBe(0);
    expect(document.querySelectorAll("#show_all_annotations:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#show_only_errors.hide").length).toBe(1);
    expect(document.querySelectorAll("#show_only_errors:not(.hide)").length).toBe(0);

    expect(document.querySelectorAll("#annotations-were-hidden.hide").length).toBe(1);
    expect(document.querySelectorAll("#annotations-were-hidden:not(.hide)").length).toBe(0);

    expect(document.querySelectorAll("#diff-switch-prefix.hide").length).toBe(0);
    expect(document.querySelectorAll("#diff-switch-prefix:not(.hide)").length).toBe(1);

    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "error" },
        { "text": "Float transformed into int", "row": 0, "type": "error" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    expect(document.querySelectorAll("#hide_all_annotations.hide").length).toBe(0);
    expect(document.querySelectorAll("#hide_all_annotations:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#show_all_annotations.hide").length).toBe(0);
    expect(document.querySelectorAll("#show_all_annotations:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#show_only_errors.hide").length).toBe(0);
    expect(document.querySelectorAll("#show_only_errors:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#annotations-were-hidden.hide").length).toBe(0);
    expect(document.querySelectorAll("#annotations-were-hidden:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#diff-switch-prefix.hide").length).toBe(0);
    expect(document.querySelectorAll("#diff-switch-prefix:not(.hide)").length).toBe(1);

    const annotationsWereHidden: HTMLSpanElement = document.querySelector("span#annotations-were-hidden a") as HTMLSpanElement;
    annotationsWereHidden.click();

    expect(document.querySelectorAll("#annotations-were-hidden").length).toBe(0);

    expect(document.querySelectorAll("#show_all_annotations.active.hide").length).toBe(0);
    expect(document.querySelectorAll("#show_all_annotations.active:not(.hide)").length).toBe(1);
});

test("Dont show a message when there is only an error", () => {
    codeListing.addAnnotation({
        type: "error",
        text: "Replace with oneliner",
        row: 1
    });

    expect(document.querySelector("#annotations-were-hidden").textContent).toBe("");
});

test("annotations should be transmitted into view", () => {
    codeListing.addUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "annotation_text": "This could be shorter",
        "markdown_text": "<p>This could be shorter</p>",
        "permission": {
            update: false,
            destroy: false,
        },
        "user": {
            name: "Jan Klaassen",
        }
    });

    codeListing.addUserAnnotation({
        "id": 2,
        "line_nr": 2,
        "annotation_text": "This should be faster",
        "markdown_text": "<p>This should be faster</p>",
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should support more than 1 annotation per row", () => {
    codeListing.addUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "annotation_text": "This could be shorter",
        "markdown_text": "<p>This could be shorter</p>",
        "permission": {
            update: false,
            destroy: false,
        },
        "user": {
            name: "Jan Klaassen",
        }
    });

    codeListing.addUserAnnotation({
        "id": 2,
        "line_nr": 1,
        "annotation_text": "This should be faster",
        "markdown_text": "<p>This should be faster</p>",
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should be able to contain both machine annotations and user annotations", () => {
    codeListing.addUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "annotation_text": "This could be shorter",
        "markdown_text": "<p>This could be shorter</p>",
        "permission": {
            update: false,
            destroy: false,
        },
        "user": {
            name: "Jan Klaassen",
        }
    });

    codeListing.addUserAnnotation({
        "id": 2,
        "line_nr": 2,
        "annotation_text": "This should be faster",
        "markdown_text": "<p>This should be faster</p>",
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });

    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "error" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "info" },
    ]);

    expect(document.querySelectorAll(".annotation").length).toBe(2 + 6);
});

test("ensure that all buttons are created", () => {
    codeListing.initButtonsForComment();
    expect(document.querySelectorAll(".annotation-button").length).toBe(3);
});

test("click on comment button", () => {
    codeListing.initButtonsForComment();

    const annotationButton: HTMLButtonElement = document.querySelector(".annotation-button");
    annotationButton.click();
    expect(document.querySelectorAll("form.annotation-submission").length).toBe(1);
    annotationButton.click();
    expect(document.querySelectorAll("form.annotation-submission").length).toBe(1);
});
