import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { stateRecorder } from "state/state_system/StateRecorder";

class ExampleState extends State {
    @stateProperty foo = "bar";
    @stateProperty fool = "bars";
}

test("a subscriber to a state should get notified anytime a stateProperty changes", () => {
    const state = new ExampleState();
    const subscriber = jest.fn();
    state.subscribe(subscriber);
    state.foo = "baz";
    expect(subscriber).toHaveBeenCalled();
});

test("a subscriber to a stateProperty should get notified anytime that stateProperty changes", () => {
    const state = new ExampleState();
    const subscriber = jest.fn();
    state.subscribe(subscriber, "foo");
    state.fool = "baz";
    expect(subscriber).not.toHaveBeenCalled();
    state.foo = "baz";
    expect(subscriber).toHaveBeenCalled();
});

test("reading a stateProperty should record a read", () => {
    const state = new ExampleState();
    jest.spyOn(stateRecorder, "recordRead");
    state.foo;
    expect(stateRecorder.recordRead).toHaveBeenCalled();
});
