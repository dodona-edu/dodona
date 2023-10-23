import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

class SubmissionState extends State {
    @stateProperty accessor id: number;
    @stateProperty accessor _code: string;
    @stateProperty accessor codeByLine: string[];

    set code(code: string) {
        this._code = code;
        this.codeByLine = code.split("\n");
    }

    get code(): string {
        return this._code;
    }
}

export const submissionState = new SubmissionState();
