Promise.all([
    d3.csv("data/ukraine/cases_by_date.csv"),
    d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv")
]).then(function(files) {
    const margin = {top: 50, left: 60, bottom: 50, right: 50};
    const height = 350;

    const parseDate = d3.timeParse("%Y-%m-%d");
    const formatDate = d3.timeFormat("%d/%m");
    const max_date = d3.max(files[0], function(d){ return parseDate(d.date)});
    d3.selectAll(".current-date").text(formatDate(max_date));

    const sortArray = ["Ukraine", "Turkey", "Poland", "Spain"];
    const translatedArray = ["Україна", "Туреччина", "Польща", "Іспанія"];

    // const sortArray = ["Sweden", "Ukraine"];
    // const translatedArray = ["Швеція", "Україна"];

    const colorCountry = d3.scaleOrdinal()
        .domain(["Ukraine", "Turkey", "Poland", "Spain", "Sweden"])
        .range(["red", "#333", "blue", "green", "blue"]);

    const input = files[1].filter(function(d) { return sortArray.includes(d["Country/Region"]) });
    const ukraine_growth_data = reshape(input,"cases").filter(function(d){ return d.cases > 10  });

    // append index to the each next day after first death
    var country = "";
    var index = 0;

    ukraine_growth_data.forEach(function(d, i){
        if(country != d.country) {
            index = 0;
            d.index = index;
            country = d.country;
            index = index + 1
        }  else {
            d.index = index;
            index = index + 1
        }
    });

    const max_day = d3.max(ukraine_growth_data, function(d){ return d.index});
    var max_cases = d3.max(ukraine_growth_data, function(d){ return d.cases; });
        max_cases = Math.ceil (max_cases / 25000) * 25000;
    const x0 = 10;

    var nested = d3.nest()
        .key(function(d){ return d.country; })
        .entries(ukraine_growth_data);

    nested.sort( function(a, b) { return  sortArray.indexOf(b.key) - sortArray.indexOf(a.key)});

    drawSpeedChart();
    window.addEventListener("resize", drawSpeedChart);

    function drawSpeedChart() {
        d3.select("#growth_speed svg").remove();

        const width = d3.select("#growth_speed").node().getBoundingClientRect().width - margin.left - margin.right;

        const yScale = d3.scaleSymlog()
            .domain([x0, max_cases])
            .range([height, 0]);

        var xScale = d3.scaleLinear()
            .domain([1, max_day])
            .range([0, width]);

        var line = d3.line()
            .x(function (d, i) {
                return xScale(d.index);
            })
            .y(function (d) {
                return yScale(d.cases);
            });


        const svg = d3.select("#growth_speed")
            .insert("svg", ".source")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        //x axis
        svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(d3.axisBottom(xScale)
                .ticks(10)
                .tickFormat(function (d, i) {
                    return i == 0 ? "день " + d : d
                }));

        //y axis
        svg.append("g")
            .attr("class", "y axis")
            .call(d3.axisLeft(yScale)
                .tickSize(-width)
                // .tickValues([10, 100, 1000, 5000, 10000]));
                .tickValues([10, 100, 1000, 10000, 25000, 50000, max_cases]));


        /* chart container*/
        const wrapper = svg.append("g")
            .attr("transform", "translate(0," + 0 + ")");

        var glines = wrapper.selectAll('.line-group')
            .data(nested).enter()
            .append('g')
            .attr('class', 'line-group');

        /* countries lines */
        glines
            .append('path')
            .attr('class', 'line-interactive')
            .attr('d', function (d) {
                return line(d.values)
            })
            .style('stroke', function (d) {
                return colorCountry(d.key)
            });

        /* countries labels */
        glines
            .append('text')
            .classed('label', true)
            .attr('x', function (k) {
                return xScale(k.values[k.values.length - 1].index - 3);
            })
            .attr('y', function (k) {
                return yScale(k.values[k.values.length - 1].cases) - 8;
            })
            .text(function (k) {
                return translatedArray[sortArray.indexOf(k.key)];
            })
            .style("font-size", "17px")
            .style("font-weight", "bold")
            .style("fill", function (k) {
                return colorCountry(k.key)
            });


        /* tooltips */
        var mouseG = glines.append("g") // black vertical line
            .attr("class", "mouse-over-effects");

        mouseG.append("path")
            .attr("class", "mouse-line")
            .style("stroke", "black")
            .style("stroke-width", "1px")
            .style("opacity", "0");

        var mousePerLine = mouseG
            .append("g")
            .attr("class", "mouse-per-line");

        mousePerLine.append("circle")
            .attr("r", 7)
            .style("stroke", function (d) {
                return colorCountry(d.key);
            })
            .style("fill", "none")
            .style("stroke-width", "1px")
            .style("opacity", "0");

        mousePerLine.append("text")
            .attr("transform", "translate(10,3)");

        var lines = document.getElementsByClassName("line-interactive");

        mouseG.append("rect")
            .attr("width", width)
            .attr("height", height)
            .attr("fill", "none")
            .attr("pointer-events", "all")
            .on("mouseout", function () {
                d3.select(".mouse-line").style("opacity", "0");
                d3.selectAll(".mouse-per-line circle").style("opacity", "0");
                d3.selectAll(".mouse-per-line text").style("opacity", "0")
            })
            .on("mouseover", function () {
                d3.select(".mouse-line").style("opacity", "1");
                d3.selectAll(".mouse-per-line circle").style("opacity", "1");
                d3.selectAll(".mouse-per-line text").style("opacity", "1")
            })
            .on("mousemove", function () {
                var bisect = d3.bisector(function (d) {
                    return d.index;
                }).right;
                var mouse = d3.mouse(this);
                var xDate = xScale.invert(mouse[0]);
                d3.select(".mouse-line")
                    .attr("d", function () {
                        var d = "M" + mouse[0] + "," + height;
                        d += " " + mouse[0] + "," + 0;
                        return d;
                    });

                d3.selectAll(".mouse-per-line")
                    .attr("transform", function (d, i) {
                        var idx = bisect(d.values, xDate);
                        var beginning = 0,
                            end = lines[i].getTotalLength(),
                            target = null;

                        while (true) {
                            target = Math.floor((beginning + end) / 2);
                            pos = lines[i].getPointAtLength(target);
                            if ((target === end || target == beginning) && pos.x !== mouse[0]) {
                                break;
                            }
                            if (pos.x > mouse[0]) end = target;
                            else if (pos.x < mouse[0]) beginning = target;
                            else break; // position found
                        }

                        d3.select(this)
                            .select("text")
                            .text(function () {
                                var textValue = d.values.filter(function (k) {
                                    return k.index === idx
                                });
                                if (textValue.length > 0) {
                                    return textValue[0].cases;
                                }
                            })
                            .style("fill", function (d) {
                                return colorCountry(d.key)
                            })
                            .attr("transform", function (d) {
                                if (d.key === "Poland") {
                                    return "translate(" + 10 + "," + -(10) + ")"
                                } else if (d.key === "Ukraine") {
                                    return "translate(" + 10 + "," + 10 + ")"
                                } else {
                                    return "translate(" + 10 + "," + 0 + ")";
                                }
                            })
                            .style("font-weight", "bold")
                            .style("text-shadow", "-1px -1px 0 #fff, 1px -1px 0 #fff, -1px  1px 0 #fff, 1px  1px 0 #fff");

                        return "translate(" + mouse[0] + "," + (pos.y) + ")";
                    })
                    .style("opacity", function (d, i) {
                        return xDate < d.values.length ? 1 : 0
                    });
            });

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

        //лінії моделів
        [1, 2, 3, 5].forEach(function (n) {
            const model_wrapper = wrapper.append("g")
                .attr("class", "model-" + n);

            model_wrapper.append("path")
                .attr("d", line(calculate_model(x0, n)))
                .attr("class", "model-line");


            model_wrapper.selectAll("text")
                .data(calculate_model(x0, n))
                .enter()
                .append("text")
                .attr("x", function (d) {
                    return xScale(d.index)
                })
                .attr("y", function (d) {
                    return yScale(d.cases)
                })
                .text(function (d, i) {
                    return i === calculate_model(x0, n).length - n ? "подвоєння - " + n + " дн." : null;
                })
                .style("fill", "grey")
                .style("font-size", "14px")
                .attr("text-anchor", function (d, i) {
                    return n == 1 ? "end" : "middle"
                });
        });
    }


    function calculate_model(x0, n){
        var model = [];
        for(var t = 1; t <= max_day; t++){
            let day_value = Math.round(x0 * Math.pow(2, (t/n)));
            if(day_value < max_cases) {
                model.push({"index": t, "cases": day_value});
            }
        }
        return model;
    }
    
   



});




