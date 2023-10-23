import { stateProperty } from "state/state_system/StateProperty";
import { State } from "state/state_system/State";

class ExerciseState extends State {
    @stateProperty accessor id: number;
}

export const exerciseState = new ExerciseState();

