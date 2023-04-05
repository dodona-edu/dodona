import { stateRecorder } from "state/state_system/StateRecorder";
import { State } from "state/state_system/State";

test("stateRecorder should record all record read events between start and finish", () => {
    const state = new State();
    stateRecorder.start();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    const log = stateRecorder.finish();
    expect(log.get(state)).toEqual(["foo", "bar"]);
});

test("stateRecorder should be able to record from multiple states", () => {
    const state1 = new State();
    const state2 = new State();
    stateRecorder.start();
    stateRecorder.recordRead(state1, "foo");
    stateRecorder.recordRead(state2, "bar");
    stateRecorder.recordRead(state2, "foo");
    const log = stateRecorder.finish();
    expect(log.get(state1)).toEqual(["foo"]);
    expect(log.get(state2)).toEqual(["bar", "foo"]);
});

test("stateRecorder should ignore record read events if not started", () => {
    const state = new State();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    const log = stateRecorder.finish();
    expect(log).toBeNull();
});

test("stateRecorder should ignore record read events if already finished", () => {
    const state = new State();
    stateRecorder.start();
    stateRecorder.finish();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    const log = stateRecorder.finish();
    expect(log).toBeNull();
});

