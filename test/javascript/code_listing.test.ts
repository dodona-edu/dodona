import codeListing from "code_listing";
import { setAnnotationVisibility } from "state/Annotations";

// bootstrap
import bootstrap from "bootstrap";
import { addTestUserAnnotation, resetUserAnnotations } from "state/UserAnnotations";
import { setMachineAnnotations } from "state/MachineAnnotations";
window.bootstrap = bootstrap;

beforeEach(async () => {
    // Mock MathJax
    window.MathJax = {} as MathJaxObject;
    // Mock typeset function of MathJax
    window.MathJax.typeset = () => "";

    document.body.innerHTML = `
    <a href="#" data-bs-toggle="tab">Code <span class="badge" id="badge_code"></span></a>
    <div class="code-table" data-submission-id="54">
    <div id="feedback-table-options" class="feedback-table-options">
        <button class="btn btn-text" id="add_global_annotation">Annotatie toevoegen</button>
        <span class="flex-spacer"></span>
        <span class="diff-switch-buttons switch-buttons hide" id="annotations_toggles">
            <span id="diff-switch-prefix">Annotaties</span>
            <div class="btn-group btn-toggle" role="group" aria-label="Annotaties" data-bs-toggle="buttons">
                <button class="annotation-toggle active" id="show_all_annotations"></button>
                <button class="annotation-toggle" id="show_only_errors"></button>
                <button class="annotation-toggle" id="hide_all_annotations"></button>
            </div>
        </span>
    </div>
    <div id="feedback-table-global-annotations">
        <div id="feedback-table-global-annotations-list"></div>
    </div>
    <div class="code-listing-container">
        <table class="code-listing highlighter-rouge">
            <tbody>
            <tr id="line-1" class="lineno">
                <td class="rouge-gutter gl"><pre>1</pre></td>
                <td class="rouge-code"><pre>print(5 + 6)</pre></td>
            </tr>
            <tr id="line-2" class="lineno">
                <td class="rouge-gutter gl"><pre>2</pre></td>
                <td class="rouge-code"><pre>print(6 + 3)</pre></td>
            </tr>
            <tr id="line-3" class="lineno">
                <td class="rouge-gutter gl"><pre>1</pre></td>
                <td class="rouge-code"><pre>print(9 + 15)</pre></td>
            </tr>
            </tbody>
        </table>
    </div>
</div>`;
    codeListing.initAnnotations(54, 1, 1, 1, "print(5 + 6)\nprint(6 + 3)\nprint(9 + 15)\n", 3);
    setAnnotationVisibility("all");
    resetUserAnnotations();
    setMachineAnnotations([]);
});

test("create feedback table with default settings", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".annotation").length).toBe(3);
});

test("html in annotations should be escaped", async () => {
    codeListing.addMachineAnnotations([{ "text": "<b>test</b>", "row": 0, "type": "warning" }]);

    await new Promise(process.nextTick);

    expect(document.querySelector(".annotation .annotation-text").textContent).toBe("<b>test</b>");
});

test("feedback table should support more than 1 annotation per row (first and last row)", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".annotation").length).toBe(6);
});

test("annotation types should be transmitted into the view", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 1, "type": "warning" },
        { "text": "Division by zero", "row": 2, "type": "error" },
    ]);

    await new Promise(process.nextTick);

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

test("dots only for non-shown messages and only the worst", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    setAnnotationVisibility("none");

    await new Promise(process.nextTick);

    // Dot on line 1 should be shown.
    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.hide").length).toBe(0);

    // Type of the dot should be error.
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(1);
});

test("dots not visible when all annotations are shown", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    setAnnotationVisibility("all");

    await new Promise(process.nextTick);

    // no dots visible
    expect(document.querySelectorAll(".dot").length).toBe(0);
});

test("only warning dot visible when in compressed error mode", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    setAnnotationVisibility("important");

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning").length).toBe(1);

    // Simulating user switching
    setAnnotationVisibility("all");
    setAnnotationVisibility("none");

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(1);
});

test("no double dots", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "info" },
        { "text": "Division by zero", "row": 0, "type": "info" },
    ]);

    setAnnotationVisibility("none");
    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot").length).toBe(1);

    setAnnotationVisibility("all");

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    setAnnotationVisibility("important");

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    setAnnotationVisibility("none");

    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);
});

test("annotations should be transmitted into view", async () => {
    addTestUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This could be shorter",
        "rendered_markdown": "<p>This could be shorter</p>",
        "released": true,
        "permission": {
            update: false,
            destroy: false,
        },
        "user": {
            name: "Jan Klaassen",
        }
    });
    addTestUserAnnotation({
        "id": 2,
        "line_nr": 2,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This should be faster",
        "rendered_markdown": "<p>This should be faster</p>",
        "released": true,
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });
    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should support more than 1 annotation per row", async () => {
    addTestUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This could be shorter",
        "rendered_markdown": "<p>This could be shorter</p>",
        "permission": {
            update: false,
            destroy: false,
        },
        "released": true,
        "user": {
            name: "Jan Klaassen",
        }
    });

    addTestUserAnnotation({
        "id": 2,
        "line_nr": 1,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This should be faster",
        "rendered_markdown": "<p>This should be faster</p>",
        "released": true,
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });
    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should be able to contain both machine annotations and user annotations", async () => {
    addTestUserAnnotation({
        "id": 1,
        "line_nr": 1,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This could be shorter",
        "rendered_markdown": "<p>This could be shorter</p>",
        "released": true,
        "permission": {
            update: false,
            destroy: false,
        },
        "user": {
            name: "Jan Klaassen",
        }
    });

    addTestUserAnnotation({
        "id": 2,
        "line_nr": 2,
        "created_at": "2023-03-02T15:15:48.776+01:00",
        "url": "http://dodona.localhost:3000/nl/annotations/1.json",
        "last_updated_by": { "name": "Zeus Kronosson" },
        "course_id": 1,
        "responses": [],
        "type": "question",
        "annotation_text": "This should be faster",
        "rendered_markdown": "<p>This should be faster</p>",
        "released": true,
        "permission": {
            update: true,
            destroy: true,
        },
        "user": {
            name: "Piet Hein",
        }
    });

    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "error" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "info" },
    ]);
    await new Promise(process.nextTick);

    expect(document.querySelectorAll(".annotation").length).toBe(2 + 6);
});

test("ensure that all buttons are created", async () => {
    codeListing.initAnnotateButtons();
    await new Promise(process.nextTick);
    expect(document.querySelectorAll(".annotation-button").length).toBe(3);
});

test("click on comment button", async () => {
    codeListing.initAnnotateButtons();

    await new Promise(process.nextTick);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
    const annotationButton: HTMLButtonElement = document.querySelector(".annotation-button");
    annotationButton.click();
    await new Promise(process.nextTick);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
    annotationButton.click();
    await new Promise(process.nextTick);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
});
