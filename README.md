elm-soundfont-ports
===================

Migration of [elm-soundfont](https://github.com/newlandsvalley/elm-soundfont) to elm 0.17.

This is an experiment with using ports for an audio application. It maintains an array of audio buffers in javascript (one for each MIDI note) indexed by note number and supports  _requestPlayNote_ and _requestPlayNotes_ command via elm ports which allows you to play the note(s) if you know the MIDI note number.

The javascript is stolen unashamedly from the latest code from three of danigb's soundfont projects: [soundfont-player](https://github.com/danigb/soundfont-player), [note.midi](https://github.com/danigb/note.midi) and [tonal.notation](https://github.com/danigb/tonal.notation). These, I have just discovered, are available as a single js file available [here](https://github.com/danigb/soundfont-player/tree/master/dist).

Libraries Used
--------------

*   Elm-comidi 1.0.2.  This is a parser for MIDI file images which uses the elm-combine parser combinator library. 

*   SoundFont. For reasons explained below, this is not a true library but is packaged in such a way as to make it reasonably straightforward to be shared by different applications.  

Disadvantages of Ports
----------------------

The main problem with ports is that they're not really capable of producing a shareable library but more intended for a one-off application.  Code that uses ports cannot be uploaded to the elm package repository.  There is no automated way of assembling your application so that the native javascript and that produced from the elm compiler can be packaged nicely into an html file - this has to be hand-crafted.

A further problem is that elm's custom and borders protection prevents you from smuggling some data types from javascript that you really need - particularly binary types for which there's no support in elm.  This means (for example) you cannot have a complete AudioBuffer node in elm and pass it back through a port to javascript later.  This in turn means that much of your functionality has to be pushed down into the javascript layer.

As was the case with commands resulting from tasks, outgoing ports have a time penalty associated with them.  This can make it difficult in an audio application to synchronize the sound as you expect it.

Finally, whereas Tasks compose - you can say, for example, Task a `andThen` Task b, commands (which wrap outgoing port requests) don't.  All you can do with a command is to request that the elm runtime executes it.

Advantages of Ports
-------------------

On the other hand, you do not have to use Tasks in order to play sounds. This, perhaps,  means that the elm code is simpler in many cases. 

Examples
--------

#### Basic

[basic](https://github.com/newlandsvalley/elm-soundfont-ports/tree/master/examples/src/basic) just tests the basic functionality of the soundfont port 'library'.

To build, cd to examples and run:

    ./compile.sh

To run, use:

    basic.html

#### MIDI File

[simpleplayer](https://github.com/newlandsvalley/elm-soundfont-ports/tree/master/examples/src/simpleplayer) is a simple MIDI file player (it plays a Swedish tune called 'Lillasystern').  It provides options for loading the acoustic grand piano soundfont, and loading and parsing the MIDI file. It converts this into a performance simply by accumulating the elapsed times of each 'NoteOn' event. It then simply passes this to the javascript port so that it can be played using web-audio. The player can be used with any type of MIDI file, but for multi-track input only the first melody track will be played. 

To build, cd to examples amd run:

    ./compilesp.sh

To run, use:

    simpleplayer.html

#### MIDI Audio Controller

[controlledplayer](https://github.com/newlandsvalley/elm-soundfont-ports/tree/master/examples/src/controlledplayer) is a controller widget for the playback of MIDI files offering start/pause/continue buttons. The player only attempts to play what it finds in MIDI track 0 (i.e. the only track in a single track recording or the first track in a multi track recording).

To build, cd to examples amd run:

    ./compilecp.sh

To run, use:

    controlledplayer.html

Issues
------

The sample tune has a tempo of 120 bpm which is what the simple player delivers naturally. However, the audio controller player uses a command issued through a port for each note it wishes to play.  As was the case when using Tasks and Effects in 0.16, each such request induces a delay in playing the sound. In response, I have reduced the time delay between successive notes by multiplying by a factor (named elmPlayerOverhead) which is currently set to 0.872.  This then delivers the tempo of 120 bpm.

