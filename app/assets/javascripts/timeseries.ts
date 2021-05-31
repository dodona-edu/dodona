import * as d3 from "d3";
import { SeriesGraph } from "series_graph";

export class TimeseriesGraph extends SeriesGraph {
    private readonly margin = { top: 20, right: 40, bottom: 20, left: 140 };
    private readonly fontSize = 12;

    private readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    // data
    private maxStack = 0; // largest value (max of colour scale domain)
    private dateRange: number; // difference between first and last date in days
    private minDate: Date;
    private maxDate: Date;
    private data: {[exId: string]: {date: Date; sum: number; [index: string]: number | Date}[]}

    // draws the graph's svg (and other) elements on the screen
    // No more data manipulation is done in this function
    draw(): void {
        const darkMode = window.dodona.darkMode;
        const emptyColor = darkMode ? "#37474F" : "white"; // no data in cell
        const lowColor = darkMode ? "#01579B" : "#E3F2FD"; // almost no data in cell
        const highColor = darkMode ? "#039BE5" : "#0D47A1"; // a lot of data in cell
        const innerWidth = this.width - this.margin.left - this.margin.right;
        const innerHeight = this.height - this.margin.top - this.margin.bottom;

        const yAxisPadding = 40; // padding between y axis (labels) and the actual graph

        const svg = this.container
            .style("height", `${this.height}px`)
            .append("svg")
            .attr("width", this.width)
            .attr("height", this.height);

        // position graph
        const graph = svg
            .append("g")
            .attr("transform",
                "translate(" + this.margin.left + "," + this.margin.top + ")");

        // Y scale for exercises
        const y = d3.scaleBand()
            .range([innerHeight, 0])
            .domain(this.exOrder)
            .padding(.5);

        // make sure cell size isn't bigger than bandwidth
        const rectSize = Math.min(y.bandwidth()*1.5, innerWidth / this.dateRange - 5);

        const yAxis = graph.append("g")
            .call(d3.axisLeft(y).tickSize(0))
            .attr("transform", `translate(-${yAxisPadding}, -${y.bandwidth()/2})`);
        yAxis
            .select(".domain").remove();
        yAxis
            .selectAll(".tick text")
            .call(this.formatTitle, this.margin.left-yAxisPadding, this.exMap);

        // Show the X scale
        const end = new Date(this.maxDate);
        end.setDate(end.getDate()-1); // bin and domain seem to handle end differently
        const x = d3.scaleTime()
            .domain([this.minDate.getTime(), end.getTime()])
            .range([0, innerWidth]);


        // add x-axis
        graph.append("g")
            .attr("transform", `translate(0, ${innerHeight-y.bandwidth()/2})`)
            .call(
                d3.axisBottom(x)
                    .ticks(15, I18n.t("date.formats.weekday_short"))
            );


        // Color scale
        const color = d3.scaleSequential(d3.interpolate(lowColor, highColor))
            .domain([0, this.maxStack]);


        // init tooltip
        const tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        // add cells
        graph.selectAll(".rectGroup")
            .data(Object.keys(this.data))
            .enter()
            .append("g")
            .attr("class", "rectGroup")
            .each((exId: string, i: number, group) => {
                d3.select(group[i]).selectAll("rect")
                    .data(this.data[exId])
                    .enter()
                    .append("rect")
                    .attr("class", "day-cell")
                    .classed("empty", d => d["sum"] === 0)
                    .attr("rx", 6)
                    .attr("ry", 6)
                    .attr("fill", emptyColor)
                    .attr("x", d => x(d["date"])-rectSize/2)
                    .attr("y", y(exId)-rectSize/2)
                    .on("mouseover", (e, d) => {
                        tooltip.transition()
                            .duration(200)
                            .style("opacity", .9);
                        let message = `${this.longDateFormat(d["date"])}<br>
                        ${I18n.t("js.submissions")} :<br>${d["sum"]} ${I18n.t("js.total")}`;
                        this.statusOrder.forEach(s => {
                            if (d[s]) {
                                message += `<br>${d[s]} ${s}`;
                            }
                        });
                        tooltip.html(message);
                    })
                    .on("mousemove", (e, _) => {
                        const bbox = tooltip.node().getBoundingClientRect();
                        tooltip
                            .style(
                                "left",
                                `${d3.pointer(e, svg.node())[0]-bbox.width * 1.1}px`
                            )
                            .style(
                                "top",
                                `${d3.pointer(e, svg.node())[1]-bbox.height*1.1}px`
                            );
                    })
                    .on("mouseout", () => {
                        tooltip.transition()
                            .duration(500)
                            .style("opacity", 0);
                    })
                    .transition().duration(500)
                    .attr("width", rectSize)
                    .attr("height", rectSize)
                    .transition().duration(500)
                    .attr("fill", d => d["sum"] === 0 ? "" : color(d["sum"]));
            });
    }

