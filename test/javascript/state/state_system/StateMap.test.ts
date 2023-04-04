import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { StateMap } from "state/state_system/StateMap";
import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { screen } from "@testing-library/dom";

describe( "StateMap", () => {
    const stateMap: StateMap<string, string> = new StateMap<string, string>();
    @customElement("test-component")
    class TestComponent extends ShadowlessLitElement {
        protected render(): TemplateResult {
            return html`<span>${stateMap.get("foo")}</span>`;
        }
    }
    beforeEach(async () => {
        stateMap.clear();
        await fixture(`<test-component></test-component>`);
    });

    test("stateMap should update users if used key gets updated", async () => {
        expect(screen.queryByText("bar")).toBeNull();
        stateMap.set("foo", "bar");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
    });

    test("stateMap should update users if used key gets deleted", async () => {
        stateMap.set("foo", "bar");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        stateMap.delete("foo");
        await nextFrame();
        expect(screen.queryByText("bar")).toBeNull();
    });

    test("stateMap should update users if used key gets cleared", async () => {
        stateMap.set("foo", "bar");
        await nextFrame();
        expect(screen.queryByText("bar")).not.toBeNull();
        stateMap.clear();
        await nextFrame();
        expect(screen.queryByText("bar")).toBeNull();
    });
});
