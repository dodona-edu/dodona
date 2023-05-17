import { stateProperty } from "state/state_system/StateProperty";
import { State } from "state/state_system/State";

class EvaluationState extends State {
    @stateProperty public id: number;
}

export const evaluationState = new EvaluationState();
