import { State } from "state/state_system/State";
import { StateController } from "state/state_system/StateController";
import { LitElement } from "lit";
import { stateProperty } from "state/state_system/StateProperty";
import { customElement } from "lit/decorators.js";
import { fixture } from "@open-wc/testing-helpers";
import spyOn = jest.spyOn;

class ExampleState extends State {
    @stateProperty accessor foo = "bar";
    @stateProperty accessor fool = "bars";
}
const state = new ExampleState();

@customElement("example-element")
class ExampleElement extends LitElement {}

let el: ExampleElement;
let controller: StateController;
beforeEach(async () => {
    el = await fixture(`<example-element></example-element>`);
    controller = new StateController(el);
});

test("StateController trigger host to update ech time a stateProperty it read changes", () => {
    controller.hostUpdate();
    state.foo;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(1);
    expect(controller.unsubscribeList[0]).toBeInstanceOf(Function);
});

test("StateController should unsubscribe from all stateProperties when disconnected", () => {
    controller.hostUpdate();
    state.foo;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(1);
    controller.hostDisconnected();
    expect(controller.unsubscribeList.length).toBe(0);
});

test("StateController should request update when a stateProperty it read changes", () => {
    controller.hostUpdate();
    state.foo;
    controller.hostUpdated();
    jest.spyOn(el, "requestUpdate");
    state.foo = "baz";
    expect(el.requestUpdate).toHaveBeenCalled();
});

test("StateController should not request an update when a property it did not read changes", () => {
    controller.hostUpdate();
    state.foo;
    controller.hostUpdated();
    jest.spyOn(el, "requestUpdate");
    state.fool = "baz";
    expect(el.requestUpdate).not.toHaveBeenCalled();
});

test("A statecontroller should listen to multiple states", () => {
    const state2 = new ExampleState();
    controller.hostUpdate();
    state.foo;
    state2.foo;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(2);
});

test("A statecontroller should update its subcribe list each update cycle", () => {
    const state2 = new ExampleState();
    controller.hostUpdate();
    state.foo;
    state2.foo;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(2);
    controller.hostUpdate();
    state.foo;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(1);
});

test("A statecontroller creates a single subcriber for each state", () => {
    controller.hostUpdate();
    state.foo;
    state.fool;
    controller.hostUpdated();
    expect(controller.unsubscribeList.length).toBe(1);
    spyOn(el, "requestUpdate");
    state.foo = "baz";
    expect(el.requestUpdate).toHaveBeenCalled();
    state.fool = "baz";
    expect(el.requestUpdate).toHaveBeenCalledTimes(2);
});
