import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

class SubmissionState extends State {
    @stateProperty id;
    @stateProperty code;
}

export const submissionState = new SubmissionState();
