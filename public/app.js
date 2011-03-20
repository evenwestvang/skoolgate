/* Inits */

var map = null;
var currentInfoBox = null;

function initialize(options) {
  if (options.fullscreen) {
    jQuery.event.add(window, "resize", resizeFrame);
    resizeFrame();
  }

  window.fbAsyncInit = function() {
    FB.init({appId: '137325976336227',
    status: true,
    cookie: true,
    xfbml: true});
  };

  CFInstall.check({
     mode: "overlay",
     destination: "http://skoleporten.bengler.no"
  });
  initMaps(options);
}

function resizeFrame() {
    $("#map_canvas").css('height',$(window).height());
}

/* Maps */

function initMaps(options) {
  options = options || {};
  var latlng;
  if (options.ll) {
    var latlng = new google.maps.LatLng(options.ll[0], options.ll[1]);
  } else {
    var latlng = new google.maps.LatLng(59.86176086468102, 10.75612752648925);
  }
  
  var myOptions = {
    zoom: 11,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    mapTypeControl: false,
    navigationControlOptions: { 
      style: google.maps.NavigationControlStyle.DEFAULT}
  };

  map = new google.maps.Map(document.getElementById(options.map_id || "map_canvas"),
      myOptions);

  var styledMap = new google.maps.StyledMapType(
      mapStyle);
  map.mapTypes.set('styled', styledMap);
  map.setMapTypeId('styled');
  var markerKeeper = new MarkerKeeper(map, options);
  
  google.maps.event.addListener(this.map, "click", function() {
    markerKeeper.closeAnyInfoboxes();
  });

  google.maps.event.addListener(this.map, "drag", function() {
    markerKeeper.getMarkersForBounds();
  });

  google.maps.event.addListener(this.map, "idle", function() {
    markerKeeper.getMarkersForBounds(true);
  });

  google.maps.event.addListenerOnce(this.map, "tilesloaded", function() {
    markerKeeper.getMarkersForBounds();
  });

  google.maps.event.addListener(this.map, "zoom_changed", function() {
    markerKeeper.closeAnyInfoboxes();
  });

  $("#2008_link").click(function(e) {
    markerKeeper.setYear(2008, this);
  });

  $("#2009_link").click(function() {
    markerKeeper.setYear(2009, this);
  });

  $("#2010_link").click(function() {
    markerKeeper.setYear(2010, this);
  });
  
  $("nav.year_selector").show();
}

