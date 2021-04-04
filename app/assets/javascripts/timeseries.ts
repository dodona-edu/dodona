import * as d3 from "d3";

const selector = "#timeseries-container";
const margin = { top: 0, right: 10, bottom: 20, left: 70 };
const width = 1500 - margin.left - margin.right;
const height = 1000 - margin.top - margin.bottom;
const status_order = [
    'correct', 'wrong', 'compilation error', 'runtime error',
    'time limit exceeded', 'memory limit exceeded', 'output limit exceeded',
    'queued', 'running'
];



function initTimeseries(url) {
    d3.select(selector).attr("class", "text-center").append("span")
        .text(I18n.t("js.loading"));
    const processor = function (raw) {
        console.log(raw);
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        let data = raw.data;
        let metaData = {};  // currently only used to track extent for y-axis per exercise
        let minDate = Date.parse(data[Object.keys(data)[0]][0].date);
        let maxDate = Date.parse(data[Object.keys(data)[0]][0].date);
        Object.entries(data).forEach(entry => {
            let ex_id = entry[0];
            let records = entry[1];
            metaData[ex_id] = {};
            // parse datestring to date
            records.forEach(r => {
                r.date = Date.parse(r.date);
            });

            // sort records by date
            records.sort((a, b) => {
                if (a.date === b.date) {
                    return status_order.indexOf(a.status) - status_order.indexOf(b.status);
                }
                return a.date - b.date
            });

            let prev_date = records[0].date;
            console.log(records)
            let stack_sum = 0;     // cumulative sum (per ex) per day
            let maxStack = 0;      // Used to calculate extent for y-axis
            // let cum_sum = 0     // cum_sum per ex per status
            let newRecords = [];   // Construct a new data array where every status is represented
            let statusVisited = 0; // Used to track if for every day that has datepoints, every status is represented
            records.forEach(d => {
                if (prev_date !== d.date) {
                    // insert empty datapoints to prevent weird jumps in the graph
                    while (statusVisited !== status_order.length - 1) { // if not all statusses have been visted (for this date), append the unvisited ones
                        newRecords.push({date: prev_date, status: status_order[statusVisited], count: 0, stack_sum: stack_sum});
                        statusVisited += 1;
                    }
                    prev_date = d.date;
                    maxStack = Math.max(maxStack, stack_sum);
                    stack_sum = 0;
                    statusVisited = 0;
                }
                // insert empty datapoints to prevent weird jumps in the graph
                while (status_order[statusVisited] !== d.status) { // if one or more statusses were skipped, insert them
                    newRecords.push({date: prev_date, status: status_order[statusVisited], count: 0, stack_sum: stack_sum});
                    statusVisited += 1;
                }
                minDate = Math.min(minDate, d.date);
                maxDate = Math.max(maxDate, d.date);
                stack_sum += d.count;
                statusVisited += 1;
                newRecords.push({...d, 'stack_sum': stack_sum})
            });
            metaData[ex_id]["maxStack"] = maxStack;
            console.log(newRecords)
            data[ex_id] = d3.groups(newRecords, d => d.status);
        });

        drawTimeSeries(data, minDate, maxDate, metaData);
    };
    d3.json(url)
        .then(processor);
}

function drawTimeSeries(data, minDate, maxDate, metaData) {
    console.log(data);
    console.log(metaData);
    console.log(minDate, maxDate)

    const graph = d3.select(selector)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale
    let y = d3.scaleBand()
        .range([height-10, 0])
        .domain(Object.keys(data))
        .padding(.4);
    graph.append("g")
        .attr('transform', `translate(0, ${-y.bandwidth() - 10})`)
        .call(d3.axisLeft(y).tickSize(0))
        .select(".domain").remove();

    let y_counts = Object.entries(metaData).reduce((acc, v) => {
            acc[v[0]] =
                d3.scaleLinear()
                    .domain([0, v[1].maxStack])
                    .range([y.bandwidth(), 0])
            return acc;
        },
        {}
    )
    let legend_y = d3.scaleBand()
        .range([y(y.domain()[y.domain().length - 1]), height/3 + y(y.domain()[y.domain().length - 1])])
        .domain(status_order)


    // Show the X scale
    let x = d3.scaleTime()
        .domain([minDate, maxDate])
        .range([0, width * 3 / 4 - 20])


    // Color scale
    let color = d3.scaleOrdinal()
        .range(d3.schemeCategory10)
        .domain(status_order);

    // Add X axis label:
    graph.append("text")
        .attr("text-anchor", "end")
        .attr("x", width * 3 / 4 - 20)
        .attr("y", height + 30)
        .text("Percentage of submissions statuses")
        .attr("fill", "currentColor")
        .style("font-size", "11px");


    let legend = graph.append('g')

    // add legend colors dots
    legend.selectAll('dots')
        .data(status_order)
        .enter()
        .append('rect')
        .attr('y', d => legend_y(d))
        .attr('x', width * 3 / 4)
        .attr('width', 15   )
        .attr('height', 15)
        .attr('fill', d => color(d));

    // add legend text
    legend.selectAll('text')
        .data(status_order)
        .enter()
        .append('text')
        .attr('y', d => legend_y(d) + 11)
        .attr('x', width * 3 / 4 + 20)
        .attr('text-anchor', 'start')
        .text(d => d)
        .attr("fill", "currentColor")
        .style("font-size", "12px");

    // add bars
    for (let ex_id of Object.keys(data)) {
        let ex_group = graph.append('g')
            .attr('transform', d => `translate(0, ${y(ex_id) + y.bandwidth() / 2})`);
        let records = data[ex_id];
        ex_group.selectAll("areas")
            .data(records)
            .enter()
            .append('path')
            .attr("class", d => d[0])
            .style("stroke", "none")
            .style("fill", d => color(d[0]))
            .attr("d", d => {
                return d3.area()
                    .x(r => {
                        return x(r.date);
                    })
                    .y0(r => y_counts[ex_id](r.stack_sum - r.count) - y.bandwidth())
                    .y1(r =>  y_counts[ex_id](r.stack_sum) - y.bandwidth())
                    .curve(d3.curveCatmullRom)
                    (d[1])
            });

        graph.append("g")
            .attr("transform", `translate(0, ${y(ex_id) + y.bandwidth()/2})`)
            .call(d3.axisBottom(x).ticks(10, "%a %b-%d"))

        graph.append("g")
            .attr("transform", `translate(0, ${y(ex_id) - y.bandwidth()/2})`)
            .call(d3.axisLeft(y_counts[ex_id]).ticks(5))
    }
}

export { initTimeseries };