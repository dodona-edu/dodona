import { initCorrectSubmissionToNextLink } from "../../app/assets/javascripts/submission";

beforeAll(() => {
    document.body.innerHTML = `
        <a href="http://test/next_link" data-title="next_tooltip" id="next-exercise-link">
            <i class="mdi mdi-chevron-right"></i>
        </a>
        <div id='submission-motivational-message'></div>
    `;
});

describe("Correct submission link to next test", () => {
    test("Incorrect status should do nothing", () => {
        initCorrectSubmissionToNextLink("wrong");
        const message = document.getElementById("submission-motivational-message");
        expect(message.innerHTML).toMatch("");
    });

    test("Link should be fetched from page", () => {
        initCorrectSubmissionToNextLink("correct");
        const message = document.getElementById("submission-motivational-message");
        expect(message.firstElementChild.children).toHaveLength(2);
        const link = message.firstElementChild.lastElementChild;
        expect(link.getAttribute("href")).toBe("http://test/next_link");
    });
});
