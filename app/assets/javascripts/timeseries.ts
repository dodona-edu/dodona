import * as d3 from "d3";

const selector = "#timeseries-container";
const margin = { top: 0, right: 10, bottom: 20, left: 70 };
const width = 1500 - margin.left - margin.right;
const height = 1000 - margin.top - margin.bottom;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    "queued", "running"
];

function drawTimeSeries(data, minDate, maxDate, metaData): void {
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
        .range([height-10, 0])
        .domain(Object.keys(data))
        .padding(.4);
    graph.append("g")
        .attr("transform", `translate(0, ${-y.bandwidth() - 10})`)
        .call(d3.axisLeft(y).tickSize(0))
        .select(".domain").remove();

    // y scales per exercise
    const yCounts = Object.entries(metaData).reduce((acc, v: [string, {maxStack}]) => {
        acc[v[0]] = d3.scaleLinear()
            .domain([0, v[1].maxStack])
            .range([y.bandwidth(), 0]);
        return acc;
    }, {}
    );

    // y scale for legend elements
    const legendY = d3.scaleBand()
        .range([
            y(y.domain()[y.domain().length - 1]),
            height/3 + y(y.domain()[y.domain().length - 1])
        ])
        .domain(statusOrder);


    // Show the X scale
    const x = d3.scaleTime()
        .domain([minDate, maxDate])
        .range([0, width * 3 / 4 - 20]);


    // Color scale
    const color = d3.scaleOrdinal()
        .range(d3.schemeCategory10)
        .domain(statusOrder);

    // Add X axis label:
    graph.append("text")
        .attr("text-anchor", "end")
        .attr("x", width * 3 / 4 - 20)
        .attr("y", height + 30)
        .text("Percentage of submissions statuses")
        .attr("fill", "currentColor")
        .style("font-size", "11px");


    const legend = graph.append("g");

    // add legend colors dots
    legend.selectAll("dots")
        .data(statusOrder)
        .enter()
        .append("rect")
        .attr("y", d => legendY(d))
        .attr("x", width * 3 / 4)
        .attr("width", 15)
        .attr("height", 15)
        .attr("fill", d => color(d));

    // add legend text
    legend.selectAll("text")
        .data(statusOrder)
        .enter()
        .append("text")
        .attr("y", d => legendY(d) + 11)
        .attr("x", width * 3 / 4 + 20)
        .attr("text-anchor", "start")
        .text(d => d)
        .attr("fill", "currentColor")
        .style("font-size", "12px");

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
                    .x(r => {
                        return x(r.date);
                    })
                    .y0(r => yCounts[exId](r.stack_sum - r.count) - y.bandwidth())
                    .y1(r => yCounts[exId](r.stack_sum) - y.bandwidth())
                    .curve(d3.curveCatmullRom)(d[1]);
            });

        graph.append("g")
            .attr("transform", `translate(0, ${y(exId) + y.bandwidth()/2})`)
            .call(d3.axisBottom(x).ticks(10, "%a %b-%d"));

        graph.append("g")
            .attr("transform", `translate(0, ${y(exId) - y.bandwidth()/2})`)
            .call(d3.axisLeft(yCounts[exId]).ticks(5));
    }
}

function initTimeseries(url): void {
    d3.select(selector).attr("class", "text-center").append("span")
        .text(I18n.t("js.loading"));
    const processor = function (raw): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        const data: {string: {date; status; count}[]} = raw.data;
        const metaData = {}; // currently only used to track extent for y-axis per exercise
        // pick date of first datapoint (to prevent null checks later on)
        let minDate = Date.parse(data[Object.keys(data)[0]][0].date);
        let maxDate = Date.parse(data[Object.keys(data)[0]][0].date);
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            const records = entry[1];
            metaData[exId] = {};
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
            // let cum_sum = 0      // cum_sum per ex per status
            // Construct a new data array where every status is represented
            const newRecords = [];
            // Used to track if for every day that has datepoints, every status is represented
            let statusVisited = 0;
            records.forEach(d => {
                if (prevDate !== d.date) {
                    // insert empty datapoints to prevent weird jumps in the graph
                    // if not all statusses have been visted (for this date), 
                    // append the unvisited ones
                    while (statusVisited !== statusOrder.length - 1) {
                        newRecords.push({
                            "date": prevDate,
                            "status": statusOrder[statusVisited],
                            "count": 0,
                            "stack_sum": stackSum
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
                    newRecords.push({
                        "date": prevDate,
                        "status": statusOrder[statusVisited],
                        "count": 0,
                        "stack_sum": stackSum
                    });
                    statusVisited += 1;
                }
                minDate = Math.min(minDate, d.date);
                maxDate = Math.max(maxDate, d.date);
                stackSum += d.count;
                statusVisited += 1;
                newRecords.push({ ...d, "stack_sum": stackSum });
            });
            metaData[exId]["maxStack"] = maxStack;
            data[exId] = d3.groups(newRecords, d => d.status);
        });

        drawTimeSeries(data, minDate, maxDate, metaData);
    };
    d3.json(url)
        .then(processor);
}

export { initTimeseries };
