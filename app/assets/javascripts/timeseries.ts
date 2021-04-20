import * as d3 from "d3";

let selector = "";
const margin = { top: 20, right: 10, bottom: 20, left: 100 };
let width = 0;
let height = 0;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
];
const commonAxis = false;
const rSum = false; // use running sum?

function drawTimeSeries(data, metaData, exMap): void {
    const yDomain: string[] = Array.from(new Set(Object.keys(data)));
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;

    // position graph
    const graph = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale for exercises (Big Y scale)
    const y = d3.scaleBand()
        .range([innerHeight, 0])
        .domain(yDomain)
        .paddingInner(.2)
        .paddingOuter(.4);
    graph.append("g")
        .attr("transform", `translate(0, ${-y.bandwidth() - 10})`)
        .call(d3.axisLeft(y).tickSize(0).tickFormat(id => exMap[id]))
        .select(".domain").remove();

    // common y scale per exercise
    const interY = d3.scaleLinear()
        .domain([0, rSum ? metaData.maxCumulative : metaData.maxStack])
        .range([y.bandwidth(), 0]);

    // y scales unique to each exercise (just in case we still want to offer the option)
    const interYs = Object.entries(metaData["per_ex"]).reduce((acc, v) => {
        acc[v[0]] =
            d3.scaleLinear()
                .domain([0, rSum ? v[1].maxCumulative : v[1].maxStack])
                .range([y.bandwidth(), 0]);
        return acc;
    }, {}
    );


    // Show the X scale
    const x = d3.scaleTime()
        .domain([metaData["minDate"], metaData["maxDate"]])
        .range([0, innerWidth]);


    // Color scale
    const color = d3.scaleOrdinal()
        .range(["green", d3.interpolateReds])
        .domain(statusOrder);


    const tooltip = d3.select(selector).append("div")
        .attr("class", "d3-tooltip")
        .attr("pointer-events", "none")
        .style("opacity", 0);


    // add x-axis
    graph.append("g")
        .attr("transform", `translate(0, ${y(y.domain()[0]) + y.bandwidth()/2})`)
        .call(d3.axisBottom(x).ticks(10, "%a %b-%d"));

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
        const records = data[exId];
        exGroup.selectAll("areas")
            .data(records)
            .enter()
            .append("path")
            .attr("class", d => d[0])
            .style("stroke", "none")
            .style("fill", d => color(d[0]))
            .attr("d", d => {
                return d3.area()
                    .x(r => x(r.date))
                    .y0(r => commonAxis ?
                        interY((rSum ? r.cSumStart : r.stack_sum - r.count)) - y.bandwidth() :
                        interYs[exId]((rSum ? r.cSumStart : r.stack_sum - r.count)) - y.bandwidth())
                    .y1(r => commonAxis ?
                        interY(rSum ? r.cSumEnd : r.stack_sum) - y.bandwidth() :
                        interYs[exId](rSum ? r.cSumEnd : r.stack_sum) - y.bandwidth())(d[1]);
            })
            .on("mouseover", (_, d) => {
                tooltip.transition()
                    .duration(200)
                    .style("opacity", .9);
                tooltip.html(`Status: ${d[0]}`);
            })
            .on("mousemove", (e, _) => {
                tooltip
                    // using the node itself results in negative coordinates for some reason
                    .style("left", `${d3.pointer(e, exGroup)[0]-tooltip.node().clientWidth-10}px`)
                    .style("top", `${d3.pointer(e, exGroup)[1] - 40}px`);
            })
            .on("mouseout", () => {
                tooltip.transition()
                    .duration(500)
                    .style("opacity", 0);
            });

        // y axis
        graph.append("g")
            .attr("transform", `translate(0, ${y(exId) - y.bandwidth()/2})`)
            .call(d3.axisLeft(commonAxis ? interY : interYs[exId]).ticks(5));
    }
}

