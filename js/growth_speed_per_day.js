d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv").then(function(data) {
     const margin = {top: 20, left: 60, bottom: 50, right: 50};
     const height = 350;
     const parseDate = d3.timeParse("%m/%d/%Y");
     const formatDate = d3.timeFormat("%m/%y");

     const sortArray = ["Ukraine"];

    var input = data.filter(function(d) { return sortArray.includes(d["Country/Region"]) });
    input = reshape(input,"cases").filter(function(d){ return d.cases > 6  });
    //console.log(input);

    // append index to the each next day after first death
    var country = "";
    var index = 1;

    input.forEach(function(d, i){
        d.date = parseDate(d.date);
        d.cases = +d.cases;
        if(country != d.country) {
            index = 1;
            d.index = index;
            country = d.country;
            index = index + 1
        }  else {
            d.index = index;
            index = index + 1
        }
    });

    const max_date = d3.max(input, function (d) { return d.date });
    const min_date = d3.min(input, function (d) { return d.date });

    var start_cases_value = input.filter(function(d){ return d.date.getTime() ===  min_date.getTime()})[0].cases;

// log(2)/(log(cases)-log(lag(cases)) ), # новий (коректний) спосіб

    // input.forEach(function (d, i) {
    //     if(i > 0){
    //         console.log(d);
    //         console.log(d.cases);
    //         console.log(input[i].cases);
    //         console.log(input[i-1].cases);
    //     }
    //
    // });

    input.forEach(function (d, i) {
        if(i > 0) {
            //d.log = Math.log(2) * d.index/Math.log(d.cases / start_cases_value);
            d.log = Math.log(2) / (Math.log(d.cases) - Math.log(input[i - 1].cases));
            d.log = d.log.toFixed(1);
            d.log = +d.log;
        } else {
            d.log = "Infinity"
        }
    });

    // console.table(input);

    input = input.filter(function(d){ return d.log != "Infinity"}).filter(function(d){ return d.log < 80});

    const max_value = d3.max(input, function (d) { return d.log  });

    var last_dubble_koef = input.filter(function(d){ return d.date.getTime() ===  max_date.getTime()})[0];
    d3.select("#last_dubble_koef").html(last_dubble_koef);

    var nested = d3.nest()
         .key(function (d) {
             return d.country;
         })
         .entries(input);

    drawSpeedPerDayChart();
    window.addEventListener("resize", drawSpeedPerDayChart);

    
    function drawSpeedPerDayChart() {
        d3.select("#growth_speed_per_day svg").remove();


    const width = d3.select("#growth_speed").node().getBoundingClientRect().width - margin.left - margin.right;

    const yScale = d3.scaleLinear()
        .domain([0, max_value + 1])
        .range([height, 0]);

    var xScale = d3.scaleTime()
        .domain([min_date, max_date])
        .range([0, width]);

    var line = d3.line()
        .x(function (d, i) {
            return xScale(d.date);
        })
        .y(function (d) {
            return yScale(d.log);
        });


    const svg = d3.select("#growth_speed_per_day")
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
            .ticks(d3.timeDay.every(31))
            .tickFormat(function (d, i) {
                return formatDate(d)
            }));

    //y axis
    svg.append("g")
        .attr("class", "y axis")
        .call(d3.axisLeft(yScale)
            .tickSize(-width));


    /* chart container*/
    const wrapper = svg.append("g")
        .attr("transform", "translate(0," + 0 + ")");


    var glines = wrapper.selectAll('.log-line')
        .data(nested).enter()
        .append('g')
        .attr('class', 'log-line');

    /* countries lines */
    glines
        .append('path')
        .attr('class', 'logline-interactive')
        .attr('d', function (d) {
            return line(d.values)
        })
        .style('stroke', "red")
        .style('fill', "none")
        .style('stroke-width', "3px")
        .style('stroke-opacity', "0.5");


    nested.forEach(function(d){
         d.values.forEach(function(t) {
             glines
                 .append("circle")
                 .attr("class", "tip")
                 .attr("fill", "red")
                 .attr("stroke", "none")
                 .attr("cx", xScale(t.date))
                 .attr("cy", yScale(t.log))
                 .attr("r", 5)
                 .attr("data-tippy-content", function () {
                     return "станом на " + d3.timeFormat("%d/%m")(t.date) + ": коефіцієнт <br> подвоєння складає " + t.log + " дн."

                 })
                 .style('opacity', "0.8")
         })
    });

        tippy('.tip', {
            arrow: false,
            arrowType: 'round',
            size: 'big',
            allowHTML: true
        });




    }




});

