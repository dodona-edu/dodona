import MarkJS from "mark.js/src/lib/mark.js";

export class Mark extends MarkJS {
    constructor(context: HTMLElement) {
        super(context);
    }

    /**
     * Monkey patched version of https://github.com/julmot/mark.js/blob/7f7e9820514e2268918c2259b58aec3bd5f437f6/src/lib/mark.js#L268
     * To allow matching whitespace only ranges
     * Should remove when https://github.com/julmot/mark.js/issues/491 is fixed
     */
    checkWhitespaceRanges(range, originalLength, string): { start: number; end: number; valid: boolean } {
        let end;
        let valid = true;
        // the max value changes after the DOM is manipulated
        const max = string.length;
        // adjust offset to account for wrapped text node
        const offset = originalLength - max;
        let start = parseInt(range.start, 10) - offset;
        // make sure to stop at max
        start = start > max ? max : start;
        end = start + parseInt(range.length, 10);
        if (end > max) {
            end = max;
            super.log(`End range automatically set to the max value of ${max}`);
        }
        if (start < 0 || end - start < 0 || start > max || end > max) {
            valid = false;
            super.log(`Invalid range: ${JSON.stringify(range)}`);
            super.opt.noMatch(range);
        }
        return {
            start: start,
            end: end,
            valid: valid
        };
    }
}
