import { CodeListing } from "../../app/assets/javascripts/code_listing/code_listing";

beforeEach(() => {
    document.body.innerHTML = "<div class='code-table'>" +
        "<div class='feedback-table-options'>" +
            "<span id='messages-were-hidden' class='hide'></span>" +
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
});

test("create feedback table with default settings", () => {
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    expect(document.querySelectorAll(".annotation").length).toBe(3);
});

test("feedback table should support more than 1 annotation per row (first and last row)", () => {
    const codeListing = new CodeListing();
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
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 1, "type": "warning" },
        { "text": "Division by zero", "row": 2, "type": "error" },
    ]);

    expect(document.querySelectorAll(".annotation.info").length).toBe(1);
    expect(document.querySelectorAll(".annotation.warning").length).toBe(1);
    expect(document.querySelectorAll(".annotation.error").length).toBe(1);
});

test("dots only for non-shown messages and only the worst", () => {
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.hideAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(1);
});

test("dots not visible when all annotations are shown", () => {
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.showAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);
});


test("only warning dot visible when in compressed error mode", () => {
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    codeListing.compressMessages();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    // Simulating user switching
    codeListing.showAllAnnotations();
    codeListing.hideAllAnnotations();
    codeListing.showAllAnnotations();

    codeListing.compressMessages();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);
});

test("no double dots", () => {
    const codeListing = new CodeListing();
    codeListing.addAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "info" },
        { "text": "Division by zero", "row": 0, "type": "info" },
    ]);

    codeListing.showAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(3);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    codeListing.hideAllAnnotations();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(2);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    codeListing.compressMessages();

    expect(document.querySelectorAll(".dot.dot-info.hide").length).toBe(3);
    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error.hide").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);
});

test("correct buttons & elements are hidden and unhidden", () => {
    const codeListing = new CodeListing();
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

    expect(document.querySelectorAll("#messages-were-hidden.hide").length).toBe(1);
    expect(document.querySelectorAll("#messages-were-hidden:not(.hide)").length).toBe(0);

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

    expect(document.querySelectorAll("#messages-were-hidden.hide").length).toBe(0);
    expect(document.querySelectorAll("#messages-were-hidden:not(.hide)").length).toBe(1);

    expect(document.querySelectorAll("#diff-switch-prefix.hide").length).toBe(0);
    expect(document.querySelectorAll("#diff-switch-prefix:not(.hide)").length).toBe(1);
});
