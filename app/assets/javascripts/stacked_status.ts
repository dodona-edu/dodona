import * as d3 from "d3";

const selector = "#stacked_status-container";
const margin = { top: 0, right: 10, bottom: 20, left: 70 };
const width = 1100 - margin.left - margin.right;
const height = 500 - margin.top - margin.bottom;
const statusOrder = [
    "correct", "wrong", "compilation error", "runtime error",
    "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    "queued", "running"
];



function initStacked(url) {
    d3.select(selector).attr("class", "text-center").append("span")
    .text(I18n.t("js.loading"));
    const processor = function (raw) {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url).then(processor), 1000);
            return;
        }
        d3.select(`${selector} *`).remove();

        let data = raw.data;
        data.sort((a, b) => {
            if (a.exercise_id === b.exercise_id) {
                return status_order.indexOf(a.status) - status_order.indexOf(b.status);
            }
            else {
                return a.exercise_id - b.exercise_id;
            }
        });
        let prev_id = data[0].exercise_id;
        let prev_sum = 0;
        let max_sum = {};
        data.forEach(d => {
            if (prev_id !== d.exercise_id) {
                max_sum[prev_id] = prev_sum;
                prev_id = d.exercise_id;
                prev_sum = 0;
            }
            prev_sum += d.count;
            d["cum_sum"] = prev_sum;
        });
        max_sum[prev_id] = prev_sum;

        drawStacked(data, max_sum);
    };
    d3.json(url).then(processor);
}

function drawStacked(data, max_sum) {

    const xTicks = 10;

    const graph = d3.select(selector)
        .append("svg")
        .attr("width", 1200)
        .attr("height", 550)
        .append("g")
        .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

    // Show the Y scale
    let y = d3.scaleBand()
        .range([height, 0])
        .domain(data.map(d => d.exercise_id))
        .padding(.5);
    graph.append("g")
        .call(d3.axisLeft(y).tickSize(0))
        .select(".domain").remove();

    let legend_y = d3.scaleBand()
        .range([y(y.domain()[y.domain().length - 1]), height/3 + y(y.domain()[y.domain().length - 1])])
        .domain(status_order)


    // Show the X scale
    let x = d3.scaleLinear()
        .domain([0, 1])
        .range([0, width * 3 / 4 - 20])
    graph.append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x).ticks(xTicks))
        // .select(".domain").remove();


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


    let legend = graph.append("g")

    // add legend colors dots
    legend.selectAll("dots")
        .data(status_order)
        .enter()
        .append("rect")
        .attr("y", d => legend_y(d))
        .attr("x", width * 3 / 4)
        .attr("width", 15   )
        .attr("height", 15)
        .attr("fill", d => color(d));

    // add legend text
    legend.selectAll("text")
        .data(status_order)
        .enter()
        .append("text")
        .attr("y", d => legend_y(d) + 11)
        .attr("x", width * 3 / 4 + 20)
        .attr("text-anchor", "start")
        .text(d => d)
        .attr("fill", "currentColor")
        .style("font-size", "12px");

    // add bars
    graph.selectAll("bars")
        .data(data)
        .enter()
        .append("rect")
        .attr("x", d => x((d.cum_sum - d.count) / max_sum[d.exercise_id]))
        .attr("width", d => x(d.count / max_sum[d.exercise_id]))
        .attr("y", d => y(d.exercise_id))
        .attr("height", y.bandwidth())
        .attr("fill", d => color(d.status));


}

export { initStacked };