function initTimeseries(url, containerId, containerHeight: number): void {
    height = containerHeight;
    selector = containerId;
    const container = d3.select(selector);

    if (!height) {
        height = container.node().clientHeight;
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

        const data: {string: {date; status; count}[]} = raw.data;
        const metaData = {}; // used to store things needed to create scales
        if (Object.keys(data).length === 0) {
            container.attr("class", "text-center").append("span")
                .text("There is not enough data to create a graph");
            return;
        }
        // pick date of first datapoint (to avoid null checks later on)
        metaData["minDate"] = Date.parse(data[Object.keys(data)[0]][0].date);
        metaData["maxDate"] = Date.parse(data[Object.keys(data)[0]][0].date);
        metaData["maxStack"] = 0;
        metaData["maxCumulative"] = 0;
        metaData["per_ex"] = {};
        // let minDate = Date.parse(data[Object.keys(data)[0]][0].date);
        // let maxDate = Date.parse(data[Object.keys(data)[0]][0].date);
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            const records = entry[1];
            metaData["per_ex"][exId] = {};
            // parse datestring to date
            records.forEach(r => {
                r.date = Date.parse(r.date);
            });

            // sort records by date
            records.sort((a, b) => {
                if (a.date === b.date) {
                    return statusOrder.indexOf(a.status) - statusOrder.indexOf(b.status);
                }
                return a.date - b.date;
            });

            let prevDate = records[0].date;
            let stackSum = 0; // cumulative sum (per ex) per day
            let maxStack = 0; // Used to calculate extent for y-axis
            const cSum = {}; // cSum per ex per status
            statusOrder.forEach(s => cSum[s] = 0);
            // Construct a new data array where every status is represented
            const newRecords = [];
            // Used to track if for every day that has datepoints, every status is represented
            let statusVisited = 0;
            records.forEach(d => {
                if (prevDate !== d.date) {
                    // insert empty datapoints to prevent weird jumps in the graph
                    // if not all statusses have been visted (for this date),
                    // append the unvisited ones
                    while (statusVisited !== statusOrder.length) {
                        cSum[statusOrder[statusVisited]] += stackSum;
                        newRecords.push({
                            "date": prevDate,
                            "status": statusOrder[statusVisited],
                            "count": 0,
                            "stack_sum": stackSum,
                            "cSumEnd": cSum[statusOrder[statusVisited]],
                            "cSumStart": !statusVisited ? 0 : cSum[statusOrder[statusVisited-1]]
                        });
                        statusVisited += 1;
                    }
                    prevDate = d.date;
                    maxStack = Math.max(maxStack, stackSum);
                    stackSum = 0;
                    statusVisited = 0;
                }
                // insert empty datapoints to prevent weird jumps in the graph
                // if one or more statusses were skipped, insert them
                while (statusOrder[statusVisited] !== d.status) {
                    cSum[statusOrder[statusVisited]] += stackSum;
                    newRecords.push({
                        "date": prevDate,
                        "status": statusOrder[statusVisited],
                        "count": 0,
                        "stack_sum": stackSum,
                        "cSumEnd": cSum[statusOrder[statusVisited]],
                        "cSumStart": !statusVisited ? 0 : cSum[statusOrder[statusVisited-1]]
                    });
                    statusVisited += 1;
                }
                metaData["minDate"] = Math.min(metaData["minDate"], d.date);
                metaData["maxDate"] = Math.max(metaData["maxDate"], d.date);
                stackSum += d.count;
                cSum[d.status] += stackSum;
                newRecords.push({
                    ...d,
                    "stack_sum": stackSum,
                    "cSumEnd": cSum[d.status],
                    "cSumStart": !statusVisited ? 0 : cSum[statusOrder[statusVisited-1]]
                });
                statusVisited += 1;
            });
            metaData["maxStack"] = Math.max(maxStack, metaData["maxStack"]);
            if (newRecords.length) {
                metaData["maxCumulative"] = Math.max(
                    newRecords[newRecords.length - 1].cSumEnd,
                    metaData["maxCumulative"]);
            }
            metaData["per_ex"][exId]["maxStack"] = maxStack;
            metaData["per_ex"][exId]["maxCumulative"] = newRecords.length ?
                newRecords[newRecords.length - 1].cSumEnd : 0;
            data[exId] = d3.groups(newRecords, d => d.status);
        });

        drawTimeSeries(data, metaData, raw.exercises);
    };
    d3.json(url)
        .then(processor);
}
export { initTimeseries };
