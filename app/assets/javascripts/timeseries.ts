import * as d3 from "d3";
import { bin } from "d3";
import { formatTitle } from "graph_helper.js";

let selector = "";
const margin = { top: 20, right: 10, bottom: 20, left: 120 };
let width = 0;
let height = 0;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
];


function insertFakeData(data): void {
    const end = new Date((data[Object.keys(data)[0]][0].date));
    const start = new Date(end);
    start.setDate(start.getDate() - 14);
    for (const exName of Object.keys(data)) {
        data[exName] = [];
        for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1 + Math.random()*2)) {
            for (let i=0; i < statusOrder.length; i++) {
                if (Math.random() > 0.5) {
                    data[exName].push({
                        "date": new Date(d),
                        "status": statusOrder[i],
                        "count": Math.round(Math.random()*20)
                    });
                }
            }
        }
    }
}

function thresholdTime(n, min, max): Function {
    return () => {
        return d3.scaleTime().domain([min, max]).ticks(n);
    };
}

function drawTimeSeries(data, metaData, exMap): void {
    const yDomain: string[] = Array.from(new Set(Object.keys(data)));
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const yAxisPadding = 20; // padding between y axis (labels) and the actual graph

    const svg = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height);

    // position graph
    const graph = svg
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale for exercises (Big Y scale)
    const y = d3.scaleBand()
        .range([innerHeight, 0])
        .domain(yDomain)
        .padding(.5);

    const yAxis = graph.append("g")
        .call(d3.axisLeft(y).tickSize(0))
        .attr("transform", `translate(-${yAxisPadding}, -${y.bandwidth()/2})`);
    yAxis
        .select(".domain").remove();
    yAxis
        .selectAll(".tick text")
        .call(formatTitle, margin.left-yAxisPadding, exMap);

    // common y scale per exercise
    const interY = d3.scaleLinear()
        .domain([0, metaData["maxStack"]])
        .range([y.bandwidth(), 0]);


    // Show the X scale
    const x = d3.scaleTime()
        .domain([metaData["minDate"], metaData["maxDate"]])
        .range([0, innerWidth]);


    // Color scale
    const color = d3.scaleOrdinal()
        .range(d3.schemeDark2)
        .domain(statusOrder);


    const tooltip = d3.select(selector).append("div")
        .attr("class", "d3-tooltip")
        .attr("pointer-events", "none")
        .style("opacity", 0)
        .style("z-index", 5);


    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${y(y.domain()[0]) + y.bandwidth()/2})`)
        .call(d3.axisBottom(x).ticks(metaData["dateRange"] / 2, "%a %b-%d"));

    // Add X axis label:
    graph.append("text")
        .attr("text-anchor", "end")
        .attr("x", innerWidth)
        .attr("y", innerHeight + 30)
        .text("Percentage of submissions statuses")
        .attr("fill", "currentColor")
        .style("font-size", "11px");

    // add areas
    for (const exId of Object.keys(data)) {
        const exGroup = graph.append("g")
            .attr("transform", `translate(0, ${y(exId) + y.bandwidth() / 2})`);
        const stack = data[exId];
        exGroup.selectAll("areas")
            .data(stack)
            .enter()
            .append("path")
            .attr("class", d => d["key"])
            .style("stroke", "none")
            .style("fill", d => color(d["key"]))
            .attr("d", d3.area()
                .x(r => x(r["data"]["date"]))
                .y0(r => interY(r[0]) - y.bandwidth())
                .y1(r => interY(r[1]) - y.bandwidth())
                .curve(d3.curveMonotoneX)
            )
            .on("mouseover", (_, d) => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
                tooltip.html(`Status: ${d["key"]}`);
            })
            .on("mousemove", (e, _) => {
                tooltip
                    .style(
                        "left",
                        `${d3.pointer(e, svg.node())[0] - tooltip.node().clientWidth * 1.1}px`
                    )
                    .style(
                        "top",
                        `${d3.pointer(e, svg.node())[1] - tooltip.node().clientHeight * 1.25}px`
                    );
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            });

        // y axis
        graph.append("g")
            .attr("transform", `translate(0, ${y(exId) - y.bandwidth()/2})`)
            .call(d3.axisLeft(interY)
                .tickValues([0, metaData["maxStack"]]));
    }
}

function initTimeseries(url, containerId, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = container.node().clientHeight - 5;
    }
    container.html(""); // clean up possible previous visualisations
    //
    width = (container.node() as Element).getBoundingClientRect().width;
    container.attr("class", "text-center").append("span")
        .text(I18n.t("js.loading"));
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }

        d3.select(`${selector} *`).remove();

        height = 150 * Object.keys(raw.data).length;
        container.node().style.height = height;

        const data: {string: {date; status; count}[]} = raw.data;
        insertFakeData(data);
        const metaData = {}; // used to store things needed to create scales
        if (Object.keys(data).length === 0) {
            container.attr("class", "text-center").append("div").style("height", `${height+5}px`)
                .text(I18n.t("js.no_data"));
            return;
        }
        // pick date of first datapoint (to avoid null checks later on)
        metaData["minDate"] = d3.min(Object.values(data),
            records => d3.min(records, d =>new Date(d.date)));
        metaData["maxDate"] = d3.max(Object.values(data),
            records => d3.max(records, d =>new Date(d.date)));
        metaData["maxStack"] = 0;
        metaData["dateRange"] = Math.round(
            (metaData["maxDate"].getTime() - metaData["minDate"].getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days
        // let minDate = Date.parse(data[Object.keys(data)[0]][0].date);
        // let maxDate = Date.parse(data[Object.keys(data)[0]][0].date);
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            let records = entry[1];
            // parse datestring to date
            records.forEach(r => {
                r.date = new Date(r.date);
            });

            const binned = d3.bin()
                .value(d => d.date.getTime())
                .thresholds(
                    thresholdTime(metaData["dateRange"]+1, metaData["minDate"], metaData["maxDate"])
                ).domain([metaData["minDate"], metaData["maxDate"]])(records);
            console.log(binned);

            records = undefined; // records no longer needed

            binned.forEach((bin, i) => {
                const newDate = new Date(metaData["minDate"]);
                newDate.setDate(newDate.getDate() + i);
                metaData["maxStack"] = Math.max(metaData["maxStack"], d3.sum(bin, r => r["count"]));
                binned[i] = bin.reduce((acc, r) => {
                    acc["date"] = r["date"];
                    acc[r["status"]] = r["count"];
                    return acc;
                }, statusOrder.reduce((acc, s) => { // make sure record is initialized with 0 counts
                    acc[s] = 0;
                    return acc;
                }, { "date": newDate }));
            });
            const stack = d3.stack().keys(statusOrder)(binned);
            data[exId] = stack;
        });

        drawTimeSeries(data, metaData, raw.exercises);
    };
    d3.json(url)
        .then(processor);
}
export { initTimeseries };