function MarkerKeeper(map, options) {
  this.markers = [];
  this.markerHash = {};
  this.previousQueryTime = new Date().getTime();
  this.showPrimaries = true;
  this.showSecondaries = true;
  this.detailLevel = 0;
  this.activeYear = 2010;
  this.map = map;
  this.useContrast = options.useContrast;
  this.options = options;

  this.setYear = function(year, clicked) {
    $("nav.year_selector ul li").removeClass("active");
    $(clicked).addClass("active");
    this.activeYear = year;
    this.getMarkersForBounds(true, true);
  };

  this.closeAnyInfoboxes = function() {
    if (this.currentInfoBox !== undefined) {
      this.currentInfoBox.close();
      this.currentInfoBox = undefined;
    }
  };

  this.addMarker = function(marker) {
    marker.setMap(this.map);  
    this.markers.push(marker);
    this.markerHash[marker.ident] = true;
    if (this.options.popInfoBoxFor == marker.ident) {
      this.markerClicked(map, marker);
      this.options.popInfoBoxFor = null;
    }
  };

  this.cullAllMarkers = function() {
    var self = this;
    this.markers = this.markers.filter(function(m) {
      self.deleteMarker(m);
    });
  };

  this.deleteMarker = function(marker) {
    marker.setMap(null);
    delete this.markerHash[marker.ident];
  };

  this.cullMarkersByBounds = function() {
    var bounds = this.map.getBounds();
    var self = this;
    this.markers = this.markers.filter(function(m) {
      if (!bounds.contains(m.position)) {
        self.deleteMarker(m);
        return false;
      }
      return true;
    });
  };

  this.updateViewStats = function() {
    disp_list = [];
    if (this.detailLevel == "schools") {
      if (this.showPrimaries) disp_list.push("barneskoler");
      if (this.showSecondaries) disp_list.push("ungdomsskoler");
    } else {
      disp_list.push("kommuner. Zoom inn for skoler.");
    }
    s = "Viser " + this.markers.length + " " + disp_list.join(' og ');
    $('#view_stats').text(s);
  };

  this.getMarkersForBounds = function(force, cull) {
    this.cull = cull;
    if (!cull) { this.cullMarkersByBounds(); }
    var current_time = new Date().getTime();
    if (current_time - this.previousQueryTime < 500 && !force) return;
    this.previousQueryTime = current_time;
    var bounds = this.map.getBounds();
    queryPack = [bounds.getSouthWest().lat(), bounds.getSouthWest().lng(), 
                 bounds.getNorthEast().lat(), bounds.getNorthEast().lng(), this.activeYear].join('/');
    var self = this;
    $.getJSON('/get_markers/' + queryPack, function(data, textStatus) {
      if (self.cull) { self.cullAllMarkers() };
      self.updateMarkers(data);
    });
  };

  this.updateMarkers = function(data) {
    var self = this;
    newDetailLevel = data.detailLevel;
    if (self.detailLevel != newDetailLevel) {
      this.cullAllMarkers();
      if (newDetailLevel == "schools") {
        $('#view_stats_container').removeClass('less_details');
      } else {
        $('#view_stats_container').addClass('less_details');
      }
      self.detailLevel = newDetailLevel;
    }
    
    $(data.objects).each(function(i, item) {
      if (self.markerHash[item.id] === undefined) {
        var size = Math.ceil(Math.sqrt(item.body));
        if (self.detailLevel != "schools") {
          size = (size / 15) + 10;
        }
        var latlng = new google.maps.LatLng(item.lat, item.lon);
        var icon_url = MarkerFactory.create(item.avg, size, self.useContrast);
        var image = new google.maps.MarkerImage(icon_url, 
          new google.maps.Size(size, size),
          new google.maps.Point(0, 0),
          new google.maps.Point(size/2, size/2)
        );
        var marker = new google.maps.Marker({
              ident: item.id,
              position: latlng,
              title: item.name,
              icon: image
          });
        self.addMarker(marker);
        google.maps.event.addListener(marker, 'click', function() {
          self.markerClicked(map,marker);
        });
      }
    }); 
    this.updateViewStats();
  };

  this.markerClicked = function(map, marker) {
    var self = this;
    boxContent = document.createElement("div");
    boxContent.style.cssText = "border: 1px solid black;margin-top: 0px; background: rgba(0,0,0,0.80); padding: 5px 10px 8px 10px; border-radius:3px; -moz-border-radius:3px; webkit-border-radius:3px; -moz-box-shadow #000 5px 5px 10px; -webkit-box-shadow #000 5px 5px 10px; box-shadow #000 5px 5px 10px;";

    $.getJSON('/marker_info/' + marker.ident, function(data, textStatus) {
      data.school_url = encodeURI(data.school_url);
      infoBox = $("#schoolTemplate").tmpl(data).appendTo($(boxContent));
      var averageSerie = {
        name: "Årsresultat",
        data: []
      };
      var series = {};

      $(data.annual_results).each(function(i,annual_result) {
        averageDataPoint = {
          x: annual_result.year, 
          y: annual_result.result_average,
          color: MarkerFactory.getColor(annual_result.result_average, self.useContrast, 10)
        }
        averageSerie.data.push(averageDataPoint);

        $(annual_result.subjects).each(function(i,result) {
          ident = result.school_year + "_" + result.test_code
          if (series[ident] === undefined) { 
            series[ident] = {
              name: result.school_year + ". kl " + humanizeTestCode(result.test_code),
              data: [],
              visible: false
            }
          };
          series[ident].data.push({
            x: annual_result.year, 
            y: result.normalized_result
          });
        });
      });

      if (averageSerie.data.length > 0) {
        resultChartOptions.series = [averageSerie];
        var sorted_keys = []
        for (key in series) {
          sorted_keys.push(key);
        }
        sorted_keys = sorted_keys.sort();
        for (key in sorted_keys) {
          resultChartOptions.series.push(series[sorted_keys[key]]);
        }
        resultChartOptions.chart.renderTo = infoBox.children().last()[0];
        chart = new Highcharts.Chart(resultChartOptions);

        if (data.school_url !== undefined) {
          setTimeout(function() {
            var like = '<fb:like href="'+data.school_url+'" width="400" height="20" show_faces="false" layout="standard" action="recommend" colorscheme="dark"/>'
            var insert = infoBox.children().last()
            insert.append(like);
            FB.XFBML.parse(insert[0]);
        }, 1500)};
      }
      var schoolPosition = new google.maps.LatLng(data.location[0],data.location[1]);

      self.map.panTo(schoolPosition);
      if (self.options.fullscreen) {
        self.map.panBy(320, 150);
      } else {
        self.map.panBy(180, 150);
      }

      var panoramaOptions = {
        pov: {
          heading: 34,
          pitch: 10,
          zoom: 0
        }
      };
      
      var sv = new google.maps.StreetViewService();
      sv.getPanoramaByLocation(schoolPosition, 100, processSVData);
      function processSVData(data, status) {
        if (status == google.maps.StreetViewStatus.OK) {
          $('#street_view_button').show();
          $('#street_view_button').click(function() {
            panorama = map.getStreetView();
            var markerPanoID = data.location.pano;
            panorama.setOptions(panoramaOptions);
            panorama.setVisible(true);
            panorama.setPano(markerPanoID);

            function refreshPanoPov() {
              var markerPos = marker.getPosition();
              var panoPos = panorama.getPosition();
              if (markerPos && panoPos) {
                var markerPosLat = markerPos.lat() / 180 * Math.PI;
                var markerPosLng = markerPos.lng() / 180 * Math.PI;
                var panoPosLat = panoPos.lat() / 180 * Math.PI;
                var panoPosLng = panoPos.lng() / 180 * Math.PI;

                var y = Math.sin(markerPosLng - panoPosLng) * Math.cos(markerPosLat);
                var x = Math.cos(panoPosLat) * Math.sin(markerPosLat) - 
                  Math.sin(panoPosLat)*Math.cos(markerPosLat) * Math.cos(markerPosLng - panoPosLng);
                var brng = Math.atan2(y,x) / Math.PI * 180;
                var pov = panorama.getPov();
                pov.heading = brng;
                panorama.setPov(pov);
              }
            }
            google.maps.event.addListener(marker, 'position_changed',refreshPanoPov);
            google.maps.event.addListener(panorama, 'position_changed',refreshPanoPov);
          });
        }
      }
    });
    this.closeAnyInfoboxes();
    infoBoxOptions.content = boxContent;
    this.currentInfoBox = new InfoBox(infoBoxOptions);                
    this.currentInfoBox.open(map, marker);
  };

  var maxScore = function(result) {
    if(result.school_year == 5) {
      return 3;
    } 
    return 5;
  };

  var humanizeTestCode = function(test_code) {
    if (test_code.match('REG')) { return "regning"; }
    if (test_code.match('LES')) { return "lesning"; }
    if (test_code.match('ENG')) { return "engelsk"; }
  };
}


