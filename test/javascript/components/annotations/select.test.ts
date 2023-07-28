import { fixture } from "@open-wc/testing-helpers";
import { getOffset, selectedRangeFromSelection } from "components/annotations/selectionHelpers";
import "components/annotations/code_listing_row";
import { submissionState } from "state/Submissions";

describe("getOffsetTest", () => {
    it("should return the correct offset", async () => {
        const context = await fixture("<div><pre><span>hello</span> <span>w<span id=\"target\">or</span>ld</span></pre></div>");
        const target = context.querySelector("#target");

        const offset = getOffset(target, 1);
        expect(offset).toBe(8);
    });

    it("should ignore anny offset outside the pre ellement", async () => {
        const context = await fixture("<div>123<pre><span>hello</span> <span>w<span id=\"target\">or</span>ld</span></pre></div>");
        const target = context.querySelector("#target");

        const offset = getOffset(target, 1);
        expect(offset).toBe(8);
    });

    it("should return undefined if the node is not inside a pre element", async () => {
        const context = await fixture("<div><span id=\"target\">hello</span><pre> world</pre></div>");
        const target = context.querySelector("#target");

        const offset = getOffset(target, 1);
        expect(offset).toBe(undefined);
    });
});

describe("selectedRangeFromSelectionTest", () => {
    let context;
    beforeEach(async () => {
        submissionState.code = "hello world\n\nprint(world)";
        context = await fixture(`
            <div>
                <span id="foo">bar</span>
                <d-code-listing-row row="1" rendered-code="<span id='t1'>hello</span> <span id='t2'>w<span id='t3'>or</span>ld</span>"></d-code-listing-row>
                <d-code-listing-row row="2" rendered-code=""></d-code-listing-row>
                <d-code-listing-row row="3" rendered-code="<span id='t4'>print</span>(<span id='t5'>w<span id='t6'>or</span>ld</span>)"></d-code-listing-row>
            </div>
        `);
        window.getSelection().removeAllRanges();
    });

    it("should return the correct range", async () => {
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#t1").childNodes[0], 3);
        range.setEnd(context.querySelector("#t3").childNodes[0], 1);
        selection.addRange(range);

        const selectedRange = selectedRangeFromSelection(selection);
        expect(selectedRange).toEqual({ row: 1, column: 3, rows: 1, columns: 5 });
    });

    it("should return the correct range when the selection spans multiple rows", async () => {
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#t1").childNodes[0], 3);
        range.setEnd(context.querySelector("#t5").childNodes[0], 1);
        selection.addRange(range);

        const selectedRange = selectedRangeFromSelection(selection);
        expect(selectedRange).toEqual({ row: 1, column: 0, rows: 3, columns: undefined });

        // Selection should be updated to the new range
        expect(selection.rangeCount).toBe(1);
        const newRange = selection.getRangeAt(0);

        expect(newRange.startContainer).toBe(context.querySelector("#line-1 .tooltip-layer"));
        expect(newRange.endContainer).toBe(context.querySelector("#line-3 .tooltip-layer"));
        expect(newRange.startOffset).toBe(0);
        expect(newRange.endOffset).toBe(4);
    });

    it("Should create multiple ranges if the selection contains multiple ranges", async () => {
        // same selection as above, but in the firefox format
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#t1").childNodes[0], 3);
        range.setEnd(context.querySelector("#line-1 .code-line"), 4);
        selection.addRange(range);

        const range2 = document.createRange();
        range2.setStart(context.querySelector("#line-3 .code-line"), 0);
        range2.setEnd(context.querySelector("#t5").childNodes[0], 1);
        selection.addRange(range2);

        // The testing framework doesn't support multiple ranges
        expect(selection.rangeCount).toBe(1);

        // The test code for when the framework does support multiple ranges
        // const selectedRange = selectedRangeFromSelection(selection);
        // expect(selectedRange).toEqual({ row: 1, column: 0, rows: 3, columns: undefined });
        //
        // // Selection should be updated to the new ranges
        // expect(selection.rangeCount).toBe(2);
        //
        // const firstRange = selection.getRangeAt(0);
        // expect(firstRange.startContainer).toBe(context.querySelector("#line-1 .code-line"));
        // expect(firstRange.endContainer).toBe(context.querySelector("#line-1 .code-line"));
        // expect(firstRange.startOffset).toBe(0);
        // expect(firstRange.endOffset).toBe(5);
        //
        // const secondRange = selection.getRangeAt(1);
        // expect(secondRange.startContainer).toBe(context.querySelector("#line-3 .code-line"));
        // expect(secondRange.endContainer).toBe(context.querySelector("#line-3 .code-line"));
        // expect(secondRange.startOffset).toBe(0);
        // expect(secondRange.endOffset).toBe(5);
    });

    it("should remove starting empty lines from the selection", async () => {
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#line-2 .code-line"), 0);
        range.setEnd(context.querySelector("#t6").childNodes[0], 1);
        selection.addRange(range);

        const selectedRange = selectedRangeFromSelection(selection);
        // Full line selection
        expect(selectedRange).toEqual({ row: 3, column: 0, rows: 1, columns: undefined });

        // Selection should be updated to the new range
        expect(selection.rangeCount).toBe(1);
        const newRange = selection.getRangeAt(0);

        expect(newRange.startContainer).toBe(context.querySelector("#line-3 .tooltip-layer"));
        expect(newRange.endContainer).toBe(context.querySelector("#line-3 .tooltip-layer"));
        expect(newRange.startOffset).toBe(0);
        expect(newRange.endOffset).toBe(4);
    });

    it("should remove ending empty lines from the selection", async () => {
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#t1").childNodes[0], 3);
        range.setEnd(context.querySelector("#line-2 .code-line"), 0);
        selection.addRange(range);

        const selectedRange = selectedRangeFromSelection(selection);
        expect(selectedRange).toEqual({ row: 1, column: 3, rows: 1, columns: undefined });

        // Selection is not updated in this case
        expect(selection.rangeCount).toBe(1);
        const newRange = selection.getRangeAt(0);
        expect(newRange).toBe(range);
    });

    it("should return undefined if start or end is not inside code-listing-row", async () => {
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStart(context.querySelector("#foo").childNodes[0], 3);
        range.setEnd(context.querySelector("#t3").childNodes[0], 1);
        selection.addRange(range);

        const selectedRange = selectedRangeFromSelection(selection);
        expect(selectedRange).toBeUndefined();

        range.setStart(context.querySelector("#t1").childNodes[0], 3);
        range.setEnd(context.querySelector("#foo").childNodes[0], 1);
        selection.addRange(range);

        const selectedRange2 = selectedRangeFromSelection(selection);
        expect(selectedRange2).toBeUndefined();
    });

    it("should be able to calculate the correct range when the selection is reversed", async () => {
        const selection = window.getSelection();
        const range = new Range();
        range.setStart(context.querySelector("#t3").childNodes[0], 1);
        range.setEnd(context.querySelector("#t1").childNodes[0], 3);
        selection.addRange(range);

        // Test framework doesn't support reversed ranges
        expect(range.startContainer).toBe(range.endContainer);

        // Test code for when the framework does support reversed ranges
        // const selectedRange = selectedRangeFromSelection(selection);
        // expect(selectedRange).toEqual({ row: 1, column: 3, rows: 1, columns: 5 });
    });

    it("should be able to calculate the correct range when the selection is reversed and spans multiple rows", async () => {
        const selection = window.getSelection();
        const range = new Range();
        range.setStart(context.querySelector("#t5").childNodes[0], 1);
        range.setEnd(context.querySelector("#t1").childNodes[0], 3);
        selection.addRange(range);

        // Test framework doesn't support reversed ranges
        expect(range.startContainer).toBe(range.endContainer);

        // Test code for when the framework does support reversed ranges
        // const selectedRange = selectedRangeFromSelection(selection);
        // expect(selectedRange).toEqual({ row: 1, column: 3, rows: 3, columns: 5 });
    });
});
