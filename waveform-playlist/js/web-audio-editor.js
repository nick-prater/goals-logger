var playlist_json = '[{"src":"/clip/english/23.wav","start":0,"end":12.79,"name":"in a row","cuein":0,"cueout":12.79,"fadeOut":{"shape":"sCurve","duration":1.6024999999999991}},{"src":"/clip/english/17.wav","start":12.79,"end":15.79,"name":"Drum","cuein":0,"cueout":3},{"src":"/clip/english/3.wav","start":15.79,"end":22.39,"name":"An amazing season","cuein":0,"cueout":6.6,"fadeIn":{"shape":"logarithmic","duration":0.5225000000000009},"fadeOut":{"shape":"linear","duration":1.4525000000000006}}]';





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

playlist.load(
	JSON.parse(playlist_json)
).then(function() {

	//initialize the WAV exporter.
	playlist.initExporter();

});


