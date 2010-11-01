/* Analytics */

var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-129279-17']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();

/* Inits */

var map = null;

function initialize() {
  jQuery.event.add(window, "resize", resizeFrame);

  CFInstall.check({
     mode: "overlay",
     destination: "http://skoleporten.bengler.no"
   });

   init_maps();
}

function resizeFrame() {
    $("#map_canvas").css('height',$(window).height()-$('footer').outerHeight() - 15);
    // $("form.search").css('left',$(window).width()-$('form').outerWidth());
}

/* Maps */

function init_maps() {
  var latlng = new google.maps.LatLng(59.919973705097505, 10.711495568481437);
  var myOptions = {
    zoom: 11,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    mapTypeControl: false,
    navigationControlOptions: { 
      style: google.maps.NavigationControlStyle.DEFAULT}
  };
  map = new google.maps.Map(document.getElementById("map_canvas"),
      myOptions);
  var styledMap = new google.maps.StyledMapType(
      style);
  map.mapTypes.set('styled', styledMap);
  map.setMapTypeId('styled');
  var markerKeeper = new MarkerKeeper(map);
}

function MarkerKeeper() {
  var markers = new Array;
  var markerHash = new Object;
  var previous_query_time = new Date().getTime();
  var show_primaries = true;
  var show_secondaries = true;
  var detail_level = 0;

  this.map = map;

  google.maps.event.addListener(this.map, "bounds_changed", function() {
    getMarkersForBounds();
  });
  google.maps.event.addListener(this.map, "zoom_changed", function() {
    zoomChanged();
  });
  google.maps.event.addListenerOnce(this.map, "tilesloaded", function() {
    getMarkersForBounds();
  });

  function addMarker(marker) {
    marker.setMap(this.map);  
    markers.push(marker);
    markerHash[marker.ident] = true
  }

  function cullAllMarkers() {
    markers = markers.filter(function(m) {
      deleteMarker(m);
    });
  }

  function cullMarkersByBounds() {
    var bounds = this.map.getBounds();
    markers = markers.filter(function(m) {
      if (!bounds.contains(m.position)) {
        deleteMarker(m);
        return false
      }
      return true
    });
  }

  function deleteMarker(marker) {
    marker.setMap(null);
    delete markerHash[marker.ident];
  }

  function updateViewStats() {
    disp_list = new Array
    if (detail_level == 0) {
      if (show_primaries) disp_list.push("barneskoler");
      if (show_secondaries) disp_list.push("ungdomsskoler");
    } else {
      disp_list.push("kommuner");
    }
    s = "Viser " + markers.length + " " + disp_list.join(' og ')
    $('#view_stats').text(s);
  }

  function zoomChanged() {
    zoom = map.getZoom();
    previous_level = detail_level;
    if (zoom < 9) {
      detail_level = 1;
    } else {
      detail_level = 0;
    }
    if (detail_level != previous_level) {
      cullAllMarkers();
    }

  }

  function getMarkersForBounds() {
    cullMarkersByBounds()
    var current_time = new Date().getTime();
    if (current_time - this.previous_query_time < 200) return;
    this.previous_query_time = current_time;
    var bounds = this.map.getBounds();
    queryPack = [bounds.getSouthWest().lat(), bounds.getSouthWest().lng(), 
                 bounds.getNorthEast().lat(), bounds.getNorthEast().lng(), detail_level].join('/');
    $.getJSON('get_markers/' + queryPack, function(data, textStatus) {
      $.each(data, function(i, item) {
        if (markerHash[item.id] == undefined) {
          var size = Math.ceil((item.body / 25)+11);
          if (detail_level != 0) {
            size = (size / 25) + 10;
          }
          var latlng = new google.maps.LatLng(item.lat, item.lon);
          var icon_url = ButtonFactory.create(item.avg, size);
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
          addMarker(marker);
        }
      }); 
    updateViewStats();
    });
  };
  return { 
  }
};

var ButtonFactory = (function() {
  return new function() {

    var h = 1;
    var s = 100;
    var l = 45;
    var a = .80;

    var getColor = function(val) {
      return "hsla(" + val +"," + s + "%," + l +"%," + a +")";
    };

    var getColor1 = function(val) {
      return "hsla(" + val +"," + s + "%," + (l*0.75) +"%," + a +")";
    };

    // draws a rounded rectangle
    var drawRect = function(context, x, y, width, height, size) {
      var radius = 5
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
    }

    this.createCanvas = function(t, size) {
      var canvas = document.createElement("canvas");

      canvas.width = size;
      canvas.height = size;

      var context = canvas.getContext("2d");

      if(t != 0 && t != undefined) {
        var t = t - 0.5
        var log_curve = (1 / (1 + Math.pow(Math.E,-t))) - 0.5
        var color_val = 40 + (log_curve * 700) 
        var color0 = getColor(color_val);
        var stroke = getColor1(color_val);
      } else {
        var color0 = "Silver";
        var stroke = "rgba(100,100,100,1)"
      }

      label = parseInt(t)
      context.clearRect(0,0,size,size);

      context.fillStyle = color0;
      context.strokeStyle = stroke;

      drawRect(context, 0, 0, size, size, size);
      context.fill();
      context.stroke();

      // context.fillStyle = "white";
      // context.strokeStyle = "black"
      // 
      // // Render Label
      // context.font = "normal 10px Arial";
      // context.textBaseline  = "top";
      // 
      // var textWidth = context.measureText(label);

      // centre the text.
      // context.fillText(label,
      //   Math.floor((width / 2) - (textWidth.width / 2)),
      //   4
      // );

      return canvas;

    };

    this.create = function(label, range) {
      var canvas = this.createCanvas(label, range);
      return canvas.toDataURL();
    };
  }
})();


var style = [
  {
    featureType: "landscape",
    elementType: "all",
    stylers: [
      { visibility: "simplified" },
      { saturation: -98 },
      { lightness: -58 },
      { gamma: 0.73 }
    ]
  },{
    featureType: "water",
    elementType: "all",
    stylers: [
      { visibility: "on" },
      { hue: "#0091ff" },
      { saturation: -52 },
      { lightness: -47 }
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
      { gamma: .5 },
      { saturation: -24 },
      { lightness: -51 }
    ]
  },{
    featureType: "transit",
    elementType: "all",
    stylers: [
      { visibility: "off" }
    ]
  }
]
