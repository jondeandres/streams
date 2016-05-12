(function(w, $) {
	var heatmapData = [];
	var heatmap;

	function refresh() {
		heatmap.setData(heatmapData);
	}

	function removePoint(point) {
		var index = heatmapData.indexOf(point);

		if (index > -1) {
			heatmapData.splice(index, 1);
			refresh();
		}
	}

	function addPoint(event) {
		var data = JSON.parse(event.data);
		var lat = data.point.lat;
		var lng = data.point.lng;

		var point = new google.maps.LatLng(lat, lng);
		heatmapData.push(point);
		refresh();

		setTimeout(function() {
			removePoint(point);
		}, 2000);
	}

	function initMap() {
		var spain = new google.maps.LatLng(40.2085, -3.713)
		var sanFrancisco = new google.maps.LatLng(37.774546, -122.433523);

		var map = new google.maps.Map(document.getElementById('map-canvas'), {
			center: sanFrancisco,
			zoom: 2,
			mapTypeId: google.maps.MapTypeId.SATELLITE
		});

		heatmap = new google.maps.visualization.HeatmapLayer({
			data: heatmapData
		});

		heatmap.setMap(map);
	}

	function initSource() {
		var channel = document.getElementsByTagName('body')[0].getAttribute('data-channel');

    $.ajax({
      type: 'POST',
      url: '/_streams',
      data: { channels: ['errors'] },
      dataType: 'json',
      success: function(data) {
		    var source = new EventSource('/_streams/' + data.path);
		    source.addEventListener('event', addPoint);
      }
    });
	}

	function init() {
		initMap();
		initSource();
	}

	init();

})(window, $);
