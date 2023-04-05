import { State } from "state/state_system/State";
import { StateController } from "state/state_system/StateController";
import { html, LitElement, TemplateResult } from "lit";
import { stateProperty } from "state/state_system/StateProperty";
import { customElement } from "lit/decorators.js";
import { fixture } from "@open-wc/testing-helpers";
import { stateRecorder } from "state/state_system/StateRecorder";
import spyOn = jest.spyOn;

class ExampleState extends State {
    @stateProperty foo = "bar";
    @stateProperty fool = "bars";
}
const state = new ExampleState();

@customElement("example-element")
class ExampleElement extends LitElement {
    controller = new StateController(this);
}

let el: ExampleElement;
beforeEach(async () => {
    el = await fixture(`<example-element></example-element>`);
});

test("StateController trigger host to update ech time a stateProperty it read changes", () => {
    el.controller.hostUpdate();
    state.foo;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(1);
    expect(el.controller.unsubscribeList[0]).toBeInstanceOf(Function);
});

test("StateController should unsubscribe from all stateProperties when disconnected", () => {
    el.controller.hostUpdate();
    state.foo;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(1);
    el.controller.hostDisconnected();
    expect(el.controller.unsubscribeList.length).toBe(0);
});

test("StateController should request update when a stateProperty it read changes", () => {
    el.controller.hostUpdate();
    state.foo;
    el.controller.hostUpdated();
    jest.spyOn(el, "requestUpdate");
    state.foo = "baz";
    expect(el.requestUpdate).toHaveBeenCalled();
});

test("StateController should not request an update when a property it did not read changes", () => {
    el.controller.hostUpdate();
    state.foo;
    el.controller.hostUpdated();
    jest.spyOn(el, "requestUpdate");
    state.fool = "baz";
    expect(el.requestUpdate).not.toHaveBeenCalled();
});

test("A statecontroller should listen to multiple states", () => {
    const state2 = new ExampleState();
    el.controller.hostUpdate();
    state.foo;
    state2.foo;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(2);
});

test("A statecontroller should update its subcribe list each update cycle", () => {
    const state2 = new ExampleState();
    el.controller.hostUpdate();
    state.foo;
    state2.foo;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(2);
    el.controller.hostUpdate();
    state.foo;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(1);
});

test("A statecontroller creates a single subcriber for each state", () => {
    el.controller.hostUpdate();
    state.foo;
    state.fool;
    el.controller.hostUpdated();
    expect(el.controller.unsubscribeList.length).toBe(1);
    spyOn(el, "requestUpdate");
    state.foo = "baz";
    expect(el.requestUpdate).toHaveBeenCalled();
    state.fool = "baz";
    expect(el.requestUpdate).toHaveBeenCalledTimes(2);
});
