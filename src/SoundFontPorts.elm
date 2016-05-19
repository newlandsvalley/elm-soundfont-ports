port module SoundFontPorts exposing (..)


import SoundFontTypes exposing (..)

-- outgoing ports (for commands to javascript)

port initialiseAudioContext : () -> Cmd msg

port requestIsOggEnabled : () -> Cmd msg

port requestLoadFonts : () -> Cmd msg

port requestPlayNote : MidiNote -> Cmd msg

port requestPlayNoteSequence : List MidiNote -> Cmd msg


-- incoming ports (for subscriptions from javascript)

port getAudioContext : (AudioContext -> msg) -> Sub msg

port oggEnabled : (Bool -> msg) -> Sub msg

port fontsLoaded : (Bool -> msg) -> Sub msg


