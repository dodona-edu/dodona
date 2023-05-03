import { fixture } from "@open-wc/testing-helpers";
import { getOffset } from "components/annotations/select";

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