var MarkerFactory = (function() {
  return new function() {

    var h = 1;
    var s = 100;
    var l = 45;
    var a = 0.75;

    this.getColor = function(val, useContrast, gamma) {
      if (!useContrast) {
        return "hsla(" + this.sCurveColor(val, gamma) +"," + s + "%," + l +"%," + a +")";
      } else {
        return "hsla(" + 0 +"," + 0 + "%," + this.sBrightness(val) +"%," + 1 +")";
      }
    };

    this.getColor1 = function(val, useContrast, gamma) {
      if (!useContrast) {
        return "hsla(" + this.sCurveColor(val, gamma) +"," + s + "%," + (l*0.75) +"%," + a +")";
      } else {
        return "hsla(" + 0 +"," + 0 + "%," + this.sBrightness(val)*0.25 +"%," + 1 +")";
      }
    };

    this.sCurveColor = function(val, gamma) {
      val -= 0.5;
      // var log_curve = (1 / (1 + Math.pow(Math.E,-(t*3))));
      // var color_val = -30 + (log_curve * 180);

      var log_curve = (1 / (1 + Math.pow(Math.E,-(val*gamma))));
      var color_val = -00 + (log_curve * 90);

      return color_val;
    };

    this.sBrightness = function(t) {
      t = t - 0.5;
      var log_curve = (1 / (1 + Math.pow(Math.E,-t))) - 0.5;
      var bright_val = 43 + (log_curve) * 500;
      return bright_val;
    };

    // draws a rounded rectangle
    var drawRect = function(context, x, y, width, height, size) {
      var radius = 5;
      width = height = size;
      context.beginPath();
      context.moveTo(x + radius, y);
      context.lineTo(x + width - radius, y);
      context.quadraticCurveTo(x + width, y, x + width, y + radius);
      context.lineTo(x + width, y + height - radius);
      context.quadraticCurveTo(x + width, y + height, x + width -
      radius, y + height);
      context.lineTo(x + radius, y + height);
      context.quadraticCurveTo(x, y + height, x, y + height - radius);
      context.lineTo(x, y + radius);
      context.quadraticCurveTo(x, y, x + radius, y);
      context.closePath();
    };

    this.createCanvas = function(t, size, useContrast, gamma) {
      var canvas = document.createElement("canvas");
      canvas.width = size;
      canvas.height = size;
      var context = canvas.getContext("2d");
      var color0;
      var boxStroke;
      var colorVal;
      if(t !== 0 && t !== undefined && t != null) {
        color0 = this.getColor(t, useContrast, gamma);
        boxStroke = this.getColor1(t, useContrast, gamma);
      } else {
        color0 = "Silver";
        boxStroke = "rgba(100,100,100,1)";
      }
      context.clearRect(0,0,size,size);
      context.fillStyle = color0;
      context.strokeStyle = boxStroke;
      drawRect(context, 0, 0, size, size, size);
      context.fill();
      context.stroke();
      return canvas;
    };

    this.create = function(label, size, useContrast, gamma) {
      gamma = gamma || 10
      var canvas = this.createCanvas(label, size, useContrast, gamma);
      return canvas.toDataURL();
    };
  }();
})();