    insertFakeData(data): void {
        const end = new Date(data[Object.keys(data)[0]][0].date);
        const start = new Date(end);
        start.setDate(start.getDate() - 14);
        for (const exName of Object.keys(data)) {
            data[exName] = [];
            for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1 + Math.random()*2)) {
                for (let i=0; i < this.statusOrder.length; i++) {
                    if (Math.random() > 0.5) {
                        data[exName].push({
                            "date": new Date(d),
                            "status": this.statusOrder[i],
                            "count": Math.round(Math.random()*20)
                        });
                    }
                }
            }
        }
    }

    // transforms the data into a form usable by the graph +
    // calculates addinional data
    // finishes by calling draw
    // can be called recursively when a 'data not yet available' response is received
    prepareData(raw: Record<string, unknown>, url: string): void {
        if (raw["status"] == "not available yet") {
            setTimeout(() => d3.json(url)
                .then((r: Record<string, unknown>) => this.prepareData(r, url)), 1000);
            return;
        }

        d3.select(`${this.selector} *`).remove();


        const data = raw.data as {
            (exId: string): {date: (Date | string); status: string; count: number}[]
        };

        // extract id's and reverse order (since graphs are built bottom up)
        this.exOrder = (raw.exercises as [string, string][]).map(ex => ex[0]).reverse();

        // convert exercises into object to map id's to exercise names
        this.exMap = (raw.exercises as [string, string][])
            .reduce((map, [id, name]) => ({ ...map, [id]: name }), {});

        if (Object.keys(data).length === 0) {
            this.drawNoData();
        }

        this.height = 75 * Object.keys(raw.data).length;

        Object.entries(data).forEach(entry => { // parse dates
            entry[1].forEach(d => {
                d["date"] = new Date(d["date"]);
            });
        });

        this.insertFakeData(data);

        this.minDate = new Date(d3.min(Object.values(data),
            records => d3.min(records, d => d["date"] as Date)));
        this.minDate.setHours(0, 0, 0, 0); // set start to midnight
        this.maxDate = new Date(d3.max(Object.values(data),
            records => d3.max(records, d => d["date"] as Date)));
        this.maxDate.setHours(23, 59, 59, 99); // set end right before midnight

        this.dateRange = Math.round(
            (this.maxDate.getTime() - this.minDate.getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days

        this.data = {};
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            let records = entry[1];

            // bin per day
            const binned = d3.bin()
                .value(d => d["date"].getTime())
                .thresholds(
                    d3.scaleTime()
                        .domain([this.minDate.getTime(), this.maxDate.getTime()])
                        .ticks(d3.timeDay)
                ).domain([this.minDate.getTime(), this.maxDate.getTime()])(records);

            records = undefined; // records no longer needed

            this.data[exId] = [];
            // reduce bins to a single record per bin (see this.data)
            binned.forEach((bin, i) => {
                const newDate = new Date(this.minDate);
                newDate.setDate(newDate.getDate() + i);
                const sum = d3.sum(bin, r => r["count"]);
                this.maxStack = Math.max(this.maxStack, sum);
                this.data[exId].push(bin.reduce((acc, r) => {
                    acc["date"] = r["date"];
                    acc["sum"] = sum;
                    acc[r["status"]] = r["count"];
                    return acc;
                }, this.statusOrder.reduce((acc, s) => {
                    acc[s] = 0; // make sure record is initialized with 0 counts
                    return acc;
                }, { "date": newDate, "sum": 0 })));
            });
        });

        this.draw();
    }
}
