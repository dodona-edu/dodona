import * as d3 from "d3";

export const testData = [
    { name: "exercise c", time: 1355752800000, status: "error" },
    { name: "exercise c", time: 1355752900000, status: "wrong" },
    { name: "exercise c", time: 1355753150000, status: "wrong" },
    { name: "exercise c", time: 1355753280000, status: "wrong" },
    { name: "exercise c", time: 1355753530000, status: "wrong" },
    { name: "exercise c", time: 1355753800000, status: "error" },
    { name: "exercise c", time: 1355754000000, status: "wrong" },
    { name: "exercise c", time: 1355755000000, status: "wrong" },
    { name: "exercise c", time: 1355755900000, status: "timeout" },
    { name: "exercise c", time: 1355757900000, status: "wrong" },
    { name: "exercise c", time: 1355759910000, status: "error" },
    { name: "exercise c", time: 1355761910000, status: "timeout" },
    { name: "exercise c", time: 1355859910000, status: "error" },
    { name: "exercise c", time: 1355859910000, status: "error" },
    { name: "exercise c", time: 1355859910000, status: "error" },
    { name: "exercise c", time: 1355859910000, status: "error" },
    { name: "exercise c", time: 1355860910000, status: "wrong" },
    { name: "exercise c", time: 1355860910000, status: "wrong" },
    { name: "exercise c", time: 1355860910000, status: "error" },
    { name: "exercise c", time: 1355860910000, status: "wrong" },
    { name: "exercise c", time: 1355864910000, status: "wrong" },
    { name: "exercise c", time: 1355864910000, status: "correct" },
];

const statusIconMap = {
    error: "\u{F0241}",
    correct: "\u{F012C}",
    wrong: "\u{F0156}",
    timeout: "\u{F0020}",
};

const statusColorMap = {
    correct: "#81c784",
    error: "#e57373",
    wrong: "#e57373",
    timeout: "#e57373",
};

const margin = { top: 20, right: 0, bottom: 0, left: 10 };

export type RawData = [
    {
        name: string,
        time: number,
        status: string
    }
];

export function draw(data: RawData): void {
    const width = 20*data.length;
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
        .domain([0, data.length])
        .range([0, width]);
    let prev;
    const timeSteps = [];
    data.forEach((d, i) => {
        const time = new Date(d.time).getHours();
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
            .tickFormat(d => new Date(data[d].time).getHours() + "u")
        );
    svg.select(".domain").remove();

    // Y axis
    const y = d3.scaleBand()
        .range([0, height])
        .padding(0)
        .domain(data.map(d => d.name));


    svg.append("g")
        .selectAll("dot")
        .data(data)
        .enter()
        .append("text")
        .attr("font-family", "Material Design Icons")
        .attr("text-anchor", "middle")
        .attr("dominant-baseline", "central")
        .attr("x", (d, i) => x(i))
        .attr("y", d => y(d.name) + 15)
        .text(d => statusIconMap[d.status])
        .style("fill", d => statusColorMap[d.status]);
    console.log(data);
}
