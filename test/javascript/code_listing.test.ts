import { CodeListing } from "../../app/assets/javascripts/code_listing/code_listing";

beforeEach(() => {
    document.body.innerHTML = "<table class='code-listing'><tbody>" +
        "<tr id='line-1' class='lineno'><td class='rouge-gutter gl'><pre>1</pre></td><td class='rouge-code'><pre>print(5 + 6)</pre></td></tr>" +
        "<tr id='line-2' class='lineno'><td class='rouge-gutter gl'><pre>2</pre></td><td class='rouge-code'><pre>print(6 + 3)</pre></td></tr>" +
        "<tr id='line-3' class='lineno'><td class='rouge-gutter gl'><pre>3</pre></td><td class='rouge-code'><pre>print(9 + 15)</pre></td></tr>" +
        "</tbody></table>";
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
