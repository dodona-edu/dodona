import codeListing from "code_listing";
import { annotationState } from "state/Annotations";

// bootstrap
import bootstrap from "bootstrap";
import { machineAnnotationState } from "state/MachineAnnotations";
import userEvent from "@testing-library/user-event";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { html } from "lit";
import { UserAnnotation, userAnnotationState } from "state/UserAnnotations";
window.bootstrap = bootstrap;

beforeEach(async () => {
    // Mock MathJax
    window.MathJax = {} as MathJaxObject;
    // Mock typeset function of MathJax
    window.MathJax.typeset = () => "";

    // Bootstrap incorrectly detects jquery, so we need to disable it
    document.body.setAttribute("data-bs-no-jquery", "true");

    await fixture( html`
    <div id="modal-container"></div>
    <a href="#" data-bs-toggle="tab">Code <d-annotations-count-badge></d-annotations-count-badge></a>
    <div class="code-table" data-submission-id="54">
        <d-annotation-options></d-annotation-options>
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
    </div>`);
    codeListing.initAnnotations(54, 1, 1, 1, "print(5 + 6)\nprint(6 + 3)\nprint(9 + 15)\n");
    annotationState.visibility = "all";
    userAnnotationState.reset();
    machineAnnotationState.setMachineAnnotations([]);
});

test("create feedback table with default settings", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
    ]);

    await nextFrame();

    expect(document.querySelectorAll(".annotation").length).toBe(3);
});

test("html in annotations should be escaped", async () => {
    codeListing.addMachineAnnotations([{ "text": "<b>test</b>", "row": 0, "type": "warning" }]);

    await nextFrame();

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

    await nextFrame();

    expect(document.querySelectorAll(".annotation").length).toBe(6);
});

test("annotation types should be transmitted into the view", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 1, "type": "warning" },
        { "text": "Division by zero", "row": 2, "type": "error" },
    ]);

    await nextFrame();

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


    const button = document.querySelector(".mdi-comment-remove-outline");
    await userEvent.click(button);

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

    const button = document.querySelector(".mdi-comment-multiple-outline");
    await userEvent.click(button);

    // no dots visible
    expect(document.querySelectorAll(".dot").length).toBe(0);
});

test("only warning dot visible when in compressed error mode", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "warning" },
        { "text": "Division by zero", "row": 0, "type": "error" },
    ]);

    let button = document.querySelector(".mdi-comment-alert-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning").length).toBe(1);

    // Simulating user switching
    button = document.querySelector(".mdi-comment-multiple-outline");
    await userEvent.click(button);
    button = document.querySelector(".mdi-comment-remove-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-error").length).toBe(1);
});

test("no double dots", async () => {
    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "info" },
        { "text": "Float transformed into int", "row": 0, "type": "info" },
        { "text": "Division by zero", "row": 0, "type": "info" },
    ]);

    let button = document.querySelector(".mdi-comment-remove-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot").length).toBe(1);

    button = document.querySelector(".mdi-comment-multiple-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    button = document.querySelector(".mdi-comment-alert-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);

    button = document.querySelector(".mdi-comment-remove-outline");
    await userEvent.click(button);

    expect(document.querySelectorAll(".dot.dot-info:not(.hide)").length).toBe(1);
    expect(document.querySelectorAll(".dot.dot-warning:not(.hide)").length).toBe(0);
    expect(document.querySelectorAll(".dot.dot-error:not(.hide)").length).toBe(0);
});

test("annotations should be transmitted into view", async () => {
    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 1,
        "rows": 1,
    }));
    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 2,
        "rows": 1,
    }));
    await nextFrame();

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should support more than 1 annotation per row", async () => {
    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 1,
        "rows": 1,
    }));

    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 1,
        "rows": 1,
    }));
    await nextFrame();

    expect(document.querySelectorAll(".annotation").length).toBe(2);
});

test("feedback table should be able to contain both machine annotations and user annotations", async () => {
    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 1,
        "rows": 1,
    }));

    await userAnnotationState.addToMap(new UserAnnotation({
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
        },
        "row": 2,
        "rows": 1,
    }));

    codeListing.addMachineAnnotations([
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 0, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "warning" },
        { "text": "Value could be assigned", "row": 1, "type": "error" },
        { "text": "Value could be assigned", "row": 2, "type": "warning" },
        { "text": "Value could be assigned", "row": 2, "type": "info" },
    ]);
    await nextFrame();

    expect(document.querySelectorAll(".annotation").length).toBe(2 + 6);
});

test("ensure that all buttons are created", async () => {
    codeListing.initAnnotateButtons();
    await nextFrame();
    expect(document.querySelectorAll("d-create-annotation-button").length).toBe(3);
});

test("click on comment button", async () => {
    codeListing.initAnnotateButtons();

    await nextFrame();
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
    const annotationButton: HTMLButtonElement = document.querySelector(".annotation-button .btn");
    await userEvent.click(annotationButton);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
    await userEvent.click(annotationButton);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
});

test("empty form should close on click outside", async () => {
    codeListing.initAnnotateButtons();
    await nextFrame();
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
    const annotationButton: HTMLButtonElement = document.querySelector(".annotation-button .btn");
    await userEvent.click(annotationButton);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
    await userEvent.click(document.body);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
});

test("form should not close when it has content", async () => {
    codeListing.initAnnotateButtons();
    await nextFrame();
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
    const annotationButton: HTMLButtonElement = document.querySelector(".annotation-button .btn");
    await userEvent.click(annotationButton);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
    const textarea: HTMLTextAreaElement = document.querySelector("d-annotation-form textarea");
    await userEvent.type(textarea, "This is a test");
    await userEvent.click(document.body);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(1);
    await userEvent.clear(textarea);
    await userEvent.click(document.body);
    expect(document.querySelectorAll("d-annotation-form").length).toBe(0);
});
