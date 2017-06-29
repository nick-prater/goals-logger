/*
 * This script is provided to give an example how the playlist can be controlled using the event emitter.
 * This enables projects to create/control the useability of the project.
 * Ultimately move this code to ui/playlist
 */
var ee = playlist.getEventEmitter();
var $container = $("body");
var $timeFormat = $container.find('.time-format');
var $audioStart = $container.find('.audio-start');
var $audioEnd = $container.find('.audio-end');
var $time = $container.find('.audio-pos');

var format = "hh:mm:ss.uuu";
var startTime = 0;
var endTime = 0;
var audioPos = 0;
var downloadUrl = undefined;
var isLooping = false;
var playoutPromises;



function cueFormatters(format) {

  function clockFormat(seconds, decimals) {
    var hours,
        minutes,
        secs,
        result;

    hours = parseInt(seconds / 3600, 10) % 24;
    minutes = parseInt(seconds / 60, 10) % 60;
    secs = seconds % 60;
    secs = secs.toFixed(decimals);

    result = (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes) + ":" + (secs < 10 ? "0" + secs : secs);

    return result;
  }

  var formats = {
    "seconds": function (seconds) {
        return seconds.toFixed(0);
    },
    "thousandths": function (seconds) {
        return seconds.toFixed(3);
    },
    "hh:mm:ss": function (seconds) {
        return clockFormat(seconds, 0);
    },
    "hh:mm:ss.u": function (seconds) {
        return clockFormat(seconds, 1);
    },
    "hh:mm:ss.uu": function (seconds) {
        return clockFormat(seconds, 2);
    },
    "hh:mm:ss.uuu": function (seconds) {
        return clockFormat(seconds, 3);
    }
  };

  return formats[format];
}

function updateSelect(start, end) {
  if (start < end) {
    $('.btn-trim-audio').removeClass('disabled');
    $('.btn-loop').removeClass('disabled');
  }
  else {
    $('.btn-trim-audio').addClass('disabled');
    $('.btn-loop').addClass('disabled');
  }

  $audioStart.val(cueFormatters(format)(start));
  $audioEnd.val(cueFormatters(format)(end));

  startTime = start;
  endTime = end;
}

function updateTime(time) {
  $time.html(cueFormatters(format)(time));

  audioPos = time;
}

updateSelect(startTime, endTime);
updateTime(audioPos);


$container.on("click", ".btn-play", function() {
  ee.emit("play");
});

$container.on("click", ".btn-pause", function() {
  isLooping = false;
  ee.emit("pause");
});

$container.on("click", ".btn-stop", function() {
  isLooping = false;
  ee.emit("stop");
});

$container.on("click", ".btn-rewind", function() {
  isLooping = false;
  ee.emit("rewind");
});

$container.on("click", ".btn-fast-forward", function() {
  isLooping = false;
  ee.emit("fastforward");
});

$container.on("click", ".btn-clear", function() {
  isLooping = false;
  ee.emit("clear");
});







$container.on("click", ".btn-download", function () {
  ee.emit('startaudiorendering', 'wav');
});

$container.on("click", ".btn-seektotime", function () {
  var time = parseInt(document.getElementById("seektime").value, 10);
  ee.emit("select", time, time);
});

$container.on("change", ".select-seek-style", function (node) {
  playlist.setSeekStyle(node.target.value);
});

$container.on("input change", ".master-gain", function(e){
  ee.emit("mastervolumechange", e.target.value);
});

$container.on("change", ".continuous-play", function(e){
  ee.emit("continuousplay", $(e.target).is(':checked'));
});

$container.on("change", ".link-endpoints", function(e){
  ee.emit("linkendpoints", $(e.target).is(':checked'));
});

$container.on("change", ".automatic-scroll", function(e){
  ee.emit("automaticscroll", $(e.target).is(':checked'));
});


function displaySoundStatus(status) {
	console.log(status);
}


function displayLoadingData(data) {
	$("#playlist_status_message").text(data);
	console.log(data);
}


function displayDownloadLink(link) {
  var dateString = (new Date()).toISOString();
  var $link = $("<a/>", {
    'href': link,
    'download': 'waveformplaylist' + dateString + '.wav',
    'text': 'Download mix ' + dateString,
    'class': 'btn btn-small btn-download-link'
  });

  $('.btn-download-link').remove();
  $('.btn-download').after($link);
}


/*
* Code below receives updates from the playlist.
*/
ee.on("select", updateSelect);

ee.on("timeupdate", updateTime);

ee.on("mute", function(track) {
  displaySoundStatus("Mute button pressed for " + track.name);
});

ee.on("solo", function(track) {
  displaySoundStatus("Solo button pressed for " + track.name);
});

ee.on("volumechange", function(volume, track) {
  displaySoundStatus(track.name + " now has volume " + volume + ".");
});

ee.on("mastervolumechange", function(volume) {
  displaySoundStatus("Master volume now has volume " + volume + ".");
});


var audioStates = ["uninitialized", "loading", "decoding", "finished"];

ee.on("audiorequeststatechange", function(state, src) {
  var name = src;

  if (src instanceof File) {
    name = src.name;
  }

  displayLoadingData("Track " + name + " is " + audioStates[state]);
});

ee.on("loadprogress", function(percent, src) {
  var name = src;

  if (src instanceof File) {
    name = src.name;
  }

  displayLoadingData("Track " + name + " has loaded " + percent + "%");
});

ee.on("audiosourcesloaded", function() {
  displayLoadingData("Tracks have all finished decoding.");
});

ee.on("audiosourcesrendered", function() {
  displayLoadingData("Tracks have been rendered");
});




ee.on('audiorenderingfinished', function (type, data) {
  if (type == 'wav'){
    if (downloadUrl) {
      window.URL.revokeObjectURL(downloadUrl);
    }

    downloadUrl = window.URL.createObjectURL(data);
    displayDownloadLink(downloadUrl);
  }
});

ee.on('finished', function () {
  console.log("The cursor has reached the end of the selection !");

  if (isLooping) {
    playoutPromises.then(function() {
      playoutPromises = playlist.play(startTime, endTime);
    });
  }
});
