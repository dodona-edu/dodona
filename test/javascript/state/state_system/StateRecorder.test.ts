import { stateRecorder } from "state/state_system/StateRecorder";
import { State } from "state/state_system/State";

test("stateRecorder should record all record read events between start and finish", () => {
    const state = new State();
    stateRecorder.start();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    const log = stateRecorder.finish();
    expect(log.get(state).has("foo")).toBe(true);
    expect(log.get(state).has("bar")).toBe(true);
});

test("stateRecorder should be able to record from multiple states", () => {
    const state1 = new State();
    const state2 = new State();
    stateRecorder.start();
    stateRecorder.recordRead(state1, "foo");
    stateRecorder.recordRead(state2, "bar");
    stateRecorder.recordRead(state2, "foo");
    const log = stateRecorder.finish();
    expect(log.get(state1).has("foo")).toBe(true);
    expect(log.get(state1).has("bar")).toBe(false);
    expect(log.get(state2).has("bar")).toBe(true);
    expect(log.get(state2).has("foo")).toBe(true);
});

test("stateRecorder should not ignore reads before start", () => {
    const state = new State();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    expect(() => stateRecorder.finish()).toThrow();
    stateRecorder.start();
    const log = stateRecorder.finish();
    expect(log.size).toBe(0);
});

test("stateRecorder should ignore record read events if already finished", () => {
    const state = new State();
    stateRecorder.start();
    let log = stateRecorder.finish();
    stateRecorder.recordRead(state, "foo");
    stateRecorder.recordRead(state, "bar");
    stateRecorder.recordRead(state, "foo");
    expect(log.size).toBe(0);
    expect(() => stateRecorder.finish()).toThrow();
    stateRecorder.start();
    log = stateRecorder.finish();
    expect(log.size).toBe(0);
});

