/**
 * https://github.com/testing-library/dom-testing-library/issues/410#issuecomment-1060917305
 * Getting the deepest element that contain string / match regex even when it split between multiple elements
 *
 * @example
 * For:
 * <div>
 *   <span>Hello</span><span> World</span>
 * </div>
 *
 * screen.getByText('Hello World') // ❌ Fail
 * screen.getByText(textContentMatcher('Hello World')) // ✅ pass
 */
export function textContentMatcher(textMatch: string | RegExp): (_content: string, node: Element) => boolean {
    // https://stackoverflow.com/questions/42920985/textcontent-without-spaces-from-formatting-text
    const cleanupExcessWhitespace: (string) => string = (text: string) => text.replace(/[\n\r]+|[\s]{2,}/g, " ").trim();
    const matchText = typeof textMatch === "string" ? text => text === textMatch : text => textMatch.test(text);
    const hasText: (node: Element) => boolean = node => matchText(cleanupExcessWhitespace(node.textContent));

    return (_content: string, node: Element) => {
        if (!hasText(node)) {
            return false;
        }

        return Array.from(node?.children || []).every(child => !hasText(child));
    };
}
