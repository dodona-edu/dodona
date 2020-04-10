interface TestSubmissionJSON {
    accepted: boolean;
}

interface GroupSubmissionJSON {
    description: string;
    groups: TestSubmissionJSON[];
}

interface SubmissionResultJSON {
    groups: GroupSubmissionJSON[];
}

interface SubmissionJSON {
    result: string;
}


function createPopoverElement(jsonData: SubmissionJSON): HTMLDivElement {
    const result: SubmissionResultJSON = JSON.parse(jsonData.result);

    const htmlElem = document.createElement("div");
    htmlElem.classList.add("review-popover-div");

    if (result.groups) {
        result.groups.filter(z => z.groups !== undefined).forEach(v => {
            const paragraph: HTMLDivElement = document.createElement("p");
            paragraph.classList.add("review-popover-group-result");

            const totalCount = v.groups.length;
            const totalAcceptedCount = v.groups.filter(p => p.accepted).length;

            const svgElement: SVGSVGElement = document.createElementNS("http://www.w3.org/2000/svg", "svg");
            svgElement.setAttribute("viewBox", "0 0 1 1");
            svgElement.setAttribute("preserveAspectRatio", "none");
            svgElement.setAttribute("data-html", "true");
            svgElement.setAttribute("height", "8");
            svgElement.setAttribute("width", "100%");
            svgElement.classList.add("progress-chart");

            const accepted: SVGLineElement = document.createElementNS("http://www.w3.org/2000/svg", "line");
            accepted.setAttribute("x1", "0");
            accepted.setAttribute("x2", String(totalAcceptedCount / totalCount));
            accepted.setAttribute("y1", "0.5");
            accepted.setAttribute("y2", "0.5");
            accepted.classList.add("correct");

            const wrong: SVGLineElement = document.createElementNS("http://www.w3.org/2000/svg", "line");
            wrong.setAttribute("x1", String(totalAcceptedCount / totalCount));
            wrong.setAttribute("x2", "1");
            wrong.setAttribute("y1", "0.5");
            wrong.setAttribute("y2", "0.5");
            wrong.classList.add("wrong");

            svgElement.append(accepted, wrong);

            const lineHeader: HTMLSpanElement = document.createElement("span");
            lineHeader.style.fontWeight = "bold";
            lineHeader.append(document.createTextNode(I18n.t("js.review.group.header")));

            const span: HTMLSpanElement = document.createElement("span");
            span.append(document.createTextNode(v.description));

            paragraph.append(lineHeader, span, svgElement);
            htmlElem.append(paragraph);
        });
    } else {
        const noContent = document.createElement("span");
        noContent.append(document.createTextNode(I18n.t("js.review.group.noContent")));

        htmlElem.append(noContent);
    }

    return htmlElem;
}

function createErrorPopover(): HTMLDivElement {
    const div: HTMLDivElement = document.createElement("div");
    const errorText: Text = document.createTextNode(I18n.t("js.review.information.error"));
    div.append(errorText);
    return div;
}

function showContent(element, content): void {
    element.popover({
        container: "body",
        html: true,
        content: content
    });
    element.popover("show");
}

function removePopover(element): void {
    element.popover("hide");
}

function initReviewTablePopover(): void {
    document.querySelectorAll(".review-popover").forEach(ele => {
        ele.addEventListener("mouseenter", async () => {
            const reviewCell: HTMLDivElement = ele.closest(".review-cell") as HTMLDivElement;
            const submissionId = reviewCell.dataset.submissionid;
            const url = `/submissions/${submissionId}.json`;
            const element = $(ele) as any;

            const response = await fetch(url);
            if (response.ok) {
                response.json().then(data => showContent(element, createPopoverElement(data)));
            } else {
                showContent(element, createErrorPopover());
            }
        });

        ele.addEventListener("mouseleave", () => {
            removePopover($(ele) as any);
        });
    });
}

export { initReviewTablePopover };
