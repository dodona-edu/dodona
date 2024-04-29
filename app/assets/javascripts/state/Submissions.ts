import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { userState } from "state/Users";
import { courseState } from "state/Courses";
import { exerciseState } from "state/Exercises";

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

    get canResubmitSubmission(): boolean {
        return userState.hasPermission("submission.submit_as_own");
    }

    get resubmitPath(): string {
        return `/courses/${courseState.id}/exercises/${exerciseState.id}/?edit_submission=${submissionState.id}`;
    }
}

export const submissionState = new SubmissionState();
