elm-soundfont-ports
===================

I am undecided how best to migrate elm-soundfont to elm 0.17.  One option is to use ports, which in turn, at the moment, means pushing all the heavy lifting down into the javascript layer.  The reason for this is that elm ports do "customs and border protection" which means it is impossible to smuggle an unsupported data type (such as AudioBuffer) past the border controls.

This is an experiment with using ports for an audio application. It maintains an array of audio buffers in javascript (one for each MIDI note) indexed by note number and supports a _requestPlayNote_ command via an elm port which allows you to play the note if you know its MIDI note number.

The javascript is stolen unashamedly from the latest code from three of danigb's soundfont projects: [soundfont-player](https://github.com/danigb/soundfont-player), [note.midi](https://github.com/danigb/note.midi) and [tonal.notation](https://github.com/danigb/tonal.notation). These, I have just discovered, are available as a single js file available [here](https://github.com/danigb/soundfont-player/tree/master/dist).

This is not intended to be a long-lived project, but it does serve as a basic illustration of how to use ports with elm 0.17.