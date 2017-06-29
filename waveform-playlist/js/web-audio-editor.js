var playlist = WaveformPlaylist.init({
	samplesPerPixel: 3000,
	waveHeight: 25,
	container: document.getElementById("playlist"),
	state: 'cursor',
	colors: {
		waveOutlineColor: '#E0EFF1',
		timeColor: 'grey',
		fadeColor: 'black'
	},
	timescale: true,
	controls: {
		show: true,
		width: 200
	},
	seekStyle : 'line',
	zoomLevels: [500, 1000, 3000, 5000]
});

playlist.load([

]).then(function() {

	//initialize the WAV exporter.
	playlist.initExporter();

});


