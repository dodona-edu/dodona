import * as d3 from "d3";

function timeString(isoDate): string {
    const date = new Date(isoDate);
    const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);

    let interval = seconds / 31536000;
    if (interval >= 1) { // more than a year ago
        return d3.timeFormat(I18n.t("date.formats.yearday_short"))(date);
    }
    interval = seconds / 604800;
    if (interval >= 1) { // this year more than a week ago
        return d3.timeFormat(I18n.t("date.formats.monthday_short"))(date);
    }
    interval = seconds / 86400;
    if (interval >= 1) { // This week more than a day ago
        return d3.timeFormat(I18n.t("date.formats.weekday"))(date);
    }
    // Today
    return d3.timeFormat(I18n.t("time.formats.hour"))(date);
}

function getElemPos(element): {x: number, y: number} {
    let elem = element;
    let xPos = 0;
    let yPos = 0;

    while (elem) {
        xPos += (elem.offsetLeft - elem.scrollLeft + elem.clientLeft);
        yPos += (elem.offsetTop - elem.scrollTop + elem.clientTop);
        elem = elem.offsetParent;
    }

    return { x: xPos, y: yPos };
}


const statusIconMap = {
    "runtime error": "\u{F0241}",
    "correct": "\u{F012C}",
    "wrong": "\u{F0156}",
    "compilation error": "\u{F0820}",
    "time limit exceeded": "\u{F0020}",
    "memory limit exceeded": "\u{F035B}",
    "output_limit_exceeded": "\u{F0BC2}",
    "running": "\u{F06AD}",
    "queued": "\u{F06AD}"
};

const statusColorMap = {
    "correct": "#81c784",
    "runtime error": "#e57373",
    "wrong": "#e57373",
    "compilation error": "#e57373",
    "time limit exceeded": "#e57373",
    "memory limit exceeded": "#e57373",
    "output_limit_exceeded": "#e57373",
    "running": "#FF8F00FF",
    "queued": "#FF8F00FF"
};

const margin = { top: 20, right: 10, bottom: 0, left: 10 };

export type RawData = [
    {
        exercise: string,
        created_at: string,
        status: string,
        summary: string,
        accepted: boolean,
        id: number,
        url: string
    }
];

export async function initTimeline(activityId: number, submissionId: Number): Promise<void> {
    const data: RawData = await fetchData(activityId);
    draw(data, submissionId);
}

async function fetchData(activityId: number): Promise<RawData> {
    const url = `/activities/${activityId}/submissions.json`;
    let raw: RawData = undefined;
    while (!raw || raw["status"] == "not available yet") {
        raw = await d3.json(url);
        if (raw["status"] == "not available yet") {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
    return raw as RawData;
}

function draw(data: RawData, submissionId: number): void {
    const sortedData = data.sort((a, b) => Date.parse(a.created_at) - Date.parse(b.created_at));

    const width = 20*sortedData.length;
    const height = 30;

    // append the svg object to the body of the page
    const svg = d3.select("#timeline")
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    const x = d3.scaleLinear()
        .domain([0, sortedData.length])
        .range([0, width]);
    let prev;
    const timeSteps = [];
    sortedData.forEach((d, i) => {
        const time = timeString(d.created_at);
        if (prev != time) {
            timeSteps.push(i);
            prev = time;
        }
    });

    svg.append("g")
        .attr("transform", "translate(0," + (0) + ")")
        .call(d3.axisTop(x)
            .ticks(timeSteps.length)
            .tickValues(timeSteps.values())
            .tickFormat(d => timeString(sortedData[d].created_at))
        )
        .selectAll("text")
        .attr("transform", "rotate(25)");
    svg.select(".domain").remove();

    // Y axis
    const y = d3.scaleBand()
        .range([0, height])
        .padding(0)
        .domain(sortedData.map(d => d.exercise));

    // create a tooltip
    const Tooltip = d3.select("#timeline")
        .append("div")
        .style("opacity", 0)
        .attr("class", "d3-tooltip")
        .attr("pointer-events", "none")
        .style("opacity", 0)
        .style("z-index", 5);

    // Three function that change the tooltip when user hover / move / leave a cell
    function mouseOver(event, d): void {
        Tooltip
            .transition()
            .duration(200)
            .style("opacity", 0.9);
        function capitalize(string): string {
            return string.charAt(0).toUpperCase() + string.slice(1);
        }

        const translatedStatus = capitalize(I18n.t(`js.status.${d.status.replaceAll(" ", "_")}`));
        const formattedTime = d3.timeFormat(I18n.t("time.formats.submission"))(new Date(d.created_at));
        let message = `<b>${translatedStatus}:</b><br/>`;
        if (d.summary) {
            message += `${d.summary}<br/>`;
        }
        message += formattedTime;

        Tooltip
            .html(message);
    }
    function mouseLeave(event, d): void {
        Tooltip.transition()
            .duration(500)
            .style("opacity", 0);
    }
    const container = document.getElementById("timeline_container");
    function mouseMove(e, d): void {
        // Tooltip
        //     .style("left", `${d3.pointer(e, svg.node())[0] + 15}px`)
        //     .style("top", `${d3.pointer(e, svg.node())[1]}px`);
        const { x, y } = getElemPos(container);

        Tooltip
            .style("left", `${e.pageX - x + container.offsetWidth+50}px`)
            .style("top", `${e.pageY - y + container.offsetHeight+50}px`);
    }


    svg.append("g")
        .selectAll("dot")
        .data(sortedData)
        .enter()
        .append("a")
        .attr("xlink:href", d => "/submissions/" + d.id)
        .append("text")
        .attr("font-family", "Material Design Icons")
        .attr("font-size", d => d.id == submissionId ? "1.5em" : "1em" )
        .attr("text-anchor", "middle")
        .attr("dominant-baseline", "central")
        .attr("x", (d, i) => x(i))
        .attr("y", d => y(d.exercise) + 15)
        .on("mouseover", mouseOver)
        .on("mouseout", mouseLeave)
        .on("mousemove", mouseMove)
        .text(d => statusIconMap[d.status])
        .style("fill", d => statusColorMap[d.status]);
}
