import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

class SubmissionState extends State {
    @stateProperty id: number;
    @stateProperty _code: string;
    @stateProperty codeByLine: string[];

    set code(code: string) {
        this._code = code;
        this.codeByLine = code.split("\n");
    }

    get code(): string {
        return this._code;
    }
}

export const submissionState = new SubmissionState();
