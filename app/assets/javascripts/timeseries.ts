import * as d3 from "d3";
import { formatTitle, d3Locale } from "graph_helper.js";

export class TimeseriesGraph {
    private selector = "";
    private container: d3.Selection<HTMLDivElement, unknown, HTMLElement, unknown>; // parent div

    private readonly margin = { top: 20, right: 40, bottom: 20, left: 140 };
    private width = 0;
    private height = 0;

    private readonly statusOrder = [
        "correct", "wrong", "compilation error", "runtime error",
        "time limit exceeded", "memory limit exceeded", "output limit exceeded",
    ];

    // data
    private exOrder: string[] // ordering of exercises
    private exMap: Record<string, string>;
    private maxStack = 0;
    private dateRange: number; // difference between first and last date in days
    private minDate: Date;
    private maxDate: Date;
    private data: {[exId: string]: {date: Date; sum: number; [index: string]: number | Date}[]}

    // draws the graph's svg (and other) elements on the screen
    // No more data manipulation is done in this function
    draw(): void {
        d3.timeFormatDefaultLocale(d3Locale);
        const darkMode = window.dodona.darkMode;
        const emptyColor = darkMode ? "#37474F" : "white";
        const lowColor = darkMode ? "#01579B" : "#E3F2FD";
        const highColor = darkMode ? "#039BE5" : "#0D47A1";
        const innerWidth = this.width - this.margin.left - this.margin.right;
        const innerHeight = this.height - this.margin.top - this.margin.bottom;

        const yAxisPadding = 40; // padding between y axis (labels) and the actual graph
        const dateFormat = d3.timeFormat(I18n.t("date.formats.weekday_long"));

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

        // Show the Y scale for exercises (Big Y scale)
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
            .call(formatTitle, this.margin.left-yAxisPadding, this.exMap);

        console.log(this.minDate, this.maxDate);
        console.log(this.data);

        // Show the X scale
        const x = d3.scaleTime()
            .domain([this.minDate, this.maxDate])
            .range([0, innerWidth]);


        // Color scale
        const color = d3.scaleSequential(d3.interpolate(lowColor, highColor))
            .domain([0, this.maxStack]);


        const tooltip = this.container.append("div")
            .attr("class", "d3-tooltip")
            .attr("pointer-events", "none")
            .style("opacity", 0)
            .style("z-index", 5);

        const tooltipLine = graph.append("line")
            .attr("y1", 0)
            .attr("y2", innerHeight-y.bandwidth()/2)
            .style("opacity", 0)
            .attr("pointer-events", "none")
            .attr("stroke", "currentColor")
            .style("width", 40);
        const tooltipLabel = graph.append("text")
            .style("opacity", 0)
            .attr("y", innerHeight-y.bandwidth()/2-5)
            .attr("dominant-baseline", "center")
            .attr("text-anchor", "start")
            .attr("fill", "currentColor")
            .attr("font-size", "12px");


        // add x-axis
        graph.append("g")
            .attr("transform", `translate(0, ${innerHeight-y.bandwidth()/2})`)
            .call(
                d3.axisBottom(x)
                    .ticks(this.dateRange / 2, I18n.t("date.formats.weekday_short"))
            );

        // add cells
        Object.keys(this.data).forEach(exId => {
            graph.selectAll("squares")
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
                    let message = `${I18n.t("js.submissions")} :<br>Total: ${d["sum"]}`;
                    this.statusOrder.forEach(s => {
                        message += `<br>${s}: ${d[s]}`;
                    });
                    tooltip.html(message);


                    const doSwitch = x(d["date"])+tooltipLabel.node().getBBox().width+5>innerWidth;
                    tooltipLine
                        .transition()
                        .duration(100)
                        .style("opacity", 1)
                        .attr("x1", x(d["date"]))
                        .attr("x2", x(d["date"]));
                    tooltipLabel
                        .transition()
                        .duration(100)
                        .style("opacity", 1)
                        .text(dateFormat(d["date"]))
                        .attr("x", doSwitch ? x(d["date"]) - 5 : x(d["date"]) + 5)
                        .attr("text-anchor", doSwitch ? "end" : "start");
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

        svg
            .on("mouseleave", () => {
                tooltipLine
                    .transition()
                    .duration(500)
                    .style("opacity", 0);
                tooltipLabel
                    .transition()
                    .duration(500)
                    .style("opacity", 0);
            });
    }


    // Displays an error message when there is not enough data
    drawNoData(): void {
        this.container
            .style("height", "50px")
            .append("div")
            .text(I18n.t("js.no_data"))
            .style("margin", "auto");
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

        this.minDate = new Date(d3.min(Object.values(data),
            records => d3.min(records, d => d["date"] as Date)));
        this.minDate.setHours(0, 0, 0, 0); // set start to midnight
        this.maxDate = new Date(d3.max(Object.values(data),
            records => d3.max(records, d => d["date"] as Date)));
        this.maxDate.setHours(0, 0, 0, 0); // set end right before midnight

        this.dateRange = Math.round(
            (this.maxDate.getTime() - this.minDate.getTime()) /
            (1000 * 3600 * 24)
        ); // dateRange in days

        this.data = {};
        Object.entries(data).forEach(entry => {
            const exId = entry[0];
            let records = entry[1];
            // parse datestring to date

            const binned = d3.bin()
                .value(d => d["date"].getTime())
                .thresholds(
                    d3.scaleTime()
                        .domain([this.minDate.getTime(), this.maxDate.getTime()])
                        .ticks(d3.timeDay)
                ).domain([this.minDate.getTime(), this.maxDate.getTime()])(records);

            records = undefined; // records no longer needed

            this.data[exId] = [];
            // reduce bins to a single record per bin
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

    // Initializes the container for the graph +
    // puts placeholder text when data isn't loaded +
    // starts data loading (and transforming) procedure
    init(url: string, containerId: string, containerHeight: number): void {
        this.height = containerHeight;
        this.selector = containerId;
        this.container = d3.select(this.selector);

        if (!this.height) {
            this.height = (this.container.node() as HTMLElement).getBoundingClientRect().height - 5;
        }
        this.container
            .html("") // clean up possible previous visualisations
            .style("height", `${this.height}px`) // prevent shrinking after switching graphs
            .style("display", "flex")
            .style("align-items", "center")
            .append("div")
            .text(I18n.t("js.loading"))
            .style("margin", "auto");
        this.width = (this.container.node() as Element).getBoundingClientRect().width;


        d3.json(url)
            .then((raw: Record<string, unknown>) => {
                this.prepareData(raw, url);
            });
    }
}
