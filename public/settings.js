
// Config hashes

resultChartOptions = {
  chart: {
     // defaultSeriesType: 'line',
     defaultSeriesType: 'column',
     marginRight: 160,
     marginBottom: 35,
     width: 400,
     height: 180
  },
  title: {
     text: null,
  },
  xAxis: {
     title: {
        text: null
     },
     categories: ['2008', '2009', '2010']
  },
  yAxis: {
     max: 1,
     min: 0,
     title: {
        text: 'Resulatat'
     },
     plotLines: [{
        value: 0,
        width: 1,
        color: '#808080'
     }]
  },
  tooltip: {
     formatter: function() {
               return '<b>'+ this.series.name +'</b><br/>'+
           this.x +': '+ this.y.toFixed(2) ;
     }
  },
  legend: {
     layout: 'vertical',
     align: 'right',
     verticalAlign: 'top',
     x: 0,
     y: 0,
     borderWidth: 0
  },
};

/**
 * Gray theme for Highcharts JS
 * @author Torstein Hønsi
 */

Highcharts.theme = {
	colors: ["#DDDF0D", "#7798BF", "#55BF3B", "#DF5353", "#aaeeee", "#ff0066", "#eeaaee", 
		"#55BF3B", "#DF5353", "#7798BF", "#aaeeee"],
	chart: {
		backgroundColor: {
			linearGradient: [0, 0, 0, 180],
			stops: [
				[0, 'rgb(16, 16, 16)'],
				[1, 'rgb(0, 0, 0)']
			]
		},
		borderWidth: 0,
		borderRadius: 4,
		plotBackgroundColor: null,
		plotShadow: false,
		plotBorderWidth: 0
	},
	title: {
		style: { 
			color: '#FFF',
			font: '16px Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif'
		}
	},
	subtitle: {
		style: { 
			color: '#DDD',
			font: '12px Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif'
		}
	},
	xAxis: {
		gridLineWidth: 0,
		lineColor: '#999',
		tickColor: '#999',
		labels: {
			style: {
				color: '#999',
				fontWeight: 'bold'
			}
		},
		title: {
			style: {
				color: '#AAA',
				font: 'bold 12px Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif'
			}				
		}
	},
	yAxis: {
		alternateGridColor: null,
		minorTickInterval: null,
		gridLineColor: 'rgba(255, 255, 255, .1)',
		lineWidth: 0,
		tickWidth: 0,
		labels: {
			style: {
				color: '#999',
				fontWeight: 'bold'
			}
		},
		title: {
			style: {
				color: '#AAA',
				font: 'bold 12px Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif'
			}				
		}
	},
	legend: {
		itemStyle: {
			color: '#CCC'
		},
		itemHoverStyle: {
			color: '#FFF'
		},
		itemHiddenStyle: {
			color: '#444'
		}
	},
	labels: {
		style: {
			color: '#DDD'
		}
	},
	tooltip: {
		backgroundColor: {
			linearGradient: [0, 0, 0, 50],
			stops: [
				[0, 'rgba(0, 0, 0, 1)'],
				[1, 'rgba(15, 15, 15, 1)']
			]
		},
		borderWidth: 0,
		style: {
			color: '#FFF'
		}
	},
  credits: 
  {
    style: { color: '#333;text-transform:lowercase;position:relative;top:-20px;' }
  },
	plotOptions: {
    series: {
      borderColor: '#000',
      borderRadius: 2,            
    },
		line: {
			dataLabels: {
				color: '#CCC'
			},
			marker: {
				lineColor: '#333'
			}
		},
		spline: {
			marker: {
				lineColor: '#333'
			}
		},
		scatter: {
			marker: {
				lineColor: '#333'
			}
		},
	},
	
	toolbar: {
		itemStyle: {
			color: '#CCC'
		}
	},
	
	navigation: {
		buttonOptions: {
			backgroundColor: {
				linearGradient: [0, 0, 0, 20],
				stops: [
					[0.4, '#606060'],
					[0.6, '#333333']
				]
			},
			borderColor: '#000000',
			symbolStroke: '#C0C0C0',
			hoverSymbolStroke: '#FFFFFF'
		}
	},
	
	exporting: {
		buttons: {
			exportButton: {
				symbolFill: '#55BE3B'
			},
			printButton: {
				symbolFill: '#7797BE'
			}
		}
	},	
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);

