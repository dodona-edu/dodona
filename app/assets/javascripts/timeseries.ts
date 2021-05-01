import * as d3 from "d3";
import { formatTitle } from "graph_helper.js";

let selector = "";
const margin = { top: 20, right: 20, bottom: 20, left: 120 };
let width = 0;
let height = 0;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
];
const bisector = d3.bisector((d: Date) => d.getTime()).left;


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

function thresholdTime(n, min, max): () => Date[] {
    return () => {
        return d3.scaleTime().domain([min, max]).ticks(n);
    };
}

function drawTimeSeries(data, metaData, exMap): void {
    const yDomain: string[] = exMap.map(ex => ex[0]).reverse();
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;
    const yAxisPadding = 20; // padding between y axis (labels) and the actual graph
    const dateFormat = d3.timeFormat("%A %B %d");
    const dateArray = d3.timeDays(metaData["minDate"], metaData["maxDate"]);
    dateArray.unshift(metaData["minDate"]);

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
        .range([innerHeight, margin.top])
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

    const tooltipLine = graph.append("line")
        .attr("y1", margin.top)
        .attr("y2", innerHeight-y.bandwidth()*1.5)
        .attr("pointer-events", "none")
        .attr("stroke", "currentColor")
        .style("width", 40);
    const tooltipLabel = graph.append("text")
        .attr("opacity", 0)
        .text("_") // dummy text to calculate height
        .attr("text-anchor", "start")
        .attr("fill", "currentColor")
        .attr("font-size", "12px");
    tooltipLabel
        .attr("y", margin.top + tooltipLabel.node().getBBox().height);


    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${y(y.domain()[0]) + y.bandwidth()/2})`)
        .call(d3.axisBottom(x).ticks(metaData["dateRange"] / 2, "%a %b-%d"));

    const legend = graph.append("g")
        .attr("transform", `translate(${-margin.left/2}, ${innerHeight-margin.top})`);

    let legendX = 0;
    for (const status of statusOrder) {
        // add legend colors dots
        const group = legend.append("g");

        group
            .append("rect")
            .attr("x", legendX)
            .attr("y", 0)
            .attr("width", 15)
            .attr("height", 15)
            .attr("fill", color(status) as string);

        // add legend text
        group
            .append("text")
            .attr("x", legendX + 20)
            .attr("y", 12)
            .attr("text-anchor", "start")
            .text(status)
            .attr("fill", "currentColor")
            .style("font-size", "12px");

        legendX += group.node().getBBox().width + 20;
    }


    function bisect(mx: number): {"date": Date; "i": number} {
        if (!dateArray) {
            return { "date": new Date(0), "i": 0 };
        }
        const date = x.invert(mx);
        const index = bisector(dateArray, date, 1);
        const a = index > 0 ? dateArray[index-1] : metaData["minDate"];
        const b = index < dateArray.length ? dateArray[index] : metaData["maxDate"];
        if (date.getTime()-a.getTime() > b.getTime()-date.getTime()) {
            return { "date": b, "i": index };
        } else {
            return { "date": a, "i": index-1 };
        }
    }

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
            .on("mouseover", () => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
            })
            .on("mousemove", (e, d) => {
                if (!dateArray) {
                    return;
                }
                const { date, i } = bisect(d3.pointer(e, graph.node())[0]);
                tooltip
                    .html(`${d[i][1]-d[i][0]} x ${d["key"]}`)
                    .style(
                        "left",
                        `${d3.pointer(e, svg.node())[0] - tooltip.node().clientWidth * 1.1}px`
                    )
                    .style(
                        "top",
                        `${d3.pointer(e, svg.node())[1] - tooltip.node().clientHeight * 1.25}px`
                    );
                tooltipLine
                    .attr("opacity", 1)
                    .attr("x1", x(date))
                    .attr("x2", x(date));
                tooltipLabel
                    .attr("opacity", 1)
                    .text(dateFormat(date))
                    .attr(
                        "x",
                        x(date) - tooltipLabel.node().getBBox().width - 5 > 0 ?
                            x(date) - tooltipLabel.node().getBBox().width - 5 :
                            x(date) + 10
                    );
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
                tooltipLabel.attr("opacity", 0);
                tooltipLine.attr("opacity", 0);
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
    container
        .html("") // clean up possible previous visualisations
        .style("height", `${height}px`) // prevent shrinking after switching graphs
        .style("display", "flex")
        .style("align-items", "center")
        .attr("class", "text-center")
        .append("div")
        .text(I18n.t("js.loading"))
        .style("margin", "auto");
    width = (container.node() as Element).getBoundingClientRect().width;
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }

        d3.select(`${selector} *`).remove();


        const data: {string: {date; status; count}[]} = raw.data;
        const metaData = {}; // used to store things needed to create scales
        if (Object.keys(data).length === 0) {
            container
                .style("height", "50px")
                .append("div")
                .text(I18n.t("js.no_data"))
                .style("margin", "auto");
            return;
        }

        height = 150 * Object.keys(raw.data).length;
        container.style("height", `${height}px`);
        insertFakeData(data);
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
