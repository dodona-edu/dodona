import { StateMap } from "state/state_system/StateMap";
import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { fixture, nextFrame } from "@open-wc/testing-helpers";
import { screen } from "@testing-library/dom";
import { stateRecorder } from "state/state_system/StateRecorder";
import { DodonaElement } from "components/meta/dodona_element";

describe( "StateMap", () => {
    const stateMap: StateMap<string, string> = new StateMap<string, string>();
    @customElement("test-component")
    class TestComponent extends DodonaElement {
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

    test("should record read on a values call", async () => {
        jest.spyOn(stateRecorder, "recordRead");
        stateMap.values();
        expect(stateRecorder.recordRead).toHaveBeenCalled();
    });

    test("subscriber should get notified for any change to the map", () => {
        const subscriber = jest.fn();
        stateMap.subscribe(subscriber);
        stateMap.set("foo", "bar");
        expect(subscriber).toHaveBeenCalled();
    });

    test("A subscriber to a specific key should get notified for any change to that key", () => {
        const subscriber = jest.fn();
        stateMap.subscribe(subscriber, "foo");
        stateMap.set("fool", "bar");
        expect(subscriber).not.toHaveBeenCalled();
        stateMap.set("foo", "bar");
        expect(subscriber).toHaveBeenCalled();
    });
});
