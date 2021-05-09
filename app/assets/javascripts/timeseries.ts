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
    const rectSize = 25;

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

    // Show the X scale
    const x = d3.scaleTime()
        .domain([metaData["minDate"], metaData["maxDate"]])
        .range([0, innerWidth]);


    // Color scale
    const color = d3.scaleSequential()
        .interpolator(d3.interpolateBlues)
        .domain([0, metaData["maxStack"]]);


    const tooltip = d3.select(selector).append("div")
        .attr("class", "d3-tooltip")
        .attr("pointer-events", "none")
        .style("opacity", 0)
        .style("z-index", 5);

    const tooltipLine = graph.append("line")
        .attr("y1", 0)
        .attr("y2", innerHeight)
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
        .attr("y", innerHeight - tooltipLabel.node().getBBox().height);


    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${innerHeight})`)
        .call(d3.axisBottom(x).ticks(metaData["dateRange"] / 2, "%a %b-%d"));

    Object.keys(data).forEach(exId => {
        graph.selectAll("squares")
            .data(data[exId])
            .enter()
            .append("rect")
            .attr("rx", 6)
            .attr("ry", 6)
            .attr("x", d => x(d["date"])-rectSize/2)
            .attr("y", y(exId)-rectSize/2)
            .attr("width", rectSize)
            .attr("height", rectSize)
            .attr("fill", d => color(d["sum"]))
            .on("mouseover", (e, d) => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
                let message = `${I18n.t("js.submissions")} :<br>Total: ${d["sum"]}`;
                statusOrder.forEach(s => { message += `<br>${s}: ${d[s]}` })
                tooltip.html(message);
                tooltipLine
                    .transition()
                    .duration(100)
                    .attr("opacity", 1)
                    .attr("x1", x(d["date"]))
                    .attr("x2", x(d["date"]));
                tooltipLabel
                    .attr("opacity", 1)
                    .text(dateFormat(d["date"]))
                    .attr(
                        "x",
                        x(d["date"]) - tooltipLabel.node().getBBox().width - 5 > 0 ?
                            x(d["date"]) - tooltipLabel.node().getBBox().width - 5 :
                            x(d["date"]) + 10
                    );
            })
            .on("mousemove", (e, _) => {
                const bbox = tooltip.node().getBoundingClientRect();
                tooltip
                    .style(
                        "left",
                        `${d3.pointer(e, svg.node())[0]-bbox.width*1.1}px`
                    )
                    .style(
                        "top",
                        `${d3.pointer(e, svg.node())[1]-bbox.height*1.25}px`
                    );
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            });
    });
}

function initTimeseries(url, containerId, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = (container.node() as HTMLElement).getBoundingClientRect().height - 5;
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

        height = 75 * Object.keys(raw.data).length;
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
                let sum = d3.sum(bin, r => r["count"]);
                metaData["maxStack"] = Math.max(metaData["maxStack"], sum);
                binned[i] = bin.reduce((acc, r) => {
                    acc["date"] = r["date"];
                    acc["sum"] = sum;
                    acc[r["status"]] = r["count"];
                    return acc;
                }, statusOrder.reduce((acc, s) => { // make sure record is initialized with 0 counts
                    acc[s] = 0;
                    return acc;
                }, { "date": newDate, "sum": 0 }));
            });
            data[exId] = binned;
        });

        drawTimeSeries(data, metaData, raw.exercises);
    };
    d3.json(url)
        .then(processor);
}
export { initTimeseries };
