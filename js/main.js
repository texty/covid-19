/**
 * Created by yevheniia on 27.03.20.
 */
const target_countries = ["Ukraine", "Austria", "Bulgaria", "Canada", "China", "France", "Germany",
    "Iran", "Israel", "Italy", "Korea, South", "Turkey", "Moldova", "Poland",
    "Portugal", "Slovenia", "Spain", "Sweden", "United Kingdom", "US"];

const translated_countries = ["Україна", "Австрія", "Болгарія", "Канада", "Китай", "Франція", "Німеччина",
    "Іран", "Ізраїль", "Італія", "Південна Корея", "Туреччина", "Молдова", "Польща", "Португалія",
    "Словенія", "Іспанія", "Швеція", "Великобританія", "США"];

var formatTime = d3.timeFormat("%d-%m-%Y");
d3.select("#today").html(formatTime(new Date));

Promise.all([
    d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"),
    d3.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv")
]).then(function(files) {

    const reshape = function(df, value_col_title){
        var filtered = df.filter(function(d) { return target_countries.includes(d["Country/Region"]) });
        var long_data = [];

        filtered.forEach( function(row) {
            Object.keys(row).forEach( function(colname) {
                // Ignore 'State' and 'Value' columns
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
                helper[key] = Object.assign({}, o); // create a copy of o
                r.push(helper[key]);
            } else {
                helper[key][value_col_title] += o[value_col_title];
            }
            return r;
        }, []);

        return data
    };

    var cases = reshape(files[0], "cases");
    var deaths = reshape(files[1], "deaths");




    /* merge */
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


    var mydata = leftJoin(cases, deaths, "country", "country", "deaths")
        .filter(function(d){ return d.deaths > 0  });

    // append index to the each next day after first death
    var country = "";
    var index = 1;

    mydata.forEach(function(d, i){
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


    const width = window.innerWidth * 0.9;
    const columns = Math.floor(width/250);
    d3.select("#chart_wrapper").style("width", columns * 250 + "px");
    console.log(columns);

    d3.select(window).on("resize", function(){
        const width = window.innerWidth * 0.9;
        const columns = Math.floor(width/250);
        d3.select("#chart_wrapper").style("width", columns * 250 + "px");
    });


    const yScale = d3.scaleSymlog()
        .domain([0, 100000])
        .range([150, 0]);

    var xScale = d3.scaleLinear()
        .domain([0, d3.max(mydata, function(d){ return d.index})]) // input
        .range([0, 150]); // output

    var line = d3.line()
        .x(function(d, i) { return xScale(d.index); }) // set the x values for the line generator
        .y(function(d) { return yScale(d.cases); }); // set the y values for the line generator


    var nested = d3.nest()
        .key(function(d){ return d.country; })
        .entries(mydata);

    const height = nested.length / columns * 250;


   const chart_container = d3.select("#chart");

   const multiple = chart_container.selectAll("svg")
        .data(nested)
        .enter()
        .append("svg")
        .attr("width", 250)
        .attr("height", 250)
        .attr("class", "multiple")
        .append("g")
        .attr("data", function(d) { return d.key })
        .attr("transform", "translate(" + 50 + "," + 50 + ")");

//                .attr("transform", function(d, i){
//                    var xshift = (i % columns) * 250;
//                    var yshift = ~~(i / columns) * 300;
//                    return "translate(" + xshift + "," + yshift + ")"} );

    // This allows to find the closest X index of the mouse:
    var bisect = d3.bisector(function(d) { return d.x; }).left;

    for (var key in nested) {
        drawLine(nested[key].values, nested[key].key);
    }

    function drawLine(data, key) {
        multiple
            .append("text")
            .text(function(d) {
                let country_i = target_countries.indexOf(d.key);
                return translated_countries[country_i]
            })
            .attr("transform", "translate(0," + -20 + ")");

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
            .attr("d", line);

        multiple.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + 150 + ")")
            .call(d3.axisBottom(xScale).tickValues([10, 20, 30, 40, 50, 60])); // Create an axis component with d3.axisBottom


        multiple.append("g")
            .attr("class", "y axis")
            .call(d3.axisLeft(yScale).ticks(5).tickValues([0, 10, 100, 1000, 10000, 100000])); // Create an axis component with d3.axisLeft
    }
});
