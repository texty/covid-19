const target_countries = ["Ukraine", "US", "Spain", "Italy", "Germany", "United Kingdom", "Brazil", "Netherlands", "Russia", "Belarus", "Austria", "Bulgaria", "Canada", "France", "Iran", "India", "Turkey", "Poland", "Sweden", "China"];
const translated_countries = ["Україна", "США", "Іспанія", "Італія", "Німеччина", "Великобританія", "Бразилія", "Нідерланди", "Росія", "Білорусь", "Австрія", "Болгарія", "Канада",  "Франція",  "Іран", "Індія", "Туреччина", "Польща",  "Швеція", "Китай"];
const oneChartWidth = 280;

Promise.all([
    d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"),
    d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv")
]).then(function(files) {
    
    //FT small multiples
    var cases = reshape(files[0].filter(function(d) { return target_countries.includes(d["Country/Region"]) }), "cases");
    var deaths = reshape(files[1].filter(function(d) { return target_countries.includes(d["Country/Region"]) }), "deaths");

    var multiples_data = leftJoin(cases, deaths, "country", "country", "deaths")
        .filter(function(d){ return d.deaths > 0  });

    // var multiples_data = cases.filter(function(d){ return d.cases > 10  });

    //остання наявна в даних дата
    const formatTime = d3.timeFormat("%d/%m");
    const max_date = d3.max(multiples_data, function(d){ return d3.timeParse("%m/%d/%y")(d.date); });
    d3.selectAll(".today").html(formatTime(max_date));
 

    var max_cases = d3.max(multiples_data, function(d){ return d.cases; });
       max_cases = Math.ceil (max_cases / 25000) * 25000;

    // append index to the each next day after first death
    var country = "";
    var index = 1;

    multiples_data.forEach(function(d, i){
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

    var width;
    var columns;

    const set_size = function(){
        //console.log("stop do it!");
        width = d3.select("#chart_wrapper").node().getBoundingClientRect().width;
        columns = Math.floor(width/oneChartWidth);
        if(width > 800) {
            d3.selectAll("#chart, #chart_wrapper p, #chart_wrapper h3, #medical").style("width", columns * oneChartWidth + "px");
        } else {
            d3.selectAll("#chart, #medical").style("width", columns * oneChartWidth + "px");
            d3.selectAll("#chart_wrapper p, #chart_wrapper h3").style("width", "100%");
        }
    };
    
    set_size();
    window.addEventListener("resize", set_size);

    const yScale = d3.scaleSymlog()
        .domain([0, max_cases])
        .range([150, 0]);

    var xScale = d3.scaleLinear()
        .domain([0, d3.max(multiples_data, function(d){ return d.index})])
        .range([0, 150]);

    var line = d3.line()
        .x(function(d, i) { return xScale(d.index); }) 
        .y(function(d) { return yScale(d.cases); });

    
    var nested = d3.nest()
        .key(function(d){ return d.country; })
        .entries(multiples_data);

    //задаємо порядок країн
    nested.sort( function(a, b) { return  target_countries.indexOf(a.key) - target_countries.indexOf(b.key)});

    const height = nested.length / columns * oneChartWidth;
    const chart_container = d3.select("#chart");
    const multiple = chart_container.selectAll("svg")
            .data(nested)
            .enter()
            .append("svg")
            .attr("width", oneChartWidth)
            .attr("height", oneChartWidth)
            .attr("class", "multiple")
            .append("g")
            .attr("data", function(d) { return d.key })
            .attr("transform", "translate(" + 70 + "," + 50 + ")");

    multiple.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + 150 + ")")
        .call(d3.axisBottom(xScale)
            .ticks(4)
            //.tickValues([0, 40, 80, 120, 160])
        ); 


    multiple.append("g")
        .attr("class", "y axis")
        .call(d3.axisLeft(yScale)
            .ticks(5)
            .tickValues([0, 1000, 10000, 100000, 1000000, max_cases])
            .tickSize(-150)
        );


    multiple.append("text")
        .text(function(d) {
            let country_i = target_countries.indexOf(d.key);
            return translated_countries[country_i]
        })
        .attr("transform", "translate(0," + -20 + ")")
        .attr("x", "90")
        .attr("text-anchor", "middle")
        .style("font-weight", "bold");

    for (var key in nested) {
        drawLine(nested[key].values, nested[key].key);
    }

    function drawLine(data, key) {
        multiple.append("path")
            .datum(data)
            .attr("class", "line")
            .style("fill", "none")
            .style("stroke", function(){
                var cur = d3.select(this.parentNode).attr("data");
                return cur === key? '#cf1e25' : "grey"
            })
            .style("stroke-width", function(){
                var cur = d3.select(this.parentNode).attr("data");
                return cur === key? 3 : 1
            })
            .style("opacity", function(){
                var cur = d3.select(this.parentNode).attr("data");
                return cur === key? 1 : 0.5
            })
            .attr("d", line);


        multiple.append('text')
            .datum(data)
            .filter(function(d, i) {
                return i === 0
            })
            .classed('label', true)
            .attr('x', function(d,i) {
                return xScale(d[d.length - 1].index);
                })
            .attr('y', function(d,i) {
                return yScale(d[d.length - 1].cases);
            })
            .text(function(d,i){
                var cur = d3.select(this.parentNode).attr("data");
                return cur === key ? d[d.length - 1].cases : "";

            })
            .style("font-size", "16px");
    }  

});


const reshape = function(df, value_col_title){
    var long_data = [];

    /* from width to long format */
    df.forEach( function(row) {
        Object.keys(row).forEach( function(colname) {
            // columns for ignore
            if(colname == "Country/Region" || colname == "Province/State" || colname == "Lat" || colname == "Long") {
                return
            }
            long_data.push({"country": row["Country/Region"], [value_col_title]: +row[colname], "date": colname});
        });
    });

    //  групуємо за країною і датою в сумуємо значення
    var helper = {};
    var data = long_data.reduce(function(r, o) {
        var key = o.country + '-' + o.date;
        if(!helper[key]) {
            helper[key] = Object.assign({}, o);
            r.push(helper[key]);
        } else {
            helper[key][value_col_title] += o[value_col_title];
        }
        return r;
    }, []);

    return data
};


/* leftJoin */
function leftJoin(left, right, left_id, right_id, col_to_join) {
    var result = [];
    _.each(left, function (litem) {
        var f = _.filter(right, function (ritem) {
            return ritem[right_id] == litem[left_id] && ritem["date"] == litem["date"];
        });
        if (f.length == 0) {
            f = [{}];
        }
        _.each(f, function (i) {
            var newObj = {};
            _.each(litem, function (v, k) {
                newObj[k] = v;
            });
            _.each(i, function (v, k) {
                if(k == col_to_join) {
                    newObj[k] = v;
                }
            });
            result.push(newObj);
        });
    });
    return result;
}