mapStyle = [
  {
    featureType: "landscape",
    elementType: "all",
    stylers: [
      { visibility: "simplified" },
      { saturation: -100 },
      { lightness: -62 },
      { gamma: 0.73 }
    ]
  },{
    featureType: "water",
    elementType: "all",
    stylers: [
      { visibility: "on" },
      { hue: "#0091ff" },
      { saturation: -72 },
      { lightness: -57 }
    ]
  },{
    featureType: "road",
    elementType: "all",
    stylers: [
      { visibility: "on" },
      { lightness: -59 },
      { gamma: 0.84 },
      { saturation: -99 }
    ]
  },{
    featureType: "road",
    elementType: "labels",
    stylers: [
      { visibility: "off" },
      { saturation: -100 }
    ]
  },{
    featureType: "poi",
    elementType: "all",
    stylers: [
      { visibility: "off" }
    ]
  },{
    featureType: "administrative",
    elementType: "labels",
    stylers: [
      { visibility: "on" },
      { gamma: 0.5 },
      { saturation: -0 },
      { lightness: -51 }
    ] 
  },{
    featureType: "transit",
    elementType: "all",
    stylers: [  
      { visibility: "off" }
    ]
  } 
];

infoBoxOptions = {
  disableAutoPan: false,
  infoBoxClearance: 10,
  maxWidth: 0,
  zIndex: 0,
  boxStyle: {
    opacity: 1,
    width: "420px"
   },
  closeBoxMargin: "-9px -9px 2px 2px",
  closeBoxURL: "/close.png",
  infoBoxClearance: new google.maps.Size(1, 1),
  isHidden: false,
  pane: "floatPane",
  enableEventPropagation: false
};
