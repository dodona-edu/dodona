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

const statusIconMap = {
    "runtime error": "\u{F0241}",
    "correct": "\u{F012C}",
    "wrong": "\u{F0156}",
    "compilation error": "\u{F0820}",
    "time limit exceeded": "\u{F0020}"
};

const statusColorMap = {
    "correct": "#81c784",
    "runtime error": "#e57373",
    "wrong": "#e57373",
    "compilation error": "#e57373",
    "time limit exceeded": "#e57373"
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

export async function initTimeline(activityId: number): Promise<void> {
    const data: RawData = await fetchData(activityId);
    draw(data);
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

function draw(data: RawData): void {
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
    console.log(timeSteps.map(d => timeString(sortedData[d].created_at)));

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


    svg.append("g")
        .selectAll("dot")
        .data(sortedData)
        .enter()
        .append("text")
        .attr("font-family", "Material Design Icons")
        .attr("text-anchor", "middle")
        .attr("dominant-baseline", "central")
        .attr("x", (d, i) => x(i))
        .attr("y", d => y(d.exercise) + 15)
        .text(d => statusIconMap[d.status])
        .style("fill", d => statusColorMap[d.status]);
}
